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

///|
pub fn SeleneLoadingMenu::render_commands(
  self : SeleneLoadingMenu,
  viewport_w? : Double = 1280.0,
  viewport_h? : Double = 720.0,
) -> Array[@selene_render2d_types.DrawCommand2D] {
  if !self.visible {
    return []
  }
  let commands : Array[@selene_render2d_types.DrawCommand2D] = [
    Rect({
      rect: {
        position: Vec2D(viewport_w / 2.0 - 200.0, viewport_h / 2.0 - 80.0),
        size: Vec2D(400.0, 160.0),
      },
      transform: @selene_math.Transform::identity(),
      fill_color: { r: 20, g: 28, b: 40, a: 0.95 },
      stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
    }),
    Text({
      text: "Loading...",
      position: Vec2D(viewport_w / 2.0, viewport_h / 2.0 - 40.0),
      transform: @selene_math.Transform::identity(),
      style: {
        font: None,
        family: "sans-serif",
        size: 28.0,
        color: { r: 245, g: 245, b: 250, a: 1.0 },
        align: Center,
        baseline: Center,
      },
    }),
  ]
  if self.text != "" {
    commands.push(
      Text({
        text: self.text,
        position: Vec2D(viewport_w / 2.0, viewport_h / 2.0 + 30.0),
        transform: @selene_math.Transform::identity(),
        style: {
          font: None,
          family: "sans-serif",
          size: 16.0,
          color: { r: 200, g: 210, b: 230, a: 1.0 },
          align: Center,
          baseline: Center,
        },
      }),
    )
  }
  commands
}
