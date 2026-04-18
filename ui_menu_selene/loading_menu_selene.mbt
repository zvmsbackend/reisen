///|
struct SeleneLoadingMenuTextTheme {
  title : SeleneMenuTextStyle
  body : SeleneMenuTextStyle
}

///|
pub impl Default for SeleneLoadingMenuTextTheme with default() {
  {
    title: {
      font: None,
      family: "sans-serif",
      size: 28.0,
      color_r: 245,
      color_g: 245,
      color_b: 250,
      color_a: 1.0,
    },
    body: {
      font: None,
      family: "sans-serif",
      size: 16.0,
      color_r: 200,
      color_g: 210,
      color_b: 230,
      color_a: 1.0,
    },
  }
}

///|
struct SeleneLoadingMenu {
  text_theme : SeleneLoadingMenuTextTheme
  mut text : String
  mut visible : Bool
}

///|
fn SeleneLoadingMenu::new(
  text_theme? : SeleneLoadingMenuTextTheme = SeleneLoadingMenuTextTheme::default(),
) -> SeleneLoadingMenu {
  { text_theme, text: "", visible: false }
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

///|
fn SeleneLoadingMenu::render_commands(
  self : SeleneLoadingMenu,
  viewport_w? : Double = 1280.0,
  viewport_h? : Double = 720.0,
) -> Array[@selene_render2d_types.DrawCommand2D] {
  if !self.visible {
    return []
  }
  let title_style = self.text_theme.title
  let body_style = self.text_theme.body
  let commands : Array[@selene_render2d_types.DrawCommand2D] = [
    Rect({
      alpha_mode: Blend,
      blend_mode: Alpha,
      rect: {
        position: Vec2(viewport_w / 2.0 - 200.0, viewport_h / 2.0 - 80.0),
        size: Vec2(400.0, 160.0),
      },
      transform: @selene_math.Transform::identity(),
      fill_color: { r: 20, g: 28, b: 40, a: 0.95 },
      stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
    }),
    Text({
      blend_mode: Alpha,
      text: "Loading...",
      position: Vec2(viewport_w / 2.0, viewport_h / 2.0 - 40.0),
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
        baseline: Center,
      },
    }),
  ]
  if self.text != "" {
    commands.push(
      Text({
        blend_mode: Alpha,
        text: self.text,
        position: Vec2(viewport_w / 2.0, viewport_h / 2.0 + 30.0),
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
    )
  }
  commands
}
