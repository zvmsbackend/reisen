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
pub fn[T] ScriptBuilder::play_video(
  self : ScriptBuilder[T],
  url : String,
  can_skip? : Bool = false,
) -> Unit {
  self.instructions.push(PlayVideo(url, can_skip))
}

///|
pub fn[T] ScriptBuilder::play_music(
  self : ScriptBuilder[T],
  music : Music,
  should_loop : Bool,
) -> Unit {
  self.instructions.push(PlayMusic(music.0, should_loop))
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
  self.instructions.push(PlaySfx(sfx.0, blocking))
}

///|
pub fn[T] ScriptBuilder::play_live2d_motion(
  self : ScriptBuilder[T],
  figure : Live2dFigure,
  group : String,
  index? : Int,
) -> Unit {
  self.instructions.push(PlayLive2dMotion(figure.0, group, index))
}

///|
pub fn[T] ScriptBuilder::set_live2d_expression(
  self : ScriptBuilder[T],
  figure : Live2dFigure,
  id? : String,
) -> Unit {
  self.instructions.push(SetLive2dExpression(figure.id(), id))
}

///|
pub fn effect_spec(
  effect : Effect,
  params : Array[EffectParam],
  phase? : EffectPhase = Post,
  duration_ms? : Int,
  blocking? : Bool = false,
  easing? : Easing = Linear,
) -> EffectSpec {
  { id: effect.0, params, phase, duration_ms, easing, blocking }
}

///|
pub fn[T, A : @assets.PixiTarget] ScriptBuilder::effect(
  self : ScriptBuilder[T],
  target : A,
  effect_spec : EffectSpec,
) -> Unit {
  self.instructions.push(ApplyEffect(target.id(), effect_spec))
}

///|
pub fn[T, A : @assets.PixiTarget] ScriptBuilder::effect_with(
  self : ScriptBuilder[T],
  target : A,
  effect : Effect,
  params : Array[EffectParam],
  phase? : EffectPhase = Post,
  duration_ms? : Int,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> Unit {
  self.instructions.push(
    ApplyEffect(target.id(), {
      id: effect.0,
      params,
      phase,
      duration_ms,
      easing,
      blocking,
    }),
  )
}
