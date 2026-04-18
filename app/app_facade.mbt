///|
pub struct AppRuntimePorts {
  ui_port_factory : &@ui_game.UiPortFactory
  menu_factory : &MenuFactory
  assets : &AssetStore
  audio : &AudioPort
  core_render_sync : RenderSyncHook
  render_extension : RenderExtensionHook?
  event_hook : EventHook
  idle_render : () -> Unit
}

///|
pub fn AppRuntimePorts::new(
  ui_port_factory : &@ui_game.UiPortFactory,
  menu_factory : &MenuFactory,
  assets : &AssetStore,
  audio? : &AudioPort = @audio.dummy,
  core_render_sync? : RenderSyncHook = noop_core_render_sync,
  render_extension? : RenderExtensionHook,
  event_hook? : EventHook = audio.as_event_hook(),
  idle_render? : () -> Unit = () => (),
) -> AppRuntimePorts {
  {
    ui_port_factory,
    menu_factory,
    assets,
    audio,
    core_render_sync,
    render_extension,
    event_hook,
    idle_render,
  }
}

///|
pub struct AppContentConfig {
  save_namespace : String
  autosave_slot : String
  autosave_title : String
  menu_background : String
  settings_background : String
  gallery_background : String
  credits_background : String
  menu_music : Music?
  ui_click_sfx_url : String
  menu_music_loop : Bool
  ui_strings : UiStrings
  languages : Array[(String, String)]
  ui_locales_json : String
  ui_locale_path : String
  script_locale_json : String
  script_default_locale_json : String
  script_locale_dir : String
  vocal_locale_dir : String
  credits : String?
  start_logo_urls : Array[String]
  start_logo_duration_ms : Int
}

///|
pub impl Default for AppContentConfig with default() {
  {
    save_namespace: "global",
    autosave_slot: "autosave",
    autosave_title: "",
    menu_background: "",
    settings_background: "",
    gallery_background: "",
    credits_background: "",
    menu_music: None,
    ui_click_sfx_url: "",
    menu_music_loop: true,
    ui_strings: UiStrings::default(),
    languages: [],
    ui_locales_json: "",
    ui_locale_path: "locales/ui.json",
    script_locale_json: "",
    script_default_locale_json: "",
    script_locale_dir: "locales",
    vocal_locale_dir: "",
    credits: None,
    start_logo_urls: [],
    start_logo_duration_ms: 2000,
  }
}

///|
pub fn AppContentConfig::new(
  save_namespace? : String = "global",
  autosave_slot? : String = "autosave",
  autosave_title? : String = "",
  menu_background? : String = "",
  settings_background? : String = "",
  gallery_background? : String = "",
  credits_background? : String = "",
  menu_music? : Music,
  ui_click_sfx_url? : String = "",
  menu_music_loop? : Bool = true,
  ui_strings? : UiStrings = UiStrings::default(),
  languages? : Array[(String, String)] = [],
  ui_locales_json? : String = "",
  ui_locale_path? : String = "locales/ui.json",
  script_locale_json? : String = "",
  script_default_locale_json? : String = "",
  script_locale_dir? : String = "locales",
  vocal_locale_dir? : String = "",
  credits? : String,
  start_logo_urls? : Array[String] = [],
  start_logo_duration_ms? : Int = 2000,
) -> AppContentConfig {
  {
    save_namespace,
    autosave_slot,
    autosave_title,
    menu_background,
    settings_background,
    gallery_background,
    credits_background,
    menu_music,
    ui_click_sfx_url,
    menu_music_loop,
    ui_strings,
    languages,
    ui_locales_json,
    ui_locale_path,
    script_locale_json,
    script_default_locale_json,
    script_locale_dir,
    vocal_locale_dir,
    credits,
    start_logo_urls,
    start_logo_duration_ms,
  }
}

///|
pub fn[T] create_app_controller(
  script_factory : ScriptFactory[T],
  new_state : () -> GameState[T],
  ports : AppRuntimePorts,
  config? : AppContentConfig = AppContentConfig::default(),
  save_store? : &SaveSlotStore = default_save_slot_storage(),
  gallery_replay_state_factories? : ReplayStateFactories[T] = ReplayStateFactories::new(),
) -> AppController[T] {
  AppController::new(
    script_factory,
    new_state,
    ports.ui_port_factory,
    ports.assets,
    ports.menu_factory,
    audio=ports.audio,
    save_namespace=config.save_namespace,
    autosave_slot=config.autosave_slot,
    autosave_title=config.autosave_title,
    menu_background=config.menu_background,
    settings_background=config.settings_background,
    gallery_background=config.gallery_background,
    credits_background=config.credits_background,
    menu_music?=config.menu_music,
    ui_click_sfx_url=config.ui_click_sfx_url,
    menu_music_loop=config.menu_music_loop,
    ui_strings=config.ui_strings,
    languages=config.languages,
    ui_locales_json=config.ui_locales_json,
    script_locale_json=config.script_locale_json,
    script_default_locale_json=config.script_default_locale_json,
    script_locale_dir=config.script_locale_dir,
    vocal_locale_dir=config.vocal_locale_dir,
    credits?=config.credits,
    save_store~,
    start_logo_urls=config.start_logo_urls,
    start_logo_duration_ms=config.start_logo_duration_ms,
    core_render_sync=ports.core_render_sync,
    render_extension?=ports.render_extension,
    event_hook=ports.event_hook,
    gallery_replay_state_factories~,
  )
}
