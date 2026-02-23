///|
test "choose_continue_slot prefers newest metadata timestamp" {
  let entries = [
    { slot: "a", meta: Some(save_slot_meta("A", "", updated_at_ms=10.0)) },
    { slot: "b", meta: Some(save_slot_meta("B", "", updated_at_ms=20.0)) },
    { slot: "c", meta: None },
  ]
  assert_eq(choose_continue_slot(entries), Some("b"))
}

///|
test "choose_continue_slot falls back when metadata missing" {
  let entries = [{ slot: "x", meta: None }, { slot: "y", meta: None }]
  assert_eq(choose_continue_slot(entries), Some("x"))
}

///|
test "choose_continue_slot none when no entries" {
  assert_eq(choose_continue_slot([]), None)
}
