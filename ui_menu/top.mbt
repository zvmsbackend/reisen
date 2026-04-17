///|
using @storage {trait SaveSlotStore}

///|
pub fn choose_continue_slot(entries : Array[@storage.SaveSlotEntry]) -> String? {
  for entry in entries; best_slot = None, best_ts = -1L {
    let ts = match entry.meta {
      Some(meta) => meta.updated_at_ms
      None => -1L
    }
    if ts > best_ts || best_slot is None {
      continue Some(entry.slot), ts
    }
  } nobreak {
    best_slot
  }
}

///|
pub fn localize_script_string(
  raw : String,
  script_locale_json : String?,
  script_default_locale_json : String?,
) -> String {
  let (localized, _, _) = @util.script_locale_resolve_at(
    raw, script_locale_json, script_default_locale_json,
  )
  localized
}

///|
pub struct GalleryTileState {
  id : String
  image_id : String
  thumbnail_id : String?
  title : String
  unlocked : Bool
  replay_label : String?
}

///|
pub fn gallery_tiles_from_registry(
  save_namespace : String,
  show_locked : Bool,
  script_locale_json : String?,
  script_default_locale_json : String?,
) -> Array[GalleryTileState] {
  let out : Array[GalleryTileState] = []
  for image in @gallery.registered_images() {
    let title = localize_script_string(
      image.title,
      script_locale_json,
      script_default_locale_json,
    )
    let tile : GalleryTileState = {
      id: image.id,
      image_id: image.image_url,
      thumbnail_id: image.thumbnail_url,
      title,
      unlocked: @gallery.is_image_unlocked_in(save_namespace, image),
      replay_label: image.replay_label,
    }
    if tile.unlocked || show_locked {
      out.push(tile)
    }
  }
  out
}

///|
pub fn find_gallery_tile(
  tiles : Array[GalleryTileState],
  id : String,
) -> GalleryTileState? {
  tiles.iter().find_first(tile => tile.id == id)
}

///|
pub fn next_unlocked_gallery_tile_id(
  tiles : Array[GalleryTileState],
  current_id : String?,
  step : Int,
) -> String? {
  if tiles.is_empty() {
    return None
  }
  let unlocked = tiles.filter(tile => tile.unlocked)
  if unlocked.is_empty() {
    return None
  }
  let current_idx = match current_id {
    Some(id) =>
      for i, tile in unlocked {
        if tile.id == id {
          break i
        }
      } nobreak {
        0
      }
    None => 0
  }
  let dir = if step < 0 { -1 } else { 1 }
  let size = unlocked.length()
  let raw = if dir < 0 { current_idx - 1 } else { current_idx + 1 }
  let wrapped = if raw < 0 { size - 1 } else if raw >= size { 0 } else { raw }
  Some(unlocked[wrapped].id)
}

///|
pub fn reduce_gallery_active_id(
  action : GalleryAction,
  active_id : String?,
  tiles : Array[GalleryTileState],
) -> String? {
  match action {
    Open(id) =>
      match find_gallery_tile(tiles, id) {
        Some(tile) => if tile.unlocked { Some(id) } else { None }
        None => None
      }
    Close => None
    Prev => next_unlocked_gallery_tile_id(tiles, active_id, -1)
    Next => next_unlocked_gallery_tile_id(tiles, active_id, 1)
    _ => active_id
  }
}

///|
using @ui_game {type UiStrings}

///|
using @audio_core {trait AudioPort}

///|
pub(open) trait MenuFactory {
  create_start_menu(
    Self,
    save_store~ : &SaveSlotStore,
    background~ : String,
    show_credits~ : Bool,
  ) -> &StartMenu
  create_gallery_menu(Self, background~ : String) -> &GalleryMenu
  create_settings_menu(
    Self,
    audio~ : &AudioPort,
    background~ : String,
    show_credits~ : Bool,
  ) -> &SettingsMenu
  create_credits_menu(Self, background~ : String) -> &CreditsMenu
  create_loading_menu(Self) -> &LoadingMenu
}

///|
pub(all) enum StartMenuAction {
  NoAction
  NewGame
  Continue(String)
  Load
  Settings
  Gallery
  Credits
}

///|
pub(all) enum StartGateAction {
  NoAction
  Start
}

///|
pub(all) enum StartLogoAction {
  NoAction
  Done
}

///|
pub(all) enum StartLocaleAction {
  NoAction
  Select(String)
}

///|
pub(open) trait StartMenu {
  set_ui_strings(Self, UiStrings) -> Unit
  render_gate(Self) -> Unit
  clear_gate(Self) -> Unit
  take_gate_action(Self) -> StartGateAction
  render_logo(Self, String, Int) -> Unit
  clear_logo(Self) -> Unit
  take_logo_action(Self) -> StartLogoAction
  render_locale_picker(Self, Array[(String, String)]) -> Unit
  clear_locale_picker(Self) -> Unit
  take_locale_action(Self) -> StartLocaleAction
  render(Self) -> Unit
  clear(Self) -> Unit
  take_action(Self) -> StartMenuAction
}

///|
pub(all) enum GalleryAction {
  NoAction
  Back
  Open(String)
  Close
  Prev
  Next
  Replay(String)
}

///|
pub(open) trait GalleryMenu {
  set_ui_strings(Self, UiStrings) -> Unit
  set_script_localization(
    Self,
    script_locale_json~ : String?,
    script_default_locale_json~ : String?,
  ) -> Unit
  render(Self) -> Unit
  clear(Self) -> Unit
  take_action(Self) -> GalleryAction
}

///|
pub(all) enum SettingsContext {
  FromStartMenu
  FromMidgame
} derive(Debug, Eq)

///|
pub(all) enum SettingsViewMode {
  Settings
  SaveList
  LoadList
}

///|
pub(all) enum SettingsAction {
  ViewChanged
  NoAction
  LanguageChanged(String)
  Back
  Credits
  NewGame
  StartMenu
  Log
  SaveSlot(String)
  LoadSlot(String)
}

///|
pub(open) trait SettingsMenu {
  set_ui_strings(Self, UiStrings) -> Unit
  set_script_localization(
    Self,
    script_locale_json~ : String?,
    script_default_locale_json~ : String?,
  ) -> Unit
  set_languages(Self, Array[(String, String)]) -> Unit
  set_locale(Self, String) -> Unit
  set_context(Self, SettingsContext) -> Unit
  set_view_mode(Self, SettingsViewMode) -> Unit
  render(Self) -> Unit
  clear(Self) -> Unit
  take_action(Self) -> SettingsAction
}

///|
pub(all) enum CreditsAction {
  NoAction
  Back
}

///|
pub(open) trait CreditsMenu {
  set_ui_strings(Self, UiStrings) -> Unit
  render(Self, String) -> Unit
  clear(Self) -> Unit
  take_action(Self) -> CreditsAction
}

///|
pub(open) trait LoadingMenu {
  render(Self, String) -> Unit
  clear(Self) -> Unit
}
