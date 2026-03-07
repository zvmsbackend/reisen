///|
using @storage {
  type GameSettings,
  trait SaveSlotStore,
  default_save_slot_storage,
  persistent_get_text_in,
  persistent_set_text_in,
  save_slot_meta,
  settings_read_in,
}

///|
using @core {type EventHook, type Runtime, type Script}

///|
using @state {type GameState, type DialogText}

///|
using @gallery {type GalleryImage, type ReplayStateFactories}

///|
using @assets {type AssetStore, type AssetStoreError, type Music, load_text}

///|
using @pixi {type PixiBindingError}

///|
using @util {script_locale_resolve_at}

///|
using @ui {
  type AudioDom,
  type UiStrings,
  type UiDom,
  type StartMenu,
  type GalleryMenu,
  type SettingsMenu,
  type CreditsMenu,
  type LoadingMenu,
  type StartMenuAction,
  type StartLocaleAction,
  type CreditsAction,
}

///|
using @engine {
  type Director,
  type GameRunner,
  type RenderSyncHook,
  type LogBuildState,
}
