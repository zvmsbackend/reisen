///|
struct SeleneMenuTextStyle {
  font : @selene_asset_types.FontHandle?
  family : String
  size : Double
  color_r : UInt
  color_g : UInt
  color_b : UInt
  color_a : Double
}

///|
pub impl Default for SeleneMenuTextStyle with default() {
  {
    font: None,
    family: "sans-serif",
    size: 24.0,
    color_r: 230,
    color_g: 238,
    color_b: 250,
    color_a: 1.0,
  }
}

///|
struct SeleneStartMenuTextTheme {
  gate_title : SeleneMenuTextStyle
  locale_title : SeleneMenuTextStyle
  locale_empty : SeleneMenuTextStyle
  locale_option_selected : SeleneMenuTextStyle
  locale_option_normal : SeleneMenuTextStyle
  locale_hint : SeleneMenuTextStyle
  start_item : SeleneMenuTextStyle
}

///|
pub impl Default for SeleneStartMenuTextTheme with default() {
  {
    gate_title: {
      font: None,
      family: "sans-serif",
      size: 32.0,
      color_r: 245,
      color_g: 245,
      color_b: 250,
      color_a: 1.0,
    },
    locale_title: {
      font: None,
      family: "sans-serif",
      size: 28.0,
      color_r: 245,
      color_g: 245,
      color_b: 250,
      color_a: 1.0,
    },
    locale_empty: {
      font: None,
      family: "sans-serif",
      size: 20.0,
      color_r: 200,
      color_g: 210,
      color_b: 230,
      color_a: 1.0,
    },
    locale_option_selected: {
      font: None,
      family: "sans-serif",
      size: 24.0,
      color_r: 245,
      color_g: 245,
      color_b: 250,
      color_a: 1.0,
    },
    locale_option_normal: {
      font: None,
      family: "sans-serif",
      size: 24.0,
      color_r: 200,
      color_g: 210,
      color_b: 230,
      color_a: 1.0,
    },
    locale_hint: {
      font: None,
      family: "sans-serif",
      size: 16.0,
      color_r: 180,
      color_g: 190,
      color_b: 210,
      color_a: 1.0,
    },
    start_item: {
      font: None,
      family: "sans-serif",
      size: 24.0,
      color_r: 230,
      color_g: 238,
      color_b: 250,
      color_a: 1.0,
    },
  }
}

///|
pub struct SeleneStartMenu {
  mut ui_strings : UiStrings
  text_theme : SeleneStartMenuTextTheme
  mut background : String
  mut logo_url : String
  mut save_ns : String
  mut save_store : &@storage.SaveSlotStore
  mut show_credits : Bool
  mut pending_action : @ui_menu.StartMenuAction
  mut pending_gate_action : @ui_menu.StartGateAction
  mut pending_logo_action : @ui_menu.StartLogoAction
  mut pending_locale_action : @ui_menu.StartLocaleAction
  mut start_selected_index : Int
  mut locale_options : Array[(String, String)]
  mut locale_selected_index : Int
  mut last_enter_down : Bool
  mut last_space_down : Bool
  mut last_up_down : Bool
  mut last_down_down : Bool
  mut last_mouse_left_down : Bool
  mut last_mouse_right_down : Bool
  mut visible_mode : String?
  mut last_viewport_w : Double
  mut last_viewport_h : Double
}

///|
pub fn SeleneStartMenu::new(
  ui_strings? : UiStrings = UiStrings::default(),
  text_theme? : SeleneStartMenuTextTheme = SeleneStartMenuTextTheme::default(),
) -> SeleneStartMenu {
  {
    ui_strings,
    text_theme,
    background: "",
    logo_url: "",
    save_ns: "global",
    save_store: @storage.default_save_slot_storage(),
    show_credits: false,
    pending_action: NoAction,
    pending_gate_action: NoAction,
    pending_logo_action: NoAction,
    pending_locale_action: NoAction,
    start_selected_index: 0,
    locale_options: [],
    locale_selected_index: 0,
    last_enter_down: false,
    last_space_down: false,
    last_up_down: false,
    last_down_down: false,
    last_mouse_left_down: false,
    last_mouse_right_down: false,
    visible_mode: None,
    last_viewport_w: 1280.0,
    last_viewport_h: 720.0,
  }
}

///|
fn SeleneStartMenu::menu_rows(
  self : SeleneStartMenu,
) -> Array[(String, @ui_menu.StartMenuAction)] {
  let rows : Array[(String, @ui_menu.StartMenuAction)] = []
  rows.push((self.ui_strings.start_menu_new_game, NewGame))
  let entries = @storage.save_slot_store_entries_in(
    self.save_store,
    self.save_ns,
  )
  let continue_slot = @ui_menu.choose_continue_slot(entries)
  if continue_slot is Some(slot) {
    rows.push((self.ui_strings.start_menu_continue, Continue(slot)))
  }
  rows.push((self.ui_strings.start_menu_load, Load))
  rows.push((self.ui_strings.start_menu_settings, Settings))
  rows.push((self.ui_strings.start_menu_gallery, Gallery))
  if self.show_credits && self.ui_strings.menu_credits != "" {
    rows.push((self.ui_strings.menu_credits, Credits))
  }
  rows
}

///|
fn SeleneStartMenu::normalize_start_selection(self : SeleneStartMenu) -> Unit {
  let count = self.menu_rows().length()
  if count <= 0 {
    self.start_selected_index = 0
    return
  }
  if self.start_selected_index < 0 || self.start_selected_index >= count {
    self.start_selected_index = 0
  }
}

///|
fn SeleneStartMenu::normalize_locale_selection(self : SeleneStartMenu) -> Unit {
  if self.locale_options.is_empty() {
    self.locale_selected_index = 0
    return
  }
  let count = self.locale_options.length()
  if self.locale_selected_index < 0 || self.locale_selected_index >= count {
    self.locale_selected_index = 0
  }
}

///|
fn SeleneStartMenu::select_next_locale(self : SeleneStartMenu) -> Unit {
  if self.locale_options.is_empty() {
    return
  }
  let count = self.locale_options.length()
  self.locale_selected_index = (self.locale_selected_index + 1) % count
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
fn SeleneStartMenu::take_up_edge(self : SeleneStartMenu) -> Bool {
  let down = @selene_inputs.is_pressed(@selene_inputs.ArrowUp)
  let edge = down && !self.last_up_down
  self.last_up_down = down
  edge
}

///|
fn SeleneStartMenu::take_down_edge(self : SeleneStartMenu) -> Bool {
  let down = @selene_inputs.is_pressed(@selene_inputs.ArrowDown)
  let edge = down && !self.last_down_down
  self.last_down_down = down
  edge
}

///|
fn SeleneStartMenu::mouse_position(_self : SeleneStartMenu) -> (Double, Double) {
  let pos = @selene_inputs.mouse.pos
  (pos.0, pos.1)
}

///|
fn SeleneStartMenu::take_mouse_left_edge(self : SeleneStartMenu) -> Bool {
  let down = @selene_inputs.mouse.left_button
  let edge = down && !self.last_mouse_left_down
  self.last_mouse_left_down = down
  edge
}

///|
fn SeleneStartMenu::take_mouse_right_edge(self : SeleneStartMenu) -> Bool {
  let down = @selene_inputs.mouse.right_button
  let edge = down && !self.last_mouse_right_down
  self.last_mouse_right_down = down
  edge
}

///|
fn SeleneStartMenu::viewport_size(self : SeleneStartMenu) -> (Double, Double) {
  let w = if self.last_viewport_w > 0.0 { self.last_viewport_w } else { 1280.0 }
  let h = if self.last_viewport_h > 0.0 { self.last_viewport_h } else { 720.0 }
  (w, h)
}

///|
fn start_point_in_box(
  x : Double,
  y : Double,
  left : Double,
  top : Double,
  width : Double,
  height : Double,
) -> Bool {
  x >= left && x <= left + width && y >= top && y <= top + height
}

///|
fn SeleneStartMenu::hover_start_row(self : SeleneStartMenu) -> Unit {
  let rows = self.menu_rows()
  if rows.is_empty() {
    return
  }
  let (mx, my) = self.mouse_position()
  let (viewport_w, viewport_h) = self.viewport_size()
  let row_left = viewport_w / 2.0 - 180.0
  let row_width = 360.0
  let mut y = viewport_h / 2.0 - 160.0
  for i in 0..<rows.length() {
    if start_point_in_box(mx, my, row_left, y - 18.0, row_width, 36.0) {
      self.start_selected_index = i
      return
    }
    y += 50.0
  }
}

///|
fn SeleneStartMenu::hover_locale_option(self : SeleneStartMenu) -> Unit {
  if self.locale_options.is_empty() {
    return
  }
  let (mx, my) = self.mouse_position()
  let (viewport_w, viewport_h) = self.viewport_size()
  let left = viewport_w / 2.0 - 160.0
  let width = 320.0
  let mut y = viewport_h / 2.0 - 70.0
  for i in 0..<self.locale_options.length() {
    if start_point_in_box(mx, my, left, y - 16.0, width, 34.0) {
      self.locale_selected_index = i
      return
    }
    y += 40.0
  }
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
    NoAction =>
      if self.take_confirm_edge() || self.take_mouse_left_edge() {
        Start
      } else {
        NoAction
      }
    other => other
  }
  self.pending_gate_action = NoAction
  result
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with render_logo(self, url, _) {
  self.logo_url = url
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
    NoAction =>
      if self.take_confirm_edge() || self.take_mouse_left_edge() {
        Done
      } else {
        NoAction
      }
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
  self.locale_options = languages
  self.normalize_locale_selection()
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with clear_locale_picker(self) {
  if self.visible_mode == Some("locale") {
    self.visible_mode = None
  }
  self.locale_options = []
  self.locale_selected_index = 0
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with take_locale_action(self) {
  let enter_down = @selene_inputs.is_pressed(@selene_inputs.Enter)
  let space_down = @selene_inputs.is_pressed(@selene_inputs.Space)
  let enter_edge = enter_down && !self.last_enter_down
  let space_edge = space_down && !self.last_space_down
  self.last_enter_down = enter_down
  self.last_space_down = space_down

  if space_edge {
    self.select_next_locale()
  }

  self.hover_locale_option()
  let mouse_confirm = self.take_mouse_left_edge()
  let mouse_back = self.take_mouse_right_edge()

  let result : @ui_menu.StartLocaleAction = match self.pending_locale_action {
    NoAction =>
      if (enter_edge || mouse_confirm || mouse_back) &&
        !self.locale_options.is_empty() {
        Select(self.locale_options[self.locale_selected_index].1)
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
  self.normalize_start_selection()
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with clear(self) {
  self.visible_mode = None
}

///|
pub impl @ui_menu.StartMenu for SeleneStartMenu with take_action(self) {
  if self.visible_mode == Some("start") {
    let rows = self.menu_rows()
    let count = rows.length()
    if count > 0 {
      self.hover_start_row()
      self.normalize_start_selection()
      if self.take_up_edge() {
        self.start_selected_index = (self.start_selected_index - 1 + count) %
          count
      }
      if self.take_down_edge() {
        self.start_selected_index = (self.start_selected_index + 1) % count
      }
    }
  }
  let result : @ui_menu.StartMenuAction = match self.pending_action {
    NoAction => {
      let rows = self.menu_rows()
      if self.visible_mode == Some("start") &&
        (self.take_confirm_edge() || self.take_mouse_left_edge()) &&
        !rows.is_empty() {
        self.normalize_start_selection()
        rows[self.start_selected_index].1
      } else {
        NoAction
      }
    }
    other => other
  }
  self.pending_action = NoAction
  result
}

///|
pub fn SeleneStartMenu::set_save_namespace(
  self : SeleneStartMenu,
  save_namespace : String,
) -> Unit {
  self.save_ns = save_namespace
}

///|
pub fn SeleneStartMenu::set_save_store(
  self : SeleneStartMenu,
  save_store : &@storage.SaveSlotStore,
) -> Unit {
  self.save_store = save_store
}

///|
pub fn SeleneStartMenu::set_show_credits(
  self : SeleneStartMenu,
  show_credits : Bool,
) -> Unit {
  self.show_credits = show_credits
}

///|
pub fn SeleneStartMenu::set_background(
  self : SeleneStartMenu,
  background : String,
) -> Unit {
  self.background = background
}

///|
pub fn SeleneStartMenu::render_commands(
  self : SeleneStartMenu,
  viewport_w? : Double = 1280.0,
  viewport_h? : Double = 720.0,
) -> Array[@selene_render2d_types.DrawCommand2D] {
  self.last_viewport_w = viewport_w
  self.last_viewport_h = viewport_h
  match self.visible_mode {
    None => []
    Some("gate") => {
      let gate_title_style = self.text_theme.gate_title
      let commands : Array[@selene_render2d_types.DrawCommand2D] = []
      commands.append([
        Rect({
          alpha_mode: @selene_render.AlphaMode2D::Blend,
          blend_mode: @selene_render.BlendMode2D::Alpha,
          rect: {
            position: Vec2(viewport_w / 2.0 - 200.0, viewport_h / 2.0 - 60.0),
            size: Vec2(400.0, 120.0),
          },
          transform: @selene_math.Transform::identity(),
          fill_color: { r: 20, g: 28, b: 40, a: 0.9 },
          stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
        }),
        Text({
          blend_mode: @selene_render.BlendMode2D::Alpha,
          text: self.ui_strings.start_gate_click_to_start,
          position: Vec2(viewport_w / 2.0, viewport_h / 2.0),
          transform: @selene_math.Transform::identity(),
          style: {
            font: gate_title_style.font,
            family: gate_title_style.family,
            size: gate_title_style.size,
            color: {
              r: gate_title_style.color_r,
              g: gate_title_style.color_g,
              b: gate_title_style.color_b,
              a: gate_title_style.color_a,
            },
            align: Center,
            baseline: Center,
          },
        }),
      ])
      commands
    }
    Some("logo") => {
      let commands : Array[@selene_render2d_types.DrawCommand2D] = []
      match fullscreen_image_command(self.logo_url, viewport_w, viewport_h) {
        Some(logo_cmd) => commands.push(logo_cmd)
        None => ()
      }
      commands
    }
    Some("locale") => {
      let locale_title_style = self.text_theme.locale_title
      let locale_empty_style = self.text_theme.locale_empty
      let locale_selected_style = self.text_theme.locale_option_selected
      let locale_normal_style = self.text_theme.locale_option_normal
      let locale_hint_style = self.text_theme.locale_hint
      let commands : Array[@selene_render2d_types.DrawCommand2D] = []
      match fullscreen_image_command(self.background, viewport_w, viewport_h) {
        Some(background_cmd) => commands.push(background_cmd)
        None => ()
      }
      commands.append([
        Rect({
          alpha_mode: @selene_render.AlphaMode2D::Blend,
          blend_mode: @selene_render.BlendMode2D::Alpha,
          rect: {
            position: Vec2(viewport_w / 2.0 - 200.0, viewport_h / 2.0 - 150.0),
            size: Vec2(400.0, 300.0),
          },
          transform: @selene_math.Transform::identity(),
          fill_color: { r: 20, g: 28, b: 40, a: 0.9 },
          stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
        }),
        Text({
          blend_mode: @selene_render.BlendMode2D::Alpha,
          text: self.ui_strings.start_locale_title,
          position: Vec2(viewport_w / 2.0, viewport_h / 2.0 - 120.0),
          transform: @selene_math.Transform::identity(),
          style: {
            font: locale_title_style.font,
            family: locale_title_style.family,
            size: locale_title_style.size,
            color: {
              r: locale_title_style.color_r,
              g: locale_title_style.color_g,
              b: locale_title_style.color_b,
              a: locale_title_style.color_a,
            },
            align: Center,
            baseline: Center,
          },
        }),
      ])
      self.normalize_locale_selection()
      if self.locale_options.is_empty() {
        commands.push(
          Text({
            blend_mode: @selene_render.BlendMode2D::Alpha,
            text: "No language options",
            position: Vec2(viewport_w / 2.0, viewport_h / 2.0 - 10.0),
            transform: @selene_math.Transform::identity(),
            style: {
              font: locale_empty_style.font,
              family: locale_empty_style.family,
              size: locale_empty_style.size,
              color: {
                r: locale_empty_style.color_r,
                g: locale_empty_style.color_g,
                b: locale_empty_style.color_b,
                a: locale_empty_style.color_a,
              },
              align: Center,
              baseline: Center,
            },
          }),
        )
      } else {
        let mut y = viewport_h / 2.0 - 70.0
        for i = 0; i < self.locale_options.length(); i = i + 1 {
          let option = self.locale_options[i]
          let is_selected = i == self.locale_selected_index
          if is_selected {
            commands.push(
              Rect({
                alpha_mode: @selene_render.AlphaMode2D::Blend,
                blend_mode: @selene_render.BlendMode2D::Alpha,
                rect: {
                  position: Vec2(viewport_w / 2.0 - 160.0, y - 16.0),
                  size: Vec2(320.0, 34.0),
                },
                transform: @selene_math.Transform::identity(),
                fill_color: { r: 70, g: 110, b: 160, a: 0.45 },
                stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
              }),
            )
          }
          commands.push(
            Text({
              blend_mode: @selene_render.BlendMode2D::Alpha,
              text: option.0,
              position: Vec2(viewport_w / 2.0, y),
              transform: @selene_math.Transform::identity(),
              style: {
                font: if is_selected {
                  locale_selected_style.font
                } else {
                  locale_normal_style.font
                },
                family: if is_selected {
                  locale_selected_style.family
                } else {
                  locale_normal_style.family
                },
                size: if is_selected {
                  locale_selected_style.size
                } else {
                  locale_normal_style.size
                },
                color: if is_selected {
                  {
                    r: locale_selected_style.color_r,
                    g: locale_selected_style.color_g,
                    b: locale_selected_style.color_b,
                    a: locale_selected_style.color_a,
                  }
                } else {
                  {
                    r: locale_normal_style.color_r,
                    g: locale_normal_style.color_g,
                    b: locale_normal_style.color_b,
                    a: locale_normal_style.color_a,
                  }
                },
                align: Center,
                baseline: Center,
              },
            }),
          )
          y += 40.0
        }
      }
      commands.push(
        Text({
          blend_mode: @selene_render.BlendMode2D::Alpha,
          text: "Space: Next  Enter: Confirm",
          position: Vec2(viewport_w / 2.0, viewport_h / 2.0 + 120.0),
          transform: @selene_math.Transform::identity(),
          style: {
            font: locale_hint_style.font,
            family: locale_hint_style.family,
            size: locale_hint_style.size,
            color: {
              r: locale_hint_style.color_r,
              g: locale_hint_style.color_g,
              b: locale_hint_style.color_b,
              a: locale_hint_style.color_a,
            },
            align: Center,
            baseline: Center,
          },
        }),
      )
      commands
    }
    Some("start") => {
      let start_item_style = self.text_theme.start_item
      let rows = self.menu_rows()
      self.normalize_start_selection()
      let commands : Array[@selene_render2d_types.DrawCommand2D] = []
      match fullscreen_image_command(self.background, viewport_w, viewport_h) {
        Some(background_cmd) => commands.push(background_cmd)
        None => ()
      }
      commands.push(
        Rect({
          alpha_mode: @selene_render.AlphaMode2D::Blend,
          blend_mode: @selene_render.BlendMode2D::Alpha,
          rect: {
            position: Vec2(viewport_w / 2.0 - 250.0, viewport_h / 2.0 - 200.0),
            size: Vec2(500.0, 400.0),
          },
          transform: @selene_math.Transform::identity(),
          fill_color: { r: 20, g: 28, b: 40, a: 0.9 },
          stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
        }),
      )
      let mut y = viewport_h / 2.0 - 160.0
      for i = 0; i < rows.length(); i = i + 1 {
        let row = rows[i]
        let is_selected = i == self.start_selected_index
        if is_selected {
          commands.push(
            Rect({
              alpha_mode: @selene_render.AlphaMode2D::Blend,
              blend_mode: @selene_render.BlendMode2D::Alpha,
              rect: {
                position: Vec2(viewport_w / 2.0 - 180.0, y - 18.0),
                size: Vec2(360.0, 36.0),
              },
              transform: @selene_math.Transform::identity(),
              fill_color: { r: 70, g: 110, b: 160, a: 0.45 },
              stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
            }),
          )
        }
        commands.push(
          Text({
            blend_mode: @selene_render.BlendMode2D::Alpha,
            text: row.0,
            position: Vec2(viewport_w / 2.0, y),
            transform: @selene_math.Transform::identity(),
            style: {
              font: start_item_style.font,
              family: start_item_style.family,
              size: start_item_style.size,
              color: {
                r: if is_selected {
                  245
                } else {
                  start_item_style.color_r
                },
                g: if is_selected {
                  245
                } else {
                  start_item_style.color_g
                },
                b: if is_selected {
                  250
                } else {
                  start_item_style.color_b
                },
                a: start_item_style.color_a,
              },
              align: Center,
              baseline: Center,
            },
          }),
        )
        y += 50.0
      }
      commands.push(
        Text({
          blend_mode: @selene_render.BlendMode2D::Alpha,
          text: "[Up/Down] Select  [Enter/Space] Confirm",
          position: Vec2(viewport_w / 2.0, viewport_h / 2.0 + 160.0),
          transform: @selene_math.Transform::identity(),
          style: {
            font: start_item_style.font,
            family: start_item_style.family,
            size: 16.0,
            color: { r: 180, g: 190, b: 210, a: 1.0 },
            align: Center,
            baseline: Center,
          },
        }),
      )
      commands
    }
    _ => []
  }
}
