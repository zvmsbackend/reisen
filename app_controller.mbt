///|
/// Top-level app controller: start menu <-> game runtime switching.

///|
pub enum AppPhase {
  StartGate
  StartLogo
  StartMenu
  Gallery
  Settings
  InGame
} derive(Show, Eq)

///|
struct AppController[T] {
  script : Script[T]
  new_state : () -> GameState[T]
  ui_root_id : String
  save_ns : String
  autosave_slot : String
  autosave_title : String
  menu_music_id : String?
  menu_music_loop : Bool
  mut menu_music_playing : Bool
  start_logo_url : String
  start_logo_duration_ms : Int
  mut start_logo_elapsed_ms : Int
  menu : StartMenu
  gallery_menu : GalleryMenu
  settings_menu : SettingsMenu
  gallery_replay_state_factories : ReplayStateFactories[T]
  mut phase : AppPhase
  render_sync : RenderSyncHook[T]
  event_hook : EventHook
  mut runner : GameRunner[T]?
  mut saved_director_json : String?
}

///|
pub fn[T] AppController::new(
  script : Script[T],
  new_state : () -> GameState[T],
  ui_root_id : String,
  save_namespace? : String = "global",
  autosave_slot? : String = "autosave",
  autosave_title? : String = "",
  menu_background? : String = "",
  settings_background? : String = "",
  gallery_background? : String = "",
  menu_music? : Music,
  menu_music_loop? : Bool = true,
  start_logo_url? : String = "",
  start_logo_duration_ms? : Int = 2000,
  render_sync? : RenderSyncHook[T] = _ => (),
  event_hook? : EventHook = _ => (),
  gallery_replay_state_factories? : ReplayStateFactories[T] = ReplayStateFactories::new(),
) -> AppController[T] {
  let app : AppController[T] = {
    script,
    new_state,
    ui_root_id,
    save_ns: save_namespace,
    autosave_slot,
    autosave_title,
    menu_music_id: menu_music.map(music => music.id),
    menu_music_loop,
    menu_music_playing: false,
    start_logo_url,
    start_logo_duration_ms,
    start_logo_elapsed_ms: 0,
    menu: StartMenu::new(
      ui_root_id,
      save_namespace~,
      background=menu_background,
    ),
    gallery_menu: GalleryMenu::new(
      ui_root_id,
      save_namespace~,
      background=gallery_background,
    ),
    settings_menu: SettingsMenu::new(
      ui_root_id,
      save_namespace~,
      background=settings_background,
    ),
    phase: AppPhase::StartGate,
    render_sync,
    event_hook,
    runner: None,
    saved_director_json: None,
    gallery_replay_state_factories,
  }
  app.menu.render_gate()
  app
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
fn[T] AppController::enter_start_menu(self : AppController[T]) -> Unit {
  self.gallery_menu.clear()
  self.menu.clear_logo()
  self.menu.clear_gate()
  self.menu.render()
  self.phase = AppPhase::StartMenu
  self.start_menu_music_start()
}

///|
fn[T] AppController::enter_start_logo(self : AppController[T]) -> Unit {
  self.menu.clear_gate()
  self.menu.render_logo(self.start_logo_url, self.start_logo_duration_ms)
  self.start_logo_elapsed_ms = 0
  self.phase = AppPhase::StartLogo
}

///|
pub fn[T] AppController::phase(self : AppController[T]) -> AppPhase {
  self.phase
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
fn[T] AppController::start_gallery_replay(
  self : AppController[T],
  replay_label : String,
) -> Unit {
  let target = gallery_replayable_images_in(self.save_ns)
    .iter()
    .find_first(image => image.replay_label == Some(replay_label))
  match target {
    Some(image) => {
      let settings = settings_read_in(self.save_ns)
      let replay_factory = self.replay_factory_for_image(image)
      let runner = start_game(
        self.script,
        replay_factory(),
        self.ui_root_id,
        render_sync=self.render_sync,
        event_hook=self.event_hook,
        settings?,
      )
      try {
        runner.jump_to_label(replay_label)
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
fn[T : FromJson] AppController::handle_menu_action(
  self : AppController[T],
  action : StartMenuAction,
) -> Unit {
  let settings = settings_read_in(self.save_ns)
  match action {
    NoAction => ()
    NewGame => {
      self.start_menu_music_stop()
      self.runner = Some(
        start_game(
          self.script,
          (self.new_state)(),
          self.ui_root_id,
          render_sync=self.render_sync,
          event_hook=self.event_hook,
          settings?,
        ),
      )
      self.menu.clear()
      self.phase = AppPhase::InGame
    }
    Continue(slot) => {
      let restored : Result[GameRunner[T], Error] = try? start_game_from_slot(
        self.script,
        slot,
        self.ui_root_id,
        render_sync=self.render_sync,
        event_hook=self.event_hook,
        save_namespace=self.save_ns,
      )
      match restored {
        Ok(runner) => {
          self.start_menu_music_stop()
          self.runner = Some(runner)
          self.menu.clear()
          self.phase = AppPhase::InGame
        }
        Err(_) => {
          self.runner = None
          self.enter_start_menu()
        }
      }
    }
    Load => {
      self.menu.clear()
      self.settings_menu.set_context(SettingsContext::FromStartMenu)
      self.settings_menu.set_view_mode(SettingsViewMode::LoadList)
      self.settings_menu.render()
      self.phase = AppPhase::Settings
    }
    Settings => {
      self.menu.clear()
      self.settings_menu.set_context(SettingsContext::FromStartMenu)
      self.settings_menu.render()
      self.phase = AppPhase::Settings
    }
    Gallery =>
      if gallery_registered_images().length() > 0 {
        self.menu.clear()
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
pub fn[T : FromJson + ToJson] AppController::tick(
  self : AppController[T],
  elapsed_ms? : Int = 0,
) -> Bool {
  match self.phase {
    AppPhase::StartGate => {
      match self.menu.take_gate_action() {
        StartGateAction::Start =>
          if self.start_logo_url == "" {
            self.enter_start_menu()
          } else {
            self.enter_start_logo()
          }
        StartGateAction::NoAction => ()
      }
      true
    }
    AppPhase::StartLogo => {
      self.start_logo_elapsed_ms += elapsed_ms
      match self.menu.take_logo_action() {
        StartLogoAction::Done => self.enter_start_menu()
        StartLogoAction::NoAction =>
          if self.start_logo_elapsed_ms >= self.start_logo_duration_ms {
            self.enter_start_menu()
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
                self.settings_menu.set_context(SettingsContext::FromMidgame)
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
                self.settings_menu.set_context(SettingsContext::FromMidgame)
                self.settings_menu.set_view_mode(SettingsViewMode::SaveList)
                self.settings_menu.render()
                self.phase = AppPhase::Settings
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
        SettingsAction::Back => {
          self.settings_menu.clear()
          match self.saved_director_json {
            Some(json) => {
              self.saved_director_json = None
              try {
                let director = director_from_save_json(self.script, json)
                let ui = UiDom::new(self.ui_root_id)
                let runner = GameRunner::new_with_hooks(
                  director,
                  ui,
                  self.render_sync,
                  self.event_hook,
                )
                match settings_read_in(self.save_ns) {
                  Some(settings) => runner.apply_settings(settings)
                  None => ()
                }
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
        SettingsAction::NewGame => {
          self.settings_menu.clear()
          self.saved_director_json = None
          let settings = settings_read_in(self.save_ns)
          self.start_menu_music_stop()
          self.runner = Some(
            start_game(
              self.script,
              (self.new_state)(),
              self.ui_root_id,
              render_sync=self.render_sync,
              event_hook=self.event_hook,
              settings?,
            ),
          )
          self.phase = AppPhase::InGame
        }
        SettingsAction::StartMenu => {
          match self.runner {
            Some(runner) => {
              runner.apply_runtime_event(SfxStopped)
              runner.clear_presentation()
            }
            None => ()
          }
          (self.event_hook)(MusicStopped)
          (self.event_hook)(SfxStopped)
          self.save_autosave_if_enabled()
          self.settings_menu.clear()
          self.saved_director_json = None
          self.runner = None
          self.enter_start_menu()
        }
        SettingsAction::SaveSlot(slot) => {
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
        SettingsAction::LoadSlot(slot) => {
          self.settings_menu.clear()
          let restored : Result[GameRunner[T], Error] = try? start_game_from_slot(
            self.script,
            slot,
            self.ui_root_id,
            render_sync=self.render_sync,
            event_hook=self.event_hook,
            save_namespace=self.save_ns,
          )
          match restored {
            Ok(runner) => {
              self.start_menu_music_stop()
              self.runner = Some(runner)
              self.phase = AppPhase::InGame
            }
            Err(_) => self.settings_menu.render()
          }
        }
        SettingsAction::ViewChanged => self.settings_menu.render()
        SettingsAction::NoAction => ()
      }
      true
    }
    AppPhase::Gallery => {
      match self.gallery_menu.take_action() {
        GalleryAction::Back => {
          self.gallery_menu.clear()
          self.enter_start_menu()
        }
        GalleryAction::Open(_)
        | GalleryAction::Close
        | GalleryAction::Prev
        | GalleryAction::Next => self.gallery_menu.render()
        GalleryAction::Replay(label) => self.start_gallery_replay(label)
        GalleryAction::NoAction => ()
      }
      true
    }
    AppPhase::StartMenu => {
      self.start_menu_music_start()
      self.handle_menu_action(self.menu.take_action())
      true
    }
  }
}
