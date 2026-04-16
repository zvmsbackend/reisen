///|
/// Top-level app controller: start menu <-> game runtime switching.

///|
fn log_app_warn(msg : String) -> Unit {
  @util.console_warn("[reisen:app] \{msg}")
}

///|
pub enum AppPhase {
  LocaleSelect
  StartGate
  StartLogo
  StartMenu
  Gallery
  Settings
  Credits
  InGame
} derive(Debug, Eq)

///|
#cfg(target="js")
pub type ScriptFactory[T] = async () -> Script[T]

///|
#cfg(target="native")
pub type ScriptFactory[T] = () -> Script[T]

///|
pub suberror AppControllerError {
  ScriptLoadFailed(message~ : String)
  ScriptValidationMissingImage(id~ : String)
  ScriptValidationMissingAudio(id~ : String)
  SaveSlotMissing(slot~ : String)
} derive(Eq)

///|
pub fn AppControllerError::message(self : AppControllerError) -> String {
  match self {
    ScriptLoadFailed(message~) => "Failed to load script resources: \{message}"
    ScriptValidationMissingImage(id~) =>
      "Script references missing image asset: \{id}"
    ScriptValidationMissingAudio(id~) =>
      "Script references missing audio asset: \{id}"
    SaveSlotMissing(slot~) => "Save slot missing: \{slot}"
  }
}

///|
struct AppController[T] {
  script_factory : ScriptFactory[T]
  mut script : Script[T]?
  new_state : () -> GameState[T]
  ui_port_factory : &@ui_game.UiPortFactory
  ui_strings_default : UiStrings
  mut ui_locales_json : String?
  mut ui_strings : UiStrings
  languages : Array[(String, String)]
  mut locale : String
  default_locale : String
  mut script_locale_json : String?
  mut script_default_locale_json : String?
  vocal_locale_dir : String
  credits : String?
  save_ns : String
  autosave_slot : String
  autosave_title : String
  menu_music_id : String?
  ui_click_sfx_id : String?
  menu_music_loop : Bool
  mut menu_music_playing : Bool
  start_logo_urls : Array[String]
  start_logo_duration_ms : Int
  mut start_logo_elapsed_ms : Int
  mut start_logo_index : Int
  start_menu : &StartMenu
  gallery_menu : &GalleryMenu
  settings_menu : &SettingsMenu
  credits_menu : &CreditsMenu
  loading_menu : &LoadingMenu
  mut credits_return_phase : AppPhase
  gallery_replay_state_factories : ReplayStateFactories[T]
  save_store : &SaveSlotStore
  mut phase : AppPhase
  mut save_store_preloaded : Bool
  core_render_sync : RenderSyncHook
  render_extension : RenderExtensionHook?
  event_hook : EventHook
  mut runner : GameRunner[T]?
  mut saved_director_json : String?
  mut saved_dialog_history : Array[DialogLogEntry]?
  assets : &AssetStore
  audio : &AudioPort
}

///|
pub fn[T] AppController::new(
  script_factory : ScriptFactory[T],
  new_state : () -> GameState[T],
  ui_port_factory : &@ui_game.UiPortFactory,
  assets : &AssetStore,
  menu_factory : &MenuFactory,
  audio? : &AudioPort = @audio.dummy,
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
  script_locale_json? : String = "",
  script_default_locale_json? : String = "",
  vocal_locale_dir? : String = "",
  credits? : String,
  save_store? : &SaveSlotStore = default_save_slot_storage(),
  start_logo_urls? : Array[String] = [],
  start_logo_duration_ms? : Int = 2000,
  core_render_sync? : RenderSyncHook = noop_core_render_sync,
  render_extension? : RenderExtensionHook,
  event_hook? : EventHook = _ => (),
  gallery_replay_state_factories? : ReplayStateFactories[T] = ReplayStateFactories::new(),
) -> AppController[T] {
  let normalized_start_logos = start_logo_urls.filter(logo => logo != "")
  let persisted_locale = persistent_get_text_in(save_namespace, "locale")
  let mut valid_persisted_locale = ""
  let mut has_persisted = false
  for language in languages {
    if language.1 == persisted_locale {
      valid_persisted_locale = language.1
      has_persisted = true
    }
  }
  let default_locale = match languages {
    [(_, code), ..] => code
    _ => ""
  }
  let selected_locale = if has_persisted {
    valid_persisted_locale
  } else {
    default_locale
  }
  let ui_click_sfx_id = match ui_click_sfx_url {
    "" => None
    _ => {
      assets.put_audio_url(ui_click_sfx_url, ui_click_sfx_url)
      Some(ui_click_sfx_url)
    }
  }
  let app : AppController[T] = {
    script_factory,
    script: None,
    new_state,
    ui_port_factory,
    ui_strings_default: ui_strings,
    ui_locales_json: match ui_locales_json {
      "" => None
      _ => Some(ui_locales_json)
    },
    ui_strings,
    languages,
    locale: selected_locale,
    default_locale,
    script_locale_json: match script_locale_json {
      "" => None
      _ => Some(script_locale_json)
    },
    script_default_locale_json: match script_default_locale_json {
      "" => None
      _ => Some(script_default_locale_json)
    },
    vocal_locale_dir,
    credits,
    save_ns: save_namespace,
    autosave_slot,
    autosave_title,
    menu_music_id: menu_music.map(music => music.0),
    ui_click_sfx_id,
    menu_music_loop,
    menu_music_playing: false,
    start_logo_urls: normalized_start_logos,
    start_logo_duration_ms,
    start_logo_elapsed_ms: 0,
    start_logo_index: 0,
    start_menu: menu_factory.create_start_menu(
      save_store~,
      background=menu_background,
      show_credits=credits is Some(_),
    ),
    gallery_menu: menu_factory.create_gallery_menu(
      background=gallery_background,
    ),
    settings_menu: menu_factory.create_settings_menu(
      audio~,
      background=settings_background,
      show_credits=credits is Some(_),
    ),
    credits_menu: menu_factory.create_credits_menu(
      background=credits_background,
    ),
    loading_menu: menu_factory.create_loading_menu(),
    credits_return_phase: StartMenu,
    save_store,
    phase: if !languages.is_empty() && !has_persisted {
      LocaleSelect
    } else {
      StartGate
    },
    save_store_preloaded: false,
    core_render_sync,
    render_extension,
    event_hook,
    runner: None,
    saved_director_json: None,
    saved_dialog_history: None,
    gallery_replay_state_factories,
    assets,
    audio,
  }
  let settings = settings_read_in(save_namespace).unwrap_or_default()
  audio.set_bgm_gain(settings.bgm_volume)
  audio.set_sfx_gain(settings.sfx_volume)
  app.settings_menu.set_languages(languages)
  app.settings_menu.set_locale(selected_locale)
  app.gallery_menu.set_script_localization(
    script_locale_json=app.script_locale_json,
    script_default_locale_json=app.script_default_locale_json,
  )
  app.settings_menu.set_script_localization(
    script_locale_json=app.script_locale_json,
    script_default_locale_json=app.script_default_locale_json,
  )
  app.refresh_ui_strings()
  app
}

///|
#cfg(target="js")
async fn[T] AppController::script(
  self : AppController[T],
) -> Script[T] raise AppControllerError {
  match self.script {
    Some(script) => script
    None => {
      self.loading_menu.render(self.ui_strings.loading_text)
      let script = (self.script_factory)() catch {
        //PixiBindingError::ResourceLoadFailed(message~) => {
        //  self.loading_menu.clear()
        //  raise ScriptLoadFailed(
        //    message="Pixi resource load failed: \{message}",
        //  )
        //}
        AssetStoreError::ResourceLoadFailed(message~) => {
          self.loading_menu.clear()
          raise ScriptLoadFailed(
            message="Asset resource load failed: \{message}",
          )
        }
        error => {
          self.loading_menu.clear()
          raise ScriptLoadFailed(
            message="Unknown script factory error \{error}",
          )
        }
      }
      self.loading_menu.clear()
      validate_script_assets(script, self.assets) catch {
        MissingImageAsset(id~) => raise ScriptValidationMissingImage(id~)
        MissingAudioAsset(id~) => raise ScriptValidationMissingAudio(id~)
        MissingSaveSlot(slot~) => raise SaveSlotMissing(slot~)
        InvalidSavePayload(raw~) =>
          raise ScriptLoadFailed(message="Invalid save payload: \{raw}")
        UnsupportedSavePayloadVersion(expected~, found~) =>
          raise ScriptLoadFailed(
            message="Unsupported save payload version: expected \{expected}, found \{found}",
          )
        LocalizationLoadFailed(message~) =>
          raise ScriptLoadFailed(
            message="Localization preload failed: \{message}",
          )
      }
      self.script = Some(script)
      script
    }
  }
}

///|
fn[T] AppController::show_current_start_logo(self : AppController[T]) -> Unit {
  if self.start_logo_index < 0 ||
    self.start_logo_index >= self.start_logo_urls.length() {
    self.enter_start_menu()
    return
  }
  self.start_menu.render_logo(
    self.start_logo_urls[self.start_logo_index],
    self.start_logo_duration_ms,
  )
  self.start_logo_elapsed_ms = 0
  self.phase = StartLogo
}

///|
fn[T] AppController::start_menu_music_start(self : AppController[T]) -> Unit {
  guard self.menu_music_id is Some(menu_music_id) && !self.menu_music_playing else {
    return
  }
  (self.event_hook)(MusicPlayed(menu_music_id, self.menu_music_loop))
  self.menu_music_playing = true
}

///|
fn[T] AppController::start_menu_music_stop(self : AppController[T]) -> Unit {
  if !self.menu_music_playing {
    return
  }
  (self.event_hook)(MusicStopped)
  self.menu_music_playing = false
}

///|
fn[T] AppController::emit_ui_click_sfx(self : AppController[T]) -> Unit {
  match self.ui_click_sfx_id {
    Some(sfx_id) => (self.event_hook)(SfxPlayed(sfx_id, false))
    None => ()
  }
}

///|
fn[T] AppController::localize_credits_text(
  self : AppController[T],
  raw : String,
) -> String {
  let (localized, _, _) = script_locale_resolve_at(
    raw,
    self.script_locale_json,
    self.script_default_locale_json,
  )
  localized
}

///|
fn[T] AppController::credits_html(self : AppController[T]) -> String {
  match self.credits {
    Some(raw) => DialogText::new(self.localize_credits_text(raw)).render()
    None => ""
  }
}

///|
fn[T] AppController::enter_credits(
  self : AppController[T],
  return_phase : AppPhase,
) -> Unit {
  match self.credits {
    Some(_) => {
      self.start_menu.clear()
      self.settings_menu.clear()
      self.gallery_menu.clear()
      self.credits_return_phase = return_phase
      self.credits_menu.render(self.credits_html())
      self.phase = Credits
    }
    None => ()
  }
}

///|
fn[T] AppController::enter_start_menu(self : AppController[T]) -> Unit {
  self.credits_menu.clear()
  self.gallery_menu.clear()
  self.start_menu.clear_logo()
  self.start_menu.clear_gate()
  self.start_menu.render()
  self.phase = StartMenu
  self.start_menu_music_start()
}

///|
fn[T] AppController::enter_start_logo(self : AppController[T]) -> Unit {
  if self.start_logo_urls.is_empty() {
    self.enter_start_menu()
    return
  }
  self.start_menu.clear_gate()
  self.start_logo_index = 0
  self.show_current_start_logo()
}

///|
fn[T] AppController::advance_start_logo(self : AppController[T]) -> Unit {
  let next = self.start_logo_index + 1
  if next >= self.start_logo_urls.length() {
    self.enter_start_menu()
    return
  }
  self.start_logo_index = next
  self.show_current_start_logo()
}

///|
pub fn[T] AppController::phase(self : AppController[T]) -> AppPhase {
  self.phase
}

///|
fn[T] AppController::sync_ui_strings(self : AppController[T]) -> Unit {
  self.start_menu.set_ui_strings(self.ui_strings)
  self.settings_menu.set_ui_strings(self.ui_strings)
  self.gallery_menu.set_ui_strings(self.ui_strings)
  self.credits_menu.set_ui_strings(self.ui_strings)
}

///|
fn[T] AppController::sync_runner_localization(self : AppController[T]) -> Unit {
  let effective_locale = match self.locale {
    "" => self.default_locale
    _ => self.locale
  }
  self.gallery_menu.set_script_localization(
    script_locale_json=self.script_locale_json,
    script_default_locale_json=self.script_default_locale_json,
  )
  self.settings_menu.set_script_localization(
    script_locale_json=self.script_locale_json,
    script_default_locale_json=self.script_default_locale_json,
  )
  if self.runner is Some(runner) {
    runner
    ..set_ui_click_sfx(self.ui_click_sfx_id)
    ..set_ui_strings(self.ui_strings)
    .set_script_localization(
      script_locale_json=self.script_locale_json,
      script_default_locale_json=self.script_default_locale_json,
      vocal_locale_dir=self.vocal_locale_dir,
      script_locale=effective_locale,
      script_default_locale=self.default_locale,
    )
  }
}

///|
fn[T] AppController::refresh_ui_strings(self : AppController[T]) -> Unit {
  let effective_locale = match self.locale {
    "" => self.default_locale
    _ => self.locale
  }
  self.ui_strings = match self.ui_locales_json {
    Some(locales_json) if effective_locale != "" && self.default_locale != "" =>
      UiStrings::from_locales_json(
        locales_json,
        effective_locale,
        self.default_locale,
        fallback=self.ui_strings_default,
      )
    _ => self.ui_strings_default
  }
  self.sync_ui_strings()
  self.sync_runner_localization()
  self.render_phase_on_locale_change()
}

///|
pub fn[T] AppController::set_localization_payload(
  self : AppController[T],
  ui_locales_json? : String = "",
  script_locale_json? : String = "",
  script_default_locale_json? : String = "",
) -> Unit {
  let next_ui_locales_json = match ui_locales_json {
    "" => None
    _ => Some(ui_locales_json)
  }
  let next_script_locale_json = match script_locale_json {
    "" => None
    _ => Some(script_locale_json)
  }
  let next_script_default_locale_json = match script_default_locale_json {
    "" => None
    _ => Some(script_default_locale_json)
  }
  self.ui_locales_json = next_ui_locales_json
  self.script_locale_json = next_script_locale_json
  self.script_default_locale_json = next_script_default_locale_json
  self.refresh_ui_strings()
}

///|
fn[T] AppController::apply_locale(
  self : AppController[T],
  code : String,
) -> Unit {
  self.locale = code
  self.settings_menu.set_locale(code)
  persistent_set_text_in(self.save_ns, "locale", code)
  self.refresh_ui_strings()
}

///|
fn[T] AppController::apply_settings_from_storage(
  self : AppController[T],
  runner : GameRunner[T],
) -> Unit {
  match settings_read_in(self.save_ns) {
    Some(settings) => runner.apply_settings(settings)
    None => ()
  }
}

///|
/// Creates a fresh `GameRunner` for the given script + state, pre-filling all
/// locale and rendering arguments from the controller's current configuration.
/// Also calls `set_ui_click_sfx` and `apply_settings_from_storage`.
fn[T] AppController::make_runner(
  self : AppController[T],
  script : Script[T],
  state : GameState[T],
) -> GameRunner[T] noraise {
  let runner = start_game(
    script,
    state,
    self.ui_port_factory,
    self.audio,
    core_render_sync=self.core_render_sync,
    render_extension?=self.render_extension,
    event_hook=self.event_hook,
    ui_strings=self.ui_strings,
    script_locale_json=self.script_locale_json.unwrap_or(""),
    script_default_locale_json=self.script_default_locale_json.unwrap_or(""),
    vocal_locale_dir=self.vocal_locale_dir,
    script_locale=self.locale,
    script_default_locale=self.default_locale,
    gallery_ns=self.save_ns,
  )
  runner.set_ui_click_sfx(self.ui_click_sfx_id)
  self.apply_settings_from_storage(runner)
  runner
}

///|
/// Loads a `GameRunner` from a save slot, pre-filling all locale and rendering
/// arguments from the controller's current configuration.
/// Also calls `set_ui_click_sfx` and `apply_settings_from_storage`.
fn[T : FromJson] AppController::load_runner_from_slot(
  self : AppController[T],
  script : Script[T],
  slot : String,
) -> GameRunner[T] raise {
  let runner = start_game_from_slot(
    script,
    slot,
    self.ui_port_factory,
    self.audio,
    core_render_sync=self.core_render_sync,
    render_extension?=self.render_extension,
    event_hook=self.event_hook,
    save_namespace=self.save_ns,
    save_store=self.save_store,
    ui_strings=self.ui_strings,
    script_locale_json=self.script_locale_json.unwrap_or(""),
    script_default_locale_json=self.script_default_locale_json.unwrap_or(""),
    vocal_locale_dir=self.vocal_locale_dir,
    script_locale=self.locale,
    script_default_locale=self.default_locale,
    gallery_ns=self.save_ns,
  )
  runner.set_ui_click_sfx(self.ui_click_sfx_id)
  self.apply_settings_from_storage(runner)
  runner
}

///|
/// Restores a `GameRunner` from a mid-game director JSON snapshot (used when
/// returning from the settings/save screen back to an in-progress game).
/// Also calls `set_ui_click_sfx` and `apply_settings_from_storage`.
fn[T : FromJson] AppController::resume_runner_from_json(
  self : AppController[T],
  script : Script[T],
  director_json : String,
  dialog_history : Array[DialogLogEntry],
) -> GameRunner[T] raise {
  let runner = start_game_from_save(
    script,
    director_json,
    self.ui_port_factory,
    self.audio,
    core_render_sync=self.core_render_sync,
    render_extension?=self.render_extension,
    event_hook=self.event_hook,
    ui_strings=self.ui_strings,
    script_locale_json=self.script_locale_json.unwrap_or(""),
    script_default_locale_json=self.script_default_locale_json.unwrap_or(""),
    vocal_locale_dir=self.vocal_locale_dir,
    script_locale=self.locale,
    script_default_locale=self.default_locale,
    gallery_ns=self.save_ns,
    dialog_history~,
  )
  runner.set_ui_click_sfx(self.ui_click_sfx_id)
  self.apply_settings_from_storage(runner)
  runner
}

///|
pub fn[T] AppController::submit_custom_event(
  self : AppController[T],
  name : String,
  payload : String,
) -> Bool {
  if self.phase != InGame {
    return false
  }
  match self.runner {
    Some(runner) => {
      ignore(runner.submit_custom_event(name, payload))
      true
    }
    None => false
  }
}

///|
fn[T] AppController::replay_factory_for_image(
  self : AppController[T],
  image : GalleryImage,
) -> () -> GameState[T] {
  match image.replay_state_factory_key {
    Some(key) =>
      match self.gallery_replay_state_factories.get(key) {
        Some(factory) => factory
        None => self.new_state
      }
    None => self.new_state
  }
}

///|
#cfg(target="js")
async fn[T] AppController::start_gallery_replay(
  self : AppController[T],
  replay_label : String,
) -> Unit raise AppControllerError {
  let target = @gallery.replayable_images_in(self.save_ns)
    .iter()
    .find_first(image => image.replay_label == Some(replay_label))
  match target {
    Some(image) => {
      let replay_factory = self.replay_factory_for_image(image)
      let runner = self.make_runner(self.script(), replay_factory())
      try {
        runner.jump_to_label(replay_label)
        self.start_menu_music_stop()
        self.gallery_menu.clear()
        self.runner = Some(runner)
        self.phase = InGame
      } catch {
        LabelNotFound(label~) => {
          log_app_warn("gallery replay label not found: '\{label}'")
          self.gallery_menu.render()
        }
        _ => self.gallery_menu.render()
      }
    }
    None => self.gallery_menu.render()
  }
}

///|
#cfg(target="js")
async fn[T : FromJson] AppController::handle_menu_action(
  self : AppController[T],
  action : StartMenuAction,
) -> Unit raise AppControllerError {
  match action {
    NoAction => ()
    NewGame => {
      self.emit_ui_click_sfx()
      self.start_menu_music_stop()
      let runner = self.make_runner(self.script(), (self.new_state)())
      self.runner = Some(runner)
      self.start_menu.clear()
      self.phase = InGame
    }
    Continue(slot) => {
      self.emit_ui_click_sfx()
      let script = self.script()
      try {
        let runner = self.load_runner_from_slot(script, slot)
        self.start_menu_music_stop()
        self.runner = Some(runner)
        self.start_menu.clear()
        self.phase = InGame
      } catch {
        _ => {
          log_app_warn(
            "continue from slot '\{slot}' failed (slot missing or corrupt)",
          )
          self.runner = None
          self.enter_start_menu()
        }
      }
    }
    Load => {
      self.emit_ui_click_sfx()
      self.start_menu.clear()
      self.settings_menu.set_context(FromStartMenu)
      self.settings_menu.set_view_mode(LoadList)
      self.settings_menu.render()
      self.phase = Settings
    }
    Settings => {
      self.emit_ui_click_sfx()
      self.start_menu.clear()
      self.settings_menu.set_context(FromStartMenu)
      self.settings_menu.render()
      self.phase = Settings
    }
    Gallery =>
      if !@gallery.registered_images().is_empty() {
        self.emit_ui_click_sfx()
        self.start_menu.clear()
        self.gallery_menu.render()
        self.phase = Gallery
      }
    Credits => self..emit_ui_click_sfx().enter_credits(StartMenu)
  }
}

///|
fn[T : ToJson] AppController::save_autosave_if_enabled(
  self : AppController[T],
) -> Unit {
  match self.autosave_slot {
    "" => return
    _ => ()
  }
  match self.runner {
    Some(runner) => {
      let slot = next_save_slot(
        self.save_store,
        self.save_ns,
        self.autosave_slot,
        6,
      )
      let preview = dialog_preview(runner)
      save_runner_to_slot_with_meta(
        runner,
        slot,
        title=self.autosave_title,
        preview~,
        save_namespace=self.save_ns,
        save_store=self.save_store,
      )
    }
    None => ()
  }
}

///|
fn[T] dialog_preview(runner : GameRunner[T]) -> String {
  match runner.director().dialog() {
    Some(line) => line.text.raw_text()
    None => ""
  }
}

///|
fn next_save_slot(
  save_store : &SaveSlotStore,
  ns : String,
  prefix : String,
  total : Int,
) -> String {
  let existing = save_store.list_slots(ns)
  for i in 1..<=total {
    let slot = "\{prefix}\{i}"
    if !existing.contains(slot) {
      return slot
    }
  }
  "\{prefix}\{total}"
}

///|
fn[T] AppController::render_phase_on_locale_change(
  self : AppController[T],
) -> Unit {
  match self.phase {
    LocaleSelect => self.start_menu.render_locale_picker(self.languages)
    StartGate => self.start_menu.render_gate()
    StartMenu => self.start_menu.render()
    Settings => self.settings_menu.render()
    Gallery => self.gallery_menu.render()
    Credits => self.credits_menu.render(self.credits_html())
    InGame => ()
    _ => ()
  }
}

///|
fn[T] AppController::tick_locale_select(self : AppController[T]) -> Bool {
  match self.start_menu.take_locale_action() {
    StartLocaleAction::Select(code) => {
      self.emit_ui_click_sfx()
      self.apply_locale(code)
      self.start_menu.clear_locale_picker()
      self.start_menu.render_gate()
      self.phase = StartGate
    }
    StartLocaleAction::NoAction => ()
  }
  true
}

///|
fn[T] AppController::tick_start_gate(self : AppController[T]) -> Bool {
  match self.start_menu.take_gate_action() {
    Start => {
      self.emit_ui_click_sfx()
      if self.start_logo_urls.is_empty() {
        self.enter_start_menu()
      } else {
        self.enter_start_logo()
      }
    }
    NoAction => ()
  }
  true
}

///|
fn[T] AppController::tick_start_logo(
  self : AppController[T],
  elapsed_ms : Int,
) -> Bool {
  self.start_logo_elapsed_ms += elapsed_ms
  match self.start_menu.take_logo_action() {
    Done => self.advance_start_logo()
    NoAction =>
      if self.start_logo_elapsed_ms >= self.start_logo_duration_ms {
        self.advance_start_logo()
      }
  }
  true
}

///|
fn[T : ToJson] AppController::tick_in_game(
  self : AppController[T],
  elapsed_ms : Int,
) -> Bool {
  match self.runner {
    Some(runner) =>
      if runner.tick(elapsed_ms~) {
        if runner.take_pending_action() is Some(action) {
          self.handle_in_game_pending_action(runner, action)
        }
        true
      } else {
        runner.apply_runtime_event(SfxStopped)
        (self.event_hook)(MusicStopped)
        (self.event_hook)(SfxStopped)
        runner.clear_presentation()
        self.runner = None
        self.enter_start_menu()
        true
      }
    None => {
      self.enter_start_menu()
      true
    }
  }
}

///|
fn[T : ToJson] AppController::handle_in_game_pending_action(
  self : AppController[T],
  runner : GameRunner[T],
  action : String,
) -> Unit {
  match action {
    "settings" => {
      self.saved_director_json = Some(runner.director().save_json())
      self.saved_dialog_history = Some(runner.dialog_history())
      runner.clear_ui()
      self.settings_menu.set_context(FromMidgame)
      self.settings_menu.set_view_mode(Settings)
      self.settings_menu.render()
      self.phase = Settings
    }
    "qsave" =>
      save_runner_to_slot_with_meta(
        runner,
        next_save_slot(self.save_store, self.save_ns, "quicksave", 6),
        preview=dialog_preview(runner),
        save_namespace=self.save_ns,
        save_store=self.save_store,
      )
    "save" => {
      self.saved_director_json = Some(runner.director().save_json())
      self.saved_dialog_history = Some(runner.dialog_history())
      runner.clear_ui()
      self.settings_menu.set_context(FromMidgame)
      self.settings_menu.set_view_mode(SaveList)
      self.settings_menu.render()
      self.phase = Settings
    }
    "log" => runner.toggle_log_visible()
    _ => ()
  }
}

///|
#cfg(target="js")
async fn[T : FromJson + ToJson] AppController::tick_settings(
  self : AppController[T],
) -> Bool raise AppControllerError {
  match self.settings_menu.take_action() {
    LanguageChanged(code) => {
      self.emit_ui_click_sfx()
      self.apply_locale(code)
      self.settings_menu.render()
    }
    Back => {
      self.emit_ui_click_sfx()
      self.settings_menu.clear()
      match self.saved_director_json {
        Some(json) => {
          self.saved_director_json = None
          let dialog_history = self.saved_dialog_history.unwrap_or([])
          self.saved_dialog_history = None
          let script = self.script()
          try {
            let runner = self.resume_runner_from_json(
              script, json, dialog_history,
            )
            runner.sync_ui()
            self.runner = Some(runner)
            self.phase = InGame
          } catch {
            _ => {
              log_app_warn("resume from saved state failed (corrupt save data)")
              self.enter_start_menu()
            }
          }
        }
        None => {
          self.saved_dialog_history = None
          self.enter_start_menu()
        }
      }
    }
    NewGame => {
      self.emit_ui_click_sfx()
      self.settings_menu.clear()
      self.saved_director_json = None
      self.saved_dialog_history = None
      self.start_menu_music_stop()
      let runner = self.make_runner(self.script(), (self.new_state)())
      self.runner = Some(runner)
      self.phase = InGame
    }
    StartMenu => {
      self.emit_ui_click_sfx()
      self.save_autosave_if_enabled()
      if self.runner is Some(runner) {
        runner..apply_runtime_event(SfxStopped).clear_presentation()
      }
      (self.event_hook)(MusicStopped)
      (self.event_hook)(SfxStopped)
      self.settings_menu.clear()
      self.saved_director_json = None
      self.saved_dialog_history = None
      self.runner = None
      self.enter_start_menu()
    }
    Credits => self..emit_ui_click_sfx().enter_credits(Settings)
    Log => {
      self.emit_ui_click_sfx()
      self.settings_menu.clear()
      match self.runner {
        Some(runner) => {
          runner.set_log_visible(true)
          self.phase = InGame
        }
        None => self.enter_start_menu()
      }
    }
    SaveSlot(slot) => {
      self.emit_ui_click_sfx()
      if self.runner is Some(runner) {
        save_runner_to_slot_with_meta(
          runner,
          slot,
          preview=dialog_preview(runner),
          save_namespace=self.save_ns,
          save_store=self.save_store,
        )
      }
      self.settings_menu.render()
    }
    LoadSlot(slot) => {
      self.emit_ui_click_sfx()
      self.settings_menu.clear()
      let script = self.script()
      let restored : Result[GameRunner[T], Error] = try? self.load_runner_from_slot(
        script, slot,
      )
      match restored {
        Ok(runner) => {
          self.start_menu_music_stop()
          self.runner = Some(runner)
          self.phase = InGame
        }
        Err(_) => {
          log_app_warn(
            "load from slot '\{slot}' failed (slot missing or corrupt)",
          )
          self.settings_menu.render()
        }
      }
    }
    ViewChanged => {
      self.emit_ui_click_sfx()
      self.settings_menu.render()
    }
    NoAction => ()
  }
  true
}

///|
#cfg(target="js")
async fn[T] AppController::tick_gallery(
  self : AppController[T],
) -> Bool raise AppControllerError {
  match self.gallery_menu.take_action() {
    Back => {
      self.emit_ui_click_sfx()
      self.gallery_menu.clear()
      self.enter_start_menu()
    }
    Open(_) | Close | Prev | Next => {
      self.emit_ui_click_sfx()
      self.gallery_menu.render()
    }
    Replay(label) => self..emit_ui_click_sfx().start_gallery_replay(label)
    NoAction => ()
  }
  true
}

///|
fn[T] AppController::tick_credits(self : AppController[T]) -> Bool {
  match self.credits_menu.take_action() {
    CreditsAction::Back => {
      self.emit_ui_click_sfx()
      self.credits_menu.clear()
      match self.credits_return_phase {
        Settings => {
          self.settings_menu.render()
          self.phase = Settings
        }
        _ => {
          self.start_menu.render()
          self.phase = StartMenu
        }
      }
    }
    CreditsAction::NoAction => ()
  }
  true
}

///|
#cfg(target="js")
async fn[T : FromJson] AppController::tick_start_menu(
  self : AppController[T],
) -> Bool raise AppControllerError {
  self.start_menu_music_start()
  self.handle_menu_action(self.start_menu.take_action())
  true
}

///|
#cfg(target="js")
pub async fn[T : FromJson + ToJson] AppController::tick(
  self : AppController[T],
  elapsed_ms? : Int = 0,
) -> Bool raise AppControllerError {
  if !self.save_store_preloaded {
    self.save_store.preload_namespace(self.save_ns)
    self.save_store_preloaded = true
  }
  match self.phase {
    LocaleSelect => self.tick_locale_select()
    StartGate => self.tick_start_gate()
    StartLogo => self.tick_start_logo(elapsed_ms)
    InGame => self.tick_in_game(elapsed_ms)
    Settings => self.tick_settings()
    Gallery => self.tick_gallery()
    Credits => self.tick_credits()
    StartMenu => self.tick_start_menu()
  }
}
