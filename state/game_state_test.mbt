///|
test "game state bool/int/string vars" {
  let state = GameState::new(())

  assert_eq(state.flag("seen_intro"), false)
  state.set_flag("seen_intro", true)
  assert_eq(state.flag("seen_intro"), true)

  assert_eq(state.int_var("score"), 0)
  state.set_int_var("score", 42)
  assert_eq(state.int_var("score"), 42)

  assert_eq(state.text_var("name"), "")
  state.set_text_var("name", "Kasumi")
  assert_eq(state.text_var("name"), "Kasumi")
}

///|
test "game state interpolation supports vars and style braces" {
  let state = GameState::new(())
  state.set_text_var("name", "Ran")
  let text = "Hello {name}! [color=#f00]{{styled}}[/color] {missing}"
  assert_eq(
    state.interpolate(text),
    "Hello Ran! [color=#f00]{{styled}}[/color] {missing}",
  )
}
