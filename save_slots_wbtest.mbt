///|
test "save slots write read list delete" {
  save_slot_delete("wb_a")
  save_slot_delete("wb_b")

  save_slot_write("wb_a", "A")
  save_slot_write("wb_b", "B")

  assert_eq(save_slot_read("wb_a"), Some("A"))
  assert_eq(save_slot_read("wb_b"), Some("B"))

  let slots = save_slot_list()
  assert_true(slots.contains("wb_a"))
  assert_true(slots.contains("wb_b"))

  save_slot_delete("wb_a")
  assert_eq(save_slot_read("wb_a"), None)
}

///|
test "save slot metadata roundtrip and entries" {
  save_slot_delete("wb_meta")
  save_slot_write("wb_meta", "STATE")
  let meta = save_slot_meta("Prologue", "Wake up in shrine", updated_at_ms=1.0)
  save_slot_write_meta("wb_meta", meta)

  assert_eq(save_slot_read_meta("wb_meta"), Some(meta))
  let entries = save_slot_entries()
  assert_true(entries.contains({ slot: "wb_meta", meta: Some(meta) }))
}

///|
test "save slot delete also removes metadata" {
  save_slot_delete("wb_meta_delete")
  save_slot_write("wb_meta_delete", "STATE")
  save_slot_write_meta(
    "wb_meta_delete",
    save_slot_meta("T", "P", updated_at_ms=2.0),
  )

  save_slot_delete("wb_meta_delete")
  assert_eq(save_slot_read("wb_meta_delete"), None)
  assert_eq(save_slot_read_meta("wb_meta_delete"), None)
}

///|
test "save slots are isolated by namespace" {
  save_slot_delete_in("game_a", "shared")
  save_slot_delete_in("game_b", "shared")

  save_slot_write_in("game_a", "shared", "A")
  save_slot_write_in("game_b", "shared", "B")

  assert_eq(save_slot_read_in("game_a", "shared"), Some("A"))
  assert_eq(save_slot_read_in("game_b", "shared"), Some("B"))
  assert_true(save_slot_list_in("game_a").contains("shared"))
  assert_true(save_slot_list_in("game_b").contains("shared"))
}

///|
test "persistent vars list remains stable" {
  persistent_delete_in("avatar", "hero")
  persistent_set_text_in("avatar", "hero", "id")
  let keys = persistent_keys_in("avatar")
  assert_true(keys.contains("hero"))
}

///|
test "persistent vars are stored outside save slots" {
  persistent_delete_in("lap", "count")
  persistent_delete_in("lap", "flag")
  persistent_delete_in("lap", "name")

  assert_eq(persistent_get_int_in("lap", "count", default=0), 0)
  assert_eq(persistent_get_flag_in("lap", "flag", default=false), false)
  assert_eq(persistent_get_text_in("lap", "name", default=""), "")

  persistent_set_int_in("lap", "count", 3)
  persistent_set_flag_in("lap", "flag", true)
  persistent_set_text_in("lap", "name", "loop")

  assert_eq(persistent_get_int_in("lap", "count", default=0), 3)
  assert_eq(persistent_get_flag_in("lap", "flag", default=false), true)
  assert_eq(persistent_get_text_in("lap", "name", default=""), "loop")
  assert_true(persistent_keys_in("lap").contains("count"))
  assert_true(persistent_keys_in("lap").contains("flag"))
  assert_true(persistent_keys_in("lap").contains("name"))
}
