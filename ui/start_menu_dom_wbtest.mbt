///|
test "choose_continue_slot prefers newest metadata timestamp" {
  let entries = [
    try! SaveSlotEntry::new(
      "a",
      meta=Some(@storage.save_slot_meta("A", "", updated_at_ms=10.0)),
    ),
    try! SaveSlotEntry::new(
      "b",
      meta=Some(@storage.save_slot_meta("B", "", updated_at_ms=20.0)),
    ),
    try! SaveSlotEntry::new("c"),
  ]
  assert_eq(choose_continue_slot(entries), Some("b"))
}

///|
test "choose_continue_slot falls back when metadata missing" {
  let entries = [try! SaveSlotEntry::new("x"), try! SaveSlotEntry::new("y")]
  assert_eq(choose_continue_slot(entries), Some("x"))
}

///|
test "choose_continue_slot none when no entries" {
  assert_eq(choose_continue_slot([]), None)
}
