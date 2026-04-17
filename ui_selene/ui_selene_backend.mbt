///|
pub struct SeleneOverlayTextStyle {
  font : @selene_asset_types.FontHandle?
  family : String
  size : Double
  color_r : UInt
  color_g : UInt
  color_b : UInt
  color_a : Double
}

///|
pub impl Default for SeleneOverlayTextStyle with default() {
  {
    font: None,
    family: "sans-serif",
    size: 24.0,
    color_r: 238,
    color_g: 244,
    color_b: 252,
    color_a: 1.0,
  }
}

///|
pub struct SeleneOverlayTextTheme {
  speaker : SeleneOverlayTextStyle
  body : SeleneOverlayTextStyle
}

///|
pub impl Default for SeleneOverlayTextTheme with default() {
  {
    speaker: {
      font: None,
      family: "sans-serif",
      size: 28.0,
      color_r: 255,
      color_g: 221,
      color_b: 170,
      color_a: 1.0,
    },
    body: {
      font: None,
      family: "sans-serif",
      size: 24.0,
      color_r: 238,
      color_g: 244,
      color_b: 252,
      color_a: 1.0,
    },
  }
}

///|
fn SeleneOverlayTextStyle::with_family(
  self : SeleneOverlayTextStyle,
  family : String,
) -> SeleneOverlayTextStyle {
  {
    font: self.font,
    family,
    size: self.size,
    color_r: self.color_r,
    color_g: self.color_g,
    color_b: self.color_b,
    color_a: self.color_a,
  }
}

///|
fn SeleneOverlayTextTheme::with_family(
  self : SeleneOverlayTextTheme,
  family : String,
) -> SeleneOverlayTextTheme {
  {
    speaker: self.speaker.with_family(family),
    body: self.body.with_family(family),
  }
}

///|
pub struct SeleneUiBackend {
  mut ui_strings : UiStrings
  overlay_text_theme : SeleneOverlayTextTheme
  mut script_locale_json : String?
  mut script_default_locale_json : String?
  mut vocal_locale_dir : String
  mut script_locale : String
  mut script_default_locale : String
  mut pending_choice : String?
  mut pending_text_input : String?
  mut pending_action : String?
  mut pending_video_action : String?
  mut pending_click : Bool
  mut pending_intro_done : Bool
  mut last_mouse_left_down : Bool
  mut last_enter_down : Bool
  mut last_space_down : Bool
  mut last_escape_down : Bool
  mut last_view : UiViewModel?
}

///|
pub fn SeleneUiBackend::new(
  ui_strings? : UiStrings = UiStrings::default(),
  overlay_text_theme? : SeleneOverlayTextTheme = SeleneOverlayTextTheme::default(),
  script_locale_json? : String? = None,
  script_default_locale_json? : String? = None,
  vocal_locale_dir? : String = "",
  script_locale? : String = "",
  script_default_locale? : String = "",
) -> SeleneUiBackend {
  {
    ui_strings,
    overlay_text_theme,
    script_locale_json,
    script_default_locale_json,
    vocal_locale_dir,
    script_locale,
    script_default_locale,
    pending_choice: None,
    pending_text_input: None,
    pending_action: None,
    pending_video_action: None,
    pending_click: false,
    pending_intro_done: false,
    last_mouse_left_down: false,
    last_enter_down: false,
    last_space_down: false,
    last_escape_down: false,
    last_view: None,
  }
}

///|
pub fn SeleneUiBackend::push_action(
  self : SeleneUiBackend,
  action : String,
) -> Unit {
  self.pending_action = Some(action)
}

///|
pub fn SeleneUiBackend::push_video_action(
  self : SeleneUiBackend,
  action : String,
) -> Unit {
  self.pending_video_action = Some(action)
}

///|
pub fn SeleneUiBackend::push_selected_choice(
  self : SeleneUiBackend,
  id : String,
) -> Unit {
  self.pending_choice = Some(id)
}

///|
pub fn SeleneUiBackend::push_submitted_text_input(
  self : SeleneUiBackend,
  text : String,
) -> Unit {
  self.pending_text_input = Some(text)
}

///|
pub fn SeleneUiBackend::push_click(self : SeleneUiBackend) -> Unit {
  self.pending_click = true
}

///|
pub fn SeleneUiBackend::last_view(self : SeleneUiBackend) -> UiViewModel? {
  self.last_view
}

///|
fn SeleneUiBackend::localize_script_text(
  self : SeleneUiBackend,
  text : DialogText,
) -> DialogText {
  @ui_game.localize_script_text(
    text,
    self.script_locale_json,
    self.script_default_locale_json,
  )
}

///|
fn SeleneUiBackend::localize_script_text_string(
  self : SeleneUiBackend,
  raw : String,
) -> String {
  @ui_game.localize_script_string(
    raw,
    self.script_locale_json,
    self.script_default_locale_json,
  )
}

///|
fn SeleneUiBackend::selene_view_from_snapshot(
  self : SeleneUiBackend,
  snapshot : UiSnapshot,
) -> UiViewModel {
  let (raw_speaker, raw_text) = match snapshot.dialog {
    Some((speaker, text, _, _)) => (speaker, text)
    None => (DialogText::empty(), DialogText::empty())
  }
  let speaker = self.localize_script_text(raw_speaker)
  let text = self.localize_script_text(raw_text)
  let typewriter = match snapshot.dialog {
    Some((_, _, typewriter, _)) => typewriter
    None => true
  }
  let append = match snapshot.dialog {
    Some((_, _, _, append)) => append
    None => false
  }
  let video = match snapshot.video {
    Some((url, can_skip)) => Some(UiVideoView::{ url, can_skip })
    None => None
  }
  let choices = snapshot.choices.map(opt => UiChoiceView::{
    id: opt.id,
    text: self.localize_script_text(opt.text),
  })
  let text_input = match snapshot.text_input {
    Some((var_name, prompt)) =>
      Some(UiTextInputView::{
        var_name,
        prompt: self.localize_script_text(prompt),
      })
    None => None
  }
  let intro_text = snapshot.intro_text.map(text => {
    self.localize_script_text(text)
  })
  let localized_dialog_history : Array[DialogLogEntry] = snapshot.dialog_history.map(entry => {
      speaker: self.localize_script_text_string(entry.speaker),
      text: self.localize_script_text_string(entry.text),
    },
  )
  {
    speaker,
    text,
    dialog_seq: snapshot.dialog_seq,
    typewriter,
    intro_text,
    video,
    append,
    text_box_visible: snapshot.text_box_visible,
    avatar_id: snapshot.avatar_id,
    choices,
    text_input,
    dialog_history: localized_dialog_history,
    dom_figures: [],
    auto_mode: false,
    skip_mode: false,
    log_visible: false,
    dirty_speaker: true,
    dirty_text: true,
    dirty_choices: true,
    dirty_text_input: true,
    dirty_action_buttons: true,
  }
}

///|
pub impl UiBackend for SeleneUiBackend with localize_vocal_url(self, raw) {
  @ui_game.localize_vocal_url(
    raw,
    self.vocal_locale_dir,
    self.script_locale,
    self.script_default_locale,
  )
}

///|
pub impl UiBackend for SeleneUiBackend with render(self, view) {
  self.last_view = Some(view)
}

///|
pub impl UiBackend for SeleneUiBackend with view_model_from_snapshot(
  self,
  snapshot,
) {
  ignore(self.ui_strings)
  self.selene_view_from_snapshot(snapshot)
}

///|
pub impl UiBackend for SeleneUiBackend with take_selected_choice(self) {
  let result = self.pending_choice
  self.pending_choice = None
  result
}

///|
pub impl UiBackend for SeleneUiBackend with take_submitted_text_input(self) {
  let result = self.pending_text_input
  self.pending_text_input = None
  result
}

///|
pub impl UiBackend for SeleneUiBackend with take_action(self) {
  let result = self.pending_action
  self.pending_action = None
  result
}

///|
pub impl UiBackend for SeleneUiBackend with take_video_action(self) {
  let result = self.pending_video_action
  self.pending_video_action = None
  result
}

///|
pub impl UiBackend for SeleneUiBackend with check_typewriter_click(self) {
  let clicked = self.pending_click
  self.pending_click = false
  clicked
}

///|
pub impl UiBackend for SeleneUiBackend with check_intro_done(self) {
  let done = self.pending_intro_done
  self.pending_intro_done = false
  done
}

///|
pub impl UiBackend for SeleneUiBackend with reveal_intro_line(self) {
  self.pending_intro_done = true
  false
}

///|
pub impl UiBackend for SeleneUiBackend with clear_game_ui(self) {
  self.pending_choice = None
  self.pending_text_input = None
  self.pending_action = None
  self.pending_video_action = None
  self.pending_click = false
  self.pending_intro_done = false
  self.last_mouse_left_down = false
  self.last_enter_down = false
  self.last_space_down = false
  self.last_escape_down = false
  self.last_view = None
}

///|
pub impl UiBackend for SeleneUiBackend with set_ui_strings(self, ui_strings) {
  self.ui_strings = ui_strings
}

///|
pub impl UiBackend for SeleneUiBackend with set_script_localization(
  self,
  script_locale_json~,
  script_default_locale_json~,
  vocal_locale_dir~,
  script_locale~,
  script_default_locale~,
) {
  self.script_locale_json = script_locale_json
  self.script_default_locale_json = script_default_locale_json
  self.vocal_locale_dir = vocal_locale_dir
  self.script_locale = script_locale
  self.script_default_locale = script_default_locale
}

///|
pub impl UiBackend for SeleneUiBackend with simulate_click(self) {
  self.pending_click = true
}

///|
pub impl UiPlatformHooks for SeleneUiBackend with advance_ui_animation_timer(
  self,
  _elapsed_ms,
) {
  let mouse_left_down = @selene_inputs.mouse.left_button
  let enter_down = @selene_inputs.is_pressed(@selene_inputs.Enter)
  let space_down = @selene_inputs.is_pressed(@selene_inputs.Space)
  let escape_down = @selene_inputs.is_pressed(@selene_inputs.Escape)

  if (mouse_left_down && !self.last_mouse_left_down) ||
    (enter_down && !self.last_enter_down) ||
    (space_down && !self.last_space_down) {
    self.pending_click = true
  }

  if escape_down && !self.last_escape_down {
    if self.pending_action is None {
      self.pending_action = Some("settings")
    }
  }

  self.last_mouse_left_down = mouse_left_down
  self.last_enter_down = enter_down
  self.last_space_down = space_down
  self.last_escape_down = escape_down
}

///|
pub impl UiPlatformHooks for SeleneUiBackend with has_active_ui_animations(self) {
  ignore(self)
  false
}

///|
pub impl UiPlatformHooks for SeleneUiBackend with set_media_volume(
  self,
  _volume,
) {
  ignore(self)
}

///|
fn dialog_text_or_intro(view : UiViewModel) -> String {
  let dialog = view.text.raw_text()
  if dialog != "" {
    return dialog
  }
  match view.intro_text {
    Some(text) => text.raw_text()
    None => ""
  }
}

///|
fn SeleneUiBackend::body_lines(view : UiViewModel) -> Array[String] {
  let lines : Array[String] = []
  let body = dialog_text_or_intro(view)
  if body != "" {
    lines.push(body)
  }
  if !view.choices.is_empty() {
    for i = 0; i < view.choices.length(); i = i + 1 {
      let choice = view.choices[i]
      lines.push("\{i + 1}. \{choice.text.raw_text()}")
      if i >= 2 {
        break
      }
    }
  }
  if view.text_input is Some(input) {
    lines.push("Input: \{input.prompt.raw_text()}")
  }
  if view.video is Some(video) {
    let skip_hint = if video.can_skip { " (skip available)" } else { "" }
    lines.push("Video: \{video.url}\{skip_hint}")
  }
  lines
}

///|
pub fn SeleneUiBackend::ui_overlay_commands(
  self : SeleneUiBackend,
  viewport_w? : Double = 1280.0,
  viewport_h? : Double = 720.0,
) -> Array[@selene_render2d_types.DrawCommand2D] {
  match self.last_view {
    None => []
    Some(view) => {
      let speaker_text_style = self.overlay_text_theme.speaker
      let body_text_style = self.overlay_text_theme.body
      let speaker = view.speaker.raw_text()
      let lines = SeleneUiBackend::body_lines(view)
      if speaker == "" && lines.is_empty() {
        return []
      }
      if !view.text_box_visible {
        return []
      }
      let panel_rect : @selene_math.Rect = {
        position: @selene_math.Vec2D(28.0, viewport_h - 236.0),
        size: @selene_math.Vec2D(viewport_w - 56.0, 208.0),
      }
      let commands : Array[@selene_render2d_types.DrawCommand2D] = [
        Rect({
          rect: panel_rect,
          transform: @selene_math.Transform::identity(),
          fill_color: { r: 10, g: 14, b: 20, a: 0.82 },
          stroke_color: Some({ r: 214, g: 224, b: 238, a: 0.92 }),
        }),
      ]
      let mut y = viewport_h - 214.0
      if speaker != "" {
        commands.push(
          Text({
            text: speaker,
            position: @selene_math.Vec2D(48.0, y),
            transform: @selene_math.Transform::identity(),
            style: {
              font: speaker_text_style.font,
              family: speaker_text_style.family,
              size: speaker_text_style.size,
              color: {
                r: speaker_text_style.color_r,
                g: speaker_text_style.color_g,
                b: speaker_text_style.color_b,
                a: speaker_text_style.color_a,
              },
              align: @selene_math.HAlign::Left,
              baseline: @selene_math.VAlign::Top,
            },
          }),
        )
        y += 38.0
      }
      for line in lines {
        commands.push(
          Text({
            text: line,
            position: @selene_math.Vec2D(48.0, y),
            transform: @selene_math.Transform::identity(),
            style: {
              font: body_text_style.font,
              family: body_text_style.family,
              size: body_text_style.size,
              color: {
                r: body_text_style.color_r,
                g: body_text_style.color_g,
                b: body_text_style.color_b,
                a: body_text_style.color_a,
              },
              align: @selene_math.HAlign::Left,
              baseline: @selene_math.VAlign::Top,
            },
          }),
        )
        y += 30.0
      }
      commands
    }
  }
}

///|
pub fn SeleneUiBackend::ui_overlay_provider(
  self : SeleneUiBackend,
  viewport_w? : Double = 1280.0,
  viewport_h? : Double = 720.0,
) -> () -> Array[@selene_render2d_types.DrawCommand2D] {
  () => self.ui_overlay_commands(viewport_w~, viewport_h~)
}

///|
pub struct SeleneUiPortFactory {
  backend : SeleneUiBackend
}

///|
pub fn SeleneUiPortFactory::new(
  ui_strings? : UiStrings = UiStrings::default(),
  overlay_text_theme? : SeleneOverlayTextTheme = SeleneOverlayTextTheme::default(),
  text_font_family? : String = "",
  script_locale_json? : String = "",
  script_default_locale_json? : String = "",
  vocal_locale_dir? : String = "",
  script_locale? : String = "",
  script_default_locale? : String = "",
) -> SeleneUiPortFactory {
  let resolved_overlay_text_theme = match text_font_family {
    "" => overlay_text_theme
    _ => overlay_text_theme.with_family(text_font_family)
  }
  {
    backend: SeleneUiBackend::new(
      ui_strings~,
      overlay_text_theme=resolved_overlay_text_theme,
      script_locale_json=match script_locale_json {
        "" => None
        _ => Some(script_locale_json)
      },
      script_default_locale_json=match script_default_locale_json {
        "" => None
        _ => Some(script_default_locale_json)
      },
      vocal_locale_dir~,
      script_locale~,
      script_default_locale~,
    ),
  }
}

///|
pub fn SeleneUiPortFactory::push_action(
  self : SeleneUiPortFactory,
  action : String,
) -> Unit {
  self.backend.push_action(action)
}

///|
pub fn SeleneUiPortFactory::push_video_action(
  self : SeleneUiPortFactory,
  action : String,
) -> Unit {
  self.backend.push_video_action(action)
}

///|
pub fn SeleneUiPortFactory::push_selected_choice(
  self : SeleneUiPortFactory,
  id : String,
) -> Unit {
  self.backend.push_selected_choice(id)
}

///|
pub fn SeleneUiPortFactory::push_submitted_text_input(
  self : SeleneUiPortFactory,
  text : String,
) -> Unit {
  self.backend.push_submitted_text_input(text)
}

///|
pub fn SeleneUiPortFactory::push_click(self : SeleneUiPortFactory) -> Unit {
  self.backend.push_click()
}

///|
pub fn SeleneUiPortFactory::last_view(
  self : SeleneUiPortFactory,
) -> UiViewModel? {
  self.backend.last_view()
}

///|
pub fn SeleneUiPortFactory::ui_overlay_commands(
  self : SeleneUiPortFactory,
  viewport_w? : Double = 1280.0,
  viewport_h? : Double = 720.0,
) -> Array[@selene_render2d_types.DrawCommand2D] {
  self.backend.ui_overlay_commands(viewport_w~, viewport_h~)
}

///|
pub fn SeleneUiPortFactory::ui_overlay_provider(
  self : SeleneUiPortFactory,
  viewport_w? : Double = 1280.0,
  viewport_h? : Double = 720.0,
) -> () -> Array[@selene_render2d_types.DrawCommand2D] {
  self.backend.ui_overlay_provider(viewport_w~, viewport_h~)
}

///|
pub impl UiPortFactory for SeleneUiPortFactory with create_port(
  self,
  ui_strings~,
  script_locale_json~,
  script_default_locale_json~,
  vocal_locale_dir~,
  script_locale~,
  script_default_locale~,
) {
  self.backend.set_ui_strings(ui_strings)
  self.backend.set_script_localization(
    script_locale_json=match script_locale_json {
      "" => None
      _ => Some(script_locale_json)
    },
    script_default_locale_json=match script_default_locale_json {
      "" => None
      _ => Some(script_default_locale_json)
    },
    vocal_locale_dir~,
    script_locale~,
    script_default_locale~,
  )
  UiPort::from_backend(self.backend, self.backend)
}
