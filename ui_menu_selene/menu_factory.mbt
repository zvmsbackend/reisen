///|
fn SeleneMenuTextStyle::with_family(
  self : SeleneMenuTextStyle,
  family : String,
) -> SeleneMenuTextStyle {
  {
    font: self.font,
    family,
    size: self.size,
    color_r: self.color_r,
    color_g: self.color_g,
    color_b: self.color_b,
    color_a: self.color_a,
  }
}

///|
fn SeleneStartMenuTextTheme::with_family(
  self : SeleneStartMenuTextTheme,
  family : String,
) -> SeleneStartMenuTextTheme {
  {
    gate_title: self.gate_title.with_family(family),
    locale_title: self.locale_title.with_family(family),
    locale_empty: self.locale_empty.with_family(family),
    locale_option_selected: self.locale_option_selected.with_family(family),
    locale_option_normal: self.locale_option_normal.with_family(family),
    locale_hint: self.locale_hint.with_family(family),
    start_item: self.start_item.with_family(family),
  }
}

///|
fn SeleneGalleryMenuTextTheme::with_family(
  self : SeleneGalleryMenuTextTheme,
  family : String,
) -> SeleneGalleryMenuTextTheme {
  {
    title: self.title.with_family(family),
    body: self.body.with_family(family),
    hint: self.hint.with_family(family),
  }
}

///|
fn SeleneSettingsMenuTextTheme::with_family(
  self : SeleneSettingsMenuTextTheme,
  family : String,
) -> SeleneSettingsMenuTextTheme {
  {
    title: self.title.with_family(family),
    row: self.row.with_family(family),
    hint: self.hint.with_family(family),
    placeholder: self.placeholder.with_family(family),
  }
}

///|
fn SeleneCreditsMenuTextTheme::with_family(
  self : SeleneCreditsMenuTextTheme,
  family : String,
) -> SeleneCreditsMenuTextTheme {
  {
    title: self.title.with_family(family),
    body: self.body.with_family(family),
    hint: self.hint.with_family(family),
  }
}

///|
fn SeleneLoadingMenuTextTheme::with_family(
  self : SeleneLoadingMenuTextTheme,
  family : String,
) -> SeleneLoadingMenuTextTheme {
  { title: self.title.with_family(family), body: self.body.with_family(family) }
}

///|
pub struct SeleneMenuFactory {
  ui_strings : UiStrings
  save_namespace : String
  start_menu : SeleneStartMenu
  gallery_menu : SeleneGalleryMenu
  settings_menu : SeleneSettingsMenu
  credits_menu : SeleneCreditsMenu
  loading_menu : SeleneLoadingMenu
}

///|
pub fn SeleneMenuFactory::new(
  ui_strings? : UiStrings = UiStrings::default(),
  save_namespace? : String = "global",
  text_font_family? : String = "",
  start_menu_text_theme? : SeleneStartMenuTextTheme = SeleneStartMenuTextTheme::default(),
  gallery_menu_text_theme? : SeleneGalleryMenuTextTheme = SeleneGalleryMenuTextTheme::default(),
  settings_menu_text_theme? : SeleneSettingsMenuTextTheme = SeleneSettingsMenuTextTheme::default(),
  credits_menu_text_theme? : SeleneCreditsMenuTextTheme = SeleneCreditsMenuTextTheme::default(),
  loading_menu_text_theme? : SeleneLoadingMenuTextTheme = SeleneLoadingMenuTextTheme::default(),
) -> SeleneMenuFactory {
  let resolved_start_menu_text_theme = match text_font_family {
    "" => start_menu_text_theme
    _ => start_menu_text_theme.with_family(text_font_family)
  }
  let resolved_gallery_menu_text_theme = match text_font_family {
    "" => gallery_menu_text_theme
    _ => gallery_menu_text_theme.with_family(text_font_family)
  }
  let resolved_settings_menu_text_theme = match text_font_family {
    "" => settings_menu_text_theme
    _ => settings_menu_text_theme.with_family(text_font_family)
  }
  let resolved_credits_menu_text_theme = match text_font_family {
    "" => credits_menu_text_theme
    _ => credits_menu_text_theme.with_family(text_font_family)
  }
  let resolved_loading_menu_text_theme = match text_font_family {
    "" => loading_menu_text_theme
    _ => loading_menu_text_theme.with_family(text_font_family)
  }
  {
    ui_strings,
    save_namespace,
    start_menu: SeleneStartMenu::new(
      ui_strings~,
      text_theme=resolved_start_menu_text_theme,
    ),
    gallery_menu: SeleneGalleryMenu::new(
      ui_strings~,
      text_theme=resolved_gallery_menu_text_theme,
    ),
    settings_menu: SeleneSettingsMenu::new(
      ui_strings~,
      save_namespace~,
      text_theme=resolved_settings_menu_text_theme,
    ),
    credits_menu: SeleneCreditsMenu::new(
      ui_strings~,
      text_theme=resolved_credits_menu_text_theme,
    ),
    loading_menu: SeleneLoadingMenu::new(
      text_theme=resolved_loading_menu_text_theme,
    ),
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
  self.start_menu.set_save_store(save_store)
  self.start_menu.set_save_namespace(self.save_namespace)
  self.start_menu.set_show_credits(show_credits)
  ignore(background)
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
  self.settings_menu.set_audio(audio)
  self.settings_menu.set_background(background)
  self.settings_menu.set_show_credits(show_credits)
  self.settings_menu.set_save_namespace(self.save_namespace)
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
