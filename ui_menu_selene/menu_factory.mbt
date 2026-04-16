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
fn SeleneMenuFactory::overlay_panel_label(self : SeleneMenuFactory) -> String? {
  if self.loading_menu.visible {
    return Some(
      match self.loading_menu.text {
        "" => "Loading..."
        text => "Loading: \{text}"
      },
    )
  }
  if self.credits_menu.visible {
    return Some("Credits")
  }
  if self.settings_menu.visible {
    return Some("Settings")
  }
  if self.gallery_menu.visible {
    return Some("Gallery")
  }
  match self.start_menu.visible_mode {
    Some(mode) => Some("Start (\{mode})")
    None => None
  }
}

///|
pub fn SeleneMenuFactory::ui_overlay_commands(
  self : SeleneMenuFactory,
  viewport_w? : Double = 1280.0,
  viewport_h? : Double = 720.0,
) -> Array[@selene_render2d_types.DrawCommand2D] {
  match self.overlay_panel_label() {
    None => []
    Some(label) => {
      let panel_rect : @selene_math.Rect = {
        position: @selene_math.Vec2D(24.0, viewport_h - 120.0),
        size: @selene_math.Vec2D(viewport_w - 48.0, 88.0),
      }
      let bg : @selene_render2d_types.RectDrawCommand2D = {
        rect: panel_rect,
        transform: @selene_math.Transform::identity(),
        fill_color: { r: 8, g: 12, b: 18, a: 0.78 },
        stroke_color: Some({ r: 228, g: 236, b: 248, a: 0.95 }),
      }
      let text : @selene_render2d_types.TextDrawCommand2D = {
        text: "Menu Overlay: \{label}",
        position: @selene_math.Vec2D(44.0, viewport_h - 78.0),
        transform: @selene_math.Transform::identity(),
        style: {
          font: None,
          family: "sans-serif",
          size: 28.0,
          color: { r: 236, g: 242, b: 252, a: 1.0 },
          align: @selene_math.HAlign::Left,
          baseline: @selene_math.VAlign::Top,
        },
      }
      [Rect(bg), Text(text)]
    }
  }
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
