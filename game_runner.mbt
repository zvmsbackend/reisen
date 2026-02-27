///|
/// Game loop glue between `Director` (state machine) and `UiDom` (HTML view).

///|
pub type RenderSyncHook[T] = async (Director[T]) -> Unit noraise

///|
pub type EventHook = (RuntimeEvent) -> Unit

///|
pub enum LogBuildState {
  NotBuilt
  Building
  Ready
} derive(Show, Eq)

///|
struct GameRunner[T] {
  director : Director[T]
  ui : UiDom
  render_sync : RenderSyncHook[T]
  event_hook : EventHook
  mut ui_dirty : Bool
  mut render_sync_dirty : Bool
  mut pending_action : String?
  mut animation_remaining_ms : Int
  mut blocking_remaining_ms : Int
  mut blocking_wait_sfx : Bool
  mut blocking_until_click : Bool
  mut log_build_state : LogBuildState
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
    animation_remaining_ms: 0,
    blocking_remaining_ms: 0,
    blocking_wait_sfx: false,
    blocking_until_click: false,
    log_build_state: NotBuilt,
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
    animation_remaining_ms: 0,
    blocking_remaining_ms: 0,
    blocking_wait_sfx: false,
    blocking_until_click: false,
    log_build_state: NotBuilt,
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
    animation_remaining_ms: 0,
    blocking_remaining_ms: 0,
    blocking_wait_sfx: false,
    blocking_until_click: false,
    log_build_state: NotBuilt,
  }
}

///|
fn[T] GameRunner::bump_animation_timer(
  self : GameRunner[T],
  duration_ms : Int,
) -> Unit {
  if duration_ms <= 0 {
    return
  }
  if duration_ms > self.animation_remaining_ms {
    self.animation_remaining_ms = duration_ms
  }
}

///|
fn[T] GameRunner::advance_animation_timer(
  self : GameRunner[T],
  elapsed_ms : Int,
) -> Unit {
  if self.animation_remaining_ms <= 0 {
    return
  }
  let remaining = self.animation_remaining_ms - elapsed_ms
  self.animation_remaining_ms = if remaining < 0 { 0 } else { remaining }
  if self.animation_remaining_ms > 0 {
    self.render_sync_dirty = true
  }
}

///|
fn[T] GameRunner::bump_blocking_timer(
  self : GameRunner[T],
  duration_ms : Int,
) -> Unit {
  if duration_ms <= 0 {
    return
  }
  if duration_ms > self.blocking_remaining_ms {
    self.blocking_remaining_ms = duration_ms
  }
}

///|
fn[T] GameRunner::advance_blocking_timer(
  self : GameRunner[T],
  elapsed_ms : Int,
) -> Unit {
  if self.blocking_remaining_ms <= 0 {
    return
  }
  let remaining = self.blocking_remaining_ms - elapsed_ms
  self.blocking_remaining_ms = if remaining < 0 { 0 } else { remaining }
}

///|
fn[T] GameRunner::clear_blocking(self : GameRunner[T]) -> Unit {
  self.blocking_remaining_ms = 0
  self.blocking_wait_sfx = false
  self.blocking_until_click = false
}

///|
fn[T] GameRunner::is_blocking_active(self : GameRunner[T]) -> Bool {
  if self.blocking_until_click {
    return true
  }
  if self.blocking_wait_sfx {
    if audio_dom_has_active_sfx() {
      return true
    }
    self.blocking_wait_sfx = false
  }
  self.blocking_remaining_ms > 0
}

///|
fn[T] GameRunner::render_ui(self : GameRunner[T]) -> Unit {
  self.ui.render(ui_view_from_director(self.director, self.ui))
  self.ui_dirty = false
}

///|
async fn[T] GameRunner::sync_canvas(self : GameRunner[T]) -> Unit noraise {
  (self.render_sync)(self.director)
  self.render_sync_dirty = false
}

///|
async fn[T] GameRunner::maybe_render_ui(self : GameRunner[T]) -> Unit noraise {
  if self.ui_dirty {
    self.render_ui()
  }
  if self.render_sync_dirty {
    self.sync_canvas()
  }
}

///|
fn[T] GameRunner::apply_event_effects(
  self : GameRunner[T],
  event : RuntimeEvent,
  mark_ui_for_text : Bool,
) -> Unit {
  match event {
    Said(_) => {
      if mark_ui_for_text {
        self.ui_dirty = true
      }
      self.ui.mark_dirty_text()
    }
    ChoicePrompt(_) => {
      if mark_ui_for_text {
        self.ui_dirty = true
      }
      self.ui.mark_dirty_choices()
    }
    TextInputPrompt(_, _) => {
      if mark_ui_for_text {
        self.ui_dirty = true
      }
      self.ui.mark_dirty_text_input()
    }
    TextBoxShown | TextBoxHidden => {
      if mark_ui_for_text {
        self.ui_dirty = true
      }
      self.ui.mark_dirty_text()
      self.ui.mark_dirty_action_buttons()
    }
    AvatarShown(_) | AvatarHidden => {
      if mark_ui_for_text {
        self.ui_dirty = true
      }
      self.ui.mark_dirty_text()
    }
    IntroShown(_) | VideoStarted(_, _) | VideoEnded(_) | ScriptEnded => {
      if mark_ui_for_text {
        self.ui_dirty = true
      }
      self.ui.mark_all_dirty()
    }
    BackgroundShown(_) | FigureHidden(_) | FigureShown(_) => {
      self.ui_dirty = true
      self.render_sync_dirty = true
    }
    DomFigureShown(_, _, _)
    | DomFigureHidden(_)
    | DomFigureInteractiveSet(_, _) => self.ui_dirty = true
    AnimatedPixi(_, spec) => {
      self.ui_dirty = true
      self.render_sync_dirty = true
      self.bump_animation_timer(spec.duration_ms)
      if spec.blocking {
        self.bump_blocking_timer(spec.duration_ms)
      }
    }
    AnimatedDom(_, spec) => {
      self.ui_dirty = true
      self.bump_animation_timer(spec.duration_ms)
      if spec.blocking {
        self.bump_blocking_timer(spec.duration_ms)
      }
    }
    EffectApplied(_, spec) => {
      self.ui_dirty = true
      self.render_sync_dirty = true
      match spec.duration_ms {
        Some(duration) => self.bump_animation_timer(duration)
        None => ()
      }
      if spec.blocking {
        match spec.duration_ms {
          Some(duration) => self.bump_blocking_timer(duration)
          None => self.blocking_until_click = true
        }
      }
    }
    Live2dMotionPlayed(_, _, _) => {
      self.ui_dirty = true
      self.render_sync_dirty = true
    }
    Live2dExpressionSet(_, _) => {
      self.ui_dirty = true
      self.render_sync_dirty = true
    }
    SfxPlayed(_, blocking) => if blocking { self.blocking_wait_sfx = true }
    _ => ()
  }
}

///|
priv enum RenderMode {
  RenderUi
  MaybeRenderUi
}

///|
async fn[T] GameRunner::apply_event_and_render(
  self : GameRunner[T],
  event : RuntimeEvent,
  mark_ui_for_text : Bool,
  mode : RenderMode,
) -> Unit noraise {
  self.apply_event_effects(event, mark_ui_for_text)
  match mode {
    RenderMode::RenderUi => self.render_ui()
    RenderMode::MaybeRenderUi => self.maybe_render_ui()
  }
}

///|
pub async fn[T] GameRunner::sync_ui(self : GameRunner[T]) -> Unit {
  self.ui.mark_all_dirty()
  self.render_ui()
  self.sync_canvas()
}

///|
pub async fn[T] GameRunner::step(
  self : GameRunner[T],
  elapsed_ms? : Int = 0,
) -> RuntimeEvent raise ScriptRuntimeError {
  self.advance_animation_timer(elapsed_ms)
  self.advance_blocking_timer(elapsed_ms)
  self.ui.advance_dom_animation_timer(elapsed_ms)
  if self.ui.has_active_dom_animations() {
    self.ui_dirty = true
  }
  if self.director.is_waiting_video() {
    match self.ui.take_video_action() {
      Some(action) => {
        let skipped = action == "skip"
        let event = self.director.complete_video_wait(skipped)
        (self.event_hook)(event)
        self.apply_event_and_render(event, false, RenderMode::RenderUi)
        return event
      }
      None => ()
    }
  }
  if self.director.is_waiting() {
    if self.director.can_auto_skip_wait_click() {
      self.ui.advance_auto_mode_timer(elapsed_ms~)
      if self.ui.should_auto_skip_wait_click() {
        self.director.skip_wait()
        self.ui.mark_auto_advanced()
      }
    }
    if self.ui.skip_mode {
      self.director.skip_wait()
    } else if self.ui.check_typewriter_click() {
      self.director.skip_wait()
    }
  }
  match self.ui.take_action() {
    Some(action) => {
      match action {
        "auto" => self.ui.toggle_auto_mode()
        "skip" => self.ui.toggle_skip_mode()
        "dialog" => {
          if self.director.text_box_visible() {
            self.director.apply_event(TextBoxHidden)
          } else {
            self.director.apply_event(TextBoxShown)
          }
          self.ui_dirty = true
          self.ui.mark_dirty_text()
        }
        "skip_on" => self.ui.set_skip_mode(true)
        "skip_off" => self.ui.set_skip_mode(false)
        "skip_hold_on" => self.ui.set_skip_hold(true)
        "skip_hold_off" => self.ui.set_skip_hold(false)
        "settings" | "qsave" | "save" => self.pending_action = Some(action)
        _ => ()
      }
      self.ui.mark_dirty_action_buttons()
      self.render_ui()
      return Noop
    }
    None => ()
  }
  if self.is_blocking_active() {
    if self.ui.check_typewriter_click() {
      self.clear_blocking()
    } else {
      self.maybe_render_ui()
      return Noop
    }
  }
  if self.director.is_waiting() {
    let event = self.director.step(elapsed_ms~)
    (self.event_hook)(event)
    self.apply_event_and_render(event, true, RenderMode::MaybeRenderUi)
    return event
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
  match self.director.intro_text() {
    Some(text) => {
      let mut intro_done = self.ui.check_intro_done()
      if self.ui.check_typewriter_click() && !intro_done {
        intro_done = self.ui.reveal_intro_line() || intro_done
      }
      if intro_done {
        self.director.ui.intro_text = None
        let event = self.director.step(elapsed_ms=0)
        (self.event_hook)(event)
        self.apply_event_and_render(event, true, RenderMode::MaybeRenderUi)
        return event
      }
      self.maybe_render_ui()
      return IntroShown(text)
    }
    None => ()
  }
  if self.director.dialog() is None {
    let event = self.director.step(elapsed_ms~)
    (self.event_hook)(event)
    self.apply_event_and_render(event, true, RenderMode::MaybeRenderUi)
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
      _ => {
        self.apply_event_and_render(event, false, RenderMode::RenderUi)
        return self.step(elapsed_ms=0)
      }
    }
  }
  let is_typewriter_done = self.ui.is_typewriter_done()
  if not(is_typewriter_done) {
    if self.ui.check_typewriter_click() {
      self.ui.complete_typewriter()
      self.ui.dirty_text = true
      let event = self.current_dialog_event()
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
  match self.director.dialog() {
    Some(line) if line.proceed_on_done => {
      let event = self.director.step(elapsed_ms=0)
      (self.event_hook)(event)
      self.apply_event_and_render(event, true, RenderMode::MaybeRenderUi)
      return event
    }
    _ => ()
  }
  if !self.director.last_event_said || self.ui.check_typewriter_click() {
    let event = self.director.step(elapsed_ms=0)
    (self.event_hook)(event)
    self.apply_event_and_render(event, true, RenderMode::MaybeRenderUi)
    return event
  }
  self.ui.advance_auto_mode_timer(elapsed_ms~)
  if self.ui.should_auto_advance() {
    self.ui.mark_auto_advanced()
    let event = self.director.step(elapsed_ms=0)
    (self.event_hook)(event)
    self.apply_event_and_render(event, true, RenderMode::MaybeRenderUi)
    return event
  }
  let event = self.current_dialog_event()
  self.maybe_render_ui()
  event
}

///|
fn[T] GameRunner::current_dialog_event(self : GameRunner[T]) -> RuntimeEvent {
  match self.director.dialog() {
    Some(line) =>
      Said(
        speaker=line.speaker,
        text=line.text,
        typewriter=line.typewriter,
        append=line.append,
        voice=None,
      )
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
pub fn[T] GameRunner::submit_custom_event(
  self : GameRunner[T],
  name : String,
  payload : String,
) -> RuntimeEvent {
  let event = self.director.submit_custom_event(name, payload)
  (self.event_hook)(event)
  event
}

///|
pub fn[T] GameRunner::jump_to_label(
  self : GameRunner[T],
  label : String,
) -> Unit raise ScriptRuntimeError {
  self.director.jump_to_label(label)
}

///|
/// Advances one frame and reports whether loop should continue.
pub async fn[T] GameRunner::tick(
  self : GameRunner[T],
  elapsed_ms? : Int = 0,
) -> Bool {
  let keep_running = try self.step(elapsed_ms~) catch {
    _ => false
  } noraise {
    event => !(event is ScriptEnded)
  }
  if self.animation_remaining_ms > 0 {
    self.sync_canvas()
  }
  keep_running
}

///|
pub fn[T] GameRunner::director(self : GameRunner[T]) -> Director[T] {
  self.director
}

///|
pub fn[T] GameRunner::flow_trace(
  self : GameRunner[T],
) -> Array[ScriptFlowTrace] {
  self.director.flow_trace()
}

///|
pub fn[T] GameRunner::dialog_history(
  self : GameRunner[T],
) -> Array[DialogLogEntry] {
  self.director.dialog_history()
}

///|
pub fn[T] GameRunner::log_build_state(self : GameRunner[T]) -> LogBuildState {
  self.log_build_state
}

///|
pub fn[T] GameRunner::set_log_build_state(
  self : GameRunner[T],
  state : LogBuildState,
) -> Unit {
  self.log_build_state = state
}

///|
pub fn[T] GameRunner::apply_runtime_event(
  self : GameRunner[T],
  event : RuntimeEvent,
) -> Unit {
  self.director.apply_event(event)
}

///|
pub fn[T] GameRunner::clear_ui(self : GameRunner[T]) -> Unit {
  self.ui.clear_game_ui()
}

///|
pub async fn[T] GameRunner::clear_presentation(self : GameRunner[T]) -> Unit {
  self.ui.clear_game_ui()
  self.director.clear_render()
  self.sync_canvas()
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
  self.ui.set_media_volume(settings.bgm_volume)
  audio_dom_set_bgm_gain(settings.bgm_volume)
  audio_dom_set_sfx_gain(settings.sfx_volume)
}
