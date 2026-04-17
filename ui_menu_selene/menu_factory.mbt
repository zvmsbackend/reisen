///|
pub struct SeleneMenuFactory {
  ui_strings : UiStrings
  start_menu : SeleneStartMenu
  gallery_menu : SeleneGalleryMenu
  settings_menu : SeleneSettingsMenu
  credits_menu : SeleneCreditsMenu
  loading_menu : SeleneLoadingMenu
}

///|
pub fn SeleneMenuFactory::new(
  ui_strings? : UiStrings = UiStrings::default(),
) -> SeleneMenuFactory {
  {
    ui_strings,
    start_menu: SeleneStartMenu::new(ui_strings~),
    gallery_menu: SeleneGalleryMenu::new(ui_strings~),
    settings_menu: SeleneSettingsMenu::new(ui_strings~),
    credits_menu: SeleneCreditsMenu::new(ui_strings~),
    loading_menu: SeleneLoadingMenu::new(),
  }
}

///|
pub fn SeleneMenuFactory::push_start_menu_action(
  self : SeleneMenuFactory,
  action : @ui_menu.StartMenuAction,
) -> Unit {
  self.start_menu.push_action(action)
}

///|
pub fn SeleneMenuFactory::push_start_gate_action(
  self : SeleneMenuFactory,
  action : @ui_menu.StartGateAction,
) -> Unit {
  self.start_menu.push_gate_action(action)
}

///|
pub fn SeleneMenuFactory::push_start_logo_done(
  self : SeleneMenuFactory,
) -> Unit {
  self.start_menu.push_logo_done()
}

///|
pub fn SeleneMenuFactory::push_start_locale(
  self : SeleneMenuFactory,
  code : String,
) -> Unit {
  self.start_menu.push_locale_code(code)
}

///|
pub fn SeleneMenuFactory::push_gallery_action(
  self : SeleneMenuFactory,
  action : @ui_menu.GalleryAction,
) -> Unit {
  self.gallery_menu.push_action(action)
}

///|
pub fn SeleneMenuFactory::push_settings_action(
  self : SeleneMenuFactory,
  action : @ui_menu.SettingsAction,
) -> Unit {
  self.settings_menu.push_action(action)
}

///|
pub fn SeleneMenuFactory::push_credits_back(self : SeleneMenuFactory) -> Unit {
  self.credits_menu.push_back()
}

///|
pub fn SeleneMenuFactory::ui_overlay_commands(
  self : SeleneMenuFactory,
  viewport_w? : Double = 1280.0,
  viewport_h? : Double = 720.0,
) -> Array[@selene_render2d_types.DrawCommand2D] {
  let commands : Array[@selene_render2d_types.DrawCommand2D] = []
  commands.append(self.start_menu.render_commands(viewport_w~, viewport_h~))
  commands.append(self.settings_menu.render_commands(viewport_w~, viewport_h~))
  commands.append(self.gallery_menu.render_commands(viewport_w~, viewport_h~))
  commands.append(self.credits_menu.render_commands(viewport_w~, viewport_h~))
  commands.append(self.loading_menu.render_commands(viewport_w~, viewport_h~))
  commands
}

///|
pub fn SeleneMenuFactory::ui_overlay_provider(
  self : SeleneMenuFactory,
  viewport_w? : Double = 1280.0,
  viewport_h? : Double = 720.0,
) -> () -> Array[@selene_render2d_types.DrawCommand2D] {
  () => self.ui_overlay_commands(viewport_w~, viewport_h~)
}

///|
pub impl @ui_menu.MenuFactory for SeleneMenuFactory with create_start_menu(
  self,
  save_store~,
  background~,
  show_credits~,
) {
  ignore(save_store)
  ignore(background)
  ignore(show_credits)
  self.start_menu
}

///|
pub impl @ui_menu.MenuFactory for SeleneMenuFactory with create_gallery_menu(
  self,
  background~,
) {
  ignore(background)
  self.gallery_menu
}

///|
pub impl @ui_menu.MenuFactory for SeleneMenuFactory with create_settings_menu(
  self,
  audio~,
  background~,
  show_credits~,
) {
  ignore(audio)
  ignore(background)
  ignore(show_credits)
  self.settings_menu
}

///|
pub impl @ui_menu.MenuFactory for SeleneMenuFactory with create_credits_menu(
  self,
  background~,
) {
  ignore(background)
  self.credits_menu
}

///|
pub impl @ui_menu.MenuFactory for SeleneMenuFactory with create_loading_menu(
  self,
) {
  self.loading_menu
}
