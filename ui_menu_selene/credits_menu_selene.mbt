///|
pub struct SeleneCreditsMenu {
  mut ui_strings : UiStrings
  mut pending_action : @ui_menu.CreditsAction
  mut text : String
  mut last_escape_down : Bool
  mut visible : Bool
}

///|
pub fn SeleneCreditsMenu::new(
  ui_strings? : UiStrings = UiStrings::default(),
) -> SeleneCreditsMenu {
  {
    ui_strings,
    pending_action: NoAction,
    text: "",
    last_escape_down: false,
    visible: false,
  }
}

///|
fn SeleneCreditsMenu::take_back_edge(self : SeleneCreditsMenu) -> Bool {
  let escape_down = @selene_inputs.is_pressed(@selene_inputs.Escape)
  let triggered = escape_down && !self.last_escape_down
  self.last_escape_down = escape_down
  triggered
}

///|
pub fn SeleneCreditsMenu::push_back(self : SeleneCreditsMenu) -> Unit {
  self.pending_action = Back
}

///|
pub impl @ui_menu.CreditsMenu for SeleneCreditsMenu with set_ui_strings(
  self,
  ui_strings,
) {
  self.ui_strings = ui_strings
}

///|
pub impl @ui_menu.CreditsMenu for SeleneCreditsMenu with render(self, text) {
  self.text = text
  self.visible = true
}

///|
pub impl @ui_menu.CreditsMenu for SeleneCreditsMenu with clear(self) {
  self.text = ""
  self.visible = false
}

///|
pub impl @ui_menu.CreditsMenu for SeleneCreditsMenu with take_action(self) {
  let result = match self.pending_action {
    @ui_menu.CreditsAction::NoAction =>
      if self.take_back_edge() {
        @ui_menu.CreditsAction::Back
      } else {
        @ui_menu.CreditsAction::NoAction
      }
    other => other
  }
  self.pending_action = @ui_menu.CreditsAction::NoAction
  result
}
