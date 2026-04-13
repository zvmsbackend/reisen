///|
/// Game loop glue between `Director` (state machine) and UI/audio ports.

///|
pub type RenderSyncHook = (CoreRenderSnapshot, Bool) -> Unit noraise

///|
pub type RenderExtensionHook = (RenderExtensionView, Bool) -> Unit noraise

///|
/// Default no-op core render hook for compatibility wiring.
pub let noop_core_render_sync : RenderSyncHook = (_, _) => ()

///|
priv struct SequenceJob {
  target : String
  is_pixi : Bool
  steps : Array[GroupStep]
  mut cursor : Int
  mut step_started : Bool
  mut remaining_ms : Int
}

///|
struct GameRunner[T] {
  director : Director[T]
  ui : UiPort
  audio : AudioPort
  render_sync : RenderSyncHook
  render_extension : RenderExtensionHook?
  event_hook : EventHook
  mut ui_click_sfx_id : String?
  mut ui_dirty : Bool
  mut render_sync_dirty : Bool
  mut pending_action : String?
  mut animation_remaining_ms : Int
  mut blocking_remaining_ms : Int
  mut blocking_wait_sfx : Bool
  mut blocking_until_click : Bool
  mut sequence_jobs : Array[SequenceJob]
}

///|
pub fn[T] GameRunner::new(director : Director[T], ui : UiDom) -> GameRunner[T] {
  let ui = UiPort::from_dom(ui)
  {
    director,
    ui,
    audio: AudioPort::browser(),
    render_sync: noop_core_render_sync,
    render_extension: None,
    event_hook: _ => (),
    ui_click_sfx_id: None,
    ui_dirty: true,
    render_sync_dirty: true,
    pending_action: None,
    animation_remaining_ms: 0,
    blocking_remaining_ms: 0,
    blocking_wait_sfx: false,
    blocking_until_click: false,
    sequence_jobs: [],
  }
}

///|
pub fn[T] GameRunner::new_with_render_sync(
  director : Director[T],
  ui : UiDom,
  render_sync : RenderSyncHook,
) -> GameRunner[T] {
  let ui = UiPort::from_dom(ui)
  {
    director,
    ui,
    audio: AudioPort::browser(),
    render_sync,
    render_extension: None,
    event_hook: _ => (),
    ui_click_sfx_id: None,
    ui_dirty: true,
    render_sync_dirty: true,
    pending_action: None,
    animation_remaining_ms: 0,
    blocking_remaining_ms: 0,
    blocking_wait_sfx: false,
    blocking_until_click: false,
    sequence_jobs: [],
  }
}

///|
pub fn[T] GameRunner::new_with_hooks(
  director : Director[T],
  ui : UiDom,
  render_sync : RenderSyncHook,
  event_hook : EventHook,
  render_extension? : RenderExtensionHook,
) -> GameRunner[T] {
  let ui = UiPort::from_dom(ui)
  {
    director,
    ui,
    audio: AudioPort::browser(),
    render_sync,
    render_extension,
    event_hook,
    ui_click_sfx_id: None,
    ui_dirty: true,
    render_sync_dirty: true,
    pending_action: None,
    animation_remaining_ms: 0,
    blocking_remaining_ms: 0,
    blocking_wait_sfx: false,
    blocking_until_click: false,
    sequence_jobs: [],
  }
}

///|
pub fn[T] GameRunner::new_with_ports(
  director : Director[T],
  ui : UiPort,
  audio : AudioPort,
  render_sync : RenderSyncHook,
  event_hook : EventHook,
  render_extension? : RenderExtensionHook,
) -> GameRunner[T] {
  {
    director,
    ui,
    audio,
    render_sync,
    render_extension,
    event_hook,
    ui_click_sfx_id: None,
    ui_dirty: true,
    render_sync_dirty: true,
    pending_action: None,
    animation_remaining_ms: 0,
    blocking_remaining_ms: 0,
    blocking_wait_sfx: false,
    blocking_until_click: false,
    sequence_jobs: [],
  }
}

///|
fn[T] GameRunner::emit_ui_click_sfx(self : GameRunner[T]) -> Unit {
  match self.ui_click_sfx_id {
    Some(sfx_id) => (self.event_hook)(SfxPlayed(sfx_id, false))
    None => ()
  }
}

///|
fn[T] GameRunner::emit_runtime_event(
  self : GameRunner[T],
  event : RuntimeEvent,
) -> Unit {
  let localized = match event {
    Said(speaker~, text~, typewriter~, append~, voice~) =>
      @core.Said(
        speaker~,
        text~,
        typewriter~,
        append~,
        voice=voice.map(raw => self.ui.localize_vocal_url(raw)),
      )
    _ => event
  }
  (self.event_hook)(localized)
}

///|
pub fn[T] GameRunner::set_ui_click_sfx(
  self : GameRunner[T],
  ui_click_sfx_id : String?,
) -> Unit {
  self.ui_click_sfx_id = ui_click_sfx_id
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
    if self.audio.has_active_sfx() {
      return true
    }
    self.blocking_wait_sfx = false
  }
  self.blocking_remaining_ms > 0
}

///|
fn group_step_duration_ms(step : GroupStep) -> Int {
  match step {
    Animate(spec) => spec.duration_ms
    Effect(spec) => spec.duration_ms.unwrap_or(0)
  }
}

///|
fn[T] GameRunner::dispatch_group_step(
  self : GameRunner[T],
  target : String,
  is_pixi : Bool,
  step : GroupStep,
) -> Unit {
  let event = match step {
    Animate(spec) => {
      let spec = { ..spec, blocking: false }
      if is_pixi {
        @core.Animated(target, spec, Pixi)
      } else {
        @core.Animated(target, spec, Dom)
      }
    }
    Effect(spec) => {
      let spec = { ..spec, blocking: false }
      @core.EffectApplied(target, spec)
    }
  }
  self.emit_runtime_event(event)
  self.director.apply_event(event)
  self.apply_event_effects(event, false)
}

///|
fn[T] GameRunner::advance_sequence_jobs(
  self : GameRunner[T],
  elapsed_ms : Int,
) -> Unit {
  if self.sequence_jobs.is_empty() {
    return
  }
  let kept : Array[SequenceJob] = []
  for job in self.sequence_jobs {
    let mut budget = if elapsed_ms < 0 { 0 } else { elapsed_ms }
    for ;; {
      if job.cursor >= job.steps.length() {
        break
      } else {
        if !job.step_started {
          let step = job.steps[job.cursor]
          self.dispatch_group_step(job.target, job.is_pixi, step)
          job.step_started = true
          job.remaining_ms = if group_step_duration_ms(step) < 0 {
            0
          } else {
            group_step_duration_ms(step)
          }
        }
        if job.remaining_ms <= 0 {
          job.cursor = job.cursor + 1
          job.step_started = false
        } else if budget <= 0 {
          break
        } else if budget >= job.remaining_ms {
          budget = budget - job.remaining_ms
          job.remaining_ms = 0
        } else {
          job.remaining_ms = job.remaining_ms - budget
          budget = 0
          break
        }
      }
    }
    if job.cursor < job.steps.length() {
      kept.push(job)
    }
  }
  self.sequence_jobs = kept
}

///|
fn[T] GameRunner::enqueue_animation_group(
  self : GameRunner[T],
  target : String,
  steps : Array[GroupStep],
  is_pixi : Bool,
) -> Unit {
  if steps.is_empty() {
    return
  }
  self.sequence_jobs.push({
    target,
    is_pixi,
    steps,
    cursor: 0,
    step_started: false,
    remaining_ms: 0,
  })
  self.advance_sequence_jobs(0)
}

///|
fn[T] GameRunner::render_ui(self : GameRunner[T]) -> Unit {
  self.ui.render(
    UiViewModel::from_snapshot(self.director.ui_snapshot(), self.ui.as_dom()),
  )
  self.ui_dirty = false
}

///|
fn[T] GameRunner::sync_canvas(self : GameRunner[T]) -> Unit noraise {
  let skip_mode = self.ui.is_skip_active()
  let core_snapshot = self.director.core_render_snapshot()
  (self.render_sync)(core_snapshot, skip_mode)
  match self.render_extension {
    Some(hook) => hook(self.director.render_extension_view(), skip_mode)
    None => ()
  }
  self.render_sync_dirty = false
}

///|
fn[T] GameRunner::maybe_render_ui(self : GameRunner[T]) -> Unit noraise {
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
      self.ui.mark_dirty_text_and_speaker()
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
      self.ui.mark_dirty_text_and_speaker()
      self.ui.mark_dirty_action_buttons()
    }
    AvatarShown(_) | AvatarHidden => {
      if mark_ui_for_text {
        self.ui_dirty = true
      }
      self.ui.mark_dirty_text_and_speaker()
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
    Animated(_, spec, kind) => {
      self.ui_dirty = true
      if kind is Pixi {
        self.render_sync_dirty = true
      }
      self.bump_animation_timer(spec.duration_ms)
      if spec.blocking {
        self.bump_blocking_timer(spec.duration_ms)
      }
    }
    EffectApplied(_, spec) => {
      self.ui_dirty = true
      self.render_sync_dirty = true
      if spec.duration_ms is Some(duration) {
        self.bump_animation_timer(duration)
      }
      if spec.blocking {
        match spec.duration_ms {
          Some(duration) => self.bump_blocking_timer(duration)
          None => self.blocking_until_click = true
        }
      }
    }
    AnimationGroupStarted(target, steps, kind) =>
      self.enqueue_animation_group(target, steps, kind is Pixi)
    Live2dMotionPlayed(_) | Live2dExpressionSet(_) => {
      self.ui_dirty = true
      self.render_sync_dirty = true
    }
    SfxPlayed(_, blocking) if blocking => self.blocking_wait_sfx = true
    _ => ()
  }
}

///|
priv enum RenderMode {
  RenderUi
  MaybeRenderUi
}

///|
fn[T] GameRunner::apply_event_and_render(
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
pub fn[T] GameRunner::sync_ui(self : GameRunner[T]) -> Unit noraise {
  self.ui.mark_all_dirty()
  self.render_ui()
  self.sync_canvas()
}

///|
fn[T] GameRunner::advance_frame_state(
  self : GameRunner[T],
  elapsed_ms : Int,
) -> Unit {
  self.advance_animation_timer(elapsed_ms)
  self.advance_blocking_timer(elapsed_ms)
  self.advance_sequence_jobs(elapsed_ms)
  self.ui.advance_dom_animation_timer(elapsed_ms)
  if self.ui.has_active_dom_animations() {
    self.ui_dirty = true
  }
}

///|
fn[T] GameRunner::step_handle_video_and_wait(
  self : GameRunner[T],
  elapsed_ms : Int,
) -> RuntimeEvent? noraise {
  if self.director.is_waiting_video() {
    match self.ui.take_video_action() {
      Some(action) => {
        let skipped = action == "skip"
        let event = self.director.complete_video_wait(skipped)
        self.emit_runtime_event(event)
        self.apply_event_and_render(event, false, RenderMode::RenderUi)
        return Some(event)
      }
      None => ()
    }
  }
  if self.director.is_waiting() {
    if self.director.can_auto_skip_wait_click() {
      self.ui.advance_auto_mode_timer(elapsed_ms)
      if self.ui.should_auto_skip_wait_click() {
        self.director.skip_wait()
        self.ui.mark_auto_advanced()
      }
    }
    if self.ui.is_skip_active() {
      self.director.skip_wait()
    } else if self.ui.check_typewriter_click() {
      self.emit_ui_click_sfx()
      self.director.skip_wait()
    }
  }
  None
}

///|
fn[T] GameRunner::step_handle_ui_action(self : GameRunner[T]) -> RuntimeEvent? {
  self.ui
  .take_action()
  .bind(action => {
    self.emit_ui_click_sfx()
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
        self.ui.mark_dirty_text_and_speaker()
      }
      "log" => self.pending_action = Some("log")
      "skip_hold_on" => self.ui.set_skip_hold(true)
      "skip_hold_off" => self.ui.set_skip_hold(false)
      "settings" | "qsave" | "save" => self.pending_action = Some(action)
      _ => ()
    }
    self.ui.mark_dirty_action_buttons()
    self.render_ui()
    Some(Noop)
  })
}

///|
fn[T] GameRunner::step_handle_blocking_or_wait(
  self : GameRunner[T],
  elapsed_ms : Int,
) -> RuntimeEvent? raise ScriptRuntimeError {
  if self.is_blocking_active() {
    if self.ui.check_typewriter_click() {
      self..emit_ui_click_sfx().clear_blocking()
    } else {
      self.maybe_render_ui()
      return Some(Noop)
    }
  }
  if self.director.is_waiting() {
    let event = self.director.step(elapsed_ms~)
    self.emit_runtime_event(event)
    self.apply_event_and_render(event, true, RenderMode::MaybeRenderUi)
    return Some(event)
  }
  None
}

///|
fn[T] GameRunner::step_handle_choices_and_input(
  self : GameRunner[T],
) -> RuntimeEvent? raise ScriptRuntimeError {
  if !self.director.choices().is_empty() {
    match self.ui.take_selected_choice() {
      Some(choice_id) => {
        self.emit_ui_click_sfx()
        let event = self.director.choose(choice_id)
        self.emit_runtime_event(event)
        self.ui.mark_all_dirty()
        self.render_ui()
        return Some(event)
      }
      None => {
        if self.ui_dirty {
          self.ui.mark_dirty_choices()
          self.render_ui()
        }
        return Some(ChoicePrompt(self.director.choices()))
      }
    }
  }
  if self.director.text_input() is Some(_) {
    if self.ui_dirty {
      let event : RuntimeEvent = match self.director.text_input() {
        Some((var_name, prompt)) => TextInputPrompt(var_name, prompt)
        None => Noop
      }
      return Some(event)
    }
    match self.ui.take_submitted_text_input() {
      Some(value) => {
        self.emit_ui_click_sfx()
        let event = self.director.submit_text_input(value)
        self.emit_runtime_event(event)
        self.director.clear_text_input()
        self.ui.mark_dirty_text_input()
        self.render_ui()
        return Some(event)
      }
      None => {
        let event : RuntimeEvent = match self.director.text_input() {
          Some((var_name, prompt)) => TextInputPrompt(var_name, prompt)
          None => Noop
        }
        self.emit_runtime_event(event)
        return Some(event)
      }
    }
  }
  None
}

///|
fn[T] GameRunner::step_handle_intro_or_empty_dialog(
  self : GameRunner[T],
  elapsed_ms : Int,
) -> RuntimeEvent? raise ScriptRuntimeError {
  if self.director.intro_text() is Some(text) {
    let mut intro_done = self.ui.check_intro_done()
    if self.ui.check_typewriter_click() && !intro_done {
      self.emit_ui_click_sfx()
      intro_done = self.ui.reveal_intro_line() || intro_done
    }
    if intro_done {
      self.director.clear_intro_text()
      let event = self.director.step(elapsed_ms=0)
      self.emit_runtime_event(event)
      self.apply_event_and_render(event, true, RenderMode::MaybeRenderUi)
      return Some(event)
    }
    self.maybe_render_ui()
    return Some(IntroShown(text))
  }
  if self.director.dialog() is None {
    let event = self.director.step(elapsed_ms~)
    self.emit_runtime_event(event)
    self.apply_event_and_render(event, true, RenderMode::MaybeRenderUi)
    return Some(event)
  }
  None
}

///|
fn[T] GameRunner::step_handle_dialog_flow(
  self : GameRunner[T],
  elapsed_ms : Int,
) -> RuntimeEvent raise ScriptRuntimeError {
  self.ui.advance_skip_mode_timer(elapsed_ms)
  if self.ui.should_skip_advance() {
    self.ui.complete_typewriter()
    self.ui.mark_skip_advanced()
    let event = self.director.step(elapsed_ms=0)
    self.emit_runtime_event(event)
    match event {
      ChoicePrompt(_) | TextInputPrompt(_, _) | ScriptEnded => {
        match event {
          ChoicePrompt(_) => self.ui.mark_dirty_choices()
          TextInputPrompt(_, _) => self.ui.mark_dirty_text_input()
          ScriptEnded => self.ui.mark_all_dirty()
          _ => ()
        }
        self.ui_dirty = true
        self.render_ui()
        return event
      }
      _ => {
        self.apply_event_and_render(event, false, RenderMode::RenderUi)
        return event
      }
    }
  }
  if !self.ui.is_typewriter_done() {
    if self.ui.check_typewriter_click() {
      self.emit_ui_click_sfx()
      self.ui.complete_typewriter()
      self.ui.mark_dirty_text()
      let event = self.current_dialog_event()
      self.render_ui()
      return event
    } else {
      ignore(self.ui.advance_typewriter(elapsed_ms))
      self.ui.mark_dirty_text()
      let event = self.current_dialog_event()
      self.render_ui()
      return event
    }
  }
  match self.director.dialog() {
    Some(line) if line.proceed_on_done => {
      let event = self.director.step(elapsed_ms=0)
      self.emit_runtime_event(event)
      self.apply_event_and_render(event, true, RenderMode::MaybeRenderUi)
      return event
    }
    _ => ()
  }
  let dialog_advance_click = self.ui.check_typewriter_click()
  if !self.director.last_event_needs_click || dialog_advance_click {
    if dialog_advance_click {
      self.emit_ui_click_sfx()
    }
    let event = self.director.step(elapsed_ms=0)
    self.emit_runtime_event(event)
    self.apply_event_and_render(event, true, RenderMode::MaybeRenderUi)
    return event
  }
  self.ui.advance_auto_mode_timer(elapsed_ms)
  if self.ui.should_auto_advance() {
    self.ui.mark_auto_advanced()
    let event = self.director.step(elapsed_ms=0)
    self.emit_runtime_event(event)
    self.apply_event_and_render(event, true, RenderMode::MaybeRenderUi)
    return event
  }
  let event = self.current_dialog_event()
  self.maybe_render_ui()
  event
}

///|
pub fn[T] GameRunner::step(
  self : GameRunner[T],
  elapsed_ms? : Int = 0,
) -> RuntimeEvent raise ScriptRuntimeError {
  self.advance_frame_state(elapsed_ms)
  if self.step_handle_video_and_wait(elapsed_ms) is Some(event) {
    return event
  }
  if self.step_handle_ui_action() is Some(event) {
    return event
  }
  if self.step_handle_blocking_or_wait(elapsed_ms) is Some(event) {
    return event
  }
  if self.step_handle_choices_and_input() is Some(event) {
    return event
  }
  if self.step_handle_intro_or_empty_dialog(elapsed_ms) is Some(event) {
    return event
  }
  self.step_handle_dialog_flow(elapsed_ms)
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
  self.emit_runtime_event(event)
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
  self.emit_runtime_event(event)
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
pub fn[T] GameRunner::tick(
  self : GameRunner[T],
  elapsed_ms? : Int = 0,
) -> Bool noraise {
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
pub fn[T] GameRunner::dialog_history(
  self : GameRunner[T],
) -> Array[DialogLogEntry] {
  self.director.dialog_history()
}

///|
pub fn[T] GameRunner::is_log_visible(self : GameRunner[T]) -> Bool {
  self.ui.is_log_visible()
}

///|
pub fn[T] GameRunner::set_log_visible(
  self : GameRunner[T],
  visible : Bool,
) -> Unit {
  self.ui.set_log_visible(visible)
  self.ui_dirty = true
}

///|
pub fn[T] GameRunner::set_ui_strings(
  self : GameRunner[T],
  ui_strings : UiStrings,
) -> Unit {
  self.ui.set_ui_strings(ui_strings)
  self.ui_dirty = true
}

///|
pub fn[T] GameRunner::set_script_localization(
  self : GameRunner[T],
  script_locale_json : String?,
  script_default_locale_json : String?,
  vocal_locale_dir : String,
  script_locale : String,
  script_default_locale : String,
) -> Unit {
  self.ui.set_script_localization(
    script_locale_json, script_default_locale_json, vocal_locale_dir, script_locale,
    script_default_locale,
  )
  self.ui_dirty = true
}

///|
pub fn[T] GameRunner::toggle_log_visible(self : GameRunner[T]) -> Unit {
  self.ui.toggle_log_visible()
  self.ui_dirty = true
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
pub fn[T] GameRunner::clear_presentation(self : GameRunner[T]) -> Unit noraise {
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
  self.audio.set_bgm_gain(settings.bgm_volume)
  self.audio.set_sfx_gain(settings.sfx_volume)
}
