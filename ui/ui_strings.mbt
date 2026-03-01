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
  settings_language : String
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
    settings_language: "Language",
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

///|
extern "js" fn ui_locale_lookup(
  locales_json : String,
  locale : String,
  key : String,
) -> @js.Nullable[String] =
  #| (locales_json, locale, key) => {
  #|   try {
  #|     if (!globalThis.__reisenUiLocaleTableCache) {
  #|       globalThis.__reisenUiLocaleTableCache = { raw: '', parsed: null };
  #|     }
  #|     const cache = globalThis.__reisenUiLocaleTableCache;
  #|     if (cache.raw !== locales_json) {
  #|       cache.raw = locales_json;
  #|       cache.parsed = locales_json ? JSON.parse(locales_json) : null;
  #|     }
  #|     const parsed = cache.parsed;
  #|     if (!parsed || typeof parsed !== 'object') return null;
  #|     const byLocale = parsed[locale];
  #|     if (!byLocale || typeof byLocale !== 'object') return null;
  #|     const value = byLocale[key];
  #|     return typeof value === 'string' ? value : null;
  #|   } catch {
  #|     return null;
  #|   }
  #| }

///|
extern "js" fn ui_locale_warn_missing(
  locale : String,
  default_locale : String,
  key : String,
) -> Unit =
  #| (locale, default_locale, key) => {
  #|   if (typeof console !== 'undefined' && console.warn) {
  #|     console.warn(`[reisen:i18n] missing ui key '${key}' for locale='${locale}' (default='${default_locale}')`);
  #|   }
  #| }

///|
fn ui_locale_resolve_string(
  locales_json : String,
  locale : String,
  default_locale : String,
  key : String,
  fallback : String,
) -> String {
  match ui_locale_lookup(locales_json, locale, key).to_option() {
    Some(value) => value
    None =>
      match ui_locale_lookup(locales_json, default_locale, key).to_option() {
        Some(value) => value
        None => {
          ui_locale_warn_missing(locale, default_locale, key)
          fallback
        }
      }
  }
}

///|
pub fn UiStrings::from_locales_json(
  locales_json : String,
  locale : String,
  default_locale : String,
  fallback? : UiStrings = UiStrings::default(),
) -> UiStrings {
  {
    start_locale_title: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "start_locale_title",
      fallback.start_locale_title,
    ),
    start_gate_click_to_start: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "start_gate_click_to_start",
      fallback.start_gate_click_to_start,
    ),
    start_menu_new_game: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "start_menu_new_game",
      fallback.start_menu_new_game,
    ),
    start_menu_continue: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "start_menu_continue",
      fallback.start_menu_continue,
    ),
    start_menu_load: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "start_menu_load",
      fallback.start_menu_load,
    ),
    start_menu_settings: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "start_menu_settings",
      fallback.start_menu_settings,
    ),
    start_menu_gallery: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "start_menu_gallery",
      fallback.start_menu_gallery,
    ),
    settings_text_speed: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_text_speed",
      fallback.settings_text_speed,
    ),
    settings_language: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_language",
      fallback.settings_language,
    ),
    settings_bgm_volume: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_bgm_volume",
      fallback.settings_bgm_volume,
    ),
    settings_sfx_volume: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_sfx_volume",
      fallback.settings_sfx_volume,
    ),
    settings_save: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_save",
      fallback.settings_save,
    ),
    settings_load: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_load",
      fallback.settings_load,
    ),
    settings_log: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_log",
      fallback.settings_log,
    ),
    settings_start_menu: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_start_menu",
      fallback.settings_start_menu,
    ),
    settings_new_game: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_new_game",
      fallback.settings_new_game,
    ),
    settings_defaults: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_defaults",
      fallback.settings_defaults,
    ),
    settings_back: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_back",
      fallback.settings_back,
    ),
    settings_confirm_cancel: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_confirm_cancel",
      fallback.settings_confirm_cancel,
    ),
    settings_confirm_ok: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_confirm_ok",
      fallback.settings_confirm_ok,
    ),
    settings_confirm_return_start_menu: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_confirm_return_start_menu",
      fallback.settings_confirm_return_start_menu,
    ),
    settings_save_game_title: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_save_game_title",
      fallback.settings_save_game_title,
    ),
    settings_load_game_title: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_load_game_title",
      fallback.settings_load_game_title,
    ),
    settings_tab_auto: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_tab_auto",
      fallback.settings_tab_auto,
    ),
    settings_tab_quick: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_tab_quick",
      fallback.settings_tab_quick,
    ),
    settings_tab_save: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_tab_save",
      fallback.settings_tab_save,
    ),
    settings_slot_delete: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_slot_delete",
      fallback.settings_slot_delete,
    ),
    settings_confirm_delete_slot: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_confirm_delete_slot",
      fallback.settings_confirm_delete_slot,
    ),
    settings_confirm_overwrite_slot: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_confirm_overwrite_slot",
      fallback.settings_confirm_overwrite_slot,
    ),
    settings_nav_prev: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_nav_prev",
      fallback.settings_nav_prev,
    ),
    settings_nav_next: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_nav_next",
      fallback.settings_nav_next,
    ),
    settings_page_prefix: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_page_prefix",
      fallback.settings_page_prefix,
    ),
    settings_slot_empty: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "settings_slot_empty",
      fallback.settings_slot_empty,
    ),
    gallery_back: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "gallery_back",
      fallback.gallery_back,
    ),
    gallery_locked: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "gallery_locked",
      fallback.gallery_locked,
    ),
    gallery_prev: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "gallery_prev",
      fallback.gallery_prev,
    ),
    gallery_next: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "gallery_next",
      fallback.gallery_next,
    ),
    gallery_replay: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "gallery_replay",
      fallback.gallery_replay,
    ),
    gallery_close: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "gallery_close",
      fallback.gallery_close,
    ),
    game_action_settings: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "game_action_settings",
      fallback.game_action_settings,
    ),
    game_action_quicksave: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "game_action_quicksave",
      fallback.game_action_quicksave,
    ),
    game_action_save: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "game_action_save",
      fallback.game_action_save,
    ),
    game_action_log: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "game_action_log",
      fallback.game_action_log,
    ),
    game_action_dialog: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "game_action_dialog",
      fallback.game_action_dialog,
    ),
    game_action_auto: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "game_action_auto",
      fallback.game_action_auto,
    ),
    game_action_skip: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "game_action_skip",
      fallback.game_action_skip,
    ),
    game_toggle_on_prefix: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "game_toggle_on_prefix",
      fallback.game_toggle_on_prefix,
    ),
    game_toggle_off_prefix: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "game_toggle_off_prefix",
      fallback.game_toggle_off_prefix,
    ),
    game_text_input_submit: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "game_text_input_submit",
      fallback.game_text_input_submit,
    ),
    game_log_building: ui_locale_resolve_string(
      locales_json,
      locale,
      default_locale,
      "game_log_building",
      fallback.game_log_building,
    ),
  }
}
