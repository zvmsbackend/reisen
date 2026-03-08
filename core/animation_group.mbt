///|
pub(all) enum GroupStep {
  Animate(AnimationSpec)
  Effect(EffectSpec)
} derive(Show, Eq)

///|
pub struct AnimationGroup {
  steps : Array[AnimationSpec]
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
  spec : AnimationSpec,
) -> AnimationGroup {
  { steps: self.steps + [spec] }
}

///|
pub fn AnimationGroup::effect(
  self : AnimationGroup,
  effect_spec : EffectSpec,
) -> MixedGroup {
  { steps: self.steps.map(step => Animate(step)) + [Effect(effect_spec)] }
}

///|
pub fn MixedGroup::animate(
  self : MixedGroup,
  spec : AnimationSpec,
) -> MixedGroup {
  { steps: self.steps + [Animate(spec)] }
}

///|
pub fn MixedGroup::effect(
  self : MixedGroup,
  effect_spec : EffectSpec,
) -> MixedGroup {
  { steps: self.steps + [Effect(effect_spec)] }
}

///|
pub fn AnimationGroup::to_steps(self : AnimationGroup) -> Array[GroupStep] {
  self.steps.map(step => GroupStep::Animate(step))
}

///|
pub fn MixedGroup::to_steps(self : MixedGroup) -> Array[GroupStep] {
  self.steps
}
