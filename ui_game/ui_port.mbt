///|
struct UiPort {
  core : UiCoreState
  backend : &UiBackend
  hooks : &UiPlatformHooks
}

///|
pub fn[T : UiBackend + UiPlatformHooks] UiPort::from_dom(dom : T) -> UiPort {
  { core: UiCoreState::new(), backend: dom, hooks: dom }
}

///|
pub fn UiPort::from_backend(
  backend : &UiBackend,
  hooks : &UiPlatformHooks,
) -> UiPort {
  { core: UiCoreState::new(), backend, hooks }
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
    text: self.core.visible_text(),
    typewriter: false,
    append: false,
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
pub fn UiPort::advance_ui_animation_timer(
  self : UiPort,
  elapsed_ms : Int,
) -> Unit {
  self.hooks.advance_ui_animation_timer(elapsed_ms)
}

///|
pub fn UiPort::has_active_ui_animations(self : UiPort) -> Bool {
  self.hooks.has_active_ui_animations()
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
}

///|
pub fn UiPort::set_media_volume(self : UiPort, volume : Double) -> Unit {
  self.hooks.set_media_volume(volume)
}

///|
pub fn UiPort::toggle_auto_mode(self : UiPort) -> Unit {
  self.core.auto_mode = !self.core.auto_mode
  if self.core.auto_mode {
    self.core.auto_mode_last_advance_ms = 0
  }
  self.core.dirty_action_buttons = true
}

///|
pub fn UiPort::toggle_skip_mode(self : UiPort) -> Unit {
  self.core.skip_mode = !self.core.skip_mode
  if self.core.skip_mode {
    self.core.skip_mode_last_advance_ms = 0
  }
  self.core.dirty_action_buttons = true
}

///|
pub fn UiPort::set_skip_hold(self : UiPort, enabled : Bool) -> Unit {
  self.core.skip_hold = enabled
  if enabled {
    self.core.skip_mode_last_advance_ms = 0
  }
  self.core.dirty_action_buttons = true
}

///|
pub fn UiPort::is_skip_active(self : UiPort) -> Bool {
  self.core.is_skip_active()
}

///|
pub fn UiPort::set_log_visible(self : UiPort, visible : Bool) -> Unit {
  self.core.log_visible = visible
  self.core.dirty_text = true
  self.core.dirty_action_buttons = true
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
  if !self.core.auto_mode {
    return false
  }
  self.core.auto_mode_last_advance_ms >= self.core.wait_click_auto_skip_delay_ms
}

///|
pub fn UiPort::mark_auto_advanced(self : UiPort) -> Unit {
  self.core.auto_mode_last_advance_ms = 0
}

///|
pub fn UiPort::advance_skip_mode_timer(self : UiPort, elapsed_ms : Int) -> Unit {
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
}

///|
pub fn UiPort::mark_skip_advanced(self : UiPort) -> Unit {
  self.core.skip_mode_last_advance_ms = 0
}

///|
pub fn UiPort::is_typewriter_done(self : UiPort) -> Bool {
  self.core.is_typewriter_done()
}

///|
pub fn UiPort::advance_typewriter(self : UiPort, elapsed_ms : Int) -> Bool {
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
  self.core.is_typewriter_done()
}

///|
pub fn UiPort::should_auto_advance(self : UiPort) -> Bool {
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
pub(open) trait UiPortFactory {
  create_port(
    Self,
    ui_strings~ : UiStrings,
    script_locale_json~ : String,
    script_default_locale_json~ : String,
    vocal_locale_dir~ : String,
    script_locale~ : String,
    script_default_locale~ : String,
  ) -> UiPort
}
