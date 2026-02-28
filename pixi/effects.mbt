///|
pub type EffectParam = (String, Double)

///|
pub type PixiEffectApply = (PixiSprite, Array[EffectParam], Int) -> Bool

///|
let pixi_effect_appliers : Map[String, PixiEffectApply] = {}

///|
pub struct Effect(String)

///|
pub(all) enum PixiEffectTarget {
  Sprite(PixiSprite)
  Live2d(PixiLive2dModel)
}

///|
pub type PixiSharedEffectApply = (PixiEffectTarget, Array[EffectParam], Int) -> Bool

///|
let pixi_shared_effect_appliers : Map[String, PixiSharedEffectApply] = {}

///|
let pixi_effect_defaults : Map[String, Array[EffectParam]] = {}

///|
pub fn register_pixi_effect(
  apply : PixiEffectApply,
  defaults? : Array[EffectParam] = [],
  id? : String = gensym(prefix="effect"),
) -> Effect {
  pixi_effect_appliers.set(id, apply)
  pixi_effect_defaults.set(id, defaults)
  id
}

///|
pub fn register_pixi_effect_shared(
  apply : PixiSharedEffectApply,
  defaults? : Array[EffectParam] = [],
  id? : String = gensym(prefix="effect"),
) -> Effect {
  pixi_shared_effect_appliers.set(id, apply)
  pixi_effect_defaults.set(id, defaults)
  id
}

///|
pub fn pixi_effect_defaults_for(
  id : String,
  fallback : Array[EffectParam],
) -> Array[EffectParam] {
  match pixi_effect_defaults.get(id) {
    Some(list) if list.length() > 0 => list
    _ => fallback
  }
}

///|
pub fn pixi_apply_effect_to_target(
  target : PixiEffectTarget,
  effect_id : String,
  params : Array[EffectParam],
  timeline_ms : Int,
) -> Bool {
  let mut skip_base = false
  match pixi_shared_effect_appliers.get(effect_id) {
    Some(apply_shared) =>
      if apply_shared(target, params, timeline_ms) {
        skip_base = true
      }
    None =>
      match target {
        Sprite(sprite) =>
          match pixi_effect_appliers.get(effect_id) {
            Some(apply) =>
              if apply(sprite, params, timeline_ms) {
                skip_base = true
              }
            None => ()
          }
        Live2d(_) => ()
      }
  }
  skip_base
}
