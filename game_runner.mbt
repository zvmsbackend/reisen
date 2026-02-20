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
}

///|
pub fn[T] GameRunner::new(director : Director[T], ui : UiDom) -> GameRunner[T] {
  { director, ui, render_sync: _ => (), event_hook: _ => () }
}

///|
pub fn[T] GameRunner::new_with_render_sync(
  director : Director[T],
  ui : UiDom,
  render_sync : RenderSyncHook[T],
) -> GameRunner[T] {
  { director, ui, render_sync, event_hook: _ => () }
}

///|
pub fn[T] GameRunner::new_with_hooks(
  director : Director[T],
  ui : UiDom,
  render_sync : RenderSyncHook[T],
  event_hook : EventHook,
) -> GameRunner[T] {
  { director, ui, render_sync, event_hook }
}

///|
fn[T] GameRunner::render_ui(self : GameRunner[T]) -> Unit {
  self.ui.render(ui_view_from_director(self.director))
  (self.render_sync)(self.director)
}

///|
pub fn[T] GameRunner::sync_ui(self : GameRunner[T]) -> Unit {
  self.render_ui()
}

///|
pub fn[T] GameRunner::step(
  self : GameRunner[T],
  elapsed_ms? : Int = 0,
) -> RuntimeEvent raise ScriptRuntimeError {
  let event = if !self.director.choices().is_empty() {
    match self.ui.take_selected_choice() {
      Some(choice_id) => self.director.choose(choice_id)
      None => ChoicePrompt(self.director.choices())
    }
  } else {
    self.director.step(elapsed_ms~)
  }
  (self.event_hook)(event)
  self.render_ui()
  event
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
  let result : Result[RuntimeEvent, ScriptRuntimeError] = try? self.step(
    elapsed_ms~,
  )
  match result {
    Ok(ScriptEnded) => false
    Ok(_) => true
    Err(_) => false
  }
}

///|
pub fn[T] GameRunner::director(self : GameRunner[T]) -> Director[T] {
  self.director
}

///|
pub fn[T] GameRunner::apply_settings(
  self : GameRunner[T],
  settings : GameSettings,
) -> Unit {
  self.ui.set_text_speed(settings.text_speed)
}
