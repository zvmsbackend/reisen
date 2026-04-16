///|
/// HTML UI bridge for dialogs and choice buttons.
/// Figures/backgrounds stay in PIXI; this module only updates DOM nodes.

///|
struct UiDom {
  root_id : String
  mut ui_strings : UiStrings
  mut script_locale_json : String?
  mut script_default_locale_json : String?
  mut vocal_locale_dir : String
  mut script_locale : String
  mut script_default_locale : String
  mut dom_animation_cursor : Int
  mut dom_timeline_ms : Int
  dom_position_anims : Map[String, DomPositionAnim]
  dom_opacity_anims : Map[String, DomScalarAnim]
  dom_scale_anims : Map[String, DomScalarAnim]
  dom_rotation_anims : Map[String, DomScalarAnim]
  dom_blur_anims : Map[String, DomScalarAnim]
  dom_brightness_anims : Map[String, DomScalarAnim]
  dom_contrast_anims : Map[String, DomScalarAnim]
  dom_saturation_anims : Map[String, DomScalarAnim]
  dom_gamma_anims : Map[String, DomScalarAnim]
  dom_color_r_anims : Map[String, DomScalarAnim]
  dom_color_g_anims : Map[String, DomScalarAnim]
  dom_color_b_anims : Map[String, DomScalarAnim]
  mut text_speed : Int
  mut typewriter_text : DialogText
  mut last_dialog_seq : Int
  mut typewriter_visible : Int
  mut typewriter_last_update_ms : Int
  mut auto_mode : Bool
  auto_mode_delay_ms : Int
  wait_click_auto_skip_delay_ms : Int
  mut media_volume : Double
  mut auto_mode_last_advance_ms : Int
  mut skip_mode : Bool
  mut skip_hold : Bool
  skip_mode_delay_ms : Int
  mut skip_mode_last_advance_ms : Int
  mut simulated_click : Bool
  mut simulated_intro_done : Bool
  mut log_visible : Bool
}

///|
pub fn UiDom::new(
  root_id : String,
  ui_strings? : UiStrings = UiStrings::default(),
  script_locale_json? : String = "",
  script_default_locale_json? : String = "",
  vocal_locale_dir? : String = "",
  script_locale? : String = "",
  script_default_locale? : String = "",
) -> UiDom {
  {
    root_id,
    ui_strings,
    script_locale_json: match script_locale_json {
      "" => None
      _ => Some(script_locale_json)
    },
    script_default_locale_json: match script_default_locale_json {
      "" => None
      _ => Some(script_default_locale_json)
    },
    vocal_locale_dir,
    script_locale,
    script_default_locale,
    dom_animation_cursor: 0,
    dom_timeline_ms: 0,
    dom_position_anims: {},
    dom_opacity_anims: {},
    dom_scale_anims: {},
    dom_rotation_anims: {},
    dom_blur_anims: {},
    dom_brightness_anims: {},
    dom_contrast_anims: {},
    dom_saturation_anims: {},
    dom_gamma_anims: {},
    dom_color_r_anims: {},
    dom_color_g_anims: {},
    dom_color_b_anims: {},
    text_speed: 50,
    typewriter_text: DialogText::empty(),
    last_dialog_seq: -1,
    typewriter_visible: 0,
    typewriter_last_update_ms: 0,
    auto_mode: false,
    auto_mode_delay_ms: 2000,
    wait_click_auto_skip_delay_ms: 160,
    media_volume: 0.7,
    auto_mode_last_advance_ms: 0,
    skip_mode: false,
    skip_hold: false,
    skip_mode_delay_ms: 50,
    skip_mode_last_advance_ms: 0,
    simulated_click: false,
    simulated_intro_done: false,
    log_visible: false,
  }
}
