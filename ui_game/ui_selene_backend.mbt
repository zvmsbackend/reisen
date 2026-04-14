///|
struct SeleneUiBackend {
  mut ui_strings : UiStrings
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
  mut last_view : UiViewModel?
}

///|
pub fn SeleneUiBackend::new(
  ui_strings? : UiStrings = UiStrings::default(),
  script_locale_json? : String? = None,
  script_default_locale_json? : String? = None,
  vocal_locale_dir? : String = "",
  script_locale? : String = "",
  script_default_locale? : String = "",
) -> SeleneUiBackend {
  {
    ui_strings,
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
fn selene_view_from_snapshot(snapshot : UiSnapshot) -> UiViewModel {
  let (speaker, text) = match snapshot.dialog {
    Some((speaker, text, _, _)) => (speaker, text)
    None => (DialogText::empty(), DialogText::empty())
  }
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
  let choices = snapshot.choices.map(opt => { id: opt.id, text: opt.text })
  let text_input = match snapshot.text_input {
    Some((var_name, prompt)) => Some({ var_name, prompt })
    None => None
  }
  {
    speaker,
    text,
    dialog_seq: snapshot.dialog_seq,
    typewriter,
    intro_text: snapshot.intro_text,
    video,
    append,
    text_box_visible: snapshot.text_box_visible,
    avatar_id: snapshot.avatar_id,
    choices,
    text_input,
    dialog_history: snapshot.dialog_history,
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
  if !raw.has_prefix("@") {
    return raw
  }
  let key = raw[1:].to_string()
  if key == "" {
    return raw
  }
  if self.vocal_locale_dir == "" {
    return key
  }
  let locale = match self.script_locale {
    "" => self.script_default_locale
    _ => self.script_locale
  }
  match locale {
    "" => "\{self.vocal_locale_dir}/\{key}"
    _ => "\{self.vocal_locale_dir}/\{locale}/\{key}"
  }
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
  ignore(self.script_locale_json)
  ignore(self.script_default_locale_json)
  selene_view_from_snapshot(snapshot)
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
  ignore(self)
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
