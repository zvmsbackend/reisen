///|
using @storage {
  type GameSettings,
  save_slot_list_in,
  save_slot_meta,
  save_slot_read_in,
  save_slot_write_in,
  save_slot_write_meta_in,
  settings_read_in,
}

///|
using @core {
  type EventHook,
  type EffectSpec,
  type FigurePlacement,
  type Runtime,
  type Script,
  type ScalarState,
  type Position,
  type Easing,
  type EffectPhase,
}

///|
using @state {type GameState}

///|
using @gallery {type GalleryImage, type ReplayStateFactories}

///|
using @assets {type AssetStore, type Music}

///|
using @pixi {
  type PixiApplication,
  type PixiBindingError,
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
using @ui {
  type UiDom,
  type StartMenu,
  type GalleryMenu,
  type SettingsMenu,
  type StartMenuAction,
}

///|
using @engine {
  type Director,
  type GameRunner,
  type RenderSyncHook,
  type LogBuildState,
  director_from_save_json,
}
