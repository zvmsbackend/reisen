///|
using @storage {trait SaveSlotStore}

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
