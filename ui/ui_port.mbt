///|
/// Phase-A platform seam for game UI access.

///|
pub struct UiPort {
  dom : UiDom
}

///|
pub fn UiPort::from_dom(dom : UiDom) -> UiPort {
  { dom, }
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
pub fn UiPort::as_dom(self : UiPort) -> UiDom {
  self.dom
}

///|
pub fn UiPort::localize_vocal_url(self : UiPort, raw : String) -> String {
  self.dom.localize_vocal_url(raw)
}

///|
pub fn UiPort::render(self : UiPort, view : UiViewModel) -> Unit {
  self.dom.render(view)
}

///|
pub fn UiPort::advance_dom_animation_timer(
  self : UiPort,
  elapsed_ms : Int,
) -> Unit {
  self.dom.advance_dom_animation_timer(elapsed_ms)
}

///|
pub fn UiPort::has_active_dom_animations(self : UiPort) -> Bool {
  self.dom.has_active_dom_animations()
}

///|
pub fn UiPort::take_selected_choice(self : UiPort) -> String? {
  self.dom.take_selected_choice()
}

///|
pub fn UiPort::take_submitted_text_input(self : UiPort) -> String? {
  self.dom.take_submitted_text_input()
}

///|
pub fn UiPort::take_action(self : UiPort) -> String? {
  self.dom.take_action()
}

///|
pub fn UiPort::take_video_action(self : UiPort) -> String? {
  self.dom.take_video_action()
}

///|
pub fn UiPort::check_typewriter_click(self : UiPort) -> Bool {
  self.dom.check_typewriter_click()
}

///|
pub fn UiPort::check_intro_done(self : UiPort) -> Bool {
  self.dom.check_intro_done()
}

///|
pub fn UiPort::reveal_intro_line(self : UiPort) -> Bool {
  self.dom.reveal_intro_line()
}

///|
pub fn UiPort::mark_all_dirty(self : UiPort) -> Unit {
  self.dom.mark_all_dirty()
}

///|
pub fn UiPort::mark_dirty_text(self : UiPort) -> Unit {
  self.dom.mark_dirty_text()
}

///|
pub fn UiPort::mark_dirty_text_and_speaker(self : UiPort) -> Unit {
  self.dom.mark_dirty_text_and_speaker()
}

///|
pub fn UiPort::mark_dirty_choices(self : UiPort) -> Unit {
  self.dom.mark_dirty_choices()
}

///|
pub fn UiPort::mark_dirty_text_input(self : UiPort) -> Unit {
  self.dom.mark_dirty_text_input()
}

///|
pub fn UiPort::mark_dirty_action_buttons(self : UiPort) -> Unit {
  self.dom.mark_dirty_action_buttons()
}

///|
pub fn UiPort::clear_game_ui(self : UiPort) -> Unit {
  self.dom.clear_game_ui()
}

///|
pub fn UiPort::set_text_speed(self : UiPort, speed : Int) -> Unit {
  self.dom.set_text_speed(speed)
}

///|
pub fn UiPort::set_media_volume(self : UiPort, volume : Double) -> Unit {
  self.dom.set_media_volume(volume)
}

///|
pub fn UiPort::toggle_auto_mode(self : UiPort) -> Unit {
  self.dom.toggle_auto_mode()
}

///|
pub fn UiPort::toggle_skip_mode(self : UiPort) -> Unit {
  self.dom.toggle_skip_mode()
}

///|
pub fn UiPort::set_skip_hold(self : UiPort, enabled : Bool) -> Unit {
  self.dom.set_skip_hold(enabled)
}

///|
pub fn UiPort::is_skip_active(self : UiPort) -> Bool {
  self.dom.is_skip_active()
}

///|
pub fn UiPort::set_log_visible(self : UiPort, visible : Bool) -> Unit {
  self.dom.set_log_visible(visible)
}

///|
pub fn UiPort::toggle_log_visible(self : UiPort) -> Unit {
  self.dom.toggle_log_visible()
}

///|
pub fn UiPort::is_log_visible(self : UiPort) -> Bool {
  self.dom.is_log_visible()
}

///|
pub fn UiPort::set_ui_strings(self : UiPort, ui_strings : UiStrings) -> Unit {
  self.dom.set_ui_strings(ui_strings)
}

///|
pub fn UiPort::set_script_localization(
  self : UiPort,
  script_locale_json : String?,
  script_default_locale_json : String?,
  vocal_locale_dir : String,
  script_locale : String,
  script_default_locale : String,
) -> Unit {
  self.dom.set_script_localization(
    script_locale_json, script_default_locale_json, vocal_locale_dir, script_locale,
    script_default_locale,
  )
}

///|
pub fn UiPort::advance_auto_mode_timer(self : UiPort, elapsed_ms : Int) -> Unit {
  self.dom.advance_auto_mode_timer(elapsed_ms~)
}

///|
pub fn UiPort::should_auto_skip_wait_click(self : UiPort) -> Bool {
  self.dom.should_auto_skip_wait_click()
}

///|
pub fn UiPort::mark_auto_advanced(self : UiPort) -> Unit {
  self.dom.mark_auto_advanced()
}

///|
pub fn UiPort::advance_skip_mode_timer(self : UiPort, elapsed_ms : Int) -> Unit {
  self.dom.advance_skip_mode_timer(elapsed_ms~)
}

///|
pub fn UiPort::should_skip_advance(self : UiPort) -> Bool {
  self.dom.should_skip_advance()
}

///|
pub fn UiPort::complete_typewriter(self : UiPort) -> Unit {
  self.dom.complete_typewriter()
}

///|
pub fn UiPort::mark_skip_advanced(self : UiPort) -> Unit {
  self.dom.mark_skip_advanced()
}

///|
pub fn UiPort::is_typewriter_done(self : UiPort) -> Bool {
  self.dom.is_typewriter_done()
}

///|
pub fn UiPort::advance_typewriter(self : UiPort, elapsed_ms : Int) -> Bool {
  self.dom.advance_typewriter(elapsed_ms~)
}

///|
pub fn UiPort::should_auto_advance(self : UiPort) -> Bool {
  self.dom.should_auto_advance()
}

///|
pub fn UiPort::simulate_click(self : UiPort) -> Unit {
  self.dom.simulate_click()
}

///|
pub struct AudioPort {
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
