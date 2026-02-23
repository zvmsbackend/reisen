///|
test "interpolate ignores style markup" {
  let state = GameState::new(())
  state.set_text_var("name", "Alice")
  let text = "Hi {name} [Title]{color:red}"
  let rendered = state.interpolate(text)
  assert_eq(rendered, "Hi Alice [Title]{color:red}")
}

///|
test "interpolate falls back to persistent vars" {
  persistent_delete("lap")
  persistent_set_text("lap", "2")
  let state = GameState::new(())
  let rendered = state.interpolate("Lap {lap}")
  assert_eq(rendered, "Lap 2")
  persistent_delete("lap")
}
