///|
test "ui view model reflects dialog and choices from director" {
  let a = label()
  let b = label()
  let compiled : Script[Int] = script(builder => {
    builder.menu("guide", "Pick one", [
      option("Route A", a),
      option("Route B", b),
    ])
    builder.label(a)
    builder.say("guide", "A")
    builder.label(b)
  })
  let director = Director::new(Runtime::new(compiled, GameState::new(0)))
  let ui = UiDom::new("ui-root")

  ignore(director.step())
  let view1 = ui_view_from_director(director, ui)
  assert_eq(view1, {
    speaker: "guide",
    text: "Pick one",
    dialog_seq: 1,
    typewriter: true,
    intro_text: None,
    video: None,
    append: false,
    text_box_visible: true,
    avatar_id: None,
    choices: [],
    text_input: None,
    dialog_history: [{ speaker: "guide", text: "Pick one" }],
    dom_figures: [],
    auto_mode: false,
    skip_mode: false,
    log_visible: false,
  })

  ignore(director.step())
  let view2 = ui_view_from_director(director, ui)
  assert_eq(view2.speaker, "guide")
  assert_eq(view2.text, "Pick one")
  assert_eq(view2.choices.length(), 2)
  assert_eq(view2.choices[0].text, "Route A")
}

///|
test "ui view model is empty before first dialog" {
  let compiled : Script[Int] = script(builder => builder.scene(dummy_bg("bg")))
  let director = Director::new(Runtime::new(compiled, GameState::new(0)))
  let ui = UiDom::new("ui-root")

  let view0 = ui_view_from_director(director, ui)
  assert_eq(view0, {
    speaker: "",
    text: "",
    dialog_seq: 0,
    typewriter: true,
    intro_text: None,
    video: None,
    append: false,
    text_box_visible: true,
    avatar_id: None,
    choices: [],
    text_input: None,
    dialog_history: [],
    dom_figures: [],
    auto_mode: false,
    skip_mode: false,
    log_visible: false,
  })
}

///|
test "ui view model includes dom figures from director" {
  let compiled : Script[Int] = script(builder => {
    builder.show_figure(dom_figure("#promo"), place_center(layer=2))
  })
  let director = Director::new(Runtime::new(compiled, GameState::new(0)))
  let ui = UiDom::new("ui-root")

  ignore(director.step())
  let view = ui_view_from_director(director, ui)
  assert_eq(view.dom_figures.length(), 1)
  assert_eq(view.dom_figures[0].id, "promo")
  assert_eq(view.dom_figures[0].dom_id, "promo")
  assert_eq(view.dom_figures[0].interactive, false)
  assert_eq(view.dom_figures[0].left_pct, 50.0)
  assert_eq(view.dom_figures[0].top_pct, 50.0)
  assert_eq(view.dom_figures[0].anchor_x, 0.5)
  assert_eq(view.dom_figures[0].anchor_y, 0.5)
}

///|
test "ui view model keeps interactive dom figure flag" {
  let compiled : Script[Int] = script(builder => {
    builder.show_figure(dom_figure("promo"), place_center(), interactive=true)
  })
  let director = Director::new(Runtime::new(compiled, GameState::new(0)))
  let ui = UiDom::new("ui-root")

  ignore(director.step())
  let view = ui_view_from_director(director, ui)
  assert_eq(view.dom_figures.length(), 1)
  assert_eq(view.dom_figures[0].interactive, true)
}

///|
test "ui view model applies new dom animations" {
  let compiled : Script[Int] = script(builder => {
    builder.show_figure(dom_figure("promo"), place_center())
    builder.animate_opacity(dom_figure("promo"), 120, 0.4)
  })
  let director = Director::new(Runtime::new(compiled, GameState::new(0)))
  let ui = UiDom::new("ui-root")

  ignore(director.step())
  ignore(director.step())
  ignore(ui_view_from_director(director, ui))
  ui.advance_dom_animation_timer(120)
  let view = ui_view_from_director(director, ui)
  assert_eq(view.dom_figures.length(), 1)
  assert_eq(view.dom_figures[0].opacity, 0.4)
}
