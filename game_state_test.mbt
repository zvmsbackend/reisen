///|
test "interpolate ignores style markup" {
  let state = GameState::new(())
  state.set_text_var("name", "Alice")
  let text = "Hi {name} [Title]{color:red}"
  let rendered = state.interpolate(text)
  assert_eq(rendered, "Hi Alice [Title]{color:red}")
}
