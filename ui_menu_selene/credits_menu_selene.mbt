///|
pub struct SeleneCreditsMenuTextTheme {
  title : SeleneMenuTextStyle
  body : SeleneMenuTextStyle
  hint : SeleneMenuTextStyle
}

///|
pub impl Default for SeleneCreditsMenuTextTheme with default() {
  {
    title: {
      font: None,
      family: "sans-serif",
      size: 36.0,
      color_r: 245,
      color_g: 245,
      color_b: 250,
      color_a: 1.0,
    },
    body: {
      font: None,
      family: "sans-serif",
      size: 18.0,
      color_r: 220,
      color_g: 228,
      color_b: 240,
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
pub struct SeleneCreditsMenu {
  mut ui_strings : UiStrings
  text_theme : SeleneCreditsMenuTextTheme
  mut pending_action : @ui_menu.CreditsAction
  mut text : String
  mut last_escape_down : Bool
  mut visible : Bool
}

///|
pub fn SeleneCreditsMenu::new(
  ui_strings? : UiStrings = UiStrings::default(),
  text_theme? : SeleneCreditsMenuTextTheme = SeleneCreditsMenuTextTheme::default(),
) -> SeleneCreditsMenu {
  {
    ui_strings,
    text_theme,
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
  let result : @ui_menu.CreditsAction = match self.pending_action {
    NoAction => if self.take_back_edge() { Back } else { NoAction }
    other => other
  }
  self.pending_action = NoAction
  result
}

///|
pub fn SeleneCreditsMenu::render_commands(
  self : SeleneCreditsMenu,
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
        position: Vec2D(viewport_w / 2.0 - 350.0, viewport_h / 2.0 - 280.0),
        size: Vec2D(700.0, 560.0),
      },
      transform: @selene_math.Transform::identity(),
      fill_color: { r: 20, g: 28, b: 40, a: 0.92 },
      stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
    }),
    Text({
      text: "Credits",
      position: Vec2D(viewport_w / 2.0, viewport_h / 2.0 - 240.0),
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
      text: self.text[:(self.text.length() / 2).max(0)].to_string(),
      position: Vec2D(viewport_w / 2.0, viewport_h / 2.0 - 160.0),
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
        baseline: Top,
      },
    }),
    Text({
      text: "(Press ESC to return)",
      position: Vec2D(viewport_w / 2.0, viewport_h / 2.0 + 220.0),
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
