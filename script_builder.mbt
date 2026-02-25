///|
/// Fluent builder for authoring `Script[T]` in MoonBit DSL style.
enum Figure {
  WebglFigure(String)
  DomFigure(String)
}

///|
struct Background {
  id : String
  url : String
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
priv enum RenderableKind {
  Webgl
  Dom
}

///|
trait AnimationTarget {
  id(Self) -> String
  kind(Self) -> RenderableKind
}

///|
pub impl AnimationTarget for Figure with id(self) {
  match self {
    WebglFigure(id) => id
    DomFigure(id) => id
  }
}

///|
pub impl AnimationTarget for Figure with kind(self) {
  match self {
    WebglFigure(_) => Webgl
    DomFigure(_) => Dom
  }
}

///|
fn normalize_dom_id(id : String) -> String {
  id.trim_start(chars="#").to_string()
}

///|
pub fn dom_figure(id : String) -> Figure {
  DomFigure(normalize_dom_id(id))
}

///|
pub impl AnimationTarget for Background with id(self) {
  self.id
}

///|
pub impl AnimationTarget for Background with kind(_) {
  Webgl
}

///|
struct ScriptBuilder[T] {
  instructions : Array[Instruction[T]]
  mut pending_error : ScriptBuildError?
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
pub fn place_left(
  layer? : Int = 0,
  scalars? : ScalarState = ScalarState::default(),
) -> FigurePlacement {
  { pos: Left, layer, scalars }
}

///|
pub fn place_center(
  layer? : Int = 0,
  scalars? : ScalarState = ScalarState::default(),
) -> FigurePlacement {
  { pos: Center, layer, scalars }
}

///|
pub fn place_right(
  layer? : Int = 0,
  scalars? : ScalarState = ScalarState::default(),
) -> FigurePlacement {
  { pos: Right, layer, scalars }
}

///|
pub fn place_custom(
  x : Double,
  y : Double,
  layer? : Int = 0,
  scalars? : ScalarState = ScalarState::default(),
) -> FigurePlacement {
  { pos: Custom(x, y), layer, scalars }
}

///|
fn position_to_anim_coords(pos : Position) -> (Double, Double) {
  match pos {
    Left => (0.05, 0.0)
    Center => (0.30, 0.0)
    Right => (0.55, 0.0)
    Custom(x, y) => (x, y)
  }
}

///|
fn position_to_dom_anim_coords(pos : Position) -> (Double, Double) {
  match pos {
    Left => (0.18, 0.5)
    Center => (0.5, 0.5)
    Right => (0.82, 0.5)
    Custom(x, y) => (x, y)
  }
}

///|
pub fn anim_opacity(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: Opacity,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_position(
  duration_ms : Int,
  from : Position?,
  to : Position,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  let to_coords = position_to_anim_coords(to)
  {
    prop: Position,
    duration_ms,
    easing,
    from: from.map(pos => {
      let (x, y) = position_to_anim_coords(pos)
      [x, y]
    }),
    to: Some([to_coords.0, to_coords.1]),
    anchor: None,
    blocking,
  }
}

///|
fn anim_position_dom(
  duration_ms : Int,
  from : Position?,
  to : Position,
  easing : Easing,
  blocking : Bool,
) -> AnimationSpec {
  let to_coords = position_to_dom_anim_coords(to)
  {
    prop: Position,
    duration_ms,
    easing,
    from: from.map(pos => {
      let (x, y) = position_to_dom_anim_coords(pos)
      [x, y]
    }),
    to: Some([to_coords.0, to_coords.1]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_scale(
  duration_ms : Int,
  from : Double?,
  to : Double,
  anchor? : (Double, Double) = (0.5, 0.5),
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: Scale,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: Some([anchor.0, anchor.1]),
    blocking,
  }
}

///|
pub fn anim_rotation(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: Rotation,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_blur(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: Blur,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_brightness(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: Brightness,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_contrast(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: Contrast,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_saturation(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: Saturation,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_gamma(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: Gamma,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_color_red(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: ColorRed,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_color_green(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: ColorGreen,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_color_blue(
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: ColorBlue,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn[T] ScriptBuilder::new() -> ScriptBuilder[T] {
  { instructions: [], pending_error: None }
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
pub fn[T] ScriptBuilder::wait_click(self : ScriptBuilder[T]) -> Unit {
  self.instructions.push(WaitForClick)
}

///|
pub fn[T] ScriptBuilder::wait_custom_event(
  self : ScriptBuilder[T],
  name : String,
  predicate : PayloadPredicate[T],
) -> Unit {
  self.instructions.push(WaitCustomEvent(name, predicate))
}

///|
pub fn[T] ScriptBuilder::unlock_cg(
  self : ScriptBuilder[T],
  image : GalleryImage,
) -> Unit {
  self.instructions.push(UnlockCg(image.id))
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
  scalars? : ScalarState,
) -> Unit {
  match scalars {
    Some(s) =>
      self.instructions.push(ShowBackgroundState({ id: bg.id, scalars: s }))
    None => self.instructions.push(ShowBackground(bg.id))
  }
}

///|
fn[T] ScriptBuilder::emit_show_figure(
  self : ScriptBuilder[T],
  figure : Figure,
  placement : FigurePlacement,
  interactive : Bool,
) -> Unit {
  match figure {
    WebglFigure(id) => self.instructions.push(ShowFigure(id, placement))
    DomFigure(id) =>
      self.instructions.push(ShowDomFigure(id, placement, interactive))
  }
}

///|
pub fn[T] ScriptBuilder::show_figure(
  self : ScriptBuilder[T],
  figure : Figure,
  placement : FigurePlacement,
  interactive? : Bool = false,
) -> Unit {
  self.emit_show_figure(figure, placement, interactive)
}

///|
pub fn[T] ScriptBuilder::show_figure_at(
  self : ScriptBuilder[T],
  figure : Figure,
  pos : Position,
  layer? : Int = 0,
  scalars? : ScalarState = ScalarState::default(),
  interactive? : Bool = false,
) -> Unit {
  self.emit_show_figure(figure, { pos, layer, scalars }, interactive)
}

///|
pub fn[T] ScriptBuilder::hide_figure(
  self : ScriptBuilder[T],
  figure : Figure,
) -> Unit {
  match figure {
    WebglFigure(id) => self.instructions.push(HideFigure(id))
    DomFigure(id) => self.instructions.push(HideDomFigure(id))
  }
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
pub fn[T] ScriptBuilder::play_sfx(
  self : ScriptBuilder[T],
  sfx : Sfx,
  blocking? : Bool = false,
) -> Unit {
  self.instructions.push(PlaySfx(sfx.id, blocking))
}

///|
pub fn effect_spec(
  id : String,
  params : Array[EffectParam],
  phase? : EffectPhase = Post,
  duration_ms? : Int,
  blocking? : Bool = false,
  easing? : Easing = Linear,
) -> EffectSpec {
  { id, params, phase, duration_ms, easing, blocking }
}

///|
fn[T, A : AnimationTarget] ScriptBuilder::check_effect_support(
  self : ScriptBuilder[T],
  target : A,
) -> Bool {
  if target.kind() is Dom {
    if self.pending_error is None {
      self.pending_error = Some(
        ScriptBuildError::EffectUnsupportedOnDomTarget(target=target.id()),
      )
    }
    false
  } else {
    true
  }
}

///|
pub fn[T, A : AnimationTarget] ScriptBuilder::effect(
  self : ScriptBuilder[T],
  target : A,
  effect_spec : EffectSpec,
) -> Unit {
  if self.check_effect_support(target) {
    self.instructions.push(ApplyEffect(target.id(), effect_spec))
  }
}

///|
pub fn[T, A : AnimationTarget] ScriptBuilder::effect_with(
  self : ScriptBuilder[T],
  target : A,
  effect : Effect,
  params : Array[EffectParam],
  phase? : EffectPhase = Post,
  duration_ms? : Int,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> Unit {
  if self.check_effect_support(target) {
    self.instructions.push(
      ApplyEffect(target.id(), {
        id: effect.id,
        params,
        phase,
        duration_ms,
        easing,
        blocking,
      }),
    )
  }
}

///|
fn[T, A : AnimationTarget] ScriptBuilder::emit_animation(
  self : ScriptBuilder[T],
  target : A,
  spec : AnimationSpec,
) -> Unit {
  match target.kind() {
    RenderableKind::Webgl =>
      self.instructions.push(AnimateWebgl(target.id(), spec))
    RenderableKind::Dom => self.instructions.push(AnimateDom(target.id(), spec))
  }
}

///|
pub fn[T, A : AnimationTarget] ScriptBuilder::animate(
  self : ScriptBuilder[T],
  target : A,
  spec : AnimationSpec,
) -> Unit {
  self.emit_animation(target, spec)
}

///|
pub fn[T, A : AnimationTarget] ScriptBuilder::animate_opacity(
  self : ScriptBuilder[T],
  target : A,
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> Unit {
  self.emit_animation(
    target,
    anim_opacity(duration_ms, from, to, easing~, blocking~),
  )
}

///|
pub fn[T, A : AnimationTarget] ScriptBuilder::animate_position(
  self : ScriptBuilder[T],
  target : A,
  duration_ms : Int,
  from? : Position,
  to : Position,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> Unit {
  match target.kind() {
    RenderableKind::Webgl =>
      self.emit_animation(
        target,
        anim_position(duration_ms, from, to, easing~, blocking~),
      )
    RenderableKind::Dom =>
      self.emit_animation(
        target,
        anim_position_dom(duration_ms, from, to, easing, blocking),
      )
  }
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
  blocking? : Bool = false,
) -> Unit {
  self.emit_animation(
    target,
    anim_scale(duration_ms, from, to, anchor~, easing~, blocking~),
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
  blocking? : Bool = false,
) -> Unit {
  self.emit_animation(
    target,
    anim_rotation(duration_ms, from, to, easing~, blocking~),
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
  blocking? : Bool = false,
) -> Unit {
  self.emit_animation(
    target,
    anim_blur(duration_ms, from, to, easing~, blocking~),
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
  blocking? : Bool = false,
) -> Unit {
  self.emit_animation(
    target,
    anim_brightness(duration_ms, from, to, easing~, blocking~),
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
  blocking? : Bool = false,
) -> Unit {
  self.emit_animation(
    target,
    anim_contrast(duration_ms, from, to, easing~, blocking~),
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
  blocking? : Bool = false,
) -> Unit {
  self.emit_animation(
    target,
    anim_saturation(duration_ms, from, to, easing~, blocking~),
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
  blocking? : Bool = false,
) -> Unit {
  self.emit_animation(
    target,
    anim_gamma(duration_ms, from, to, easing~, blocking~),
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
  blocking? : Bool = false,
) -> Unit {
  self.emit_animation(
    target,
    anim_color_red(duration_ms, from, to, easing~, blocking~),
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
  blocking? : Bool = false,
) -> Unit {
  self.emit_animation(
    target,
    anim_color_green(duration_ms, from, to, easing~, blocking~),
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
  blocking? : Bool = false,
) -> Unit {
  self.emit_animation(
    target,
    anim_color_blue(duration_ms, from, to, easing~, blocking~),
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
  match self.pending_error {
    Some(err) => raise err
    None => ()
  }
  script_from_instructions(self.instructions)
}
