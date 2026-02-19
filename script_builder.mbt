///|
/// Fluent builder for authoring `Script[T]` in MoonBit DSL style.

///|
pub struct ScriptBuilder[T] {
  instructions : Array[Instruction[T]]
}

///|
pub fn[T] ScriptBuilder::new() -> ScriptBuilder[T] {
  { instructions: [] }
}

///|
pub fn[T] ScriptBuilder::label(self : ScriptBuilder[T], name : String) -> Unit {
  self.instructions.push(Label(name))
}

///|
pub fn[T] ScriptBuilder::jump(self : ScriptBuilder[T], label : String) -> Unit {
  self.instructions.push(Jump(label))
}

///|
pub fn[T] ScriptBuilder::jump_if(
  self : ScriptBuilder[T],
  label : String,
  predicate : ScriptPredicate[T],
) -> Unit {
  self.instructions.push(JumpIf(label, predicate))
}

///|
pub fn[T] ScriptBuilder::wait(self : ScriptBuilder[T], ms : Int) -> Unit {
  self.instructions.push(Wait(ms))
}

///|
pub fn[T] ScriptBuilder::say(
  self : ScriptBuilder[T],
  speaker : String,
  text : String,
) -> Unit {
  self.instructions.push(Say(speaker, text))
}

///|
pub fn[T] ScriptBuilder::choice(
  self : ScriptBuilder[T],
  options : Array[ChoiceOption],
) -> Unit {
  self.instructions.push(Choice(options))
}

///|
pub fn[T] ScriptBuilder::run_code(
  self : ScriptBuilder[T],
  id : String,
  hook : ScriptHook[T],
) -> Unit {
  self.instructions.push(RunCode(id, hook))
}

///|
pub fn[T] ScriptBuilder::show_background(
  self : ScriptBuilder[T],
  id : String,
) -> Unit {
  self.instructions.push(ShowBackground(id))
}

///|
pub fn[T] ScriptBuilder::show_figure(
  self : ScriptBuilder[T],
  id : String,
  placement : FigurePlacement,
) -> Unit {
  self.instructions.push(ShowFigure(id, placement))
}

///|
pub fn[T] ScriptBuilder::hide_figure(
  self : ScriptBuilder[T],
  id : String,
) -> Unit {
  self.instructions.push(HideFigure(id))
}

///|
pub fn[T] ScriptBuilder::play_music(
  self : ScriptBuilder[T],
  id : String,
  should_loop : Bool,
) -> Unit {
  self.instructions.push(PlayMusic(id, should_loop))
}

///|
pub fn[T] ScriptBuilder::stop_music(self : ScriptBuilder[T]) -> Unit {
  self.instructions.push(StopMusic)
}

///|
pub fn[T] ScriptBuilder::play_sfx(self : ScriptBuilder[T], id : String) -> Unit {
  self.instructions.push(PlaySfx(id))
}

///|
pub fn[T] ScriptBuilder::animate(
  self : ScriptBuilder[T],
  target : String,
  spec : AnimationSpec,
) -> Unit {
  self.instructions.push(Animate(target, spec))
}

///|
pub fn[T] ScriptBuilder::build(self : ScriptBuilder[T]) -> Script[T] raise ScriptBuildError {
  script_from_instructions(self.instructions)
}
