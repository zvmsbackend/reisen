///|
/// Script runtime for executing `Script[T]` against `GameState[T]`.
/// Produces runtime events for renderer/audio/UI layers.

///|
pub enum RuntimeEvent {
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
  ChoicePrompt(Array[ChoiceOption])
  TextInputPrompt(String, String)
  BackgroundShown(String)
  BackgroundShownState(BackgroundState)
  FigureShown(String, FigurePlacement)
  FigureHidden(String)
  DomFigureShown(String, FigurePlacement)
  DomFigureHidden(String)
  MusicPlayed(String, Bool)
  MusicStopped
  SfxPlayed(String, Bool)
  SfxStopped
  CgUnlocked(String)
  Animated(String, AnimationSpec)
  EffectApplied(String, EffectSpec)
  WaitStarted(Int)
  WaitForClickStarted
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
pub struct Runtime[T] {
  script : Script[T]
  state : GameState[T]
  mut ip : Int
  mut pending_choices : Array[ChoiceOption]
  mut pending_text_input : (String, String)?
  mut wait_ms : Int
  mut wait_for_click : Bool
  mut ended : Bool
}

///|
pub struct RuntimeSave[T] {
  state : GameState[T]
  ip : Int
  pending_choices : Array[ChoiceOption]
  pending_text_input : (String, String)?
  wait_ms : Int
  wait_for_click : Bool
  ended : Bool
} derive(ToJson, FromJson)

///|
pub fn[T] Runtime::new(script : Script[T], state : GameState[T]) -> Runtime[T] {
  {
    script,
    state,
    ip: 0,
    pending_choices: [],
    pending_text_input: None,
    wait_ms: 0,
    wait_for_click: false,
    ended: false,
  }
}

///|

///|
pub fn[T] Runtime::save(self : Runtime[T]) -> RuntimeSave[T] {
  {
    state: self.state,
    ip: self.ip,
    pending_choices: self.pending_choices,
    pending_text_input: self.pending_text_input,
    wait_ms: self.wait_ms,
    wait_for_click: self.wait_for_click,
    ended: self.ended,
  }
}

///|
fn[T] Runtime::from_save(
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
    pending_text_input: None,
    wait_ms: if save.wait_ms < 0 {
      0
    } else {
      save.wait_ms
    },
    wait_for_click: save.wait_for_click,
    ended: save.ended,
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
  let save : RuntimeSave[T] = @json.from_json(@json.parse(s))
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
      if predicate(self.state) {
        self.jump_to_label(label)
      } else {
        self.ip = self.ip + 1
      }
      Noop
    }
    Wait(ms) => {
      self.ip = self.ip + 1
      self.wait_ms = if ms < 0 { 0 } else { ms }
      WaitStarted(self.wait_ms)
    }
    WaitForClick => {
      self.ip = self.ip + 1
      self.wait_for_click = true
      WaitForClickStarted
    }
    Say(speaker~, text~, typewriter~, append~, voice~) => {
      self.ip = self.ip + 1
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
    Choice(options) => {
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
    ShowDomFigure(id, placement) => {
      self.ip = self.ip + 1
      DomFigureShown(id, placement)
    }
    HideDomFigure(id) => {
      self.ip = self.ip + 1
      DomFigureHidden(id)
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
      gallery_unlock_image_by_id(id)
      CgUnlocked(id)
    }
    Animate(target, spec) => {
      self.ip = self.ip + 1
      Animated(target, spec)
    }
    ApplyEffect(target, spec) => {
      self.ip = self.ip + 1
      EffectApplied(target, spec)
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
  self.wait_ms > 0 || self.wait_for_click
}

///|
pub fn[T] Runtime::skip_wait(self : Runtime[T]) -> Unit {
  self.wait_ms = 0
  self.wait_for_click = false
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
      self.pending_choices = []
      self.jump_to_label(opt.jump)
      return self.step()
    }
  }
  raise ScriptRuntimeError::ChoiceNotFound(id~)
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
