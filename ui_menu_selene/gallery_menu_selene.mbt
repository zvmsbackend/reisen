///|
struct SeleneGalleryMenuTextTheme {
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
  mut last_mouse_left_down : Bool
  mut last_mouse_right_down : Bool
  mut visible : Bool
  mut last_viewport_w : Double
  mut last_viewport_h : Double
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
    last_mouse_left_down: false,
    last_mouse_right_down: false,
    visible: false,
    last_viewport_w: 1280.0,
    last_viewport_h: 720.0,
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
fn SeleneGalleryMenu::mouse_position(
  _self : SeleneGalleryMenu,
) -> (Double, Double) {
  let pos = @selene_inputs.mouse.pos
  (pos.0, pos.1)
}

///|
fn SeleneGalleryMenu::take_mouse_left_edge(self : SeleneGalleryMenu) -> Bool {
  let down = @selene_inputs.mouse.left_button
  let edge = down && !self.last_mouse_left_down
  self.last_mouse_left_down = down
  edge
}

///|
fn SeleneGalleryMenu::take_mouse_right_edge(self : SeleneGalleryMenu) -> Bool {
  let down = @selene_inputs.mouse.right_button
  let edge = down && !self.last_mouse_right_down
  self.last_mouse_right_down = down
  edge
}

///|
fn SeleneGalleryMenu::viewport_size(
  self : SeleneGalleryMenu,
) -> (Double, Double) {
  let w = if self.last_viewport_w > 0.0 { self.last_viewport_w } else { 1280.0 }
  let h = if self.last_viewport_h > 0.0 { self.last_viewport_h } else { 720.0 }
  (w, h)
}

///|
fn gallery_point_in_box(
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
fn gallery_prev_button_rect(
  viewport_w : Double,
  viewport_h : Double,
) -> @selene_math.Rect {
  {
    position: Vec2(viewport_w / 2.0 - 240.0, viewport_h / 2.0 + 125.0),
    size: Vec2(110.0, 34.0),
  }
}

///|
fn gallery_next_button_rect(
  viewport_w : Double,
  viewport_h : Double,
) -> @selene_math.Rect {
  {
    position: Vec2(viewport_w / 2.0 + 130.0, viewport_h / 2.0 + 125.0),
    size: Vec2(110.0, 34.0),
  }
}

///|
fn gallery_replay_button_rect(
  viewport_w : Double,
  viewport_h : Double,
) -> @selene_math.Rect {
  {
    position: Vec2(viewport_w / 2.0 - 55.0, viewport_h / 2.0 + 125.0),
    size: Vec2(110.0, 34.0),
  }
}

///|
fn gallery_close_button_rect(
  viewport_w : Double,
  viewport_h : Double,
) -> @selene_math.Rect {
  {
    position: Vec2(viewport_w / 2.0 - 55.0, viewport_h / 2.0 + 165.0),
    size: Vec2(110.0, 30.0),
  }
}

///|
fn SeleneGalleryMenu::hover_tile_row(self : SeleneGalleryMenu) -> Unit {
  if self.active_id is Some(_) {
    return
  }
  let tiles = self.gallery_tiles()
  if tiles.is_empty() {
    return
  }
  let (mx, my) = self.mouse_position()
  let (viewport_w, viewport_h) = self.viewport_size()
  let left = viewport_w / 2.0 - 250.0
  let top = viewport_h / 2.0 - 110.0
  let row_h = 36.0
  let max_rows = if tiles.length() > 8 { 8 } else { tiles.length() }
  for i in 0..<max_rows {
    let y = top + row_h * i.to_double()
    if gallery_point_in_box(mx, my, left, y, 500.0, row_h) {
      self.selected_index = i
      return
    }
  }
}

///|
fn SeleneGalleryMenu::input_action(
  self : SeleneGalleryMenu,
) -> @ui_menu.GalleryAction {
  self.hover_tile_row()
  let mouse_left = self.take_mouse_left_edge()
  let mouse_right = self.take_mouse_right_edge()

  if mouse_right {
    return match self.active_id {
      Some(_) => Close
      None => Back
    }
  }

  if self.take_back_edge() {
    return match self.active_id {
      Some(_) => Close
      None => Back
    }
  }

  if self.active_id is Some(_) {
    if mouse_left {
      let (viewport_w, viewport_h) = self.viewport_size()
      let (mx, my) = self.mouse_position()
      let prev_rect = gallery_prev_button_rect(viewport_w, viewport_h)
      let next_rect = gallery_next_button_rect(viewport_w, viewport_h)
      let replay_rect = gallery_replay_button_rect(viewport_w, viewport_h)
      let close_rect = gallery_close_button_rect(viewport_w, viewport_h)
      if gallery_point_in_box(
          mx,
          my,
          prev_rect.position.0,
          prev_rect.position.1,
          prev_rect.size.0,
          prev_rect.size.1,
        ) {
        return Prev
      }
      if gallery_point_in_box(
          mx,
          my,
          next_rect.position.0,
          next_rect.position.1,
          next_rect.size.0,
          next_rect.size.1,
        ) {
        return Next
      }
      let tiles = self.gallery_tiles()
      return match self.active_id {
        Some(active_id) =>
          match @ui_menu.find_gallery_tile(tiles, active_id) {
            Some(tile) =>
              if gallery_point_in_box(
                  mx,
                  my,
                  close_rect.position.0,
                  close_rect.position.1,
                  close_rect.size.0,
                  close_rect.size.1,
                ) {
                Close
              } else {
                match tile.replay_label {
                  Some(label) =>
                    if gallery_point_in_box(
                        mx,
                        my,
                        replay_rect.position.0,
                        replay_rect.position.1,
                        replay_rect.size.0,
                        replay_rect.size.1,
                      ) {
                      Replay(label)
                    } else {
                      Close
                    }
                  None => Close
                }
              }
            None => Close
          }
        None => NoAction
      }
    }
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
      if self.take_confirm_edge() || mouse_left {
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
  self.last_viewport_w = viewport_w
  self.last_viewport_h = viewport_h
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
      alpha_mode: @selene_render.AlphaMode2D::Blend,
      blend_mode: @selene_render.BlendMode2D::Alpha,
      rect: {
        position: Vec2(viewport_w / 2.0 - 300.0, viewport_h / 2.0 - 200.0),
        size: Vec2(600.0, 400.0),
      },
      transform: @selene_math.Transform::identity(),
      fill_color: { r: 20, g: 28, b: 40, a: 0.92 },
      stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
    }),
    Text({
      blend_mode: @selene_render.BlendMode2D::Alpha,
      text: self.ui_strings.start_menu_gallery,
      position: Vec2(viewport_w / 2.0, viewport_h / 2.0 - 160.0),
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
          blend_mode: @selene_render.BlendMode2D::Alpha,
          text: tile.title,
          position: Vec2(viewport_w / 2.0, viewport_h / 2.0 - 110.0),
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
          blend_mode: @selene_render.BlendMode2D::Alpha,
          text: tile.image_id,
          position: Vec2(viewport_w / 2.0, viewport_h / 2.0 - 70.0),
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
      let prev_rect = gallery_prev_button_rect(viewport_w, viewport_h)
      let next_rect = gallery_next_button_rect(viewport_w, viewport_h)
      let replay_rect = gallery_replay_button_rect(viewport_w, viewport_h)
      let close_rect = gallery_close_button_rect(viewport_w, viewport_h)
      commands.push(
        Rect({
          alpha_mode: @selene_render.AlphaMode2D::Blend,
          blend_mode: @selene_render.BlendMode2D::Alpha,
          rect: prev_rect,
          transform: @selene_math.Transform::identity(),
          fill_color: { r: 52, g: 78, b: 116, a: 0.65 },
          stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
        }),
      )
      commands.push(
        Text({
          blend_mode: @selene_render.BlendMode2D::Alpha,
          text: self.ui_strings.gallery_prev,
          position: Vec2(
            prev_rect.position.0 + prev_rect.size.0 / 2.0,
            prev_rect.position.1 + 18.0,
          ),
          transform: @selene_math.Transform::identity(),
          style: {
            font: hint_style.font,
            family: hint_style.family,
            size: hint_style.size,
            color: { r: 235, g: 240, b: 248, a: 1.0 },
            align: Center,
            baseline: Center,
          },
        }),
      )
      commands.push(
        Rect({
          alpha_mode: @selene_render.AlphaMode2D::Blend,
          blend_mode: @selene_render.BlendMode2D::Alpha,
          rect: next_rect,
          transform: @selene_math.Transform::identity(),
          fill_color: { r: 52, g: 78, b: 116, a: 0.65 },
          stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
        }),
      )
      commands.push(
        Text({
          blend_mode: @selene_render.BlendMode2D::Alpha,
          text: self.ui_strings.gallery_next,
          position: Vec2(
            next_rect.position.0 + next_rect.size.0 / 2.0,
            next_rect.position.1 + 18.0,
          ),
          transform: @selene_math.Transform::identity(),
          style: {
            font: hint_style.font,
            family: hint_style.family,
            size: hint_style.size,
            color: { r: 235, g: 240, b: 248, a: 1.0 },
            align: Center,
            baseline: Center,
          },
        }),
      )
      match tile.replay_label {
        Some(_) => {
          commands.push(
            Rect({
              alpha_mode: @selene_render.AlphaMode2D::Blend,
              blend_mode: @selene_render.BlendMode2D::Alpha,
              rect: replay_rect,
              transform: @selene_math.Transform::identity(),
              fill_color: { r: 40, g: 104, b: 92, a: 0.7 },
              stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
            }),
          )
          commands.push(
            Text({
              blend_mode: @selene_render.BlendMode2D::Alpha,
              text: self.ui_strings.gallery_replay,
              position: Vec2(
                replay_rect.position.0 + replay_rect.size.0 / 2.0,
                replay_rect.position.1 + 18.0,
              ),
              transform: @selene_math.Transform::identity(),
              style: {
                font: hint_style.font,
                family: hint_style.family,
                size: hint_style.size,
                color: { r: 235, g: 248, b: 244, a: 1.0 },
                align: Center,
                baseline: Center,
              },
            }),
          )
        }
        None => ()
      }
      commands.push(
        Rect({
          alpha_mode: @selene_render.AlphaMode2D::Blend,
          blend_mode: @selene_render.BlendMode2D::Alpha,
          rect: close_rect,
          transform: @selene_math.Transform::identity(),
          fill_color: { r: 112, g: 62, b: 62, a: 0.72 },
          stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
        }),
      )
      commands.push(
        Text({
          blend_mode: @selene_render.BlendMode2D::Alpha,
          text: self.ui_strings.gallery_close,
          position: Vec2(
            close_rect.position.0 + close_rect.size.0 / 2.0,
            close_rect.position.1 + 16.0,
          ),
          transform: @selene_math.Transform::identity(),
          style: {
            font: hint_style.font,
            family: hint_style.family,
            size: hint_style.size,
            color: { r: 248, g: 238, b: 238, a: 1.0 },
            align: Center,
            baseline: Center,
          },
        }),
      )
      commands.push(
        Text({
          blend_mode: @selene_render.BlendMode2D::Alpha,
          text: viewer_controls,
          position: Vec2(viewport_w / 2.0, viewport_h / 2.0 + 204.0),
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
            blend_mode: @selene_render.BlendMode2D::Alpha,
            text: self.ui_strings.gallery_locked,
            position: Vec2(viewport_w / 2.0, viewport_h / 2.0),
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
              blend_mode: @selene_render.BlendMode2D::Alpha,
              text: prefix + label,
              position: Vec2(left, top + row_h * i.to_double()),
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
          blend_mode: @selene_render.BlendMode2D::Alpha,
          text: "[Arrows] Move   Enter Open   Esc=" +
          self.ui_strings.gallery_back,
          position: Vec2(viewport_w / 2.0, viewport_h / 2.0 + 140.0),
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
