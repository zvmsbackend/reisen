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
using @assets_web {type WebAssetStore}

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
  type PixiTexture,
  type PixiLive2dModel,
  type PixiSprite,
  type PixiEffectTarget,
  get_canvas_by_id,
  window_inner_height,
  window_inner_width,
}

///|
using @effect_types {type EffectParam}

///|
using @engine {
  type RenderExtensionHook,
  type RenderExtensionView,
  type RenderExtensionUpdate,
}
