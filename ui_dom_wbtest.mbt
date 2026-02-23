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
    typewriter: true,
    choices: [],
    text_input: None,
    auto_mode: false,
    skip_mode: false,
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
    typewriter: true,
    choices: [],
    text_input: None,
    auto_mode: false,
    skip_mode: false,
  })
}
