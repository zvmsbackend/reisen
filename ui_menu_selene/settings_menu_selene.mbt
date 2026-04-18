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
  mut audio : &@audio_core.AudioPort
  mut background : String
  mut show_credits : Bool
  mut save_namespace : String
  mut pending_action : @ui_menu.SettingsAction
  mut script_locale_json : String?
  mut script_default_locale_json : String?
  mut languages : Array[(String, String)]
  mut locale : String
  mut text_speed : Int
  mut bgm_volume : Double
  mut sfx_volume : Double
  mut selected_index : Int
  mut slot_type_index : Int
  mut slot_page : Int
  mut last_up_down : Bool
  mut last_down_down : Bool
  mut last_left_down : Bool
  mut last_right_down : Bool
  mut context : @ui_menu.SettingsContext
  mut view_mode : @ui_menu.SettingsViewMode
  mut settings_loaded : Bool
  mut last_escape_down : Bool
  mut last_enter_down : Bool
  mut last_space_down : Bool
  mut last_mouse_left_down : Bool
  mut last_mouse_right_down : Bool
  mut visible : Bool
  mut last_viewport_w : Double
  mut last_viewport_h : Double
}

///|
pub fn SeleneSettingsMenu::new(
  ui_strings? : UiStrings = UiStrings::default(),
  audio? : &@audio_core.AudioPort = @audio_core.dummy,
  background? : String = "",
  show_credits? : Bool = false,
  save_namespace? : String = "global",
  text_theme? : SeleneSettingsMenuTextTheme = SeleneSettingsMenuTextTheme::default(),
) -> SeleneSettingsMenu {
  {
    ui_strings,
    text_theme,
    audio,
    background,
    show_credits,
    save_namespace,
    pending_action: NoAction,
    script_locale_json: None,
    script_default_locale_json: None,
    languages: [],
    locale: "",
    text_speed: 50,
    bgm_volume: 0.7,
    sfx_volume: 0.8,
    selected_index: 0,
    slot_type_index: 2,
    slot_page: 0,
    last_up_down: false,
    last_down_down: false,
    last_left_down: false,
    last_right_down: false,
    context: FromStartMenu,
    view_mode: Settings,
    settings_loaded: false,
    last_escape_down: false,
    last_enter_down: false,
    last_space_down: false,
    last_mouse_left_down: false,
    last_mouse_right_down: false,
    visible: false,
    last_viewport_w: 1280.0,
    last_viewport_h: 720.0,
  }
}

///|
pub fn SeleneSettingsMenu::set_audio(
  self : SeleneSettingsMenu,
  audio : &@audio_core.AudioPort,
) -> Unit {
  self.audio = audio
}

///|
pub fn SeleneSettingsMenu::set_background(
  self : SeleneSettingsMenu,
  background : String,
) -> Unit {
  self.background = background
}

///|
pub fn SeleneSettingsMenu::set_show_credits(
  self : SeleneSettingsMenu,
  show_credits : Bool,
) -> Unit {
  self.show_credits = show_credits
}

///|
pub fn SeleneSettingsMenu::set_save_namespace(
  self : SeleneSettingsMenu,
  save_namespace : String,
) -> Unit {
  self.save_namespace = save_namespace
  self.settings_loaded = false
}

///|
fn clamp_int(v : Int, lo : Int, hi : Int) -> Int {
  if v < lo {
    lo
  } else if v > hi {
    hi
  } else {
    v
  }
}

///|
fn clamp_double(v : Double, lo : Double, hi : Double) -> Double {
  if v < lo {
    lo
  } else if v > hi {
    hi
  } else {
    v
  }
}

///|
fn SeleneSettingsMenu::slot_type_label(self : SeleneSettingsMenu) -> String {
  match self.slot_type_index {
    0 => self.ui_strings.settings_tab_auto
    1 => self.ui_strings.settings_tab_quick
    _ => self.ui_strings.settings_tab_save
  }
}

///|
fn SeleneSettingsMenu::slot_name_at(
  self : SeleneSettingsMenu,
  index : Int,
) -> String {
  let n = self.slot_page * 6 + index + 1
  match self.slot_type_index {
    0 => "autosave\{n}"
    1 => "quicksave\{n}"
    _ => n.to_string()
  }
}

///|
fn SeleneSettingsMenu::localize_save_preview(
  self : SeleneSettingsMenu,
  raw : String,
) -> String {
  @ui_menu.localize_script_string(
    raw,
    self.script_locale_json,
    self.script_default_locale_json,
  )
}

///|
fn SeleneSettingsMenu::filtered_slot_entries(
  self : SeleneSettingsMenu,
) -> Array[@storage.SaveSlotEntry] {
  let store = @storage.default_save_slot_storage()
  let entries = @storage.save_slot_store_entries_in(store, self.save_namespace)
  entries.filter(fn(entry) {
    match self.slot_type_index {
      0 => entry.slot.has_prefix("autosave")
      1 => entry.slot.has_prefix("quicksave")
      _ =>
        !(entry.slot.has_prefix("autosave") ||
        entry.slot.has_prefix("quicksave"))
    }
  })
}

///|
fn SeleneSettingsMenu::slot_row_content(
  self : SeleneSettingsMenu,
  index : Int,
) -> (String, String, String, Bool) {
  let entries = self.filtered_slot_entries()
  let idx = self.slot_page * 6 + index
  if idx < entries.length() {
    let entry = entries[idx]
    let title = match entry.meta {
      Some(meta) =>
        match meta.title {
          "" => entry.slot
          _ => meta.title
        }
      None => entry.slot
    }
    let preview = match entry.meta {
      Some(meta) => self.localize_save_preview(meta.preview)
      None => ""
    }
    return (entry.slot, title, preview, true)
  }
  let slot = self.slot_name_at(index)
  (slot, self.ui_strings.settings_slot_empty, "", false)
}

///|
fn SeleneSettingsMenu::visible_rows(self : SeleneSettingsMenu) -> Int {
  match self.view_mode {
    Settings => {
      let context_rows = match self.context {
        FromStartMenu => 2
        FromMidgame => 4
      }
      let credits_rows = if self.show_credits { 1 } else { 0 }
      4 + context_rows + credits_rows + 2
    }
    SaveList | LoadList => 9
  }
}

///|
fn SeleneSettingsMenu::normalize_selection(self : SeleneSettingsMenu) -> Unit {
  let count = self.visible_rows()
  if count <= 0 {
    self.selected_index = 0
    return
  }
  self.selected_index = clamp_int(self.selected_index, 0, count - 1)
}

///|
fn SeleneSettingsMenu::load_settings_if_needed(
  self : SeleneSettingsMenu,
) -> Unit {
  if self.settings_loaded {
    return
  }
  let settings = @storage.settings_read_in(self.save_namespace).unwrap_or_default()
  self.text_speed = settings.text_speed
  self.bgm_volume = settings.bgm_volume
  self.sfx_volume = settings.sfx_volume
  self.settings_loaded = true
}

///|
fn SeleneSettingsMenu::persist_settings(self : SeleneSettingsMenu) -> Unit {
  self.text_speed = clamp_int(self.text_speed, 10, 100)
  self.bgm_volume = clamp_double(self.bgm_volume, 0.0, 1.0)
  self.sfx_volume = clamp_double(self.sfx_volume, 0.0, 1.0)
  let settings = @storage.GameSettings::new(
    self.text_speed,
    self.bgm_volume,
    self.sfx_volume,
  ) catch {
    _ => @storage.GameSettings::default()
  }
  @storage.settings_write_in(self.save_namespace, settings)
  self.audio.set_bgm_gain(self.bgm_volume)
  self.audio.set_sfx_gain(self.sfx_volume)
}

///|
fn SeleneSettingsMenu::take_back_edge(self : SeleneSettingsMenu) -> Bool {
  let escape_down = @selene_inputs.is_pressed(@selene_inputs.Escape)
  let triggered = escape_down && !self.last_escape_down
  self.last_escape_down = escape_down
  triggered
}

///|
fn SeleneSettingsMenu::take_confirm_edge(self : SeleneSettingsMenu) -> Bool {
  let enter_down = @selene_inputs.is_pressed(@selene_inputs.Enter)
  let space_down = @selene_inputs.is_pressed(@selene_inputs.Space)
  let triggered = (enter_down && !self.last_enter_down) ||
    (space_down && !self.last_space_down)
  self.last_enter_down = enter_down
  self.last_space_down = space_down
  triggered
}

///|
fn SeleneSettingsMenu::take_up_edge(self : SeleneSettingsMenu) -> Bool {
  let down = @selene_inputs.is_pressed(@selene_inputs.ArrowUp)
  let edge = down && !self.last_up_down
  self.last_up_down = down
  edge
}

///|
fn SeleneSettingsMenu::take_down_edge(self : SeleneSettingsMenu) -> Bool {
  let down = @selene_inputs.is_pressed(@selene_inputs.ArrowDown)
  let edge = down && !self.last_down_down
  self.last_down_down = down
  edge
}

///|
fn SeleneSettingsMenu::take_left_edge(self : SeleneSettingsMenu) -> Bool {
  let down = @selene_inputs.is_pressed(@selene_inputs.ArrowLeft)
  let edge = down && !self.last_left_down
  self.last_left_down = down
  edge
}

///|
fn SeleneSettingsMenu::take_right_edge(self : SeleneSettingsMenu) -> Bool {
  let down = @selene_inputs.is_pressed(@selene_inputs.ArrowRight)
  let edge = down && !self.last_right_down
  self.last_right_down = down
  edge
}

///|
fn SeleneSettingsMenu::mouse_position(
  _self : SeleneSettingsMenu,
) -> (Double, Double) {
  let pos = @selene_inputs.mouse.pos
  (pos.0, pos.1)
}

///|
fn SeleneSettingsMenu::take_mouse_left_edge(self : SeleneSettingsMenu) -> Bool {
  let down = @selene_inputs.mouse.left_button
  let edge = down && !self.last_mouse_left_down
  self.last_mouse_left_down = down
  edge
}

///|
fn SeleneSettingsMenu::take_mouse_right_edge(self : SeleneSettingsMenu) -> Bool {
  let down = @selene_inputs.mouse.right_button
  let edge = down && !self.last_mouse_right_down
  self.last_mouse_right_down = down
  edge
}

///|
fn SeleneSettingsMenu::viewport_size(
  self : SeleneSettingsMenu,
) -> (Double, Double) {
  let w = if self.last_viewport_w > 0.0 { self.last_viewport_w } else { 1280.0 }
  let h = if self.last_viewport_h > 0.0 { self.last_viewport_h } else { 720.0 }
  (w, h)
}

///|
fn settings_point_in_box(
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
fn SeleneSettingsMenu::hover_row_by_mouse(self : SeleneSettingsMenu) -> Unit {
  let (mx, my) = self.mouse_position()
  let (viewport_w, viewport_h) = self.viewport_size()
  let row_left = viewport_w / 2.0 - 286.0
  let row_width = 572.0
  match self.view_mode {
    Settings => {
      let mut row_y = viewport_h / 2.0 - 150.0
      for i in 0..<4 {
        if settings_point_in_box(mx, my, row_left, row_y - 4.0, row_width, 30.0) {
          self.selected_index = i
          return
        }
        row_y += 36.0
      }

      let mut action_count = match self.context {
        FromStartMenu => 2
        FromMidgame => 4
      }
      if self.show_credits {
        action_count += 1
      }
      action_count += 2

      let action_base = settings_action_row_base()
      let mut action_y = row_y + 10.0
      for i in 0..<action_count {
        if settings_point_in_box(
            mx,
            my,
            row_left,
            action_y - 4.0,
            row_width,
            30.0,
          ) {
          self.selected_index = action_base + i
          return
        }
        action_y += 32.0
      }
    }
    SaveList | LoadList => {
      if settings_point_in_box(
          mx,
          my,
          row_left,
          viewport_h / 2.0 - 154.0,
          row_width,
          30.0,
        ) {
        self.selected_index = 0
        return
      }
      let mut slot_y = viewport_h / 2.0 - 110.0
      for i in 0..<6 {
        if settings_point_in_box(
            mx,
            my,
            row_left,
            slot_y - 4.0,
            row_width,
            46.0,
          ) {
          self.selected_index = i + 1
          return
        }
        slot_y += 52.0
      }
      if settings_point_in_box(mx, my, row_left, slot_y - 4.0, row_width, 30.0) {
        self.selected_index = 7
        return
      }
      slot_y += 34.0
      if settings_point_in_box(mx, my, row_left, slot_y - 4.0, row_width, 30.0) {
        self.selected_index = 8
        return
      }
    }
  }
}

///|
fn SeleneSettingsMenu::mouse_action(
  self : SeleneSettingsMenu,
) -> @ui_menu.SettingsAction {
  let click = self.take_mouse_left_edge()
  let right_click = self.take_mouse_right_edge()

  if right_click {
    return Back
  }
  if !click {
    return NoAction
  }

  self.hover_row_by_mouse()
  let (mx, _) = self.mouse_position()
  let (viewport_w, _) = self.viewport_size()
  let panel_center_x = viewport_w / 2.0
  let move_right = mx >= panel_center_x
  match self.view_mode {
    Settings =>
      if self.selected_index <= 3 {
        self.apply_horizontal_in_settings(move_right)
      } else {
        self.confirm_settings_row()
      }
    SaveList | LoadList =>
      if self.selected_index == 0 || self.selected_index == 7 {
        self.apply_horizontal_in_slots(move_right)
      } else {
        self.confirm_slot_row()
      }
  }
}

///|
fn SeleneSettingsMenu::cycle_language(
  self : SeleneSettingsMenu,
  forward : Bool,
) -> String? {
  if self.languages.is_empty() {
    return None
  }
  let mut index = 0
  for i = 0; i < self.languages.length(); i = i + 1 {
    if self.languages[i].1 == self.locale {
      index = i
      break
    }
  }
  let count = self.languages.length()
  index = if forward {
    (index + 1) % count
  } else {
    (index + count - 1) % count
  }
  let code = self.languages[index].1
  self.locale = code
  Some(code)
}

///|
fn settings_action_row_base() -> Int {
  4
}

///|
fn SeleneSettingsMenu::apply_horizontal_in_settings(
  self : SeleneSettingsMenu,
  move_right : Bool,
) -> @ui_menu.SettingsAction {
  self.load_settings_if_needed()
  let delta_int = if move_right { 10 } else { -10 }
  let delta_volume = if move_right { 0.05 } else { -0.05 }
  match self.selected_index {
    0 => {
      self.text_speed = clamp_int(self.text_speed + delta_int, 10, 100)
      self.persist_settings()
      NoAction
    }
    1 =>
      match self.cycle_language(move_right) {
        Some(code) => LanguageChanged(code)
        None => NoAction
      }
    2 => {
      self.bgm_volume = clamp_double(self.bgm_volume + delta_volume, 0.0, 1.0)
      self.persist_settings()
      NoAction
    }
    3 => {
      self.sfx_volume = clamp_double(self.sfx_volume + delta_volume, 0.0, 1.0)
      self.persist_settings()
      NoAction
    }
    _ => NoAction
  }
}

///|
fn SeleneSettingsMenu::confirm_settings_row(
  self : SeleneSettingsMenu,
) -> @ui_menu.SettingsAction {
  self.load_settings_if_needed()
  let base = settings_action_row_base()
  let mut row = self.selected_index - base
  if row < 0 {
    if self.selected_index == 1 {
      return match self.cycle_language(true) {
        Some(code) => LanguageChanged(code)
        None => NoAction
      }
    }
    return NoAction
  }
  match self.context {
    FromStartMenu => {
      if row == 0 {
        return NewGame
      }
      if row == 1 {
        return {
          self.view_mode = LoadList
          self.selected_index = 1
          self.slot_page = 0
          ViewChanged
        }
      }
      row -= 2
    }
    FromMidgame => {
      if row == 0 {
        return {
          self.view_mode = SaveList
          self.selected_index = 1
          self.slot_page = 0
          ViewChanged
        }
      }
      if row == 1 {
        return {
          self.view_mode = LoadList
          self.selected_index = 1
          self.slot_page = 0
          ViewChanged
        }
      }
      if row == 2 {
        return Log
      }
      if row == 3 {
        return StartMenu
      }
      row -= 4
    }
  }
  if self.show_credits {
    if row == 0 {
      return Credits
    }
    row -= 1
  }
  if row == 0 {
    self.text_speed = 50
    self.bgm_volume = 0.7
    self.sfx_volume = 0.8
    self.persist_settings()
    return NoAction
  }
  if row == 1 {
    self.persist_settings()
    return Back
  }
  NoAction
}

///|
fn SeleneSettingsMenu::apply_horizontal_in_slots(
  self : SeleneSettingsMenu,
  move_right : Bool,
) -> @ui_menu.SettingsAction {
  if self.selected_index == 0 {
    self.slot_type_index = if move_right {
      (self.slot_type_index + 1) % 3
    } else {
      (self.slot_type_index + 2) % 3
    }
    self.slot_page = 0
    return ViewChanged
  }
  if self.selected_index == 7 && self.slot_type_index == 2 {
    if move_right {
      self.slot_page = clamp_int(self.slot_page + 1, 0, 99)
      return ViewChanged
    }
    if self.slot_page > 0 {
      self.slot_page -= 1
      return ViewChanged
    }
  }
  NoAction
}

///|
fn SeleneSettingsMenu::confirm_slot_row(
  self : SeleneSettingsMenu,
) -> @ui_menu.SettingsAction {
  if self.selected_index == 0 {
    self.slot_type_index = (self.slot_type_index + 1) % 3
    self.slot_page = 0
    return ViewChanged
  }
  if self.selected_index >= 1 && self.selected_index <= 6 {
    let (slot, _, _, _) = self.slot_row_content(self.selected_index - 1)
    return match self.view_mode {
      SaveList => SaveSlot(slot)
      LoadList => LoadSlot(slot)
      _ => NoAction
    }
  }
  if self.selected_index == 7 {
    if self.slot_type_index == 2 && self.slot_page < 99 {
      self.slot_page += 1
      return ViewChanged
    }
    return NoAction
  }
  if self.selected_index == 8 {
    return Back
  }
  NoAction
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
  self.selected_index = match view_mode {
    Settings => 0
    SaveList | LoadList => 1
  }
  self.slot_page = 0
  self.normalize_selection()
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with render(self) {
  self.visible = true
  if self.view_mode is Settings {
    self.load_settings_if_needed()
  }
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with clear(self) {
  self.visible = false
  self.selected_index = 0
}

///|
pub impl @ui_menu.SettingsMenu for SeleneSettingsMenu with take_action(self) {
  if !self.visible {
    let action = self.pending_action
    self.pending_action = NoAction
    return action
  }

  let result : @ui_menu.SettingsAction = match self.pending_action {
    NoAction =>
      if self.take_back_edge() {
        Back
      } else {
        self.hover_row_by_mouse()
        if self.take_up_edge() {
          self.selected_index -= 1
          self.normalize_selection()
        }
        if self.take_down_edge() {
          self.selected_index += 1
          self.normalize_selection()
        }
        let left_edge = self.take_left_edge()
        let right_edge = self.take_right_edge()
        let confirm = self.take_confirm_edge()
        let mouse_action = self.mouse_action()

        if left_edge {
          match self.view_mode {
            Settings => self.apply_horizontal_in_settings(false)
            SaveList | LoadList => self.apply_horizontal_in_slots(false)
          }
        } else if right_edge {
          match self.view_mode {
            Settings => self.apply_horizontal_in_settings(true)
            SaveList | LoadList => self.apply_horizontal_in_slots(true)
          }
        } else if confirm {
          match self.view_mode {
            Settings => self.confirm_settings_row()
            SaveList | LoadList => self.confirm_slot_row()
          }
        } else {
          match mouse_action {
            NoAction => NoAction
            other => other
          }
        }
      }
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
  self.last_viewport_w = viewport_w
  self.last_viewport_h = viewport_h
  if !self.visible {
    return []
  }
  let title_style = self.text_theme.title
  let row_style = self.text_theme.row
  let hint_style = self.text_theme.hint
  let placeholder_style = self.text_theme.placeholder
  self.normalize_selection()

  let commands : Array[@selene_render2d_types.DrawCommand2D] = []
  match fullscreen_image_command(self.background, viewport_w, viewport_h) {
    Some(background_cmd) => commands.push(background_cmd)
    None => ()
  }
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
    Settings =>
      "\{self.ui_strings.settings_text_speed} / \{self.ui_strings.settings_language}"
    SaveList => self.ui_strings.settings_save_game_title
    LoadList => self.ui_strings.settings_load_game_title
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
      let mut language_label = self.locale
      for i = 0; i < self.languages.length(); i = i + 1 {
        let lang = self.languages[i]
        if lang.1 == self.locale {
          language_label = lang.0
          break
        }
      }
      let settings_rows : Array[(String, String)] = [
        (self.ui_strings.settings_text_speed, "\{self.text_speed}"),
        (
          self.ui_strings.settings_language,
          if language_label == "" {
            "-"
          } else {
            language_label
          },
        ),
        (
          self.ui_strings.settings_bgm_volume,
          "\{(self.bgm_volume * 100.0).to_int()}%",
        ),
        (
          self.ui_strings.settings_sfx_volume,
          "\{(self.sfx_volume * 100.0).to_int()}%",
        ),
      ]
      let mut row_y = viewport_h / 2.0 - 150.0
      for i = 0; i < settings_rows.length(); i = i + 1 {
        let selected = self.selected_index == i
        if selected {
          commands.push(
            Rect({
              rect: {
                position: Vec2D(viewport_w / 2.0 - 286.0, row_y - 4.0),
                size: Vec2D(572.0, 30.0),
              },
              transform: @selene_math.Transform::identity(),
              fill_color: { r: 70, g: 110, b: 160, a: 0.35 },
              stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
            }),
          )
        }
        commands.push(
          Text({
            text: settings_rows[i].0,
            position: Vec2D(viewport_w / 2.0 - 275.0, row_y),
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
            text: settings_rows[i].1,
            position: Vec2D(viewport_w / 2.0 + 275.0, row_y),
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
              align: @selene_math.HAlign::Right,
              baseline: @selene_math.VAlign::Top,
            },
          }),
        )
        row_y += 36.0
      }

      let action_rows : Array[@ui_menu.SettingsAction] = []
      let action_labels : Array[String] = []
      match self.context {
        FromStartMenu => {
          action_rows.push(NewGame)
          action_labels.push(self.ui_strings.settings_new_game)
          action_rows.push(ViewChanged)
          action_labels.push(self.ui_strings.settings_load)
        }
        FromMidgame => {
          action_rows.push(ViewChanged)
          action_labels.push(self.ui_strings.settings_save)
          action_rows.push(ViewChanged)
          action_labels.push(self.ui_strings.settings_load)
          action_rows.push(Log)
          action_labels.push(self.ui_strings.settings_log)
          action_rows.push(StartMenu)
          action_labels.push(self.ui_strings.settings_start_menu)
        }
      }
      if self.show_credits {
        action_rows.push(Credits)
        action_labels.push(self.ui_strings.menu_credits)
      }
      action_rows.push(NoAction)
      action_labels.push(self.ui_strings.settings_defaults)
      action_rows.push(Back)
      action_labels.push(self.ui_strings.settings_back)

      let action_base = settings_action_row_base()
      let mut action_y = row_y + 10.0
      for i = 0; i < action_labels.length(); i = i + 1 {
        let selected = self.selected_index == action_base + i
        if selected {
          commands.push(
            Rect({
              rect: {
                position: Vec2D(viewport_w / 2.0 - 286.0, action_y - 4.0),
                size: Vec2D(572.0, 30.0),
              },
              transform: @selene_math.Transform::identity(),
              fill_color: { r: 70, g: 110, b: 160, a: 0.35 },
              stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
            }),
          )
        }
        commands.push(
          Text({
            text: action_labels[i],
            position: Vec2D(viewport_w / 2.0 - 275.0, action_y),
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
        action_y += 32.0
      }

      commands.push(
        Text({
          text: "[↑/↓] Select  [←/→] Adjust  [Enter/Space] Confirm  [Esc] Back",
          position: Vec2D(viewport_w / 2.0, viewport_h / 2.0 + 210.0),
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
    SaveList | LoadList => {
      let title_text = "\{self.ui_strings.settings_tab_auto}/\{self.ui_strings.settings_tab_quick}/\{self.ui_strings.settings_tab_save}: \{self.slot_type_label()}"
      let selected_tab = self.selected_index == 0
      if selected_tab {
        commands.push(
          Rect({
            rect: {
              position: Vec2D(
                viewport_w / 2.0 - 286.0,
                viewport_h / 2.0 - 154.0,
              ),
              size: Vec2D(572.0, 30.0),
            },
            transform: @selene_math.Transform::identity(),
            fill_color: { r: 70, g: 110, b: 160, a: 0.35 },
            stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
          }),
        )
      }
      commands.push(
        Text({
          text: title_text,
          position: Vec2D(viewport_w / 2.0 - 275.0, viewport_h / 2.0 - 150.0),
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

      let mut slot_y = viewport_h / 2.0 - 110.0
      for i = 0; i < 6; i = i + 1 {
        let (slot, title, preview, has_existing) = self.slot_row_content(i)
        let selected = self.selected_index == i + 1
        if selected {
          commands.push(
            Rect({
              rect: {
                position: Vec2D(viewport_w / 2.0 - 286.0, slot_y - 4.0),
                size: Vec2D(572.0, 46.0),
              },
              transform: @selene_math.Transform::identity(),
              fill_color: { r: 70, g: 110, b: 160, a: 0.35 },
              stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
            }),
          )
        }
        commands.push(
          Text({
            text: if has_existing {
              "\{slot} | \{title}"
            } else {
              "\{slot} | \{self.ui_strings.settings_slot_empty}"
            },
            position: Vec2D(viewport_w / 2.0 - 275.0, slot_y),
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
        if preview != "" {
          commands.push(
            Text({
              text: preview,
              position: Vec2D(viewport_w / 2.0 - 260.0, slot_y + 22.0),
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
                align: @selene_math.HAlign::Left,
                baseline: @selene_math.VAlign::Top,
              },
            }),
          )
        }
        slot_y += 52.0
      }

      let nav_selected = self.selected_index == 7
      if nav_selected {
        commands.push(
          Rect({
            rect: {
              position: Vec2D(viewport_w / 2.0 - 286.0, slot_y - 4.0),
              size: Vec2D(572.0, 30.0),
            },
            transform: @selene_math.Transform::identity(),
            fill_color: { r: 70, g: 110, b: 160, a: 0.35 },
            stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
          }),
        )
      }
      commands.push(
        Text({
          text: "\{self.ui_strings.settings_page_prefix}: \{self.slot_page + 1}   \{self.ui_strings.settings_nav_prev}/\{self.ui_strings.settings_nav_next}",
          position: Vec2D(viewport_w / 2.0 - 275.0, slot_y),
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
      slot_y += 34.0

      let back_selected = self.selected_index == 8
      if back_selected {
        commands.push(
          Rect({
            rect: {
              position: Vec2D(viewport_w / 2.0 - 286.0, slot_y - 4.0),
              size: Vec2D(572.0, 30.0),
            },
            transform: @selene_math.Transform::identity(),
            fill_color: { r: 70, g: 110, b: 160, a: 0.35 },
            stroke_color: Some({ r: 220, g: 228, b: 242, a: 1.0 }),
          }),
        )
      }
      commands.push(
        Text({
          text: self.ui_strings.settings_back,
          position: Vec2D(viewport_w / 2.0 - 275.0, slot_y),
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
            align: @selene_math.HAlign::Left,
            baseline: @selene_math.VAlign::Top,
          },
        }),
      )
      commands.push(
        Text({
          text: "[↑/↓] Select  [←/→] Tab/Page  [Enter/Space] Confirm  [Esc] Back",
          position: Vec2D(viewport_w / 2.0, viewport_h / 2.0 + 210.0),
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
  }
  commands
}
