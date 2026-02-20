///|
/// Fluent builder for authoring `Script[T]` in MoonBit DSL style.

///|
pub struct ScriptBuilder[T] {
  instructions : Array[Instruction[T]]
}

///|
/// Convenience entrypoint for the DSL style:
/// `let s = script(builder => { ... })`.
pub fn[T] script(
  f : (ScriptBuilder[T]) -> Unit,
) -> Script[T] raise ScriptBuildError {
  let builder : ScriptBuilder[T] = ScriptBuilder::new()
  f(builder)
  builder.build()
}

///|
pub fn option(id : String, text : String, jump : String) -> ChoiceOption {
  { id, text, jump }
}

///|
pub fn place_left(layer? : Int = 0, opacity? : Double = 1.0) -> FigurePlacement {
  { pos: Left, layer, opacity }
}

///|
pub fn place_center(
  layer? : Int = 0,
  opacity? : Double = 1.0,
) -> FigurePlacement {
  { pos: Center, layer, opacity }
}

///|
pub fn place_right(
  layer? : Int = 0,
  opacity? : Double = 1.0,
) -> FigurePlacement {
  { pos: Right, layer, opacity }
}

///|
pub fn place_custom(
  x : Double,
  y : Double,
  layer? : Int = 0,
  opacity? : Double = 1.0,
) -> FigurePlacement {
  { pos: Custom(x, y), layer, opacity }
}

///|
pub fn anim_opacity(
  duration_ms : Int,
  easing? : Easing = Linear,
) -> AnimationSpec {
  { prop: Opacity, duration_ms, easing }
}

///|
pub fn anim_position(
  duration_ms : Int,
  easing? : Easing = Linear,
) -> AnimationSpec {
  { prop: Position, duration_ms, easing }
}

///|
pub fn anim_scale(
  duration_ms : Int,
  easing? : Easing = Linear,
) -> AnimationSpec {
  { prop: Scale, duration_ms, easing }
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
pub fn[T] ScriptBuilder::build(
  self : ScriptBuilder[T],
) -> Script[T] raise ScriptBuildError {
  script_from_instructions(self.instructions)
}
