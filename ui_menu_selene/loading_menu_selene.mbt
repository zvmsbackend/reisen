///|
pub struct SeleneLoadingMenu {
  mut text : String
  mut visible : Bool
}

///|
pub fn SeleneLoadingMenu::new() -> SeleneLoadingMenu {
  { text: "", visible: false }
}

///|
pub impl @ui_menu.LoadingMenu for SeleneLoadingMenu with render(self, text) {
  self.text = text
  self.visible = true
}

///|
pub impl @ui_menu.LoadingMenu for SeleneLoadingMenu with clear(self) {
  self.text = ""
  self.visible = false
}
