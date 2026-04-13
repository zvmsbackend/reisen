///|
/// Phase-A platform seam for game UI access.

///|
pub(open) trait UiBackend {
  localize_vocal_url(Self, String) -> String
  render(Self, UiViewModel) -> Unit
  view_model_from_snapshot(Self, UiSnapshot) -> UiViewModel
  advance_dom_animation_timer(Self, Int) -> Unit
  has_active_dom_animations(Self) -> Bool
  take_selected_choice(Self) -> String?
  take_submitted_text_input(Self) -> String?
  take_action(Self) -> String?
  take_video_action(Self) -> String?
  check_typewriter_click(Self) -> Bool
  check_intro_done(Self) -> Bool
  reveal_intro_line(Self) -> Bool
  clear_game_ui(Self) -> Unit
  set_text_speed(Self, Int) -> Unit
  set_media_volume(Self, Double) -> Unit
  toggle_auto_mode(Self) -> Unit
  toggle_skip_mode(Self) -> Unit
  set_skip_hold(Self, Bool) -> Unit
  is_skip_active(Self) -> Bool
  set_log_visible(Self, Bool) -> Unit
  set_ui_strings(Self, UiStrings) -> Unit
  set_script_localization(
    Self,
    script_locale_json~ : String?,
    script_default_locale_json~ : String?,
    vocal_locale_dir~ : String,
    script_locale~ : String,
    script_default_locale~ : String,
  ) -> Unit
  advance_auto_mode_timer(Self, elapsed_ms~ : Int) -> Unit
  should_auto_skip_wait_click(Self) -> Bool
  mark_auto_advanced(Self) -> Unit
  advance_skip_mode_timer(Self, elapsed_ms~ : Int) -> Unit
  should_skip_advance(Self) -> Bool
  complete_typewriter(Self) -> Unit
  mark_skip_advanced(Self) -> Unit
  is_typewriter_done(Self) -> Bool
  advance_typewriter(Self, elapsed_ms~ : Int) -> Bool
  should_auto_advance(Self) -> Bool
  simulate_click(Self) -> Unit
}

///|
pub impl UiBackend for UiDom with localize_vocal_url(self, raw) {
  UiDom::localize_vocal_url(self, raw)
}

///|
pub impl UiBackend for UiDom with render(self, view) {
  UiDom::render(self, view)
}

///|
pub impl UiBackend for UiDom with view_model_from_snapshot(self, snapshot) {
  UiViewModel::from_snapshot(snapshot, self)
}

///|
pub impl UiBackend for UiDom with advance_dom_animation_timer(self, elapsed_ms) {
  UiDom::advance_dom_animation_timer(self, elapsed_ms)
}

///|
pub impl UiBackend for UiDom with has_active_dom_animations(self) {
  UiDom::has_active_dom_animations(self)
}

///|
pub impl UiBackend for UiDom with take_selected_choice(self) {
  UiDom::take_selected_choice(self)
}

///|
pub impl UiBackend for UiDom with take_submitted_text_input(self) {
  UiDom::take_submitted_text_input(self)
}

///|
pub impl UiBackend for UiDom with take_action(self) {
  UiDom::take_action(self)
}

///|
pub impl UiBackend for UiDom with take_video_action(self) {
  UiDom::take_video_action(self)
}

///|
pub impl UiBackend for UiDom with check_typewriter_click(self) {
  UiDom::check_typewriter_click(self)
}

///|
pub impl UiBackend for UiDom with check_intro_done(self) {
  UiDom::check_intro_done(self)
}

///|
pub impl UiBackend for UiDom with reveal_intro_line(self) {
  UiDom::reveal_intro_line(self)
}

///|
pub impl UiBackend for UiDom with clear_game_ui(self) {
  UiDom::clear_game_ui(self)
}

///|
pub impl UiBackend for UiDom with set_text_speed(self, speed) {
  UiDom::set_text_speed(self, speed)
}

///|
pub impl UiBackend for UiDom with set_media_volume(self, volume) {
  UiDom::set_media_volume(self, volume)
}

///|
pub impl UiBackend for UiDom with toggle_auto_mode(self) {
  UiDom::toggle_auto_mode(self)
}

///|
pub impl UiBackend for UiDom with toggle_skip_mode(self) {
  UiDom::toggle_skip_mode(self)
}

///|
pub impl UiBackend for UiDom with set_skip_hold(self, enabled) {
  UiDom::set_skip_hold(self, enabled)
}

///|
pub impl UiBackend for UiDom with is_skip_active(self) {
  UiDom::is_skip_active(self)
}

///|
pub impl UiBackend for UiDom with set_log_visible(self, visible) {
  UiDom::set_log_visible(self, visible)
}

///|
pub impl UiBackend for UiDom with set_ui_strings(self, ui_strings) {
  UiDom::set_ui_strings(self, ui_strings)
}

///|
pub impl UiBackend for UiDom with set_script_localization(
  self,
  script_locale_json~,
  script_default_locale_json~,
  vocal_locale_dir~,
  script_locale~,
  script_default_locale~,
) {
  UiDom::set_script_localization(
    self,
    script_locale_json~,
    script_default_locale_json~,
    vocal_locale_dir~,
    script_locale~,
    script_default_locale~,
  )
}

///|
pub impl UiBackend for UiDom with advance_auto_mode_timer(self, elapsed_ms~) {
  UiDom::advance_auto_mode_timer(self, elapsed_ms~)
}

///|
pub impl UiBackend for UiDom with should_auto_skip_wait_click(self) {
  UiDom::should_auto_skip_wait_click(self)
}

///|
pub impl UiBackend for UiDom with mark_auto_advanced(self) {
  UiDom::mark_auto_advanced(self)
}

///|
pub impl UiBackend for UiDom with advance_skip_mode_timer(self, elapsed_ms~) {
  UiDom::advance_skip_mode_timer(self, elapsed_ms~)
}

///|
pub impl UiBackend for UiDom with should_skip_advance(self) {
  UiDom::should_skip_advance(self)
}

///|
pub impl UiBackend for UiDom with complete_typewriter(self) {
  UiDom::complete_typewriter(self)
}

///|
pub impl UiBackend for UiDom with mark_skip_advanced(self) {
  UiDom::mark_skip_advanced(self)
}

///|
pub impl UiBackend for UiDom with is_typewriter_done(self) {
  UiDom::is_typewriter_done(self)
}

///|
pub impl UiBackend for UiDom with advance_typewriter(self, elapsed_ms~) {
  UiDom::advance_typewriter(self, elapsed_ms~)
}

///|
pub impl UiBackend for UiDom with should_auto_advance(self) {
  UiDom::should_auto_advance(self)
}

///|
pub impl UiBackend for UiDom with simulate_click(self) {
  UiDom::simulate_click(self)
}

///|
struct UiPort {
  core : UiCoreState
  backend : &UiBackend
}

///|
priv struct UiCoreState {
  mut text_speed : Int
  mut typewriter_text : DialogText
  mut last_dialog_seq : Int
  mut typewriter_visible : Int
  mut typewriter_last_update_ms : Int
  mut auto_mode : Bool
  auto_mode_delay_ms : Int
  wait_click_auto_skip_delay_ms : Int
  mut auto_mode_last_advance_ms : Int
  mut skip_mode : Bool
  mut skip_hold : Bool
  skip_mode_delay_ms : Int
  mut skip_mode_last_advance_ms : Int
  mut simulated_click : Bool
  mut simulated_intro_done : Bool
  mut log_visible : Bool
  mut dirty_speaker : Bool
  mut dirty_text : Bool
  mut dirty_choices : Bool
  mut dirty_text_input : Bool
  mut dirty_action_buttons : Bool
}

///|
fn UiCoreState::new() -> UiCoreState {
  {
    text_speed: 50,
    typewriter_text: DialogText::empty(),
    last_dialog_seq: -1,
    typewriter_visible: 0,
    typewriter_last_update_ms: 0,
    auto_mode: false,
    auto_mode_delay_ms: 2000,
    wait_click_auto_skip_delay_ms: 160,
    auto_mode_last_advance_ms: 0,
    skip_mode: false,
    skip_hold: false,
    skip_mode_delay_ms: 50,
    skip_mode_last_advance_ms: 0,
    simulated_click: false,
    simulated_intro_done: false,
    log_visible: false,
    dirty_speaker: true,
    dirty_text: true,
    dirty_choices: true,
    dirty_text_input: true,
    dirty_action_buttons: true,
  }
}

///|
fn UiCoreState::is_skip_active(self : UiCoreState) -> Bool {
  self.skip_mode || self.skip_hold
}

///|
fn UiCoreState::text_speed_ms_per_char(self : UiCoreState) -> Int {
  if self.text_speed <= 0 {
    100
  } else {
    2000 / self.text_speed
  }
}

///|
fn UiCoreState::is_typewriter_done(self : UiCoreState) -> Bool {
  self.typewriter_visible >= self.typewriter_text.length()
}

///|
fn UiCoreState::sync_from_snapshot(
  self : UiCoreState,
  snapshot : UiSnapshot,
) -> Unit {
  defer {
    self.last_dialog_seq = snapshot.dialog_seq
  }
  guard snapshot.dialog is Some((_, text, typewriter, append)) else {
    self.typewriter_text = DialogText::empty()
    self.typewriter_visible = 0
    self.typewriter_last_update_ms = 0
  }
  if snapshot.dialog_seq == self.last_dialog_seq {
    return
  }
  if append && typewriter && !self.is_skip_active() {
    let prev_len = self.typewriter_text.length()
    self.typewriter_text = text
    if self.typewriter_visible < prev_len {
      self.typewriter_visible = prev_len
    }
    if self.typewriter_visible > self.typewriter_text.length() {
      self.typewriter_visible = self.typewriter_text.length()
    }
    self.typewriter_last_update_ms = 0
  } else if typewriter && !self.is_skip_active() {
    self.typewriter_text = text
    self.typewriter_visible = 0
    self.typewriter_last_update_ms = 0
  } else {
    self.typewriter_text = text
    self.typewriter_visible = self.typewriter_text.length()
    self.typewriter_last_update_ms = 0
  }
}

///|
fn UiCoreState::mark_all_dirty(self : UiCoreState) -> Unit {
  self.dirty_speaker = true
  self.dirty_text = true
  self.dirty_choices = true
  self.dirty_text_input = true
  self.dirty_action_buttons = true
}

///|
fn UiCoreState::clear_render_dirty_after_frame(self : UiCoreState) -> Unit {
  self.dirty_speaker = false
  self.dirty_text = false
  self.dirty_choices = false
  self.dirty_text_input = false
  self.dirty_action_buttons = false
}

///|
pub fn UiPort::from_dom(dom : UiDom) -> UiPort {
  { core: UiCoreState::new(), backend: dom }
}

///|
pub fn UiPort::from_backend(backend : &UiBackend) -> UiPort {
  { core: UiCoreState::new(), backend }
}

///|
pub fn UiPort::new(
  root_id : String,
  ui_strings? : UiStrings = UiStrings::default(),
  script_locale_json? : String = "",
  script_default_locale_json? : String = "",
  vocal_locale_dir? : String = "",
  script_locale? : String = "",
  script_default_locale? : String = "",
) -> UiPort {
  UiPort::from_dom(
    UiDom::new(
      root_id,
      ui_strings~,
      script_locale_json~,
      script_default_locale_json~,
      vocal_locale_dir~,
      script_locale~,
      script_default_locale~,
    ),
  )
}

///|
pub fn UiPort::localize_vocal_url(self : UiPort, raw : String) -> String {
  self.backend.localize_vocal_url(raw)
}

///|
pub fn UiPort::render(self : UiPort, view : UiViewModel) -> Unit {
  self.backend.render(view)
  if view.video is Some(_) || view.intro_text is Some(_) {
    return
  }
  self.core.clear_render_dirty_after_frame()
}

///|
pub fn UiPort::view_model_from_snapshot(
  self : UiPort,
  snapshot : UiSnapshot,
) -> UiViewModel {
  self.core.sync_from_snapshot(snapshot)
  let view = self.backend.view_model_from_snapshot(snapshot)
  {
    ..view,
    auto_mode: self.core.auto_mode,
    skip_mode: self.core.is_skip_active(),
    log_visible: self.core.log_visible,
    dirty_speaker: self.core.dirty_speaker,
    dirty_text: self.core.dirty_text,
    dirty_choices: self.core.dirty_choices,
    dirty_text_input: self.core.dirty_text_input,
    dirty_action_buttons: self.core.dirty_action_buttons,
  }
}

///|
pub fn UiPort::advance_dom_animation_timer(
  self : UiPort,
  elapsed_ms : Int,
) -> Unit {
  self.backend.advance_dom_animation_timer(elapsed_ms)
}

///|
pub fn UiPort::has_active_dom_animations(self : UiPort) -> Bool {
  self.backend.has_active_dom_animations()
}

///|
pub fn UiPort::take_selected_choice(self : UiPort) -> String? {
  self.backend.take_selected_choice()
}

///|
pub fn UiPort::take_submitted_text_input(self : UiPort) -> String? {
  self.backend.take_submitted_text_input()
}

///|
pub fn UiPort::take_action(self : UiPort) -> String? {
  self.backend.take_action()
}

///|
pub fn UiPort::take_video_action(self : UiPort) -> String? {
  self.backend.take_video_action()
}

///|
pub fn UiPort::check_typewriter_click(self : UiPort) -> Bool {
  if self.core.simulated_click {
    self.core.simulated_click = false
    return true
  }
  self.backend.check_typewriter_click()
}

///|
pub fn UiPort::check_intro_done(self : UiPort) -> Bool {
  if self.core.simulated_intro_done {
    self.core.simulated_intro_done = false
    return true
  }
  self.backend.check_intro_done()
}

///|
pub fn UiPort::reveal_intro_line(self : UiPort) -> Bool {
  self.backend.reveal_intro_line()
}

///|
pub fn UiPort::mark_all_dirty(self : UiPort) -> Unit {
  self.core.mark_all_dirty()
}

///|
pub fn UiPort::mark_dirty_text(self : UiPort) -> Unit {
  self.core.dirty_text = true
}

///|
pub fn UiPort::mark_dirty_text_and_speaker(self : UiPort) -> Unit {
  self.core.dirty_speaker = true
  self.core.dirty_text = true
}

///|
pub fn UiPort::mark_dirty_choices(self : UiPort) -> Unit {
  self.core.dirty_choices = true
}

///|
pub fn UiPort::mark_dirty_text_input(self : UiPort) -> Unit {
  self.core.dirty_text_input = true
}

///|
pub fn UiPort::mark_dirty_action_buttons(self : UiPort) -> Unit {
  self.core.dirty_action_buttons = true
}

///|
pub fn UiPort::clear_game_ui(self : UiPort) -> Unit {
  self.core.typewriter_text = DialogText::empty()
  self.core.typewriter_visible = 0
  self.core.typewriter_last_update_ms = 0
  self.core.last_dialog_seq = -1
  self.core.auto_mode_last_advance_ms = 0
  self.core.skip_mode_last_advance_ms = 0
  self.core.mark_all_dirty()
  self.backend.clear_game_ui()
}

///|
pub fn UiPort::set_text_speed(self : UiPort, speed : Int) -> Unit {
  let clamped = if speed < 10 { 10 } else if speed > 100 { 100 } else { speed }
  self.core.text_speed = clamped
  self.backend.set_text_speed(clamped)
}

///|
pub fn UiPort::set_media_volume(self : UiPort, volume : Double) -> Unit {
  self.backend.set_media_volume(volume)
}

///|
pub fn UiPort::toggle_auto_mode(self : UiPort) -> Unit {
  self.core.auto_mode = !self.core.auto_mode
  if self.core.auto_mode {
    self.core.auto_mode_last_advance_ms = 0
  }
  self.backend.toggle_auto_mode()
  self.core.dirty_action_buttons = true
}

///|
pub fn UiPort::toggle_skip_mode(self : UiPort) -> Unit {
  self.core.skip_mode = !self.core.skip_mode
  if self.core.skip_mode {
    self.core.skip_mode_last_advance_ms = 0
  }
  self.backend.toggle_skip_mode()
  self.core.dirty_action_buttons = true
}

///|
pub fn UiPort::set_skip_hold(self : UiPort, enabled : Bool) -> Unit {
  self.core.skip_hold = enabled
  if enabled {
    self.core.skip_mode_last_advance_ms = 0
  }
  self.backend.set_skip_hold(enabled)
  self.core.dirty_action_buttons = true
}

///|
pub fn UiPort::is_skip_active(self : UiPort) -> Bool {
  self.core.is_skip_active() || self.backend.is_skip_active()
}

///|
pub fn UiPort::set_log_visible(self : UiPort, visible : Bool) -> Unit {
  self.core.log_visible = visible
  self.core.dirty_text = true
  self.core.dirty_action_buttons = true
  self.backend.set_log_visible(visible)
}

///|
pub fn UiPort::toggle_log_visible(self : UiPort) -> Unit {
  let next = !self.core.log_visible
  self.core.log_visible = next
  self.core.dirty_text = true
  self.core.dirty_action_buttons = true
}

///|
pub fn UiPort::is_log_visible(self : UiPort) -> Bool {
  self.core.log_visible
}

///|
pub fn UiPort::set_ui_strings(self : UiPort, ui_strings : UiStrings) -> Unit {
  self.core.mark_all_dirty()
  self.backend.set_ui_strings(ui_strings)
}

///|
pub fn UiPort::set_script_localization(
  self : UiPort,
  script_locale_json~ : String?,
  script_default_locale_json~ : String?,
  vocal_locale_dir~ : String,
  script_locale~ : String,
  script_default_locale~ : String,
) -> Unit {
  self.core.mark_all_dirty()
  self.backend.set_script_localization(
    script_locale_json~,
    script_default_locale_json~,
    vocal_locale_dir~,
    script_locale~,
    script_default_locale~,
  )
}

///|
pub fn UiPort::advance_auto_mode_timer(self : UiPort, elapsed_ms : Int) -> Unit {
  self.backend.advance_auto_mode_timer(elapsed_ms~)
  if !self.core.auto_mode {
    return
  }
  if !self.is_typewriter_done() {
    return
  }
  self.core.auto_mode_last_advance_ms += elapsed_ms
}

///|
pub fn UiPort::should_auto_skip_wait_click(self : UiPort) -> Bool {
  if self.backend.should_auto_skip_wait_click() {
    return true
  }
  if !self.core.auto_mode {
    return false
  }
  self.core.auto_mode_last_advance_ms >= self.core.wait_click_auto_skip_delay_ms
}

///|
pub fn UiPort::mark_auto_advanced(self : UiPort) -> Unit {
  self.core.auto_mode_last_advance_ms = 0
  self.backend.mark_auto_advanced()
}

///|
pub fn UiPort::advance_skip_mode_timer(self : UiPort, elapsed_ms : Int) -> Unit {
  self.backend.advance_skip_mode_timer(elapsed_ms~)
  if !self.core.is_skip_active() {
    return
  }
  if !self.is_typewriter_done() {
    return
  }
  self.core.skip_mode_last_advance_ms += elapsed_ms
}

///|
pub fn UiPort::should_skip_advance(self : UiPort) -> Bool {
  if self.backend.should_skip_advance() {
    return true
  }
  if !self.core.is_skip_active() {
    return false
  }
  if !self.is_typewriter_done() {
    return false
  }
  self.core.skip_mode_last_advance_ms >= self.core.skip_mode_delay_ms
}

///|
pub fn UiPort::complete_typewriter(self : UiPort) -> Unit {
  self.core.typewriter_visible = self.core.typewriter_text.length()
  self.backend.complete_typewriter()
}

///|
pub fn UiPort::mark_skip_advanced(self : UiPort) -> Unit {
  self.core.skip_mode_last_advance_ms = 0
  self.backend.mark_skip_advanced()
}

///|
pub fn UiPort::is_typewriter_done(self : UiPort) -> Bool {
  self.core.is_typewriter_done() || self.backend.is_typewriter_done()
}

///|
pub fn UiPort::advance_typewriter(self : UiPort, elapsed_ms : Int) -> Bool {
  let backend_done = self.backend.advance_typewriter(elapsed_ms~)
  if self.core.is_typewriter_done() {
    return true
  }
  self.core.typewriter_last_update_ms += elapsed_ms
  let ms_per_char = self.core.text_speed_ms_per_char()
  if self.core.typewriter_last_update_ms >= ms_per_char {
    let chars_to_add = self.core.typewriter_last_update_ms / ms_per_char
    self.core.typewriter_last_update_ms = self.core.typewriter_last_update_ms %
      ms_per_char
    self.core.typewriter_visible += chars_to_add
    if self.core.typewriter_visible > self.core.typewriter_text.length() {
      self.core.typewriter_visible = self.core.typewriter_text.length()
    }
  }
  self.core.is_typewriter_done() || backend_done
}

///|
pub fn UiPort::should_auto_advance(self : UiPort) -> Bool {
  if self.backend.should_auto_advance() {
    return true
  }
  if !self.core.auto_mode {
    return false
  }
  if !self.is_typewriter_done() {
    return false
  }
  self.core.auto_mode_last_advance_ms >= self.core.auto_mode_delay_ms
}

///|
pub fn UiPort::simulate_click(self : UiPort) -> Unit {
  self.core.simulated_click = true
  self.backend.simulate_click()
}

///|
struct AudioPort {
  has_active_sfx_impl : () -> Bool
  set_bgm_gain_impl : (Double) -> Unit
  set_sfx_gain_impl : (Double) -> Unit
}

///|
pub fn AudioPort::new(
  has_active_sfx_impl : () -> Bool,
  set_bgm_gain_impl : (Double) -> Unit,
  set_sfx_gain_impl : (Double) -> Unit,
) -> AudioPort {
  { has_active_sfx_impl, set_bgm_gain_impl, set_sfx_gain_impl }
}

///|
pub fn AudioPort::browser() -> AudioPort {
  AudioPort::new(
    AudioDom::has_active_sfx,
    AudioDom::set_bgm_gain,
    AudioDom::set_sfx_gain,
  )
}

///|
pub fn AudioPort::has_active_sfx(self : AudioPort) -> Bool {
  (self.has_active_sfx_impl)()
}

///|
pub fn AudioPort::set_bgm_gain(self : AudioPort, gain : Double) -> Unit {
  (self.set_bgm_gain_impl)(gain)
}

///|
pub fn AudioPort::set_sfx_gain(self : AudioPort, gain : Double) -> Unit {
  (self.set_sfx_gain_impl)(gain)
}
