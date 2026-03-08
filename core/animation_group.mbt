///|
struct TimedAnimationStep {
  duration_ms : Int
  spec : AnimationSpec
  easing : Easing
} derive(Show, Eq)

///|
struct TimedEffectStep {
  duration_ms : Int
  effect_spec : EffectSpec
  easing : Easing
} derive(Show, Eq)

///|
enum GroupStep {
  Animate(TimedAnimationStep)
  Effect(TimedEffectStep)
} derive(Show, Eq)

///|
pub struct AnimationGroup {
  steps : Array[TimedAnimationStep]
} derive(Show, Eq)

///|
pub struct MixedGroup {
  steps : Array[GroupStep]
} derive(Show, Eq)

///|
pub fn AnimationGroup::new() -> AnimationGroup {
  { steps: [] }
}

///|
pub fn MixedGroup::new() -> MixedGroup {
  { steps: [] }
}

///|
pub fn AnimationGroup::animate(
  self : AnimationGroup,
  duration_ms : Int,
  spec : AnimationSpec,
  easing? : Easing = Linear,
) -> AnimationGroup {
  { steps: self.steps + [{duration_ms, spec, easing}] }
}

///|
pub fn AnimationGroup::effect(
  self : AnimationGroup,
  duration_ms : Int,
  effect_spec : EffectSpec,
  easing? : Easing = Linear,
  ) -> MixedGroup {
  {
    steps: self.steps.map(step => Animate(step)) + [
      Effect({ duration_ms, effect_spec, easing }),
    ],
  }
}

///|
pub fn MixedGroup::animate(
  self : MixedGroup,
  duration_ms : Int,
  spec : AnimationSpec,
  easing? : Easing = Linear,
) -> MixedGroup {
  { steps: self.steps + [Animate({ duration_ms, spec, easing })] }
}

///|
pub fn MixedGroup::effect(
  self : MixedGroup,
  duration_ms : Int,
  effect_spec : EffectSpec,
  easing? : Easing = Linear,
) -> MixedGroup {
  { steps: self.steps + [Effect({ duration_ms, effect_spec, easing })] }
}
