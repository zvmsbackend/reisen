///|
using @core {
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
using @engine {type Director, type RenderSyncHook}
