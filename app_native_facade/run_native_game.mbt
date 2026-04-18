///|
pub using @app {
  type AppContentConfig,
  type ScriptFactory,
  type AppController,
  default_app_error_handler,
}

///|
pub using @assets_selene {type NativeAssetStore}

///|
pub using @selene_runtime {type NativeLoopConfig}

///|
pub using @state {type GameState}

///|
pub using @storage {trait SaveSlotStore, default_save_slot_storage}

///|
pub using @gallery {type ReplayStateFactories}

///|
pub fn[T : FromJson + ToJson] run_native_game(
  script_factory_builder : (@assets_selene.NativeAssetStore) -> @core.Script[T],
  new_state : () -> @state.GameState[T],
  config? : @app.AppContentConfig = @app.AppContentConfig::default(),
  text_font_family? : String = "",
  save_store? : &@storage.SaveSlotStore = @storage.default_save_slot_storage(),
  gallery_replay_state_factories? : @gallery.ReplayStateFactories[T] = @gallery.ReplayStateFactories::new(),
  loop_config? : @selene_runtime.NativeLoopConfig = @selene_runtime.NativeLoopConfig::default(),
  on_controller_ready? : (@app.AppController[T]) -> Unit = _ => (),
) -> Unit {
  let native_store = @assets_selene.NativeAssetStore::new()
  let assets : &@assets.AssetStore = native_store
  let audio = @audio_selene.SeleneAudio::new_with_store(assets)
  let ui_factory = @ui_selene.SeleneUiPortFactory::new(
    ui_strings=config.ui_strings,
    text_font_family~,
  )
  let menu_factory = @ui_menu_selene.SeleneMenuFactory::new(
    ui_strings=config.ui_strings,
    save_namespace=config.save_namespace,
    text_font_family~,
  )
  let presenter = @selene_presenter.SelenePresenter::new(
    asset_store=native_store,
  )
  presenter.set_ui_overlay_providers(
    Some(ui_factory.ui_overlay_provider()),
    Some(menu_factory.ui_overlay_provider()),
  )
  let (core_render_sync, render_extension) = presenter.as_render_hooks()

  let ports = @app.AppRuntimePorts::new(
    ui_factory,
    menu_factory,
    assets,
    audio~,
    core_render_sync~,
    render_extension~,
    idle_render=() => presenter.submit_overlay_frame(),
  )
  let script_factory : @app.ScriptFactory[T] = () => {
    script_factory_builder(native_store)
  }

  let app = @app.create_app_controller(
    script_factory,
    new_state,
    ports,
    config~,
    save_store~,
    gallery_replay_state_factories~,
  )

  on_controller_ready(app)

  @app.run_native_app_loop(
    app,
    ui_locale_path=config.ui_locale_path,
    script_locale_dir=config.script_locale_dir,
    idle_render=() => presenter.submit_overlay_frame(),
    config=loop_config,
  )
}
