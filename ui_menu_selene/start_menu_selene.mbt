///|
pub struct SeleneStartMenu {
  mut ui_strings : UiStrings
  mut pending_action : @ui_menu.StartMenuAction
  mut pending_gate_action : @ui_menu.StartGateAction
  mut pending_logo_action : @ui_menu.StartLogoAction
  mut pending_locale_action : @ui_menu.StartLocaleAction
  mut last_enter_down : Bool
  mut last_space_down : Bool
  mut visible_mode : String?
}

///|
pub fn SeleneStartMenu::new(
  ui_strings? : UiStrings = UiStrings::default(),
) -> SeleneStartMenu {
  {
    ui_strings,
    pending_action: NoAction,
    pending_gate_action: NoAction,
    pending_logo_action: NoAction,
    pending_locale_action: NoAction,
    last_enter_down: false,
    last_space_down: false,
    visible_mode: None,
  }
}

///|
fn SeleneStartMenu::take_confirm_edge(self : SeleneStartMenu) -> Bool {
  let enter_down = @selene_inputs.is_pressed(@selene_inputs.Enter)
  let space_down = @selene_inputs.is_pressed(@selene_inputs.Space)
  let triggered = (enter_down && !self.last_enter_down) ||
    (space_down && !self.last_space_down)
  self.last_enter_down = enter_down
  self.last_space_down = space_down
  triggered
}

///|
pub fn SeleneStartMenu::push_action(
  self : SeleneStartMenu,
  action : @ui_menu.StartMenuAction,
) -> Unit {
  self.pending_action = action
}

///|
pub fn SeleneStartMenu::push_gate_action(
  self : SeleneStartMenu,
  action : @ui_menu.StartGateAction,
) -> Unit {
  self.pending_gate_action = action
}

///|
pub fn SeleneStartMenu::push_logo_done(self : SeleneStartMenu) -> Unit {
  self.pending_logo_action = Done
}

///|
pub fn SeleneStartMenu::push_locale_code(
  self : SeleneStartMenu,
  code : String,
) -> Unit {
  self.pending_locale_action = Select(code)
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with set_ui_strings(
  self,
  ui_strings,
) {
  self.ui_strings = ui_strings
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with render_gate(self) {
  self.visible_mode = Some("gate")
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with clear_gate(self) {
  if self.visible_mode == Some("gate") {
    self.visible_mode = None
  }
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with take_gate_action(self) {
  let result = match self.pending_gate_action {
    @ui_menu.StartGateAction::NoAction =>
      if self.take_confirm_edge() {
        @ui_menu.StartGateAction::Start
      } else {
        @ui_menu.StartGateAction::NoAction
      }
    other => other
  }
  self.pending_gate_action = @ui_menu.StartGateAction::NoAction
  result
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with render_logo(self, _, _) {
  self.visible_mode = Some("logo")
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with clear_logo(self) {
  if self.visible_mode == Some("logo") {
    self.visible_mode = None
  }
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with take_logo_action(self) {
  let result = match self.pending_logo_action {
    @ui_menu.StartLogoAction::NoAction =>
      if self.take_confirm_edge() {
        @ui_menu.StartLogoAction::Done
      } else {
        @ui_menu.StartLogoAction::NoAction
      }
    other => other
  }
  self.pending_logo_action = @ui_menu.StartLogoAction::NoAction
  result
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with render_locale_picker(
  self,
  _,
) {
  self.visible_mode = Some("locale")
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with clear_locale_picker(self) {
  if self.visible_mode == Some("locale") {
    self.visible_mode = None
  }
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with take_locale_action(self) {
  let result = self.pending_locale_action
  self.pending_locale_action = NoAction
  result
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with render(self) {
  self.visible_mode = Some("start")
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with clear(self) {
  self.visible_mode = None
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with take_action(self) {
  let result = self.pending_action
  self.pending_action = NoAction
  result
}
