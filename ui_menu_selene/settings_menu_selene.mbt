///|
pub struct SeleneSettingsMenu {
  mut ui_strings : UiStrings
  mut pending_action : @ui_menu.SettingsAction
  mut script_locale_json : String?
  mut script_default_locale_json : String?
  mut languages : Array[(String, String)]
  mut locale : String
  mut context : @ui_menu.SettingsContext
  mut view_mode : @ui_menu.SettingsViewMode
  mut last_escape_down : Bool
  mut visible : Bool
}

///|
pub fn SeleneSettingsMenu::new(
  ui_strings? : UiStrings = UiStrings::default(),
) -> SeleneSettingsMenu {
  {
    ui_strings,
    pending_action: NoAction,
    script_locale_json: None,
    script_default_locale_json: None,
    languages: [],
    locale: "",
    context: FromStartMenu,
    view_mode: Settings,
    last_escape_down: false,
    visible: false,
  }
}

///|
fn SeleneSettingsMenu::take_back_edge(self : SeleneSettingsMenu) -> Bool {
  let escape_down = @selene_inputs.is_pressed(@selene_inputs.Escape)
  let triggered = escape_down && !self.last_escape_down
  self.last_escape_down = escape_down
  triggered
}

///|
pub fn SeleneSettingsMenu::push_action(
  self : SeleneSettingsMenu,
  action : @ui_menu.SettingsAction,
) -> Unit {
  self.pending_action = action
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with set_ui_strings(
  self,
  ui_strings,
) {
  self.ui_strings = ui_strings
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with set_script_localization(
  self,
  script_locale_json~,
  script_default_locale_json~,
) {
  self.script_locale_json = script_locale_json
  self.script_default_locale_json = script_default_locale_json
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with set_languages(
  self,
  languages,
) {
  self.languages = languages
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with set_locale(
  self,
  locale,
) {
  self.locale = locale
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with set_context(
  self,
  context,
) {
  self.context = context
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with set_view_mode(
  self,
  view_mode,
) {
  self.view_mode = view_mode
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with render(self) {
  self.visible = true
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with clear(self) {
  self.visible = false
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with take_action(self) {
  let result = match self.pending_action {
    @ui_menu.SettingsAction::NoAction =>
      if self.take_back_edge() {
        @ui_menu.SettingsAction::Back
      } else {
        @ui_menu.SettingsAction::NoAction
      }
    other => other
  }
  self.pending_action = @ui_menu.SettingsAction::NoAction
  result
}
