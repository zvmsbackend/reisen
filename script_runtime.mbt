///|
/// Script runtime for executing `Script[T]` against `GameState[T]`.
/// Produces runtime events for renderer/audio/UI layers.

///|
pub enum RuntimeEvent {
  Noop
  Said(String, String)
  ChoicePrompt(Array[ChoiceOption])
  BackgroundShown(String)
  FigureShown(String, FigurePlacement)
  FigureHidden(String)
  MusicPlayed(String, Bool)
  MusicStopped
  SfxPlayed(String)
  Animated(String, AnimationSpec)
  WaitStarted(Int)
  ScriptEnded
} derive(Show, Eq)

///|
pub suberror ScriptRuntimeError {
  LabelNotFound(label~ : String)
  ChoiceNotActive
  ChoiceNotFound(id~ : String)
  ChoicePending
  TimerPending(ms~ : Int)
  InvalidInstructionPointer(ip~ : Int)
}

///|
pub struct Runtime[T] {
  script : Script[T]
  state : GameState[T]
  mut ip : Int
  mut pending_choices : Array[ChoiceOption]
  mut wait_ms : Int
  mut ended : Bool
}

///|
priv struct RuntimeSave[T] {
  state : GameState[T]
  ip : Int
  pending_choices : Array[ChoiceOption]
  wait_ms : Int
  ended : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn[T] Runtime::new(script : Script[T], state : GameState[T]) -> Runtime[T] {
  {
    script,
    state,
    ip: 0,
    pending_choices: [],
    wait_ms: 0,
    ended: false,
  }
}

fn[T] Runtime::save(self : Runtime[T]) -> RuntimeSave[T] {
  {
    state: self.state,
    ip: self.ip,
    pending_choices: self.pending_choices,
    wait_ms: self.wait_ms,
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
    wait_ms: if save.wait_ms < 0 { 0 } else { save.wait_ms },
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
fn[T] Runtime::jump_to_label(
  self : Runtime[T],
  label : String,
) -> Unit raise ScriptRuntimeError {
  match self.script.labels.get(label) {
    Some(idx) => self.ip = idx
    None => raise ScriptRuntimeError::LabelNotFound(label=label)
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
    Say(name, text) => {
      self.ip = self.ip + 1
      Said(name, text)
    }
    Choice(options) => {
      self.ip = self.ip + 1
      self.pending_choices = options
      ChoicePrompt(options)
    }
    RunCode(_, hook) => {
      hook(self.state)
      self.ip = self.ip + 1
      Noop
    }
    ShowBackground(id) => {
      self.ip = self.ip + 1
      BackgroundShown(id)
    }
    ShowFigure(id, placement) => {
      self.ip = self.ip + 1
      FigureShown(id, placement)
    }
    HideFigure(id) => {
      self.ip = self.ip + 1
      FigureHidden(id)
    }
    PlayMusic(id, should_loop) => {
      self.ip = self.ip + 1
      MusicPlayed(id, should_loop)
    }
    StopMusic => {
      self.ip = self.ip + 1
      MusicStopped
    }
    PlaySfx(id) => {
      self.ip = self.ip + 1
      SfxPlayed(id)
    }
    Animate(target, spec) => {
      self.ip = self.ip + 1
      Animated(target, spec)
    }
  }
}

///|
pub fn[T] Runtime::step(self : Runtime[T], elapsed_ms? : Int = 0) -> RuntimeEvent raise ScriptRuntimeError {
  if self.ended {
    return ScriptEnded
  }
  if self.pending_choices.length() > 0 {
    return ChoicePrompt(self.pending_choices)
  }
  if self.wait_ms > 0 {
    let dt = if elapsed_ms < 0 { 0 } else { elapsed_ms }
    self.wait_ms = self.wait_ms - dt
    if self.wait_ms > 0 {
      return Noop
    }
    self.wait_ms = 0
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
pub fn[T] Runtime::choose(self : Runtime[T], id : String) -> RuntimeEvent raise ScriptRuntimeError {
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
  raise ScriptRuntimeError::ChoiceNotFound(id=id)
}
