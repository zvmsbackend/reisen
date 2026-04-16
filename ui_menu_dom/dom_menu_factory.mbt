///|
struct DomMenuFactory {
  root_id : String
  save_namespace : String
  ui_strings : UiStrings
}

///|
pub fn DomMenuFactory::new(
  root_id : String,
  save_namespace : String,
  ui_strings? : UiStrings = UiStrings::default(),
) -> DomMenuFactory {
  { root_id, save_namespace, ui_strings }
}

///|
pub impl @ui_menu.MenuFactory for DomMenuFactory with create_start_menu(
  self,
  save_store~,
  background~,
  show_credits~,
) {
  StartMenu::new(
    self.root_id,
    save_namespace=self.save_namespace,
    save_store~,
    background~,
    ui_strings=self.ui_strings,
    show_credits~,
  )
}

///|
pub impl @ui_menu.MenuFactory for DomMenuFactory with create_gallery_menu(
  self,
  background~,
) {
  GalleryMenu::new(
    self.root_id,
    save_namespace=self.save_namespace,
    background~,
    ui_strings=self.ui_strings,
  )
}

///|
pub impl @ui_menu.MenuFactory for DomMenuFactory with create_settings_menu(
  self,
  audio~,
  background~,
  show_credits~,
) {
  SettingsMenu::new(
    self.root_id,
    audio~,
    save_namespace=self.save_namespace,
    background~,
    ui_strings=self.ui_strings,
    show_credits~,
  )
}

///|
pub impl @ui_menu.MenuFactory for DomMenuFactory with create_credits_menu(
  self,
  background~,
) {
  CreditsMenu::new(self.root_id, background~, ui_strings=self.ui_strings)
}

///|
pub impl @ui_menu.MenuFactory for DomMenuFactory with create_loading_menu(self) {
  LoadingMenu::new(self.root_id)
}
