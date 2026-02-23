///|
/// Fluent builder for authoring `Script[T]` in MoonBit DSL style.
struct Figure {
  id : String
}

///|
struct Background {
  id : String
}

///|
struct Music {
  id : String
}

///|
struct Sfx {
  id : String
}

///|
struct Label {
  name : String
}

///|
struct ScriptBuilder[T] {
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
pub fn option(
  text : String,
  jump : Label,
  id? : String = gensym(prefix="choice"),
) -> ChoiceOption {
  { id, text, jump: jump.name }
}

///|
pub fn label(name? : String = gensym(prefix="label")) -> Label {
  { name, }
}

///|
pub fn place_left(layer? : Int = 0, opacity? : Double = 1.0) -> FigurePlacement {
  { pos: Left, layer, opacity, scale: 1.0 }
}

///|
pub fn place_center(
  layer? : Int = 0,
  opacity? : Double = 1.0,
) -> FigurePlacement {
  { pos: Center, layer, opacity, scale: 1.0 }
}

///|
pub fn place_right(
  layer? : Int = 0,
  opacity? : Double = 1.0,
) -> FigurePlacement {
  { pos: Right, layer, opacity, scale: 1.0 }
}

///|
pub fn place_custom(
  x : Double,
  y : Double,
  layer? : Int = 0,
  opacity? : Double = 1.0,
) -> FigurePlacement {
  { pos: Custom(x, y), layer, opacity, scale: 1.0 }
}

///|
pub fn anim_opacity(
  duration_ms : Int,
  easing? : Easing = Linear,
) -> AnimationSpec {
  { prop: Opacity, duration_ms, easing, from: None, to: None }
}

///|
pub fn anim_position(
  duration_ms : Int,
  easing? : Easing = Linear,
) -> AnimationSpec {
  { prop: Position, duration_ms, easing, from: None, to: None }
}

///|
pub fn anim_scale(
  duration_ms : Int,
  easing? : Easing = Linear,
) -> AnimationSpec {
  { prop: Scale, duration_ms, easing, from: None, to: None }
}

///|
pub fn anim_opacity_range(
  duration_ms : Int,
  from : Double,
  to : Double,
  easing? : Easing = Linear,
) -> AnimationSpec {
  { prop: Opacity, duration_ms, easing, from: Some([from]), to: Some([to]) }
}

///|
pub fn anim_position_range(
  duration_ms : Int,
  from_x : Double,
  from_y : Double,
  to_x : Double,
  to_y : Double,
  easing? : Easing = Linear,
) -> AnimationSpec {
  {
    prop: Position,
    duration_ms,
    easing,
    from: Some([from_x, from_y]),
    to: Some([to_x, to_y]),
  }
}

///|
pub fn anim_scale_range(
  duration_ms : Int,
  from : Double,
  to : Double,
  easing? : Easing = Linear,
) -> AnimationSpec {
  { prop: Scale, duration_ms, easing, from: Some([from]), to: Some([to]) }
}

///|
pub fn[T] ScriptBuilder::new() -> ScriptBuilder[T] {
  { instructions: [] }
}

///|
pub fn[T] ScriptBuilder::label(self : ScriptBuilder[T], label : Label) -> Unit {
  self.instructions.push(Label(label.name))
}

///|
pub fn[T] ScriptBuilder::jump(self : ScriptBuilder[T], label : Label) -> Unit {
  self.instructions.push(Jump(label.name))
}

///|
pub fn[T] ScriptBuilder::jump_if(
  self : ScriptBuilder[T],
  label : Label,
  predicate : ScriptPredicate[T],
) -> Unit {
  self.instructions.push(JumpIf(label.name, predicate))
}

///|
/// Emits a two-way branch:
/// - `JumpIf(then_label, predicate)`
/// - `Jump(else_label)`
pub fn[T] ScriptBuilder::branch(
  self : ScriptBuilder[T],
  then_label : Label,
  else_label : Label,
  predicate : ScriptPredicate[T],
) -> Unit {
  self.instructions.push(JumpIf(then_label.name, predicate))
  self.instructions.push(Jump(else_label.name))
}

///|
pub fn[T] ScriptBuilder::wait(self : ScriptBuilder[T], ms : Int) -> Unit {
  self.instructions.push(Wait(ms))
}

///|
pub fn[T] ScriptBuilder::narrate(
  self : ScriptBuilder[T],
  text : String,
  typewriter? : Bool = true,
) -> Unit {
  self.instructions.push(Say("", text, typewriter))
}

///|
pub fn[T] ScriptBuilder::say(
  self : ScriptBuilder[T],
  speaker : String,
  text : String,
  typewriter? : Bool = true,
) -> Unit {
  self.instructions.push(Say(speaker, text, typewriter))
}

///|
pub fn[T] ScriptBuilder::say_many(
  self : ScriptBuilder[T],
  speaker : String,
  texts : Array[String],
  typewriter? : Bool = true,
) -> Unit {
  for text in texts {
    self.instructions.push(Say(speaker, text, typewriter))
  }
}

///|
pub fn[T] ScriptBuilder::apply(
  self : ScriptBuilder[T],
  f : (ScriptBuilder[T]) -> Unit,
) -> Unit {
  f(self)
}

///|
pub fn[T] ScriptBuilder::menu(
  self : ScriptBuilder[T],
  speaker : String,
  prompt : String,
  options : Array[ChoiceOption],
) -> Unit {
  self.instructions.push(Say(speaker, prompt, true))
  self.instructions.push(Choice(options))
}

///|
pub fn[T] ScriptBuilder::choice(
  self : ScriptBuilder[T],
  options : Array[ChoiceOption],
) -> Unit {
  self.instructions.push(Choice(options))
}

///|
pub fn[T] ScriptBuilder::input_text(
  self : ScriptBuilder[T],
  variable_name : String,
  prompt : String,
) -> Unit {
  self.instructions.push(InputText(variable_name, prompt))
}

///|
pub fn[T] ScriptBuilder::run_code(
  self : ScriptBuilder[T],
  hook : ScriptHook[T],
) -> Unit {
  self.instructions.push(RunCode(hook))
}

///|
pub fn[T] ScriptBuilder::scene(
  self : ScriptBuilder[T],
  bg : Background,
) -> Unit {
  self.instructions.push(ShowBackground(bg.id))
}

///|
pub fn[T] ScriptBuilder::show_figure(
  self : ScriptBuilder[T],
  figure : Figure,
  placement : FigurePlacement,
) -> Unit {
  self.instructions.push(ShowFigure(figure.id, placement))
}

///|
pub fn[T] ScriptBuilder::show_figure_at(
  self : ScriptBuilder[T],
  figure : Figure,
  pos : Position,
  layer? : Int = 0,
  opacity? : Double = 1.0,
) -> Unit {
  self.instructions.push(
    ShowFigure(figure.id, { pos, layer, opacity, scale: 1.0 }),
  )
}

///|
pub fn[T] ScriptBuilder::hide_figure(
  self : ScriptBuilder[T],
  figure : Figure,
) -> Unit {
  self.instructions.push(HideFigure(figure.id))
}

///|
pub fn[T] ScriptBuilder::play_music(
  self : ScriptBuilder[T],
  music : Music,
  should_loop : Bool,
) -> Unit {
  self.instructions.push(PlayMusic(music.id, should_loop))
}

///|
pub fn[T] ScriptBuilder::stop_music(self : ScriptBuilder[T]) -> Unit {
  self.instructions.push(StopMusic)
}

///|
pub fn[T] ScriptBuilder::play_sfx(self : ScriptBuilder[T], sfx : Sfx) -> Unit {
  self.instructions.push(PlaySfx(sfx.id))
}

///|
pub fn[T] ScriptBuilder::animate(
  self : ScriptBuilder[T],
  target : Figure,
  spec : AnimationSpec,
) -> Unit {
  self.instructions.push(Animate(target.id, spec))
}

///|
pub fn[T] ScriptBuilder::animate_opacity(
  self : ScriptBuilder[T],
  target : Figure,
  duration_ms : Int,
  easing? : Easing = Linear,
) -> Unit {
  self.instructions.push(Animate(target.id, anim_opacity(duration_ms, easing~)))
}

///|
pub fn[T] ScriptBuilder::animate_opacity_range(
  self : ScriptBuilder[T],
  target : Figure,
  duration_ms : Int,
  from : Double,
  to : Double,
  easing? : Easing = Linear,
) -> Unit {
  self.instructions.push(
    Animate(target.id, anim_opacity_range(duration_ms, from, to, easing~)),
  )
}

///|
pub fn[T] ScriptBuilder::animate_position(
  self : ScriptBuilder[T],
  target : Figure,
  duration_ms : Int,
  easing? : Easing = Linear,
) -> Unit {
  self.instructions.push(
    Animate(target.id, anim_position(duration_ms, easing~)),
  )
}

///|
pub fn[T] ScriptBuilder::animate_position_range(
  self : ScriptBuilder[T],
  target : Figure,
  duration_ms : Int,
  from_x : Double,
  from_y : Double,
  to_x : Double,
  to_y : Double,
  easing? : Easing = Linear,
) -> Unit {
  self.instructions.push(
    Animate(
      target.id,
      anim_position_range(duration_ms, from_x, from_y, to_x, to_y, easing~),
    ),
  )
}

///|
pub fn[T] ScriptBuilder::animate_scale(
  self : ScriptBuilder[T],
  target : Figure,
  duration_ms : Int,
  easing? : Easing = Linear,
) -> Unit {
  self.instructions.push(Animate(target.id, anim_scale(duration_ms, easing~)))
}

///|
pub fn[T] ScriptBuilder::animate_scale_range(
  self : ScriptBuilder[T],
  target : Figure,
  duration_ms : Int,
  from : Double,
  to : Double,
  easing? : Easing = Linear,
) -> Unit {
  self.instructions.push(
    Animate(target.id, anim_scale_range(duration_ms, from, to, easing~)),
  )
}

///|
pub fn[T] ScriptBuilder::load_text(
  self : ScriptBuilder[T],
  text : String,
) -> Unit {
  reisen_text_script_to_builder(text, self)
}

///|
pub fn[T] ScriptBuilder::build(
  self : ScriptBuilder[T],
) -> Script[T] raise ScriptBuildError {
  script_from_instructions(self.instructions)
}
