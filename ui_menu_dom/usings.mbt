///|
using @gallery {type GalleryImage}

///|
using @storage {
  type GameSettings,
  type SaveSlotEntry,
  default_save_slot_storage,
  save_slot_store_entries_in,
  settings_read_in,
  settings_write_in,
}

///|
using @ui_game {type UiStrings}

///|
using @ui_menu {
  type StartGateAction,
  type StartLogoAction,
  type GalleryAction,
  type SettingsContext,
  type SettingsViewMode,
  type SettingsAction,
}
