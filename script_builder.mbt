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
struct Effect {
  id : String
}

///|
struct Label {
  name : String
}

///|
trait AnimationTarget {
  id(Self) -> String
}

///|
pub impl AnimationTarget for Figure with id(self) {
  self.id
}

///|
pub impl AnimationTarget for Background with id(self) {
  self.id
}

///|
pub fn effect(id : String) -> Effect {
  { id, }
}

///|
pub fn effect_param(name : String, value : Double) -> EffectParam {
  (name, value)
}

///|
pub fn effect_spec(id : String, params : Array[EffectParam]) -> EffectSpec {
  { id, params, phase: Some(Post), duration_ms: None, easing: Some(Linear) }
}

///|
pub fn effect_spec_with_phase(
  id : String,
  params : Array[EffectParam],
  phase : EffectPhase,
) -> EffectSpec {
  { id, params, phase: Some(phase), duration_ms: None, easing: Some(Linear) }
}

///|
pub fn effect_spec_with_duration(
  id : String,
  params : Array[EffectParam],
  duration_ms : Int,
) -> EffectSpec {
  let duration = if duration_ms < 0 { 0 } else { duration_ms }
  {
    id,
    params,
    phase: Some(Post),
    duration_ms: Some(duration),
    easing: Some(Linear),
  }
}

///|
pub fn effect_spec_with_phase_duration(
  id : String,
  params : Array[EffectParam],
  phase : EffectPhase,
  duration_ms : Int,
) -> EffectSpec {
  let duration = if duration_ms < 0 { 0 } else { duration_ms }
  {
    id,
    params,
    phase: Some(phase),
    duration_ms: Some(duration),
    easing: Some(Linear),
  }
}

///|
pub fn effect_spec_with_timing(
  id : String,
  params : Array[EffectParam],
  phase : EffectPhase,
  duration_ms : Int,
  easing : Easing,
) -> EffectSpec {
  let duration = if duration_ms < 0 { 0 } else { duration_ms }
  {
    id,
    params,
    phase: Some(phase),
    duration_ms: Some(duration),
    easing: Some(easing),
  }
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
  { pos: Left, layer, scalars: { ..ScalarState::default(), opacity, } }
}

///|
pub fn place_center(
  layer? : Int = 0,
  opacity? : Double = 1.0,
) -> FigurePlacement {
  { pos: Center, layer, scalars: { ..ScalarState::default(), opacity, } }
}

///|
pub fn place_right(
  layer? : Int = 0,
  opacity? : Double = 1.0,
) -> FigurePlacement {
  { pos: Right, layer, scalars: { ..ScalarState::default(), opacity, } }
}

///|
pub fn place_custom(
  x : Double,
  y : Double,
  layer? : Int = 0,
  opacity? : Double = 1.0,
) -> FigurePlacement {
  { pos: Custom(x, y), layer, scalars: { ..ScalarState::default(), opacity, } }
}

///|
pub fn anim_opacity(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
) -> AnimationSpec {
  {
    prop: Opacity,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
  }
}

///|
pub fn anim_position(
  duration_ms : Int,
  from : (Double, Double)?,
  to : (Double, Double),
  easing? : Easing = Linear,
) -> AnimationSpec {
  {
    prop: Position,
    duration_ms,
    easing,
    from: from.map(n => [n.0, n.1]),
    to: Some([to.0, to.1]),
    anchor: None,
  }
}

///|
pub fn anim_scale(
  duration_ms : Int,
  from : Double?,
  to : Double,
  anchor? : (Double, Double) = (0.5, 0.5),
  easing? : Easing = Linear,
) -> AnimationSpec {
  {
    prop: Scale,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: Some([anchor.0, anchor.1]),
  }
}

///|
pub fn anim_rotation(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
) -> AnimationSpec {
  {
    prop: Rotation,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
  }
}

///|
pub fn anim_blur(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
) -> AnimationSpec {
  {
    prop: Blur,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
  }
}

///|
pub fn anim_brightness(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
) -> AnimationSpec {
  {
    prop: Brightness,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
  }
}

///|
pub fn anim_contrast(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
) -> AnimationSpec {
  {
    prop: Contrast,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
  }
}

///|
pub fn anim_saturation(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
) -> AnimationSpec {
  {
    prop: Saturation,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
  }
}

///|
pub fn anim_gamma(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
) -> AnimationSpec {
  {
    prop: Gamma,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
  }
}

///|
pub fn anim_color_red(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
) -> AnimationSpec {
  {
    prop: ColorRed,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
  }
}

///|
pub fn anim_color_green(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
) -> AnimationSpec {
  {
    prop: ColorGreen,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
  }
}

///|
pub fn anim_color_blue(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
) -> AnimationSpec {
  {
    prop: ColorBlue,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
  }
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
pub fn[T] ScriptBuilder::intro(self : ScriptBuilder[T], text : String) -> Unit {
  self.instructions.push(Intro(text))
}

///|
pub fn[T] ScriptBuilder::show_text_box(self : ScriptBuilder[T]) -> Unit {
  self.instructions.push(ShowTextBox)
}

///|
pub fn[T] ScriptBuilder::hide_text_box(self : ScriptBuilder[T]) -> Unit {
  self.instructions.push(HideTextBox)
}

///|
pub fn[T] ScriptBuilder::show_avatar(
  self : ScriptBuilder[T],
  url : String,
) -> Unit {
  self.instructions.push(ShowAvatar(url))
}

///|
pub fn[T] ScriptBuilder::hide_avatar(self : ScriptBuilder[T]) -> Unit {
  self.instructions.push(HideAvatar)
}

///|
pub fn[T] ScriptBuilder::narrate(
  self : ScriptBuilder[T],
  text : String,
  typewriter? : Bool = true,
  append? : Bool = false,
  voice? : String = "",
) -> Unit {
  let voice_id = if voice == "" { None } else { Some(voice) }
  self.instructions.push(
    Say(speaker="", text~, typewriter~, append~, voice=voice_id),
  )
}

///|
pub fn[T] ScriptBuilder::say(
  self : ScriptBuilder[T],
  speaker : String,
  text : String,
  typewriter? : Bool = true,
  append? : Bool = false,
  voice? : String = "",
) -> Unit {
  let voice_id = if voice == "" { None } else { Some(voice) }
  self.instructions.push(
    Say(speaker~, text~, typewriter~, append~, voice=voice_id),
  )
}

///|
pub fn[T] ScriptBuilder::say_many(
  self : ScriptBuilder[T],
  speaker : String,
  texts : Array[String],
  typewriter? : Bool = true,
  append? : Bool = false,
  voice? : String = "",
) -> Unit {
  let voice_id = if voice == "" { None } else { Some(voice) }
  for text in texts {
    self.instructions.push(
      Say(speaker~, text~, typewriter~, append~, voice=voice_id),
    )
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
  self.instructions.push(
    Say(speaker~, text=prompt, typewriter=true, append=false, voice=None),
  )
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
pub fn[T] ScriptBuilder::scene_with_scalars(
  self : ScriptBuilder[T],
  id : String,
  scalars : ScalarState,
) -> Unit {
  self.instructions.push(ShowBackgroundState({ id, scalars }))
}

///|
pub fn[T] ScriptBuilder::scene_with_opacity_scale(
  self : ScriptBuilder[T],
  id : String,
  opacity : Double,
  scale : Double,
) -> Unit {
  let scalars = { ..ScalarState::default(), opacity, scale }
  self.instructions.push(ShowBackgroundState({ id, scalars }))
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
    ShowFigure(figure.id, {
      pos,
      layer,
      scalars: { ..ScalarState::default(), opacity, },
    }),
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
pub fn[T, A : AnimationTarget] ScriptBuilder::effect(
  self : ScriptBuilder[T],
  target : A,
  effect : Effect,
  params : Array[EffectParam],
  phase? : EffectPhase,
  duration_ms? : Int,
  easing? : Easing = Linear,
) -> Unit {
  let resolved_phase = phase.unwrap_or(Post)
  self.instructions.push(
    ApplyEffect(target.id(), {
      id: effect.id,
      params,
      phase: Some(resolved_phase),
      duration_ms,
      easing: Some(easing),
    }),
  )
}

///|
pub fn[T, A : AnimationTarget] ScriptBuilder::animate(
  self : ScriptBuilder[T],
  target : A,
  spec : AnimationSpec,
) -> Unit {
  self.instructions.push(Animate(target.id(), spec))
}

///|
pub fn[T, A : AnimationTarget] ScriptBuilder::animate_opacity(
  self : ScriptBuilder[T],
  target : A,
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
) -> Unit {
  self.instructions.push(
    Animate(target.id(), anim_opacity(duration_ms, from, to, easing~)),
  )
}

///|
pub fn[T, A : AnimationTarget] ScriptBuilder::animate_position(
  self : ScriptBuilder[T],
  target : A,
  duration_ms : Int,
  from? : (Double, Double),
  to : (Double, Double),
  easing? : Easing = Linear,
) -> Unit {
  self.instructions.push(
    Animate(target.id(), anim_position(duration_ms, from, to, easing~)),
  )
}

///|
pub fn[T, A : AnimationTarget] ScriptBuilder::animate_scale(
  self : ScriptBuilder[T],
  target : A,
  duration_ms : Int,
  from? : Double,
  to : Double,
  anchor? : (Double, Double) = (0.5, 0.5),
  easing? : Easing = Linear,
) -> Unit {
  self.instructions.push(
    Animate(target.id(), anim_scale(duration_ms, from, to, anchor~, easing~)),
  )
}

///|
pub fn[T, A : AnimationTarget] ScriptBuilder::animate_rotation(
  self : ScriptBuilder[T],
  target : A,
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
) -> Unit {
  self.instructions.push(
    Animate(target.id(), anim_rotation(duration_ms, from, to, easing~)),
  )
}

///|
pub fn[T, A : AnimationTarget] ScriptBuilder::animate_blur(
  self : ScriptBuilder[T],
  target : A,
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
) -> Unit {
  self.instructions.push(
    Animate(target.id(), anim_blur(duration_ms, from, to, easing~)),
  )
}

///|
pub fn[T, A : AnimationTarget] ScriptBuilder::animate_brightness(
  self : ScriptBuilder[T],
  target : A,
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
) -> Unit {
  self.instructions.push(
    Animate(target.id(), anim_brightness(duration_ms, from, to, easing~)),
  )
}

///|
pub fn[T, A : AnimationTarget] ScriptBuilder::animate_contrast(
  self : ScriptBuilder[T],
  target : A,
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
) -> Unit {
  self.instructions.push(
    Animate(target.id(), anim_contrast(duration_ms, from, to, easing~)),
  )
}

///|
pub fn[T, A : AnimationTarget] ScriptBuilder::animate_saturation(
  self : ScriptBuilder[T],
  target : A,
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
) -> Unit {
  self.instructions.push(
    Animate(target.id(), anim_saturation(duration_ms, from, to, easing~)),
  )
}

///|
pub fn[T, A : AnimationTarget] ScriptBuilder::animate_gamma(
  self : ScriptBuilder[T],
  target : A,
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
) -> Unit {
  self.instructions.push(
    Animate(target.id(), anim_gamma(duration_ms, from, to, easing~)),
  )
}

///|
pub fn[T, A : AnimationTarget] ScriptBuilder::animate_color_red(
  self : ScriptBuilder[T],
  target : A,
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
) -> Unit {
  self.instructions.push(
    Animate(target.id(), anim_color_red(duration_ms, from, to, easing~)),
  )
}

///|
pub fn[T, A : AnimationTarget] ScriptBuilder::animate_color_green(
  self : ScriptBuilder[T],
  target : A,
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
) -> Unit {
  self.instructions.push(
    Animate(target.id(), anim_color_green(duration_ms, from, to, easing~)),
  )
}

///|
pub fn[T, A : AnimationTarget] ScriptBuilder::animate_color_blue(
  self : ScriptBuilder[T],
  target : A,
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
) -> Unit {
  self.instructions.push(
    Animate(target.id(), anim_color_blue(duration_ms, from, to, easing~)),
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
