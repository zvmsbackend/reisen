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
  save_namespace : String
  mut ui_strings : UiStrings
  text_theme : SeleneGalleryMenuTextTheme
  show_locked : Bool
  mut background : String
  mut pending_action : @ui_menu.GalleryAction
  mut script_locale_json : String?
  mut script_default_locale_json : String?
  mut active_id : String?
  mut selected_index : Int
  mut last_enter_down : Bool
  mut last_space_down : Bool
  mut last_left_down : Bool
  mut last_right_down : Bool
  mut last_up_down : Bool
  mut last_down_down : Bool
  mut last_escape_down : Bool
  mut visible : Bool
}

///|
pub fn SeleneGalleryMenu::new(
  save_namespace? : String = "global",
  ui_strings? : UiStrings = UiStrings::default(),
  show_locked? : Bool = true,
  text_theme? : SeleneGalleryMenuTextTheme = SeleneGalleryMenuTextTheme::default(),
) -> SeleneGalleryMenu {
  {
    save_namespace,
    ui_strings,
    text_theme,
    show_locked,
    background: "",
    pending_action: NoAction,
    script_locale_json: None,
    script_default_locale_json: None,
    active_id: None,
    selected_index: 0,
    last_enter_down: false,
    last_space_down: false,
    last_left_down: false,
    last_right_down: false,
    last_up_down: false,
    last_down_down: false,
    last_escape_down: false,
    visible: false,
  }
}

///|
fn SeleneGalleryMenu::gallery_tiles(
  self : SeleneGalleryMenu,
) -> Array[@ui_menu.GalleryTileState] {
  @ui_menu.gallery_tiles_from_registry(
    self.save_namespace,
    self.show_locked,
    self.script_locale_json,
    self.script_default_locale_json,
  )
}

///|
fn SeleneGalleryMenu::normalize_selection(self : SeleneGalleryMenu) -> Unit {
  let tiles = self.gallery_tiles()
  if tiles.is_empty() {
    self.selected_index = 0
    return
  }
  let count = tiles.length()
  if self.selected_index < 0 {
    self.selected_index = count - 1
  }
  if self.selected_index >= count {
    self.selected_index = 0
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
fn SeleneGalleryMenu::take_confirm_edge(self : SeleneGalleryMenu) -> Bool {
  let enter_down = @selene_inputs.is_pressed(@selene_inputs.Enter)
  let space_down = @selene_inputs.is_pressed(@selene_inputs.Space)
  let triggered = (enter_down && !self.last_enter_down) ||
    (space_down && !self.last_space_down)
  self.last_enter_down = enter_down
  self.last_space_down = space_down
  triggered
}

///|
fn SeleneGalleryMenu::take_left_edge(self : SeleneGalleryMenu) -> Bool {
  let down = @selene_inputs.is_pressed(@selene_inputs.ArrowLeft)
  let triggered = down && !self.last_left_down
  self.last_left_down = down
  triggered
}

///|
fn SeleneGalleryMenu::take_right_edge(self : SeleneGalleryMenu) -> Bool {
  let down = @selene_inputs.is_pressed(@selene_inputs.ArrowRight)
  let triggered = down && !self.last_right_down
  self.last_right_down = down
  triggered
}

///|
fn SeleneGalleryMenu::take_up_edge(self : SeleneGalleryMenu) -> Bool {
  let down = @selene_inputs.is_pressed(@selene_inputs.ArrowUp)
  let triggered = down && !self.last_up_down
  self.last_up_down = down
  triggered
}

///|
fn SeleneGalleryMenu::take_down_edge(self : SeleneGalleryMenu) -> Bool {
  let down = @selene_inputs.is_pressed(@selene_inputs.ArrowDown)
  let triggered = down && !self.last_down_down
  self.last_down_down = down
  triggered
}

///|
fn SeleneGalleryMenu::input_action(
  self : SeleneGalleryMenu,
) -> @ui_menu.GalleryAction {
  if self.take_back_edge() {
    return match self.active_id {
      Some(_) => Close
      None => Back
    }
  }

  if self.active_id is Some(_) {
    if self.take_left_edge() {
      return Prev
    }
    if self.take_right_edge() {
      return Next
    }
    if self.take_confirm_edge() {
      let tiles = self.gallery_tiles()
      match self.active_id {
        Some(active_id) =>
          match @ui_menu.find_gallery_tile(tiles, active_id) {
            Some(tile) =>
              match tile.replay_label {
                Some(label) => Replay(label)
                None => Close
              }
            None => Close
          }
        None => NoAction
      }
    } else {
      NoAction
    }
  } else {
    let mut moved = false
    let tiles = self.gallery_tiles()
    if !tiles.is_empty() {
      let columns = 3
      if self.take_left_edge() {
        self.selected_index -= 1
        moved = true
      }
      if self.take_right_edge() {
        self.selected_index += 1
        moved = true
      }
      if self.take_up_edge() {
        self.selected_index -= columns
        moved = true
      }
      if self.take_down_edge() {
        self.selected_index += columns
        moved = true
      }
      if moved {
        self.normalize_selection()
      }
      if self.take_confirm_edge() {
        self.normalize_selection()
        let tile = tiles[self.selected_index]
        if tile.unlocked {
          return Open(tile.id)
        }
      }
    }
    NoAction
  }
}

///|
fn SeleneGalleryMenu::apply_action_state(
  self : SeleneGalleryMenu,
  action : @ui_menu.GalleryAction,
) -> Unit {
  let tiles = self.gallery_tiles()
  self.active_id = @ui_menu.reduce_gallery_active_id(
    action,
    self.active_id,
    tiles,
  )
  match action {
    Open(id) =>
      match @ui_menu.find_gallery_tile(tiles, id) {
        Some(tile) =>
          if tile.unlocked {
            for i, t in tiles {
              if t.id == id {
                self.selected_index = i
                break
              }
            }
          }
        None => ()
      }
    _ => ()
  }
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
pub fn SeleneGalleryMenu::set_background(
  self : SeleneGalleryMenu,
  background : String,
) -> Unit {
  self.background = background
}

///|
pub impl @ui_menu.GalleryMenu for SeleneGalleryMenu with render(self) {
  self.visible = true
  self.normalize_selection()
}

///|
pub impl @ui_menu.GalleryMenu for SeleneGalleryMenu with clear(self) {
  self.visible = false
  self.active_id = None
  self.selected_index = 0
}

///|
pub impl @ui_menu.GalleryMenu for SeleneGalleryMenu with take_action(self) {
  if !self.visible {
    return NoAction
  }
  let result : @ui_menu.GalleryAction = match self.pending_action {
    NoAction => self.input_action()
    other => other
  }
  self.pending_action = NoAction
  self.apply_action_state(result)
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
  let tiles = self.gallery_tiles()
  let active_tile = match self.active_id {
    Some(id) => @ui_menu.find_gallery_tile(tiles, id)
    None => None
  }
  let title_style = self.text_theme.title
  let body_style = self.text_theme.body
  let hint_style = self.text_theme.hint
  let commands : Array[@selene_render2d_types.DrawCommand2D] = []
  match fullscreen_image_command(self.background, viewport_w, viewport_h) {
    Some(background_cmd) => commands.push(background_cmd)
    None => ()
  }
  commands.append([
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
      text: self.ui_strings.start_menu_gallery,
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
  ])

  match active_tile {
    Some(tile) => {
      commands.push(
        Text({
          text: tile.title,
          position: Vec2D(viewport_w / 2.0, viewport_h / 2.0 - 110.0),
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
      )
      commands.push(
        Text({
          text: tile.image_id,
          position: Vec2D(viewport_w / 2.0, viewport_h / 2.0 - 70.0),
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
      )
      let replay_hint = match tile.replay_label {
        Some(_) => "  Enter=" + self.ui_strings.gallery_replay
        None => ""
      }
      let viewer_controls = "<- " +
        self.ui_strings.gallery_prev +
        "   -> " +
        self.ui_strings.gallery_next +
        replay_hint +
        "   Esc=" +
        self.ui_strings.gallery_close
      commands.push(
        Text({
          text: viewer_controls,
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
      )
    }
    None => {
      if tiles.is_empty() {
        commands.push(
          Text({
            text: self.ui_strings.gallery_locked,
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
        )
      } else {
        let row_h = 36.0
        let left = viewport_w / 2.0 - 250.0
        let top = viewport_h / 2.0 - 110.0
        let max_rows = 8
        let count = if tiles.length() > max_rows {
          max_rows
        } else {
          tiles.length()
        }
        for i in 0..<count {
          let tile = tiles[i]
          let selected = i == self.selected_index
          let label = if tile.unlocked {
            tile.title
          } else {
            self.ui_strings.gallery_locked
          }
          let prefix = if selected { "> " } else { "  " }
          commands.push(
            Text({
              text: prefix + label,
              position: Vec2D(left, top + row_h * i.to_double()),
              transform: @selene_math.Transform::identity(),
              style: {
                font: body_style.font,
                family: body_style.family,
                size: body_style.size,
                color: {
                  r: if selected {
                    245
                  } else {
                    body_style.color_r
                  },
                  g: if selected {
                    245
                  } else {
                    body_style.color_g
                  },
                  b: if selected {
                    250
                  } else {
                    body_style.color_b
                  },
                  a: if selected {
                    1.0
                  } else {
                    body_style.color_a
                  },
                },
                align: Left,
                baseline: Top,
              },
            }),
          )
        }
      }
      commands.push(
        Text({
          text: "↑↓←→ Move   Enter Open   Esc=" +
          self.ui_strings.gallery_back,
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
      )
    }
  }
  commands
}
