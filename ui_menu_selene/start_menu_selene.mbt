///|
pub struct SeleneStartMenu {
  mut ui_strings : UiStrings
  mut pending_action : @ui_menu.StartMenuAction
  mut pending_gate_action : @ui_menu.StartGateAction
  mut pending_logo_action : @ui_menu.StartLogoAction
  mut pending_locale_action : @ui_menu.StartLocaleAction
  mut locale_codes : Array[String]
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
    locale_codes: [],
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
  let result : @ui_menu.StartGateAction = match self.pending_gate_action {
    NoAction => if self.take_confirm_edge() { Start } else { NoAction }
    other => other
  }
  self.pending_gate_action = NoAction
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
  let result : @ui_menu.StartLogoAction = match self.pending_logo_action {
    NoAction => if self.take_confirm_edge() { Done } else { NoAction }
    other => other
  }
  self.pending_logo_action = NoAction
  result
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with render_locale_picker(
  self,
  languages,
) {
  self.visible_mode = Some("locale")
  self.locale_codes = languages.map(language => language.1)
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with clear_locale_picker(self) {
  if self.visible_mode == Some("locale") {
    self.visible_mode = None
  }
  self.locale_codes = []
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with take_locale_action(self) {
  let result : @ui_menu.StartLocaleAction = match self.pending_locale_action {
    NoAction =>
      if self.take_confirm_edge() && !self.locale_codes.is_empty() {
        Select(self.locale_codes[0])
      } else {
        NoAction
      }
    other => other
  }
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
  let result : @ui_menu.StartMenuAction = match self.pending_action {
    NoAction =>
      if self.visible_mode == Some("start") && self.take_confirm_edge() {
        NewGame
      } else {
        NoAction
      }
    other => other
  }
  self.pending_action = NoAction
  result
}

///|
pub fn SeleneStartMenu::render_commands(
  self : SeleneStartMenu,
  viewport_w? : Double = 1280.0,
  viewport_h? : Double = 720.0,
) -> Array[@selene_render2d_types.DrawCommand2D] {
  match self.visible_mode {
    None => []
    Some("gate") => {
      let commands : Array[@selene_render2d_types.DrawCommand2D] = [
        Rect({
          rect: {
            position: Vec2D(viewport_w / 2.0 - 200.0, viewport_h / 2.0 - 60.0),
            size: Vec2D(400.0, 120.0),
          },
          transform: @selene_math.Transform::identity(),
          fill_color: { r: 20, g: 28, b: 40, a: 0.9 },
          stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
        }),
        Text({
          text: self.ui_strings.start_gate_click_to_start,
          position: Vec2D(viewport_w / 2.0, viewport_h / 2.0),
          transform: @selene_math.Transform::identity(),
          style: {
            font: None,
            family: "sans-serif",
            size: 32.0,
            color: { r: 245, g: 245, b: 250, a: 1.0 },
            align: Center,
            baseline: Center,
          },
        }),
      ]
      commands
    }
    Some("logo") => []
    Some("locale") => {
      let commands : Array[@selene_render2d_types.DrawCommand2D] = [
        Rect({
          rect: {
            position: Vec2D(viewport_w / 2.0 - 200.0, viewport_h / 2.0 - 150.0),
            size: Vec2D(400.0, 300.0),
          },
          transform: @selene_math.Transform::identity(),
          fill_color: { r: 20, g: 28, b: 40, a: 0.9 },
          stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
        }),
        Text({
          text: "Select Language",
          position: Vec2D(viewport_w / 2.0, viewport_h / 2.0 - 120.0),
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
        Text({
          text: "(Language selector UI placeholder)",
          position: Vec2D(viewport_w / 2.0, viewport_h / 2.0),
          transform: @selene_math.Transform::identity(),
          style: {
            font: None,
            family: "sans-serif",
            size: 20.0,
            color: { r: 200, g: 210, b: 230, a: 1.0 },
            align: Center,
            baseline: Center,
          },
        }),
      ]
      commands
    }
    Some("start") => {
      let commands : Array[@selene_render2d_types.DrawCommand2D] = [
        Rect({
          rect: {
            position: Vec2D(viewport_w / 2.0 - 250.0, viewport_h / 2.0 - 200.0),
            size: Vec2D(500.0, 400.0),
          },
          transform: @selene_math.Transform::identity(),
          fill_color: { r: 20, g: 28, b: 40, a: 0.9 },
          stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
        }),
      ]
      let mut y = viewport_h / 2.0 - 160.0
      let button_texts = [
        "New Game", "Continue", "Load", "Settings", "Gallery", "Credits",
      ]
      for text in button_texts {
        commands.push(
          Text({
            text,
            position: Vec2D(viewport_w / 2.0, y),
            transform: @selene_math.Transform::identity(),
            style: {
              font: None,
              family: "sans-serif",
              size: 24.0,
              color: { r: 230, g: 238, b: 250, a: 1.0 },
              align: Center,
              baseline: Center,
            },
          }),
        )
        y += 50.0
      }
      commands
    }
    _ => []
  }
}
