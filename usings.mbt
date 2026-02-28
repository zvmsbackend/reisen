///|
using @util {gensym}

///|
using @storage {
  type GameSettings,
  type SaveSlotEntry,
  game_settings_default,
  persistent_delete,
  persistent_delete_in,
  persistent_get_flag,
  persistent_get_flag_in,
  persistent_get_text,
  persistent_set_flag,
  persistent_set_flag_in,
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
using @core {type GameState, game_state_from_json_string}

///|
using @gallery {
  type GalleryImage,
  type ReplayStateFactories,
  type ReplayStateFactoryKey,
}

///|
using @assets {
  type AssetStore,
  type Background,
  type DomFigure,
  type Image,
  type Live2dFigure,
  type Music,
  type PixiFigure,
  type Sfx,
  type Video,
  dom_figure,
  load_bytes,
  load_image,
  load_text,
  load_video,
}
