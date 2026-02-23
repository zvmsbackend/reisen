///|
/// Top-level app controller: start menu <-> game runtime switching.

///|
pub enum AppPhase {
  StartMenu
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
  menu : StartMenu
  settings_menu : SettingsMenu
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
  render_sync? : RenderSyncHook[T] = _ => (),
  event_hook? : EventHook = _ => (),
) -> AppController[T] {
  let app : AppController[T] = {
    script,
    new_state,
    ui_root_id,
    save_ns: save_namespace,
    autosave_slot,
    autosave_title,
    menu: StartMenu::new(
      ui_root_id,
      save_namespace~,
      background=menu_background,
    ),
    settings_menu: SettingsMenu::new(
      ui_root_id,
      save_namespace~,
      background=settings_background,
    ),
    phase: AppPhase::StartMenu,
    render_sync,
    event_hook,
    runner: None,
    saved_director_json: None,
  }
  app.menu.render()
  app
}

///|
pub fn[T] AppController::phase(self : AppController[T]) -> AppPhase {
  self.phase
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
          self.runner = Some(runner)
          self.menu.clear()
          self.phase = AppPhase::InGame
        }
        Err(_) => {
          self.runner = None
          self.menu.render()
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
            (self.event_hook)(MusicStopped)
            runner.clear_ui()
            self.runner = None
            self.menu.render()
            self.phase = AppPhase::StartMenu
            true
          }
        None => {
          self.menu.render()
          self.phase = AppPhase::StartMenu
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
                _ => {
                  self.menu.render()
                  self.phase = AppPhase::StartMenu
                }
              }
            }
            None => {
              self.menu.render()
              self.phase = AppPhase::StartMenu
            }
          }
        }
        SettingsAction::Saved => self.settings_menu.render()
        SettingsAction::NewGame => {
          self.settings_menu.clear()
          self.saved_director_json = None
          let settings = settings_read_in(self.save_ns)
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
        SettingsAction::Load => self.settings_menu.render()
        SettingsAction::StartMenu => {
          self.save_autosave_if_enabled()
          (self.event_hook)(MusicStopped)
          self.settings_menu.clear()
          self.saved_director_json = None
          self.runner = None
          self.menu.render()
          self.phase = AppPhase::StartMenu
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
    AppPhase::StartMenu => {
      self.handle_menu_action(self.menu.take_action())
      true
    }
  }
}
