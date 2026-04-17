///|
pub struct SeleneGalleryMenuTextTheme {
  title : SeleneMenuTextStyle
  body : SeleneMenuTextStyle
  hint : SeleneMenuTextStyle
}

///|
pub impl Default for SeleneGalleryMenuTextTheme with default() {
  {
    title: {
      font: None,
      family: "sans-serif",
      size: 32.0,
      color_r: 245,
      color_g: 245,
      color_b: 250,
      color_a: 1.0,
    },
    body: {
      font: None,
      family: "sans-serif",
      size: 20.0,
      color_r: 200,
      color_g: 210,
      color_b: 230,
      color_a: 1.0,
    },
    hint: {
      font: None,
      family: "sans-serif",
      size: 16.0,
      color_r: 180,
      color_g: 190,
      color_b: 210,
      color_a: 0.8,
    },
  }
}

///|
pub struct SeleneGalleryMenu {
  mut ui_strings : UiStrings
  text_theme : SeleneGalleryMenuTextTheme
  mut pending_action : @ui_menu.GalleryAction
  mut script_locale_json : String?
  mut script_default_locale_json : String?
  mut last_escape_down : Bool
  mut visible : Bool
}

///|
pub fn SeleneGalleryMenu::new(
  ui_strings? : UiStrings = UiStrings::default(),
  text_theme? : SeleneGalleryMenuTextTheme = SeleneGalleryMenuTextTheme::default(),
) -> SeleneGalleryMenu {
  {
    ui_strings,
    text_theme,
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
  let result : @ui_menu.GalleryAction = match self.pending_action {
    NoAction => if self.take_back_edge() { Back } else { NoAction }
    other => other
  }
  self.pending_action = NoAction
  result
}

///|
pub fn SeleneGalleryMenu::render_commands(
  self : SeleneGalleryMenu,
  viewport_w? : Double = 1280.0,
  viewport_h? : Double = 720.0,
) -> Array[@selene_render2d_types.DrawCommand2D] {
  if !self.visible {
    return []
  }
  let title_style = self.text_theme.title
  let body_style = self.text_theme.body
  let hint_style = self.text_theme.hint
  let commands : Array[@selene_render2d_types.DrawCommand2D] = [
    Rect({
      rect: {
        position: Vec2D(viewport_w / 2.0 - 300.0, viewport_h / 2.0 - 200.0),
        size: Vec2D(600.0, 400.0),
      },
      transform: @selene_math.Transform::identity(),
      fill_color: { r: 20, g: 28, b: 40, a: 0.92 },
      stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
    }),
    Text({
      text: "Gallery",
      position: Vec2D(viewport_w / 2.0, viewport_h / 2.0 - 160.0),
      transform: @selene_math.Transform::identity(),
      style: {
        font: title_style.font,
        family: title_style.family,
        size: title_style.size,
        color: {
          r: title_style.color_r,
          g: title_style.color_g,
          b: title_style.color_b,
          a: title_style.color_a,
        },
        align: Center,
        baseline: Top,
      },
    }),
    Text({
      text: "(Gallery items would be displayed here)",
      position: Vec2D(viewport_w / 2.0, viewport_h / 2.0),
      transform: @selene_math.Transform::identity(),
      style: {
        font: body_style.font,
        family: body_style.family,
        size: body_style.size,
        color: {
          r: body_style.color_r,
          g: body_style.color_g,
          b: body_style.color_b,
          a: body_style.color_a,
        },
        align: Center,
        baseline: Center,
      },
    }),
    Text({
      text: "(Press ESC to return)",
      position: Vec2D(viewport_w / 2.0, viewport_h / 2.0 + 140.0),
      transform: @selene_math.Transform::identity(),
      style: {
        font: hint_style.font,
        family: hint_style.family,
        size: hint_style.size,
        color: {
          r: hint_style.color_r,
          g: hint_style.color_g,
          b: hint_style.color_b,
          a: hint_style.color_a,
        },
        align: Center,
        baseline: Top,
      },
    }),
  ]
  commands
}
