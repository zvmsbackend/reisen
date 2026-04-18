///|
using @debug {assert_eq}

///|
fn mk_view(
  text_box_visible : Bool,
  dialog_seq : Int,
  choices? : Array[UiChoiceView] = [],
) -> UiViewModel {
  {
    speaker: DialogText::String("guide"),
    text: DialogText::String("line"),
    dialog_seq,
    typewriter: true,
    intro_text: None,
    video: None,
    append: false,
    text_box_visible,
    avatar_id: None,
    choices,
    text_input: None,
    dialog_history: [],
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
fn mk_choice(id : String, text : String) -> UiChoiceView {
  { id, text: DialogText::String(text) }
}

///|
test "selene ui animation starts when dialog box becomes visible" {
  let backend = SeleneUiBackend::new()

  backend.render(mk_view(false, 0))
  backend.render(mk_view(true, 1))

  assert_eq(backend.panel_alpha, 0.0)
  assert_eq(backend.panel_alpha_anim is Some(_), true)
  assert_eq(backend.has_active_ui_animations(), true)
}

///|
test "selene ui animation restarts for changed choice list" {
  let backend = SeleneUiBackend::new()

  let choices_a = [mk_choice("a", "Route A")]
  let choices_b = [mk_choice("b", "Route B")]

  backend.render(mk_view(true, 1, choices=choices_a))
  backend.advance_ui_animation_timer(300)
  assert_eq(backend.has_active_ui_animations(), false)

  backend.render(mk_view(true, 1, choices=choices_b))

  assert_eq(backend.choices_alpha, 0.0)
  assert_eq(backend.choices_alpha_anim is Some(_), true)
  assert_eq(backend.has_active_ui_animations(), true)
}

///|
test "selene ui animations complete after timer advances" {
  let backend = SeleneUiBackend::new()

  let choices = [mk_choice("a", "Route A")]
  backend.render(mk_view(true, 1, choices~))

  assert_eq(backend.has_active_ui_animations(), true)

  backend.advance_ui_animation_timer(500)

  assert_eq(backend.has_active_ui_animations(), false)
  assert_eq(backend.panel_alpha, 1.0)
  assert_eq(backend.choices_alpha, 1.0)
}
