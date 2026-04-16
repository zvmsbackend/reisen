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
using @core {type DialogLogEntry, type EventHook, type Runtime, type Script}

///|
using @state {type GameState, type DialogText}

///|
using @gallery {type GalleryImage, type ReplayStateFactories}

///|
using @assets {trait AssetStore, type AssetStoreError, type Music}

///|
using @util {load_text}

///|
using @util {script_locale_resolve_at}

///|
using @audio {trait AudioPort}

///|
using @ui_game {type UiStrings}

///|
using @ui_menu {
  trait MenuFactory,
  trait StartMenu,
  trait GalleryMenu,
  trait SettingsMenu,
  trait CreditsMenu,
  trait LoadingMenu,
  type StartMenuAction,
  type StartLocaleAction,
  type CreditsAction,
}

///|
using @engine {
  type Director,
  type GameRunner,
  type RenderSyncHook,
  type RenderExtensionHook,
  noop_core_render_sync,
}
