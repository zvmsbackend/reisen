///|
using @core {
  animation_progress,
  type EffectSpec,
  type FigurePlacement,
  type ScalarState,
  type Position,
  type Easing,
  type EffectPhase,
}

///|
using @assets {type AssetStore}

///|
using @presenter_common {
  animation_anchor_from_values,
  animation_lerp,
  animation_lerp_optional,
  animation_sample,
  animation_value,
}

///|
using @pixi {
  type PixiApplication,
  type PixiBlurFilter,
  type PixiCanvas,
  type PixiColorMatrixFilter,
  type PixiContainer,
  type PixiEffectTarget,
  type PixiLive2dModel,
  type PixiSprite,
  type PixiTexture,
  type EffectParam,
  get_canvas_by_id,
  pixi_apply_effect_to_target,
  pixi_effect_defaults_for,
  window_inner_height,
  window_inner_width,
}

///|
using @engine {
  type RenderExtensionHook,
  type RenderExtensionView,
  type RenderExtensionUpdate,
}
