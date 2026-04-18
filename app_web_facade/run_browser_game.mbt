///|
pub using @app {
  type AppContentConfig,
  type ScriptFactory,
  type AppController,
  default_app_error_handler,
}

///|
pub using @assets_web {type WebAssetStore}

///|
pub using @state {type GameState}

///|
pub using @storage {trait SaveSlotStore, default_save_slot_storage}

///|
pub using @gallery {type ReplayStateFactories}

///|
priv struct DomUiPortFactory {
  root_id : String
}

///|
fn DomUiPortFactory::new(root_id : String) -> DomUiPortFactory {
  { root_id, }
}

///|
impl @ui_game.UiPortFactory for DomUiPortFactory with create_port(
  self,
  ui_strings~,
  script_locale_json~,
  script_default_locale_json~,
  vocal_locale_dir~,
  script_locale~,
  script_default_locale~,
) {
  @ui_game.UiPort::from_dom(
    @ui_dom.UiDom::new(
      self.root_id,
      ui_strings~,
      script_locale_json~,
      script_default_locale_json~,
      vocal_locale_dir~,
      script_locale~,
      script_default_locale~,
    ),
  )
}

///|
pub async fn[T : FromJson + ToJson] run_browser_game(
  script_factory_builder : async (@assets_web.WebAssetStore) -> @core.Script[T],
  new_state : () -> @state.GameState[T],
  root_id? : String = "ui-root",
  canvas_id? : String = "gl-canvas",
  config? : @app.AppContentConfig = @app.AppContentConfig::default(),
  save_store? : &@storage.SaveSlotStore = @storage.default_save_slot_storage(),
  gallery_replay_state_factories? : @gallery.ReplayStateFactories[T] = @gallery.ReplayStateFactories::new(),
  on_controller_ready? : (@app.AppController[T]) -> Unit = _ => (),
) -> Unit {
  let web_assets = @assets_web.WebAssetStore::new()
  let assets : &@assets.AssetStore = web_assets
  let audio = @audio_web.AudioDom::new_with_store(assets)
  let ui_factory = DomUiPortFactory::new(root_id)
  let menu_factory = @ui_menu_dom.DomMenuFactory::new(
    root_id,
    config.save_namespace,
    ui_strings=config.ui_strings,
  )
  let render_extension = @presenter.make_pixi_render_extension_hook_from_canvas(
    canvas_id, web_assets,
  )

  let ports = @app.AppRuntimePorts::new(
    ui_factory,
    menu_factory,
    assets,
    audio~,
    render_extension?,
  )
  let script_factory : @app.ScriptFactory[T] = () => {
    script_factory_builder(web_assets)
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

  @app.run_browser_app_loop(
    app,
    ui_locale_path=config.ui_locale_path,
    script_locale_dir=config.script_locale_dir,
  )
}
