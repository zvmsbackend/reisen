///|
using @storage {
  type GameSettings,
  persistent_get_text_in,
  persistent_set_text_in,
  save_slot_list_in,
  save_slot_meta,
  save_slot_read_in,
  save_slot_write_in,
  save_slot_write_meta_in,
  settings_read_in,
}

///|
using @core {type EventHook, type Runtime, type Script}

///|
using @state {type GameState}

///|
using @gallery {type GalleryImage, type ReplayStateFactories}

///|
using @assets {type AssetStore, type Music}

///|
using @pixi {type PixiBindingError}

///|
using @ui {
  type UiStrings,
  type UiDom,
  type StartMenu,
  type GalleryMenu,
  type SettingsMenu,
  type StartMenuAction,
  type StartLocaleAction,
}

///|
using @engine {
  type Director,
  type GameRunner,
  type RenderSyncHook,
  type LogBuildState,
  director_from_save_json,
}
