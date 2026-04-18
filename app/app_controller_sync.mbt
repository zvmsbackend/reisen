///|
fn[T] AppController::script(
  self : AppController[T],
) -> Script[T] raise AppControllerError {
  match self.script {
    Some(script) => script
    None => {
      self.loading_menu.render(self.ui_strings.loading_text)
      let script = self.load_script_from_factory()
      self.loading_menu.clear()
      self.validate_and_cache_script(script)
    }
  }
}

///|
fn[T] AppController::start_gallery_replay(
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
fn[T : FromJson] AppController::handle_menu_action(
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
fn[T : FromJson + ToJson] AppController::tick_settings(
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
      match self.take_saved_resume_state() {
        Some(saved) => {
          let script = self.script()
          try {
            let runner = self.resume_runner_from_json(
              script,
              saved.director_json,
              saved.dialog_history,
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
        None => self.enter_start_menu()
      }
    }
    NewGame => {
      self.emit_ui_click_sfx()
      self.settings_menu.clear()
      self.clear_saved_resume_state()
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
      self.clear_saved_resume_state()
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
fn[T] AppController::tick_gallery(
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
fn[T : FromJson] AppController::tick_start_menu(
  self : AppController[T],
) -> Bool raise AppControllerError {
  self.start_menu_music_start()
  self.handle_menu_action(self.start_menu.take_action())
  true
}

///|
pub fn[T : FromJson + ToJson] AppController::tick(
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
