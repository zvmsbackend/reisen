///|
pub(open) trait UiBackend {
  localize_vocal_url(Self, String) -> String
  render(Self, UiViewModel) -> Unit
  view_model_from_snapshot(Self, UiSnapshot) -> UiViewModel
  take_selected_choice(Self) -> String?
  take_submitted_text_input(Self) -> String?
  take_action(Self) -> String?
  take_video_action(Self) -> String?
  check_typewriter_click(Self) -> Bool
  check_intro_done(Self) -> Bool
  reveal_intro_line(Self) -> Bool
  clear_game_ui(Self) -> Unit
  set_ui_strings(Self, UiStrings) -> Unit
  set_script_localization(
    Self,
    script_locale_json~ : String?,
    script_default_locale_json~ : String?,
    vocal_locale_dir~ : String,
    script_locale~ : String,
    script_default_locale~ : String,
  ) -> Unit
  simulate_click(Self) -> Unit
}

///|
pub(open) trait UiPlatformHooks {
  advance_ui_animation_timer(Self, Int) -> Unit
  has_active_ui_animations(Self) -> Bool
  set_media_volume(Self, Double) -> Unit
}
