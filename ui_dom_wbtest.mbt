///|
test "ui view model reflects dialog and choices from director" {
  let compiled : Script[Int] = script(builder => {
    builder.label("start")
    builder.menu("guide", "Pick one", [
      option("a", "Route A", "a"),
      option("b", "Route B", "b"),
    ])
    builder.label("a")
    builder.say("guide", "A")
    builder.label("b")
  })
  let director = Director::new(Runtime::new(compiled, GameState::new(0)))

  ignore(director.step())
  let view1 = ui_view_from_director(director)
  assert_eq(view1, { speaker: "guide", text: "Pick one", choices: [] })

  ignore(director.step())
  let view2 = ui_view_from_director(director)
  assert_eq(view2.speaker, "guide")
  assert_eq(view2.text, "Pick one")
  assert_eq(view2.choices.length(), 2)
  assert_eq(view2.choices[0], { id: "a", text: "Route A" })
}

///|
test "ui view model is empty before first dialog" {
  let compiled : Script[Int] = script(builder => {
    builder.label("start")
    builder.scene("bg")
  })
  let director = Director::new(Runtime::new(compiled, GameState::new(0)))

  let view0 = ui_view_from_director(director)
  assert_eq(view0, { speaker: "", text: "", choices: [] })
}
