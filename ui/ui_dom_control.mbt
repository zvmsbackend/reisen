///|
pub fn UiDom::set_text_speed(self : UiDom, speed : Int) -> Unit {
  let clamped = if speed < 10 { 10 } else if speed > 100 { 100 } else { speed }
  self.text_speed = clamped
}

///|
pub fn UiDom::text_speed_ms_per_char(self : UiDom) -> Int {
  let speed = self.text_speed
  if speed <= 0 {
    100
  } else {
    2000 / speed
  }
}

///|
pub fn UiDom::start_typewriter(self : UiDom, text : DialogText) -> Unit {
  self.typewriter_text = text
  self.typewriter_visible = 0
  self.typewriter_last_update_ms = 0
}

///|
pub fn UiDom::is_typewriter_done(self : UiDom) -> Bool {
  self.typewriter_visible >= self.typewriter_text.length()
}

///|
pub fn UiDom::typewriter_visible_text(self : UiDom) -> DialogText {
  self.typewriter_text.slice(self.typewriter_visible)
}

///|
pub fn UiDom::advance_typewriter(self : UiDom, elapsed_ms~ : Int) -> Bool {
  if self.is_typewriter_done() {
    return true
  }
  self.typewriter_last_update_ms += elapsed_ms
  let ms_per_char = self.text_speed_ms_per_char()
  if self.typewriter_last_update_ms >= ms_per_char {
    let chars_to_add = self.typewriter_last_update_ms / ms_per_char
    self.typewriter_last_update_ms = self.typewriter_last_update_ms %
      ms_per_char
    self.typewriter_visible += chars_to_add
    if self.typewriter_visible > self.typewriter_text.length() {
      self.typewriter_visible = self.typewriter_text.length()
    }
  }
  self.is_typewriter_done()
}

///|
pub fn UiDom::complete_typewriter(self : UiDom) -> Unit {
  self.typewriter_visible = self.typewriter_text.length()
}

///|
pub fn UiDom::set_auto_mode(self : UiDom, enabled : Bool) -> Unit {
  self.auto_mode = enabled
  if enabled {
    self.auto_mode_last_advance_ms = 0
  }
}

///|
pub fn UiDom::set_media_volume(self : UiDom, volume : Double) -> Unit {
  self.media_volume = if volume < 0.0 {
    0.0
  } else if volume > 1.0 {
    1.0
  } else {
    volume
  }
}

///|
pub fn UiDom::toggle_auto_mode(self : UiDom) -> Unit {
  self.set_auto_mode(not(self.auto_mode))
}

///|
pub fn UiDom::should_auto_advance(self : UiDom) -> Bool {
  if not(self.auto_mode) {
    return false
  }
  if not(self.is_typewriter_done()) {
    return false
  }
  self.auto_mode_last_advance_ms >= self.auto_mode_delay_ms
}

///|
pub fn UiDom::mark_auto_advanced(self : UiDom) -> Unit {
  self.auto_mode_last_advance_ms = 0
}

///|
pub fn UiDom::should_auto_skip_wait_click(self : UiDom) -> Bool {
  if not(self.auto_mode) {
    return false
  }
  self.auto_mode_last_advance_ms >= self.wait_click_auto_skip_delay_ms
}

///|
pub fn UiDom::advance_auto_mode_timer(self : UiDom, elapsed_ms~ : Int) -> Unit {
  if not(self.auto_mode) {
    return
  }
  if not(self.is_typewriter_done()) {
    return
  }
  self.auto_mode_last_advance_ms += elapsed_ms
}

///|
pub fn UiDom::set_skip_mode(self : UiDom, enabled : Bool) -> Unit {
  self.skip_mode = enabled
  if enabled {
    self.skip_mode_last_advance_ms = 0
  }
}

///|
pub fn UiDom::set_skip_hold(self : UiDom, enabled : Bool) -> Unit {
  self.skip_hold = enabled
  if enabled {
    self.skip_mode_last_advance_ms = 0
  }
}

///|
pub fn UiDom::is_skip_active(self : UiDom) -> Bool {
  self.skip_mode || self.skip_hold
}

///|
pub fn UiDom::toggle_skip_mode(self : UiDom) -> Unit {
  self.set_skip_mode(not(self.skip_mode))
}

///|
pub fn UiDom::set_log_visible(self : UiDom, visible : Bool) -> Unit {
  self.log_visible = visible
  self.dirty_text = true
  self.dirty_action_buttons = true
}

///|
pub fn UiDom::toggle_log_visible(self : UiDom) -> Unit {
  self.set_log_visible(not(self.log_visible))
}

///|
pub fn UiDom::is_log_visible(self : UiDom) -> Bool {
  self.log_visible
}

///|
pub fn UiDom::set_ui_strings(self : UiDom, ui_strings : UiStrings) -> Unit {
  self.ui_strings = ui_strings
  self.mark_all_dirty()
}

///|
pub fn UiDom::set_script_localization(
  self : UiDom,
  script_locale_json : String?,
  script_default_locale_json : String?,
  vocal_locale_dir : String,
  script_locale : String,
  script_default_locale : String,
) -> Unit {
  self.script_locale_json = script_locale_json
  self.script_default_locale_json = script_default_locale_json
  self.vocal_locale_dir = vocal_locale_dir
  self.script_locale = script_locale
  self.script_default_locale = script_default_locale
  self.mark_all_dirty()
}

///|
pub fn UiDom::should_skip_advance(self : UiDom) -> Bool {
  if not(self.is_skip_active()) {
    return false
  }
  if not(self.is_typewriter_done()) {
    return false
  }
  self.skip_mode_last_advance_ms >= self.skip_mode_delay_ms
}

///|
pub fn UiDom::advance_skip_mode_timer(self : UiDom, elapsed_ms~ : Int) -> Unit {
  if not(self.is_skip_active()) {
    return
  }
  if not(self.is_typewriter_done()) {
    return
  }
  self.skip_mode_last_advance_ms += elapsed_ms
}

///|
pub fn UiDom::mark_skip_advanced(self : UiDom) -> Unit {
  self.skip_mode_last_advance_ms = 0
}

///|
pub fn UiDom::simulate_click(self : UiDom) -> Unit {
  self.simulated_click = true
}
