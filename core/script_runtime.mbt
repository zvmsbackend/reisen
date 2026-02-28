///|
/// Script runtime for executing `Script[T]` against `GameState[T]`.
/// Produces runtime events for renderer/audio/UI layers.

///|
pub(all) enum RuntimeEvent {
  Noop
  Said(
    speaker~ : String,
    text~ : String,
    typewriter~ : Bool,
    append~ : Bool,
    voice~ : String?
  )
  IntroShown(String)
  TextBoxShown
  TextBoxHidden
  AvatarShown(String)
  AvatarHidden
  VideoStarted(String, Bool)
  VideoEnded(Bool)
  ChoicePrompt(Array[ChoiceOption])
  TextInputPrompt(String, String)
  BackgroundShown(String)
  BackgroundShownState(BackgroundState)
  FigureShown(String, FigurePlacement)
  FigureHidden(String)
  DomFigureShown(String, FigurePlacement, Bool)
  DomFigureHidden(String)
  DomFigureInteractiveSet(String, Bool)
  MusicPlayed(String, Bool)
  MusicStopped
  SfxPlayed(String, Bool)
  SfxStopped
  CgUnlocked(String)
  AnimatedPixi(String, AnimationSpec)
  AnimatedDom(String, AnimationSpec)
  EffectApplied(String, EffectSpec)
  Live2dMotionPlayed(String, String, Int?)
  Live2dExpressionSet(String, String?)
  WaitStarted(Int)
  WaitForClickStarted
  WaitCustomEventStarted(String)
  Custom(String, String)
  ScriptEnded
} derive(Show, Eq)

///|
pub suberror ScriptRuntimeError {
  LabelNotFound(label~ : String)
  ChoiceNotActive
  ChoiceNotFound(id~ : String)
  InvalidInstructionPointer(ip~ : Int)
}

///|
pub enum ScriptFlowTrace {
  ChoiceResolved(ip~ : Int, choice_id~ : String)
  JumpIfResolved(ip~ : Int, target~ : String, taken~ : Bool)
  CustomJumpResolved(ip~ : Int, name~ : String, target~ : String)
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct Runtime[T] {
  script : Script[T]
  state : GameState[T]
  mut ip : Int
  mut pending_choices : Array[ChoiceOption]
  mut pending_choice_ip : Int?
  mut pending_text_input : (String, String)?
  mut wait_ms : Int
  mut wait_for_click : Bool
  mut wait_for_click_can_skip : Bool
  mut wait_custom_name : String?
  mut wait_video : Bool
  mut last_say_proceed_on_done : Bool
  mut ended : Bool
  flow_trace : Array[ScriptFlowTrace]
}

///|
pub struct RuntimeSave[T] {
  state : GameState[T]
  ip : Int
  pending_choices : Array[ChoiceOption]
  pending_choice_ip : Int?
  pending_text_input : (String, String)?
  wait_ms : Int
  wait_for_click : Bool
  wait_for_click_can_skip : Bool
  wait_custom_name : String?
  wait_video : Bool
  last_say_proceed_on_done : Bool
  ended : Bool
  flow_trace : Array[ScriptFlowTrace]
} derive(ToJson, FromJson)

///|
priv struct RuntimeSaveLegacy[T] {
  state : GameState[T]
  ip : Int
  pending_choices : Array[ChoiceOption]
  pending_text_input : (String, String)?
  wait_ms : Int
  wait_for_click : Bool
  wait_custom_name : String?
  wait_video : Bool
  last_say_proceed_on_done : Bool
  ended : Bool
} derive(FromJson)

///|
pub fn[T] Runtime::new(script : Script[T], state : GameState[T]) -> Runtime[T] {
  {
    script,
    state,
    ip: 0,
    pending_choices: [],
    pending_choice_ip: None,
    pending_text_input: None,
    wait_ms: 0,
    wait_for_click: false,
    wait_for_click_can_skip: true,
    wait_custom_name: None,
    wait_video: false,
    last_say_proceed_on_done: false,
    ended: false,
    flow_trace: [],
  }
}

///|

///|
pub fn[T] Runtime::save(self : Runtime[T]) -> RuntimeSave[T] {
  {
    state: self.state,
    ip: self.ip,
    pending_choices: self.pending_choices,
    pending_choice_ip: self.pending_choice_ip,
    pending_text_input: self.pending_text_input,
    wait_ms: self.wait_ms,
    wait_for_click: self.wait_for_click,
    wait_for_click_can_skip: self.wait_for_click_can_skip,
    wait_custom_name: self.wait_custom_name,
    wait_video: self.wait_video,
    last_say_proceed_on_done: self.last_say_proceed_on_done,
    ended: self.ended,
    flow_trace: self.flow_trace,
  }
}

///|
pub fn[T] Runtime::from_save(
  script : Script[T],
  save : RuntimeSave[T],
) -> Runtime[T] raise ScriptRuntimeError {
  if save.ip < 0 || save.ip > script.instructions.length() {
    raise ScriptRuntimeError::InvalidInstructionPointer(ip=save.ip)
  }
  {
    script,
    state: save.state,
    ip: save.ip,
    pending_choices: save.pending_choices,
    pending_choice_ip: save.pending_choice_ip,
    pending_text_input: None,
    wait_ms: if save.wait_ms < 0 {
      0
    } else {
      save.wait_ms
    },
    wait_for_click: save.wait_for_click,
    wait_for_click_can_skip: save.wait_for_click_can_skip,
    wait_custom_name: save.wait_custom_name,
    wait_video: save.wait_video,
    last_say_proceed_on_done: save.last_say_proceed_on_done,
    ended: save.ended,
    flow_trace: save.flow_trace,
  }
}

///|
pub fn[T : ToJson] Runtime::save_json(self : Runtime[T]) -> String {
  self.save().to_json().stringify()
}

///|
pub fn[T : FromJson] Runtime::from_json_string(
  script : Script[T],
  s : String,
) -> Runtime[T] raise {
  let json = @json.parse(s)
  let save : RuntimeSave[T] = @json.from_json(json) catch {
    _ => {
      let legacy : RuntimeSaveLegacy[T] = @json.from_json(json)
      {
        state: legacy.state,
        ip: legacy.ip,
        pending_choices: legacy.pending_choices,
        pending_choice_ip: None,
        pending_text_input: legacy.pending_text_input,
        wait_ms: legacy.wait_ms,
        wait_for_click: legacy.wait_for_click,
        wait_for_click_can_skip: true,
        wait_custom_name: legacy.wait_custom_name,
        wait_video: legacy.wait_video,
        last_say_proceed_on_done: legacy.last_say_proceed_on_done,
        ended: legacy.ended,
        flow_trace: [],
      }
    }
  }
  Runtime::from_save(script, save)
}

///|
pub fn[T] Runtime::jump_to_label(
  self : Runtime[T],
  label : String,
) -> Unit raise ScriptRuntimeError {
  match self.script.labels.get(label) {
    Some(idx) => self.ip = idx
    None => raise ScriptRuntimeError::LabelNotFound(label~)
  }
}

///|
fn[T] Runtime::run_inst(
  self : Runtime[T],
  inst : Instruction[T],
) -> RuntimeEvent raise ScriptRuntimeError {
  match inst {
    Label(_) => {
      self.ip = self.ip + 1
      Noop
    }
    Jump(label) => {
      self.jump_to_label(label)
      Noop
    }
    JumpIf(label, predicate) => {
      let current_ip = self.ip
      if predicate(self.state) {
        self.flow_trace.push(
          ScriptFlowTrace::JumpIfResolved(
            ip=current_ip,
            target=label,
            taken=true,
          ),
        )
        self.jump_to_label(label)
      } else {
        self.flow_trace.push(
          ScriptFlowTrace::JumpIfResolved(
            ip=current_ip,
            target=label,
            taken=false,
          ),
        )
        self.ip = self.ip + 1
      }
      Noop
    }
    Wait(ms) => {
      self.ip = self.ip + 1
      self.wait_ms = if ms < 0 { 0 } else { ms }
      WaitStarted(self.wait_ms)
    }
    WaitForClick(can_skip) => {
      self.ip = self.ip + 1
      self.wait_for_click = true
      self.wait_for_click_can_skip = can_skip
      WaitForClickStarted
    }
    WaitCustomEvent(name, _) => {
      self.wait_custom_name = Some(name)
      WaitCustomEventStarted(name)
    }
    WaitCustomEventJump(name, _) => {
      self.wait_custom_name = Some(name)
      WaitCustomEventStarted(name)
    }
    Say(speaker~, text~, typewriter~, append~, voice~, proceed_on_done~) => {
      self.ip = self.ip + 1
      self.last_say_proceed_on_done = proceed_on_done
      let interpolated = self.state.interpolate(text)
      let name_interpolated = self.state.interpolate(speaker)
      let voice_interpolated = match voice {
        Some(v) => Some(self.state.interpolate(v))
        None => None
      }
      Said(
        speaker=name_interpolated,
        text=interpolated,
        typewriter~,
        append~,
        voice=voice_interpolated,
      )
    }
    Intro(text) => {
      self.ip = self.ip + 1
      let interpolated = self.state.interpolate(text)
      IntroShown(interpolated)
    }
    ShowTextBox => {
      self.ip = self.ip + 1
      TextBoxShown
    }
    HideTextBox => {
      self.ip = self.ip + 1
      TextBoxHidden
    }
    ShowAvatar(id) => {
      self.ip = self.ip + 1
      AvatarShown(id)
    }
    HideAvatar => {
      self.ip = self.ip + 1
      AvatarHidden
    }
    PlayVideo(url, can_skip) => {
      self.ip = self.ip + 1
      self.wait_video = true
      VideoStarted(url, can_skip)
    }
    Choice(options) => {
      self.pending_choice_ip = Some(self.ip)
      self.ip = self.ip + 1
      self.pending_choices = options
      ChoicePrompt(options)
    }
    InputText(var_name, prompt) => {
      self.ip = self.ip + 1
      let prompt_interpolated = self.state.interpolate(prompt)
      self.pending_text_input = Some((var_name, prompt_interpolated))
      TextInputPrompt(var_name, prompt_interpolated)
    }
    RunCode(hook) => {
      hook(self.state)
      self.ip = self.ip + 1
      Noop
    }
    ShowBackground(id) => {
      self.ip = self.ip + 1
      BackgroundShown(id)
    }
    ShowBackgroundState(state) => {
      self.ip = self.ip + 1
      BackgroundShownState(state)
    }
    ShowFigure(id, placement) => {
      self.ip = self.ip + 1
      FigureShown(id, placement)
    }
    HideFigure(id) => {
      self.ip = self.ip + 1
      FigureHidden(id)
    }
    ShowDomFigure(id, placement, interactive) => {
      self.ip = self.ip + 1
      DomFigureShown(id, placement, interactive)
    }
    HideDomFigure(id) => {
      self.ip = self.ip + 1
      DomFigureHidden(id)
    }
    SetDomFigureInteractive(id, interactive) => {
      self.ip = self.ip + 1
      DomFigureInteractiveSet(id, interactive)
    }
    PlayMusic(id, should_loop) => {
      self.ip = self.ip + 1
      MusicPlayed(id, should_loop)
    }
    StopMusic => {
      self.ip = self.ip + 1
      MusicStopped
    }
    PlaySfx(id, blocking) => {
      self.ip = self.ip + 1
      SfxPlayed(id, blocking)
    }
    UnlockCg(id) => {
      self.ip = self.ip + 1
      @storage.persistent_set_flag("gallery.image." + id, true)
      CgUnlocked(id)
    }
    AnimatePixi(target, spec) => {
      self.ip = self.ip + 1
      AnimatedPixi(target, spec)
    }
    AnimateDom(target, spec) => {
      self.ip = self.ip + 1
      AnimatedDom(target, spec)
    }
    ApplyEffect(target, spec) => {
      self.ip = self.ip + 1
      EffectApplied(target, spec)
    }
    PlayLive2dMotion(target, group, index) => {
      self.ip = self.ip + 1
      Live2dMotionPlayed(target, group, index)
    }
    SetLive2dExpression(target, id) => {
      self.ip = self.ip + 1
      Live2dExpressionSet(target, id)
    }
  }
}

///|
pub fn[T] Runtime::step(
  self : Runtime[T],
  elapsed_ms? : Int = 0,
) -> RuntimeEvent raise ScriptRuntimeError {
  if self.ended {
    return ScriptEnded
  }
  if self.pending_choices.length() > 0 {
    return ChoicePrompt(self.pending_choices)
  }
  if self.pending_text_input is Some(_) {
    match self.pending_text_input {
      Some((var_name, prompt)) => return TextInputPrompt(var_name, prompt)
      None => ()
    }
  }
  if self.wait_ms > 0 {
    let dt = if elapsed_ms < 0 { 0 } else { elapsed_ms }
    self.wait_ms = self.wait_ms - dt
    if self.wait_ms > 0 {
      return Noop
    }
    self.wait_ms = 0
  }
  if self.wait_for_click {
    return Noop
  }
  if self.wait_custom_name is Some(_) {
    return Noop
  }
  if self.wait_video {
    return Noop
  }
  for {
    if self.ip >= self.script.instructions.length() {
      self.ended = true
      return ScriptEnded
    }
    let inst = self.script.instructions[self.ip]
    let evt = self.run_inst(inst)
    if evt is Noop {
      continue
    }
    return evt
  }
}

///|
pub fn[T] Runtime::is_waiting(self : Runtime[T]) -> Bool {
  self.wait_ms > 0 ||
  self.wait_for_click ||
  self.wait_custom_name is Some(_) ||
  self.wait_video
}

///|
pub fn[T] Runtime::skip_wait(self : Runtime[T]) -> Unit {
  self.wait_ms = 0
  self.wait_for_click = false
  self.wait_for_click_can_skip = true
  self.wait_custom_name = None
  self.wait_video = false
}

///|
pub fn[T] Runtime::can_skip_wait(self : Runtime[T]) -> Bool {
  if self.wait_for_click {
    self.wait_for_click_can_skip
  } else {
    true
  }
}

///|
pub fn[T] Runtime::can_auto_skip_wait_click(self : Runtime[T]) -> Bool {
  self.wait_for_click && self.wait_for_click_can_skip
}

///|
pub fn[T] Runtime::is_waiting_video(self : Runtime[T]) -> Bool {
  self.wait_video
}

///|
pub fn[T] Runtime::complete_video_wait(
  self : Runtime[T],
  skipped : Bool,
) -> RuntimeEvent {
  self.wait_video = false
  VideoEnded(skipped)
}

///|
pub fn[T] Runtime::last_say_proceed_on_done(self : Runtime[T]) -> Bool {
  self.last_say_proceed_on_done
}

///|
pub fn[T] Runtime::submit_custom_event(
  self : Runtime[T],
  name : String,
  payload : String,
) -> RuntimeEvent {
  match self.wait_custom_name {
    Some(waiting_name) if waiting_name == name =>
      if self.ip < self.script.instructions.length() {
        match self.script.instructions[self.ip] {
          WaitCustomEvent(expected, predicate) if expected == name =>
            if predicate(self.state, payload) {
              self.wait_custom_name = None
              self.ip = self.ip + 1
            }
          WaitCustomEventJump(expected, selector) if expected == name => {
            let selected = selector(self.state, payload)
            match self.script.labels.get(selected.0) {
              Some(idx) => {
                self.flow_trace.push(
                  ScriptFlowTrace::CustomJumpResolved(
                    ip=self.ip,
                    name~,
                    target=selected.0,
                  ),
                )
                self.wait_custom_name = None
                self.ip = idx
              }
              None => ()
            }
          }
          _ => ()
        }
      }
    _ => ()
  }
  Custom(name, payload)
}

///|
pub fn[T] Runtime::choose(
  self : Runtime[T],
  id : String,
) -> RuntimeEvent raise ScriptRuntimeError {
  if self.pending_choices.length() == 0 {
    raise ScriptRuntimeError::ChoiceNotActive
  }
  for opt in self.pending_choices {
    if opt.id == id {
      match self.pending_choice_ip {
        Some(choice_ip) =>
          self.flow_trace.push(
            ScriptFlowTrace::ChoiceResolved(ip=choice_ip, choice_id=id),
          )
        None => ()
      }
      self.pending_choices = []
      self.pending_choice_ip = None
      self.jump_to_label(opt.jump)
      return self.step()
    }
  }
  raise ScriptRuntimeError::ChoiceNotFound(id~)
}

///|
pub fn[T] Runtime::flow_trace(self : Runtime[T]) -> Array[ScriptFlowTrace] {
  self.flow_trace
}

///|
pub fn[T] Runtime::ip(self : Runtime[T]) -> Int {
  self.ip
}

///|
pub fn[T] Runtime::force_custom_jump(
  self : Runtime[T],
  name : String,
  target : String,
) -> Unit raise ScriptRuntimeError {
  match self.wait_custom_name {
    Some(waiting) if waiting == name => {
      self.wait_custom_name = None
      self.jump_to_label(target)
    }
    _ => ()
  }
}

///|
pub fn[T] Runtime::submit_text_input(
  self : Runtime[T],
  value : String,
) -> RuntimeEvent raise ScriptRuntimeError {
  match self.pending_text_input {
    Some((var_name, _)) => {
      self.state.set_text_var(var_name, value)
      self.pending_text_input = None
      self.step()
    }
    None => raise ScriptRuntimeError::ChoiceNotActive
  }
}
