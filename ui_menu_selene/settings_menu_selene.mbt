///|
pub struct SeleneSettingsMenuTextTheme {
  title : SeleneMenuTextStyle
  row : SeleneMenuTextStyle
  hint : SeleneMenuTextStyle
  placeholder : SeleneMenuTextStyle
}

///|
pub impl Default for SeleneSettingsMenuTextTheme with default() {
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
    row: {
      font: None,
      family: "sans-serif",
      size: 20.0,
      color_r: 230,
      color_g: 238,
      color_b: 250,
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
    placeholder: {
      font: None,
      family: "sans-serif",
      size: 20.0,
      color_r: 200,
      color_g: 210,
      color_b: 230,
      color_a: 1.0,
    },
  }
}

///|
pub struct SeleneSettingsMenu {
  mut ui_strings : UiStrings
  text_theme : SeleneSettingsMenuTextTheme
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
  text_theme? : SeleneSettingsMenuTextTheme = SeleneSettingsMenuTextTheme::default(),
) -> SeleneSettingsMenu {
  {
    ui_strings,
    text_theme,
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
  let title_style = self.text_theme.title
  let row_style = self.text_theme.row
  let hint_style = self.text_theme.hint
  let placeholder_style = self.text_theme.placeholder
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
        font: title_style.font,
        family: title_style.family,
        size: title_style.size,
        color: {
          r: title_style.color_r,
          g: title_style.color_g,
          b: title_style.color_b,
          a: title_style.color_a,
        },
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
            font: row_style.font,
            family: row_style.family,
            size: row_style.size,
            color: {
              r: row_style.color_r,
              g: row_style.color_g,
              b: row_style.color_b,
              a: row_style.color_a,
            },
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
            font: row_style.font,
            family: row_style.family,
            size: row_style.size,
            color: {
              r: row_style.color_r,
              g: row_style.color_g,
              b: row_style.color_b,
              a: row_style.color_a,
            },
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
            font: hint_style.font,
            family: hint_style.family,
            size: hint_style.size,
            color: {
              r: hint_style.color_r,
              g: hint_style.color_g,
              b: hint_style.color_b,
              a: hint_style.color_a,
            },
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
            font: placeholder_style.font,
            family: placeholder_style.family,
            size: placeholder_style.size,
            color: {
              r: placeholder_style.color_r,
              g: placeholder_style.color_g,
              b: placeholder_style.color_b,
              a: placeholder_style.color_a,
            },
            align: @selene_math.HAlign::Center,
            baseline: @selene_math.VAlign::Center,
          },
        }),
      )
  }
  commands
}
