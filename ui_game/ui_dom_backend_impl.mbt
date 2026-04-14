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
pub impl UiBackend for UiDom with simulate_click(self) {
  UiDom::simulate_click(self)
}

///|
pub impl UiPlatformHooks for UiDom with advance_ui_animation_timer(
  self,
  elapsed_ms,
) {
  UiDom::advance_dom_animation_timer(self, elapsed_ms)
}

///|
pub impl UiPlatformHooks for UiDom with has_active_ui_animations(self) {
  UiDom::has_active_dom_animations(self)
}

///|
pub impl UiPlatformHooks for UiDom with set_media_volume(self, volume) {
  UiDom::set_media_volume(self, volume)
}
