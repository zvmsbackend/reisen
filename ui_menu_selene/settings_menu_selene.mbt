///|
pub struct SeleneSettingsMenu {
  mut ui_strings : UiStrings
  mut pending_action : @ui_menu.SettingsAction
  mut script_locale_json : String?
  mut script_default_locale_json : String?
  mut languages : Array[(String, String)]
  mut locale : String
  mut context : @ui_menu.SettingsContext
  mut view_mode : @ui_menu.SettingsViewMode
  mut last_escape_down : Bool
  mut visible : Bool
}

///|
pub fn SeleneSettingsMenu::new(
  ui_strings? : UiStrings = UiStrings::default(),
) -> SeleneSettingsMenu {
  {
    ui_strings,
    pending_action: NoAction,
    script_locale_json: None,
    script_default_locale_json: None,
    languages: [],
    locale: "",
    context: FromStartMenu,
    view_mode: Settings,
    last_escape_down: false,
    visible: false,
  }
}

///|
fn SeleneSettingsMenu::take_back_edge(self : SeleneSettingsMenu) -> Bool {
  let escape_down = @selene_inputs.is_pressed(@selene_inputs.Escape)
  let triggered = escape_down && !self.last_escape_down
  self.last_escape_down = escape_down
  triggered
}

///|
pub fn SeleneSettingsMenu::push_action(
  self : SeleneSettingsMenu,
  action : @ui_menu.SettingsAction,
) -> Unit {
  self.pending_action = action
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with set_ui_strings(
  self,
  ui_strings,
) {
  self.ui_strings = ui_strings
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with set_script_localization(
  self,
  script_locale_json~,
  script_default_locale_json~,
) {
  self.script_locale_json = script_locale_json
  self.script_default_locale_json = script_default_locale_json
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with set_languages(
  self,
  languages,
) {
  self.languages = languages
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with set_locale(
  self,
  locale,
) {
  self.locale = locale
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with set_context(
  self,
  context,
) {
  self.context = context
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with set_view_mode(
  self,
  view_mode,
) {
  self.view_mode = view_mode
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with render(self) {
  self.visible = true
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with clear(self) {
  self.visible = false
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with take_action(self) {
  let result : @ui_menu.SettingsAction = match self.pending_action {
    NoAction => if self.take_back_edge() { Back } else { NoAction }
    other => other
  }
  self.pending_action = NoAction
  result
}

///|
pub fn SeleneSettingsMenu::render_commands(
  self : SeleneSettingsMenu,
  viewport_w? : Double = 1280.0,
  viewport_h? : Double = 720.0,
) -> Array[@selene_render2d_types.DrawCommand2D] {
  if !self.visible {
    return []
  }
  let commands : Array[@selene_render2d_types.DrawCommand2D] = []
  let panel_rect : @selene_math.Rect = {
    position: Vec2D(viewport_w / 2.0 - 300.0, viewport_h / 2.0 - 250.0),
    size: Vec2D(600.0, 500.0),
  }
  commands.push(
    Rect({
      rect: panel_rect,
      transform: @selene_math.Transform::identity(),
      fill_color: { r: 20, g: 28, b: 40, a: 0.92 },
      stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
    }),
  )
  let title = match self.view_mode {
    Settings => "Settings"
    SaveList => "Save Game"
    LoadList => "Load Game"
  }
  commands.push(
    Text({
      text: title,
      position: Vec2D(viewport_w / 2.0, viewport_h / 2.0 - 210.0),
      transform: @selene_math.Transform::identity(),
      style: {
        font: None,
        family: "sans-serif",
        size: 32.0,
        color: { r: 245, g: 245, b: 250, a: 1.0 },
        align: @selene_math.HAlign::Center,
        baseline: @selene_math.VAlign::Top,
      },
    }),
  )
  match self.view_mode {
    Settings => {
      commands.push(
        Text({
          text: "Language: \{self.locale}",
          position: Vec2D(viewport_w / 2.0 - 280.0, viewport_h / 2.0 - 150.0),
          transform: @selene_math.Transform::identity(),
          style: {
            font: None,
            family: "sans-serif",
            size: 20.0,
            color: { r: 230, g: 238, b: 250, a: 1.0 },
            align: @selene_math.HAlign::Left,
            baseline: @selene_math.VAlign::Top,
          },
        }),
      )
      commands.push(
        Text({
          text: match self.context {
            FromStartMenu => "Context: Start Menu"
            FromMidgame => "Context: Midgame"
          },
          position: Vec2D(viewport_w / 2.0 - 280.0, viewport_h / 2.0 - 110.0),
          transform: @selene_math.Transform::identity(),
          style: {
            font: None,
            family: "sans-serif",
            size: 20.0,
            color: { r: 230, g: 238, b: 250, a: 1.0 },
            align: @selene_math.HAlign::Left,
            baseline: @selene_math.VAlign::Top,
          },
        }),
      )
      commands.push(
        Text({
          text: "(Press ESC to return)",
          position: Vec2D(viewport_w / 2.0, viewport_h / 2.0 + 180.0),
          transform: @selene_math.Transform::identity(),
          style: {
            font: None,
            family: "sans-serif",
            size: 16.0,
            color: { r: 180, g: 190, b: 210, a: 0.8 },
            align: @selene_math.HAlign::Center,
            baseline: @selene_math.VAlign::Top,
          },
        }),
      )
    }
    SaveList | LoadList =>
      commands.push(
        Text({
          text: "(Slot management - press ESC to return)",
          position: Vec2D(viewport_w / 2.0, viewport_h / 2.0),
          transform: @selene_math.Transform::identity(),
          style: {
            font: None,
            family: "sans-serif",
            size: 20.0,
            color: { r: 200, g: 210, b: 230, a: 1.0 },
            align: @selene_math.HAlign::Center,
            baseline: @selene_math.VAlign::Center,
          },
        }),
      )
  }
  commands
}
