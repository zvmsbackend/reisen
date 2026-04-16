///|
pub struct SeleneGalleryMenu {
  mut ui_strings : UiStrings
  mut pending_action : @ui_menu.GalleryAction
  mut script_locale_json : String?
  mut script_default_locale_json : String?
  mut last_escape_down : Bool
  mut visible : Bool
}

///|
pub fn SeleneGalleryMenu::new(
  ui_strings? : UiStrings = UiStrings::default(),
) -> SeleneGalleryMenu {
  {
    ui_strings,
    pending_action: NoAction,
    script_locale_json: None,
    script_default_locale_json: None,
    last_escape_down: false,
    visible: false,
  }
}

///|
fn SeleneGalleryMenu::take_back_edge(self : SeleneGalleryMenu) -> Bool {
  let escape_down = @selene_inputs.is_pressed(@selene_inputs.Escape)
  let triggered = escape_down && !self.last_escape_down
  self.last_escape_down = escape_down
  triggered
}

///|
pub fn SeleneGalleryMenu::push_action(
  self : SeleneGalleryMenu,
  action : @ui_menu.GalleryAction,
) -> Unit {
  self.pending_action = action
}

///|
pub impl @ui_menu.GalleryMenu for SeleneGalleryMenu with set_ui_strings(
  self,
  ui_strings,
) {
  self.ui_strings = ui_strings
}

///|
pub impl @ui_menu.GalleryMenu for SeleneGalleryMenu with set_script_localization(
  self,
  script_locale_json~,
  script_default_locale_json~,
) {
  self.script_locale_json = script_locale_json
  self.script_default_locale_json = script_default_locale_json
}

///|
pub impl @ui_menu.GalleryMenu for SeleneGalleryMenu with render(self) {
  self.visible = true
}

///|
pub impl @ui_menu.GalleryMenu for SeleneGalleryMenu with clear(self) {
  self.visible = false
}

///|
pub impl @ui_menu.GalleryMenu for SeleneGalleryMenu with take_action(self) {
  let result = match self.pending_action {
    @ui_menu.GalleryAction::NoAction =>
      if self.take_back_edge() {
        @ui_menu.GalleryAction::Back
      } else {
        @ui_menu.GalleryAction::NoAction
      }
    other => other
  }
  self.pending_action = @ui_menu.GalleryAction::NoAction
  result
}
