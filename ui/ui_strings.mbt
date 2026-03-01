///|
/// User-facing UI strings used by engine-provided menus and overlays.
pub struct UiStrings {
  start_locale_title : String
  start_gate_click_to_start : String
  start_menu_new_game : String
  start_menu_continue : String
  start_menu_load : String
  start_menu_settings : String
  start_menu_gallery : String
  settings_text_speed : String
  settings_bgm_volume : String
  settings_sfx_volume : String
  settings_save : String
  settings_load : String
  settings_log : String
  settings_start_menu : String
  settings_new_game : String
  settings_defaults : String
  settings_back : String
  settings_confirm_cancel : String
  settings_confirm_ok : String
  settings_confirm_return_start_menu : String
  settings_save_game_title : String
  settings_load_game_title : String
  settings_tab_auto : String
  settings_tab_quick : String
  settings_tab_save : String
  settings_slot_delete : String
  settings_confirm_delete_slot : String
  settings_confirm_overwrite_slot : String
  settings_nav_prev : String
  settings_nav_next : String
  settings_page_prefix : String
  settings_slot_empty : String
  gallery_back : String
  gallery_locked : String
  gallery_prev : String
  gallery_next : String
  gallery_replay : String
  gallery_close : String
  game_action_settings : String
  game_action_quicksave : String
  game_action_save : String
  game_action_log : String
  game_action_dialog : String
  game_action_auto : String
  game_action_skip : String
  game_toggle_on_prefix : String
  game_toggle_off_prefix : String
  game_text_input_submit : String
  game_log_building : String
}

///|
pub impl Default for UiStrings with default() {
  {
    start_locale_title: "Choose Language",
    start_gate_click_to_start: "Click to Start",
    start_menu_new_game: "New Game",
    start_menu_continue: "Continue",
    start_menu_load: "Load",
    start_menu_settings: "Settings",
    start_menu_gallery: "Gallery",
    settings_text_speed: "Text Speed",
    settings_bgm_volume: "BGM Volume",
    settings_sfx_volume: "SFX Volume",
    settings_save: "Save",
    settings_load: "Load",
    settings_log: "Log",
    settings_start_menu: "Start Menu",
    settings_new_game: "New Game",
    settings_defaults: "Defaults",
    settings_back: "Back",
    settings_confirm_cancel: "Cancel",
    settings_confirm_ok: "Confirm",
    settings_confirm_return_start_menu: "Return to the start menu? Unsaved progress will be lost.",
    settings_save_game_title: "Save Game",
    settings_load_game_title: "Load Game",
    settings_tab_auto: "Auto",
    settings_tab_quick: "Quick",
    settings_tab_save: "Save",
    settings_slot_delete: "×",
    settings_confirm_delete_slot: "Delete this save slot?",
    settings_confirm_overwrite_slot: "Overwrite this save slot?",
    settings_nav_prev: "Prev",
    settings_nav_next: "Next",
    settings_page_prefix: "Page",
    settings_slot_empty: "Empty",
    gallery_back: "Back",
    gallery_locked: "Locked",
    gallery_prev: "Prev",
    gallery_next: "Next",
    gallery_replay: "Replay",
    gallery_close: "Close",
    game_action_settings: "⚙",
    game_action_quicksave: "Q.Save",
    game_action_save: "Save",
    game_action_log: "Log",
    game_action_dialog: "Dialog",
    game_action_auto: "Auto",
    game_action_skip: "Skip",
    game_toggle_on_prefix: "☑ ",
    game_toggle_off_prefix: "☐ ",
    game_text_input_submit: "Submit",
    game_log_building: "Building log...",
  }
}
