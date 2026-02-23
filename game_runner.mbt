///|
/// Game loop glue between `Director` (state machine) and `UiDom` (HTML view).

///|
pub type RenderSyncHook[T] = (Director[T]) -> Unit

///|
pub type EventHook = (RuntimeEvent) -> Unit

///|
struct GameRunner[T] {
  director : Director[T]
  ui : UiDom
  render_sync : RenderSyncHook[T]
  event_hook : EventHook
  mut ui_dirty : Bool
  mut render_sync_dirty : Bool
  mut pending_action : String?
}

///|
pub fn[T] GameRunner::new(director : Director[T], ui : UiDom) -> GameRunner[T] {
  {
    director,
    ui,
    render_sync: _ => (),
    event_hook: _ => (),
    ui_dirty: true,
    render_sync_dirty: true,
    pending_action: None,
  }
}

///|
pub fn[T] GameRunner::new_with_render_sync(
  director : Director[T],
  ui : UiDom,
  render_sync : RenderSyncHook[T],
) -> GameRunner[T] {
  {
    director,
    ui,
    render_sync,
    event_hook: _ => (),
    ui_dirty: true,
    render_sync_dirty: true,
    pending_action: None,
  }
}

///|
pub fn[T] GameRunner::new_with_hooks(
  director : Director[T],
  ui : UiDom,
  render_sync : RenderSyncHook[T],
  event_hook : EventHook,
) -> GameRunner[T] {
  {
    director,
    ui,
    render_sync,
    event_hook,
    ui_dirty: true,
    render_sync_dirty: true,
    pending_action: None,
  }
}

///|
fn[T] GameRunner::render_ui(self : GameRunner[T]) -> Unit {
  self.ui.render(ui_view_from_director(self.director, self.ui))
  self.ui_dirty = false
}

///|
fn[T] GameRunner::sync_canvas(self : GameRunner[T]) -> Unit {
  (self.render_sync)(self.director)
  self.render_sync_dirty = false
}

///|
fn[T] GameRunner::maybe_render_ui(self : GameRunner[T]) -> Unit {
  if self.ui_dirty {
    self.render_ui()
  }
  if self.render_sync_dirty {
    self.sync_canvas()
  }
}

///|
pub fn[T] GameRunner::sync_ui(self : GameRunner[T]) -> Unit {
  self.ui.mark_all_dirty()
  self.render_ui()
  self.sync_canvas()
}

///|
pub fn[T] GameRunner::step(
  self : GameRunner[T],
  elapsed_ms? : Int = 0,
) -> RuntimeEvent raise ScriptRuntimeError {
  match self.ui.take_action() {
    Some(action) => {
      match action {
        "auto" => self.ui.toggle_auto_mode()
        "skip" => self.ui.toggle_skip_mode()
        "settings" | "qsave" | "save" => self.pending_action = Some(action)
        _ => ()
      }
      self.ui.mark_dirty_action_buttons()
      self.render_ui()
      return Noop
    }
    None => ()
  }
  if !self.director.choices().is_empty() {
    match self.ui.take_selected_choice() {
      Some(choice_id) => {
        let event = self.director.choose(choice_id)
        (self.event_hook)(event)
        self.ui.mark_all_dirty()
        self.render_ui()
        return event
      }
      None => {
        if self.ui_dirty {
          self.ui.mark_dirty_choices()
          self.render_ui()
        }
        return ChoicePrompt(self.director.choices())
      }
    }
  }
  if self.director.text_input() is Some(_) {
    if self.ui_dirty {
      let event = match self.director.text_input() {
        Some((var_name, prompt)) => TextInputPrompt(var_name, prompt)
        None => Noop
      }
      return event
    }
    match self.ui.take_submitted_text_input() {
      Some(value) => {
        let event = self.director.submit_text_input(value)
        (self.event_hook)(event)
        self.director.ui.text_input = None
        self.ui.mark_dirty_text_input()
        self.render_ui()
        return event
      }
      None => {
        let event = match self.director.text_input() {
          Some((var_name, prompt)) => TextInputPrompt(var_name, prompt)
          None => Noop
        }
        (self.event_hook)(event)
        return event
      }
    }
  }
  if self.director.dialog() is None {
    let event = self.director.step(elapsed_ms~)
    (self.event_hook)(event)
    match event {
      Said(_, _) => {
        self.ui_dirty = true
        self.ui.mark_dirty_text()
      }
      ChoicePrompt(_) => {
        self.ui_dirty = true
        self.ui.mark_dirty_choices()
      }
      TextInputPrompt(_, _) => {
        self.ui_dirty = true
        self.ui.mark_dirty_text_input()
      }
      ScriptEnded => {
        self.ui_dirty = true
        self.ui.mark_all_dirty()
      }
      BackgroundShown(_) | FigureHidden(_) | FigureShown(_) => {
        self.ui_dirty = true
        self.render_sync_dirty = true
      }
      _ => ()
    }
    self.maybe_render_ui()
    return event
  }
  self.ui.advance_skip_mode_timer(elapsed_ms~)
  if self.ui.should_skip_advance() {
    self.ui.complete_typewriter()
    self.ui.mark_skip_advanced()
    let event = self.director.step(elapsed_ms=0)
    (self.event_hook)(event)
    match event {
      ChoicePrompt(_) | TextInputPrompt(_, _) | ScriptEnded => {
        self.ui.mark_dirty_choices()
        return event
      }
      Said(_, _) => {
        self.ui.mark_dirty_text()
        self.render_ui()
        return self.step(elapsed_ms=0)
      }
      _ => {
        self.render_ui()
        return self.step(elapsed_ms=0)
      }
    }
  }
  let is_typewriter_done = self.ui.is_typewriter_done()
  if not(is_typewriter_done) {
    if self.ui.check_typewriter_click() {
      self.ui.complete_typewriter()
      let event = self.director.step(elapsed_ms=0)
      (self.event_hook)(event)
      match event {
        Said(_, _) => self.ui.mark_dirty_text()
        ChoicePrompt(_) => self.ui.mark_dirty_choices()
        TextInputPrompt(_, _) => self.ui.mark_dirty_text_input()
        ScriptEnded => self.ui.mark_all_dirty()
        BackgroundShown(_) | FigureHidden(_) | FigureShown(_) => {
          self.ui_dirty = true
          self.render_sync_dirty = true
        }
        _ => ()
      }
      self.render_ui()
      return event
    } else {
      ignore(self.ui.advance_typewriter(elapsed_ms~))
      self.ui.dirty_text = true
      let event = self.current_dialog_event()
      self.render_ui()
      return event
    }
  }
  if !self.director.last_event_said || self.ui.check_typewriter_click() {
    let event = self.director.step(elapsed_ms=0)
    (self.event_hook)(event)
    match event {
      Said(_, _) => {
        self.ui_dirty = true
        self.ui.mark_dirty_text()
      }
      ChoicePrompt(_) => {
        self.ui_dirty = true
        self.ui.mark_dirty_choices()
      }
      TextInputPrompt(_, _) => {
        self.ui_dirty = true
        self.ui.mark_dirty_text_input()
      }
      ScriptEnded => {
        self.ui_dirty = true
        self.ui.mark_all_dirty()
      }
      BackgroundShown(_) | FigureHidden(_) | FigureShown(_) => {
        self.ui_dirty = true
        self.render_sync_dirty = true
      }
      _ => ()
    }
    self.maybe_render_ui()
    return event
  }
  self.ui.advance_auto_mode_timer(elapsed_ms~)
  if self.ui.should_auto_advance() {
    self.ui.mark_auto_advanced()
    let event = self.director.step(elapsed_ms=0)
    (self.event_hook)(event)
    self.ui_dirty = true
    self.ui.mark_dirty_text()
    self.maybe_render_ui()
    return event
  }
  let event = self.current_dialog_event()
  self.maybe_render_ui()
  event
}

///|
fn[T] GameRunner::current_dialog_event(self : GameRunner[T]) -> RuntimeEvent {
  match self.director.dialog() {
    Some(line) => Said(line.speaker, line.text)
    None => Noop
  }
}

///|
pub fn[T] GameRunner::submit_choice(
  self : GameRunner[T],
  choice_id : String,
) -> RuntimeEvent raise ScriptRuntimeError {
  let event = self.director.choose(choice_id)
  (self.event_hook)(event)
  self.render_ui()
  event
}

///|
/// Advances one frame and reports whether loop should continue.
pub fn[T] GameRunner::tick(self : GameRunner[T], elapsed_ms? : Int = 0) -> Bool {
  (!(self.step(elapsed_ms~) is ScriptEnded)) catch {
    _ => false
  }
}

///|
pub fn[T] GameRunner::director(self : GameRunner[T]) -> Director[T] {
  self.director
}

///|
pub fn[T] GameRunner::clear_ui(self : GameRunner[T]) -> Unit {
  self.ui.clear_game_ui()
}

///|
pub fn[T] GameRunner::complete_typewriter(self : GameRunner[T]) -> Unit {
  self.ui.complete_typewriter()
}

///|
pub fn[T] GameRunner::simulate_click(self : GameRunner[T]) -> Unit {
  self.ui.simulate_click()
}

///|
pub fn[T] GameRunner::toggle_auto_mode(self : GameRunner[T]) -> Unit {
  self.ui.toggle_auto_mode()
}

///|
pub fn[T] GameRunner::toggle_skip_mode(self : GameRunner[T]) -> Unit {
  self.ui.toggle_skip_mode()
}

///|
pub fn[T] GameRunner::take_game_action(self : GameRunner[T]) -> String? {
  self.ui.take_action()
}

///|
pub fn[T] GameRunner::take_pending_action(self : GameRunner[T]) -> String? {
  let action = self.pending_action
  self.pending_action = None
  action
}

///|
pub fn[T] GameRunner::apply_settings(
  self : GameRunner[T],
  settings : GameSettings,
) -> Unit {
  self.ui.set_text_speed(settings.text_speed)
  audio_dom_set_bgm_gain(settings.bgm_volume)
  audio_dom_set_sfx_gain(settings.sfx_volume)
}
