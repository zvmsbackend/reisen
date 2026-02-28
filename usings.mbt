///|
using @util {gensym}

///|
using @storage {
  type GameSettings,
  type SaveSlotEntry,
  game_settings_default,
  save_slot_delete_in,
  save_slot_entries_in,
  save_slot_list_in,
  save_slot_meta,
  save_slot_read_in,
  save_slot_write_in,
  save_slot_write_meta_in,
  settings_read_in,
  settings_write_in,
}

///|
using @core {
  type AnimationSpec,
  type BackgroundState,
  type ChoiceOption,
  type DomFigureState,
  type EffectParam,
  type EffectSpec,
  type FigurePlacement,
  type Instruction,
  type Runtime,
  type RuntimeEvent,
  type RuntimeSave,
  type Script,
  type ScriptFlowTrace,
  type ScriptHook,
  type ScriptPredicate,
  type ScalarState,
  type PayloadPredicate,
  type PayloadJumpSelector,
  type ScriptBuildError,
  type ScriptRuntimeError,
  type Position,
  type Easing,
  type EffectPhase,
  type Label,
  script_from_instructions,
}

///|
using @state {type GameState}

///|
using @gallery {type GalleryImage, type ReplayStateFactories}

///|
using @assets {
  type AssetStore,
  type Background,
  type DomFigure,
  type Live2dFigure,
  type Music,
  type Sfx,
}
