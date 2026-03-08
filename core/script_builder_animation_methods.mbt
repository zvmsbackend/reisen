///|
fn[T, A : @assets.AnimationTarget] ScriptBuilder::emit_animation(
  self : ScriptBuilder[T],
  target : A,
  spec : AnimationSpec,
) -> Unit {
  self.instructions.push(Animate(target.id(), spec, target.kind()))
}

///|
fn[T, A : @assets.AnimationTarget] ScriptBuilder::emit_animation_group(
  self : ScriptBuilder[T],
  target : A,
  steps : Array[GroupStep],
) -> Unit {
  self.instructions.push(AnimateGroup(target.id(), steps, target.kind()))
}

///|
pub fn[T, A : @assets.AnimationTarget] ScriptBuilder::animate(
  self : ScriptBuilder[T],
  target : A,
  spec : AnimationSpec,
) -> Unit {
  self.emit_animation(target, spec)
}

///|
pub fn[T, A : @assets.AnimationTarget] ScriptBuilder::animate_group(
  self : ScriptBuilder[T],
  target : A,
  group : AnimationGroup,
) -> Unit {
  self.emit_animation_group(target, group.to_steps())
}

///|
pub fn[T, A : @assets.PixiTarget] ScriptBuilder::animate_mixed_group(
  self : ScriptBuilder[T],
  target : A,
  group : MixedGroup,
) -> Unit {
  self.emit_animation_group(target, group.to_steps())
}

///|
pub fn[T, A : @assets.AnimationTarget] ScriptBuilder::animate_opacity(
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
    anim_opacity(duration_ms, from?, to, easing~, blocking~),
  )
}

///|
pub fn[T, A : @assets.AnimationTarget] ScriptBuilder::animate_position(
  self : ScriptBuilder[T],
  target : A,
  duration_ms : Int,
  from? : Position,
  to : Position,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> Unit {
  let spec = match target.kind() {
    Pixi => anim_position(duration_ms, from?, to, easing~, blocking~)
    Dom => anim_position_dom(duration_ms, from?, to, easing, blocking)
  }
  self.emit_animation(target, spec)
}

///|
pub fn[T, A : @assets.AnimationTarget] ScriptBuilder::animate_scale(
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
    anim_scale(duration_ms, from?, to, anchor~, easing~, blocking~),
  )
}

///|
pub fn[T, A : @assets.AnimationTarget] ScriptBuilder::animate_rotation(
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
    anim_rotation(duration_ms, from?, to, easing~, blocking~),
  )
}

///|
pub fn[T, A : @assets.AnimationTarget] ScriptBuilder::animate_blur(
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
    anim_blur(duration_ms, from?, to, easing~, blocking~),
  )
}

///|
pub fn[T, A : @assets.AnimationTarget] ScriptBuilder::animate_brightness(
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
    anim_brightness(duration_ms, from?, to, easing~, blocking~),
  )
}

///|
pub fn[T, A : @assets.AnimationTarget] ScriptBuilder::animate_contrast(
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
    anim_contrast(duration_ms, from?, to, easing~, blocking~),
  )
}

///|
pub fn[T, A : @assets.AnimationTarget] ScriptBuilder::animate_saturation(
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
    anim_saturation(duration_ms, from?, to, easing~, blocking~),
  )
}

///|
pub fn[T, A : @assets.AnimationTarget] ScriptBuilder::animate_gamma(
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
    anim_gamma(duration_ms, from?, to, easing~, blocking~),
  )
}

///|
pub fn[T, A : @assets.AnimationTarget] ScriptBuilder::animate_color_red(
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
    anim_color_red(duration_ms, from?, to, easing~, blocking~),
  )
}

///|
pub fn[T, A : @assets.AnimationTarget] ScriptBuilder::animate_color_green(
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
    anim_color_green(duration_ms, from?, to, easing~, blocking~),
  )
}

///|
pub fn[T, A : @assets.AnimationTarget] ScriptBuilder::animate_color_blue(
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
    anim_color_blue(duration_ms, from?, to, easing~, blocking~),
  )
}
