///|
pub fn UiDom::take_selected_choice(self : UiDom) -> String? {
  dom_take_selected_choice(self.root_id).to_option()
}

///|
pub fn UiDom::take_submitted_text_input(self : UiDom) -> String? {
  dom_take_submitted_text_input(self.root_id).to_option()
}

///|
pub fn UiDom::take_action(self : UiDom) -> String? {
  dom_take_action(self.root_id).to_option()
}

///|
pub fn UiDom::take_video_action(self : UiDom) -> String? {
  dom_take_video_action(self.root_id).to_option()
}

///|
pub fn UiDom::check_typewriter_click(self : UiDom) -> Bool {
  if self.simulated_click {
    self.simulated_click = false
    return true
  }
  dom_take_typewriter_click(self.root_id)
}

///|
pub fn UiDom::check_intro_done(self : UiDom) -> Bool {
  if self.simulated_intro_done {
    self.simulated_intro_done = false
    return true
  }
  dom_take_intro_done(self.root_id)
}

///|
pub fn UiDom::reveal_intro_line(self : UiDom) -> Bool {
  dom_reveal_intro_line(self.root_id)
}

///|
pub fn UiDom::simulate_intro_done(self : UiDom) -> Unit {
  self.simulated_intro_done = true
  dom_mark_intro_done(self.root_id)
}

///|
pub fn UiDom::mark_all_dirty(self : UiDom) -> Unit {
  self.dirty_speaker = true
  self.dirty_text = true
  self.dirty_choices = true
  self.dirty_text_input = true
  self.dirty_action_buttons = true
}

///|
pub fn UiDom::mark_dirty_text(self : UiDom) -> Unit {
  self.dirty_text = true
}

///|
pub fn UiDom::mark_dirty_text_and_speaker(self : UiDom) -> Unit {
  self.dirty_speaker = true
  self.dirty_text = true
}

///|
pub fn UiDom::mark_dirty_choices(self : UiDom) -> Unit {
  self.dirty_choices = true
}

///|
pub fn UiDom::mark_dirty_text_input(self : UiDom) -> Unit {
  self.dirty_text_input = true
}

///|
pub fn UiDom::mark_dirty_action_buttons(self : UiDom) -> Unit {
  self.dirty_action_buttons = true
}

///|
pub fn UiDom::clear_game_ui(self : UiDom) -> Unit {
  self.dom_animation_cursor = 0
  self.dom_timeline_ms = 0
  self.dom_position_anims.clear()
  self.dom_opacity_anims.clear()
  self.dom_scale_anims.clear()
  self.dom_rotation_anims.clear()
  self.dom_blur_anims.clear()
  self.dom_brightness_anims.clear()
  self.dom_contrast_anims.clear()
  self.dom_saturation_anims.clear()
  self.dom_gamma_anims.clear()
  self.dom_color_r_anims.clear()
  self.dom_color_g_anims.clear()
  self.dom_color_b_anims.clear()
  dom_clear_game_ui(self.root_id)
}
