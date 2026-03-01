///|
/// Top-level app controller: start menu <-> game runtime switching.

///|
pub enum AppPhase {
  LocaleSelect
  StartGate
  StartLogo
  StartMenu
  Gallery
  Settings
  InGame
} derive(Show, Eq)

///|
pub type ScriptFactory[T] = async () -> Script[T]

///|
struct AppController[T] {
  script_factory : ScriptFactory[T]
  mut script : Script[T]?
  new_state : () -> GameState[T]
  ui_root_id : String
  ui_strings_default : UiStrings
  mut ui_strings : UiStrings
  languages : Array[(String, String)]
  mut locale : String
  default_locale : String
  ui_locale_path : String
  mut ui_locales_json : String?
  mut ui_locale_load_attempted : Bool
  script_locale_dir : String
  mut script_locale_json : String?
  mut script_default_locale_json : String?
  mut script_locale_load_attempted : Bool
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
  start_menu : StartMenu
  gallery_menu : GalleryMenu
  settings_menu : SettingsMenu
  gallery_replay_state_factories : ReplayStateFactories[T]
  mut phase : AppPhase
  render_sync : RenderSyncHook[T]
  event_hook : EventHook
  mut runner : GameRunner[T]?
  mut saved_director_json : String?
  assets : AssetStore
}

///|
pub fn[T] AppController::new(
  script_factory : ScriptFactory[T],
  new_state : () -> GameState[T],
  ui_root_id : String,
  assets : AssetStore,
  save_namespace? : String = "global",
  autosave_slot? : String = "autosave",
  autosave_title? : String = "",
  menu_background? : String = "",
  settings_background? : String = "",
  gallery_background? : String = "",
  menu_music? : Music,
  ui_click_sfx_url? : String = "",
  menu_music_loop? : Bool = true,
  ui_strings? : UiStrings = UiStrings::default(),
  languages? : Array[(String, String)] = [],
  ui_locale_path? : String = "locales/ui.json",
  script_locale_dir? : String = "locales",
  start_logo_urls? : Array[String] = [],
  start_logo_duration_ms? : Int = 2000,
  render_sync? : RenderSyncHook[T] = _ => (),
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
  let ui_click_sfx_id = if ui_click_sfx_url == "" {
    None
  } else {
    assets.put_audio_url(ui_click_sfx_url, ui_click_sfx_url)
    Some(ui_click_sfx_url)
  }
  let app : AppController[T] = {
    script_factory,
    script: None,
    new_state,
    ui_root_id,
    ui_strings_default: ui_strings,
    ui_strings,
    languages,
    locale: selected_locale,
    default_locale,
    ui_locale_path,
    ui_locales_json: None,
    ui_locale_load_attempted: false,
    script_locale_dir,
    script_locale_json: None,
    script_default_locale_json: None,
    script_locale_load_attempted: false,
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
    start_menu: StartMenu::new(
      ui_root_id,
      save_namespace~,
      background=menu_background,
      ui_strings~,
    ),
    gallery_menu: GalleryMenu::new(
      ui_root_id,
      save_namespace~,
      background=gallery_background,
      ui_strings~,
    ),
    settings_menu: SettingsMenu::new(
      ui_root_id,
      save_namespace~,
      background=settings_background,
      ui_strings~,
    ),
    phase: if !languages.is_empty() && !has_persisted {
      AppPhase::LocaleSelect
    } else {
      AppPhase::StartGate
    },
    render_sync,
    event_hook,
    runner: None,
    saved_director_json: None,
    gallery_replay_state_factories,
    assets,
  }
  match settings_read_in(save_namespace) {
    Some(settings) => AudioDom::set_sfx_gain(settings.sfx_volume)
    None => ()
  }
  app.settings_menu.set_languages(languages)
  app.settings_menu.set_locale(selected_locale)
  app
}

///|
async fn[T] AppController::script(self : AppController[T]) -> Script[T] {
  match self.script {
    Some(script) => script
    None => {
      let script = (self.script_factory)() catch {
        PixiBindingError::ResourceLoadFailed(message~) =>
          abort("Failed to load script resources: \{message}")
        _ => panic()
      }
      validate_script_assets(script, self.assets) catch {
        MissingImageAsset(id~) =>
          abort("Script references missing image asset: \{id}")
        MissingAudioAsset(id~) =>
          abort("Script references missing audio asset: \{id}")
        MissingSaveSlot(slot~) =>
          abort("Script references missing save slot: \{slot}")
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
  self.phase = AppPhase::StartLogo
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
fn[T] AppController::enter_start_menu(self : AppController[T]) -> Unit {
  self.gallery_menu.clear()
  self.start_menu.clear_logo()
  self.start_menu.clear_gate()
  self.start_menu.render()
  self.phase = AppPhase::StartMenu
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
}

///|
fn[T] AppController::sync_runner_localization(self : AppController[T]) -> Unit {
  let effective_locale = if self.locale != "" {
    self.locale
  } else {
    self.default_locale
  }
  match self.runner {
    Some(runner) => {
      runner.set_ui_click_sfx(self.ui_click_sfx_id)
      runner.set_ui_strings(self.ui_strings)
      runner.set_script_localization(
        self.script_locale_json,
        self.script_default_locale_json,
        effective_locale,
        self.default_locale,
      )
    }
    None => ()
  }
}

///|
fn[T] AppController::refresh_ui_strings(self : AppController[T]) -> Unit {
  let effective_locale = if self.locale != "" {
    self.locale
  } else {
    self.default_locale
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
}

///|
async fn[T] AppController::ensure_ui_locales_loaded(
  self : AppController[T],
) -> Bool {
  if self.ui_locale_load_attempted {
    return false
  }
  self.ui_locale_load_attempted = true
  if self.ui_locale_path == "" {
    return false
  }
  self.ui_locales_json = Some(load_text(self.ui_locale_path) catch { _ => "" })
  self.refresh_ui_strings()
  true
}

///|
async fn[T] AppController::ensure_script_locales_loaded(
  self : AppController[T],
) -> Bool {
  if self.script_locale_load_attempted {
    return false
  }
  self.script_locale_load_attempted = true
  if self.script_locale_dir == "" {
    return false
  }
  let selected_code = if self.locale != "" {
    self.locale
  } else {
    self.default_locale
  }
  let default_code = self.default_locale
  let selected_path = if selected_code == "" {
    ""
  } else {
    "\{self.script_locale_dir}/\{selected_code}.json"
  }
  let default_path = if default_code == "" {
    ""
  } else {
    "\{self.script_locale_dir}/\{default_code}.json"
  }
  self.script_locale_json = if selected_path == "" {
    None
  } else {
    let raw = load_text(selected_path) catch { _ => "" }
    if raw == "" {
      None
    } else {
      Some(raw)
    }
  }
  self.script_default_locale_json = if default_path == "" {
    None
  } else {
    let raw = load_text(default_path) catch { _ => "" }
    if raw == "" {
      None
    } else {
      Some(raw)
    }
  }
  self.sync_runner_localization()
  true
}

///|
fn[T] AppController::apply_locale(
  self : AppController[T],
  code : String,
) -> Unit {
  self.locale = code
  self.settings_menu.set_locale(code)
  persistent_set_text_in(self.save_ns, "locale", code)
  self.script_locale_load_attempted = false
  self.script_locale_json = None
  self.script_default_locale_json = None
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
pub fn[T] AppController::submit_custom_event(
  self : AppController[T],
  name : String,
  payload : String,
) -> Bool {
  if self.phase != AppPhase::InGame {
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
async fn[T] AppController::start_gallery_replay(
  self : AppController[T],
  replay_label : String,
) -> Unit {
  let target = @gallery.replayable_images_in(self.save_ns)
    .iter()
    .find_first(image => image.replay_label == Some(replay_label))
  match target {
    Some(image) => {
      let settings = settings_read_in(self.save_ns)
      let replay_factory = self.replay_factory_for_image(image)
      let runner = start_game(
        self.script(),
        replay_factory(),
        self.ui_root_id,
        render_sync=self.render_sync,
        event_hook=self.event_hook,
        settings?,
        ui_strings=self.ui_strings,
        script_locale_json=self.script_locale_json.unwrap_or(""),
        script_default_locale_json=self.script_default_locale_json.unwrap_or(""),
        script_locale=self.locale,
        script_default_locale=self.default_locale,
      )
      runner.set_ui_click_sfx(self.ui_click_sfx_id)
      try {
        runner.jump_to_label(replay_label)
        self.apply_settings_from_storage(runner)
        self.start_menu_music_stop()
        self.gallery_menu.clear()
        self.runner = Some(runner)
        self.phase = AppPhase::InGame
      } catch {
        _ => self.gallery_menu.render()
      }
    }
    None => self.gallery_menu.render()
  }
}

///|
async fn[T : FromJson] AppController::handle_menu_action(
  self : AppController[T],
  action : StartMenuAction,
) -> Unit {
  let settings = settings_read_in(self.save_ns)
  match action {
    NoAction => ()
    NewGame => {
      self.emit_ui_click_sfx()
      self.start_menu_music_stop()
      let runner = start_game(
        self.script(),
        (self.new_state)(),
        self.ui_root_id,
        render_sync=self.render_sync,
        event_hook=self.event_hook,
        settings?,
        ui_strings=self.ui_strings,
        script_locale_json=self.script_locale_json.unwrap_or(""),
        script_default_locale_json=self.script_default_locale_json.unwrap_or(""),
        script_locale=self.locale,
        script_default_locale=self.default_locale,
      )
      runner.set_ui_click_sfx(self.ui_click_sfx_id)
      self.apply_settings_from_storage(runner)
      self.runner = Some(runner)
      self.start_menu.clear()
      self.phase = AppPhase::InGame
    }
    Continue(slot) =>
      try {
        self.emit_ui_click_sfx()
        let runner = start_game_from_slot(
          self.script(),
          slot,
          self.ui_root_id,
          render_sync=self.render_sync,
          event_hook=self.event_hook,
          save_namespace=self.save_ns,
          ui_strings=self.ui_strings,
          script_locale_json=self.script_locale_json.unwrap_or(""),
          script_default_locale_json=self.script_default_locale_json.unwrap_or(
            "",
          ),
          script_locale=self.locale,
          script_default_locale=self.default_locale,
        )
        runner.set_ui_click_sfx(self.ui_click_sfx_id)
        self.apply_settings_from_storage(runner)
        self.start_menu_music_stop()
        self.runner = Some(runner)
        self.start_menu.clear()
        self.phase = AppPhase::InGame
      } catch {
        _ => {
          self.runner = None
          self.enter_start_menu()
        }
      }
    Load => {
      self.emit_ui_click_sfx()
      self.start_menu.clear()
      self.settings_menu.set_context(FromStartMenu)
      self.settings_menu.set_view_mode(LoadList)
      self.settings_menu.render()
      self.phase = AppPhase::Settings
    }
    Settings => {
      self.emit_ui_click_sfx()
      self.start_menu.clear()
      self.settings_menu.set_context(FromStartMenu)
      self.settings_menu.render()
      self.phase = AppPhase::Settings
    }
    Gallery =>
      if @gallery.registered_images().length() > 0 {
        self.emit_ui_click_sfx()
        self.start_menu.clear()
        self.gallery_menu.render()
        self.phase = AppPhase::Gallery
      }
  }
}

///|
fn[T : ToJson] AppController::save_autosave_if_enabled(
  self : AppController[T],
) -> Unit {
  if self.autosave_slot == "" {
    return
  }
  match self.runner {
    Some(runner) => {
      let slot = next_save_slot(self.save_ns, self.autosave_slot, 6)
      let preview = dialog_preview(runner)
      save_runner_to_slot_with_meta(
        runner,
        slot,
        title=self.autosave_title,
        preview~,
        save_namespace=self.save_ns,
      )
    }
    None => ()
  }
}

///|
fn[T] dialog_preview(runner : GameRunner[T]) -> String {
  match runner.director().dialog() {
    Some(line) => line.text
    None => ""
  }
}

///|
fn next_save_slot(ns : String, prefix : String, total : Int) -> String {
  let existing = save_slot_list_in(ns)
  for i in 1..<=total {
    let slot = "\{prefix}\{i}"
    if !slot_exists(existing, slot) {
      return slot
    }
  }
  "\{prefix}\{total}"
}

///|
fn slot_exists(existing : Array[String], slot : String) -> Bool {
  for s in existing {
    if s == slot {
      return true
    }
  }
  false
}

///|
pub async fn[T : FromJson + ToJson] AppController::tick(
  self : AppController[T],
  elapsed_ms? : Int = 0,
) -> Bool {
  let ui_locale_changed = self.ensure_ui_locales_loaded()
  let script_locale_changed = self.ensure_script_locales_loaded()
  if ui_locale_changed || script_locale_changed {
    match self.phase {
      AppPhase::LocaleSelect =>
        self.start_menu.render_locale_picker(self.languages)
      AppPhase::StartGate => self.start_menu.render_gate()
      AppPhase::StartMenu => self.start_menu.render()
      AppPhase::Settings => self.settings_menu.render()
      AppPhase::Gallery => self.gallery_menu.render()
      AppPhase::InGame =>
        match self.runner {
          Some(runner) => runner.sync_ui()
          None => ()
        }
      _ => ()
    }
  }
  match self.phase {
    AppPhase::LocaleSelect => {
      match self.start_menu.take_locale_action() {
        StartLocaleAction::Select(code) => {
          self.emit_ui_click_sfx()
          self.apply_locale(code)
          self.start_menu.clear_locale_picker()
          self.start_menu.render_gate()
          self.phase = AppPhase::StartGate
        }
        StartLocaleAction::NoAction => ()
      }
      true
    }
    AppPhase::StartGate => {
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
    AppPhase::StartLogo => {
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
    AppPhase::InGame =>
      match self.runner {
        Some(runner) =>
          if runner.tick(elapsed_ms~) {
            match runner.take_pending_action() {
              Some("settings") => {
                self.saved_director_json = Some(runner.director().save_json())
                runner.clear_ui()
                self.settings_menu.set_context(FromMidgame)
                self.settings_menu.render()
                self.phase = AppPhase::Settings
              }
              Some("qsave") =>
                save_runner_to_slot_with_meta(
                  runner,
                  next_save_slot(self.save_ns, "quicksave", 6),
                  preview=dialog_preview(runner),
                  save_namespace=self.save_ns,
                )
              Some("save") => {
                self.saved_director_json = Some(runner.director().save_json())
                runner.clear_ui()
                self.settings_menu.set_context(FromMidgame)
                self.settings_menu.set_view_mode(SaveList)
                self.settings_menu.render()
                self.phase = AppPhase::Settings
              }
              Some("log") => {
                if runner.log_build_state() == LogBuildState::NotBuilt {
                  runner.start_reconstruct_dialog_history(
                    self.script(),
                    (self.new_state)(),
                  )
                }
                runner.toggle_log_visible()
              }
              _ => ()
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
    AppPhase::Settings => {
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
              try {
                let director = director_from_save_json(self.script(), json)
                let ui = UiDom::new(
                  self.ui_root_id,
                  ui_strings=self.ui_strings,
                  script_locale_json=self.script_locale_json.unwrap_or(""),
                  script_default_locale_json=self.script_default_locale_json.unwrap_or(
                    "",
                  ),
                  script_locale=self.locale,
                  script_default_locale=self.default_locale,
                )
                let runner = GameRunner::new_with_hooks(
                  director,
                  ui,
                  self.render_sync,
                  self.event_hook,
                )
                runner.set_ui_click_sfx(self.ui_click_sfx_id)
                self.apply_settings_from_storage(runner)
                runner.sync_ui()
                self.runner = Some(runner)
                self.phase = AppPhase::InGame
              } catch {
                _ => self.enter_start_menu()
              }
            }
            None => self.enter_start_menu()
          }
        }
        NewGame => {
          self.emit_ui_click_sfx()
          self.settings_menu.clear()
          self.saved_director_json = None
          let settings = settings_read_in(self.save_ns)
          self.start_menu_music_stop()
          let runner = start_game(
            self.script(),
            (self.new_state)(),
            self.ui_root_id,
            render_sync=self.render_sync,
            event_hook=self.event_hook,
            settings?,
            ui_strings=self.ui_strings,
            script_locale_json=self.script_locale_json.unwrap_or(""),
            script_default_locale_json=self.script_default_locale_json.unwrap_or(
              "",
            ),
            script_locale=self.locale,
            script_default_locale=self.default_locale,
          )
          runner.set_ui_click_sfx(self.ui_click_sfx_id)
          self.apply_settings_from_storage(runner)
          self.runner = Some(runner)
          self.phase = AppPhase::InGame
        }
        StartMenu => {
          self.emit_ui_click_sfx()
          self.save_autosave_if_enabled()
          match self.runner {
            Some(runner) => {
              runner.apply_runtime_event(SfxStopped)
              runner.clear_presentation()
            }
            None => ()
          }
          (self.event_hook)(MusicStopped)
          (self.event_hook)(SfxStopped)
          self.settings_menu.clear()
          self.saved_director_json = None
          self.runner = None
          self.enter_start_menu()
        }
        Log => {
          self.emit_ui_click_sfx()
          self.settings_menu.clear()
          match self.runner {
            Some(runner) => {
              if runner.log_build_state() == LogBuildState::NotBuilt {
                runner.start_reconstruct_dialog_history(
                  self.script(),
                  (self.new_state)(),
                )
              }
              runner.set_log_visible(true)
              self.phase = AppPhase::InGame
            }
            None => self.enter_start_menu()
          }
        }
        SaveSlot(slot) => {
          self.emit_ui_click_sfx()
          match self.runner {
            Some(runner) =>
              save_runner_to_slot_with_meta(
                runner,
                slot,
                preview=dialog_preview(runner),
                save_namespace=self.save_ns,
              )
            None => ()
          }
          self.settings_menu.render()
        }
        LoadSlot(slot) => {
          self.emit_ui_click_sfx()
          self.settings_menu.clear()
          let restored : Result[GameRunner[T], Error] = try? start_game_from_slot(
            self.script(),
            slot,
            self.ui_root_id,
            render_sync=self.render_sync,
            event_hook=self.event_hook,
            save_namespace=self.save_ns,
            ui_strings=self.ui_strings,
            script_locale_json=self.script_locale_json.unwrap_or(""),
            script_default_locale_json=self.script_default_locale_json.unwrap_or(
              "",
            ),
            script_locale=self.locale,
            script_default_locale=self.default_locale,
          )
          match restored {
            Ok(runner) => {
              runner.set_ui_click_sfx(self.ui_click_sfx_id)
              self.apply_settings_from_storage(runner)
              self.start_menu_music_stop()
              self.runner = Some(runner)
              self.phase = AppPhase::InGame
            }
            Err(_) => self.settings_menu.render()
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
    AppPhase::Gallery => {
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
        Replay(label) => {
          self.emit_ui_click_sfx()
          self.start_gallery_replay(label)
        }
        NoAction => ()
      }
      true
    }
    AppPhase::StartMenu => {
      self.start_menu_music_start()
      self.handle_menu_action(self.start_menu.take_action())
      true
    }
  }
}
