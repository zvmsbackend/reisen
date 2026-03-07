///|
test "save slots write read list delete" {
  let store = default_save_slot_store()
  store.delete_slot("global", "wb_a")
  store.delete_slot("global", "wb_b")

  store.write_slot("global", "wb_a", "A")
  store.write_slot("global", "wb_b", "B")

  assert_eq(store.read_slot("global", "wb_a"), Some("A"))
  assert_eq(store.read_slot("global", "wb_b"), Some("B"))

  let slots = store.list_slots("global")
  assert_true(slots.contains("wb_a"))
  assert_true(slots.contains("wb_b"))

  store.delete_slot("global", "wb_a")
  assert_eq(store.read_slot("global", "wb_a"), None)
}

///|
test "save slot metadata roundtrip and entries" {
  let store = default_save_slot_store()
  store.delete_slot("global", "wb_meta")
  store.write_slot("global", "wb_meta", "STATE")
  let meta = save_slot_meta("Prologue", "Wake up in shrine", updated_at_ms=1.0)
  store.write_slot_meta("global", "wb_meta", meta)

  assert_eq(store.read_slot_meta("global", "wb_meta"), Some(meta))
  let entries = save_slot_store_entries_in(store, "global")
  assert_true(
    entries.contains(try! SaveSlotEntry::new("wb_meta", meta=Some(meta))),
  )
}

///|
test "save slot delete also removes metadata" {
  let store = default_save_slot_store()
  store.delete_slot("global", "wb_meta_delete")
  store.write_slot("global", "wb_meta_delete", "STATE")
  store.write_slot_meta(
    "global",
    "wb_meta_delete",
    save_slot_meta("T", "P", updated_at_ms=2.0),
  )

  store.delete_slot("global", "wb_meta_delete")
  assert_eq(store.read_slot("global", "wb_meta_delete"), None)
  assert_eq(store.read_slot_meta("global", "wb_meta_delete"), None)
}

///|
test "save slots are isolated by namespace" {
  let store = default_save_slot_store()
  store.delete_slot("game_a", "shared")
  store.delete_slot("game_b", "shared")

  store.write_slot("game_a", "shared", "A")
  store.write_slot("game_b", "shared", "B")

  assert_eq(store.read_slot("game_a", "shared"), Some("A"))
  assert_eq(store.read_slot("game_b", "shared"), Some("B"))
  assert_true(store.list_slots("game_a").contains("shared"))
  assert_true(store.list_slots("game_b").contains("shared"))
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

///|
struct PrefixedStore {
  prefix : String
}

///|
fn ns_with_prefix(prefix : String, ns : String) -> String {
  "\{prefix}.\{ns}"
}

///|
impl SaveSlotStore for PrefixedStore with read_slot(self, ns, slot) {
  local_save_slot_store().read_slot(ns_with_prefix(self.prefix, ns), slot)
}

///|
impl SaveSlotStore for PrefixedStore with write_slot(self, ns, slot, value) {
  local_save_slot_store().write_slot(
    ns_with_prefix(self.prefix, ns),
    slot,
    value,
  )
}

///|
impl SaveSlotStore for PrefixedStore with delete_slot(self, ns, slot) {
  local_save_slot_store().delete_slot(ns_with_prefix(self.prefix, ns), slot)
}

///|
impl SaveSlotStore for PrefixedStore with list_slots(self, ns) {
  local_save_slot_store().list_slots(ns_with_prefix(self.prefix, ns))
}

///|
impl SaveSlotStore for PrefixedStore with read_slot_meta(self, ns, slot) {
  local_save_slot_store().read_slot_meta(ns_with_prefix(self.prefix, ns), slot)
}

///|
impl SaveSlotStore for PrefixedStore with write_slot_meta(self, ns, slot, meta) {
  local_save_slot_store().write_slot_meta(
    ns_with_prefix(self.prefix, ns),
    slot,
    meta,
  )
}

///|
impl SaveSlotStore for PrefixedStore with preload_namespace(_, _) {
  ()
}

///|
test "store trait wrappers work with local backend" {
  let store = local_save_slot_store()
  save_slot_store_delete_in(store, "wb_store", "slot")
  save_slot_store_write_in(store, "wb_store", "slot", "payload")
  assert_eq(save_slot_store_read_in(store, "wb_store", "slot"), Some("payload"))
  let meta = save_slot_meta("Title", "Preview", updated_at_ms=10.0)
  save_slot_store_write_meta_in(store, "wb_store", "slot", meta)
  assert_eq(save_slot_store_read_meta_in(store, "wb_store", "slot"), Some(meta))
}

///|
test "legacy wrappers still delegate correctly" {
  save_slot_delete("wb_legacy")
  save_slot_write("wb_legacy", "legacy")
  assert_eq(save_slot_read("wb_legacy"), Some("legacy"))
  save_slot_delete("wb_legacy")
}

///|
test "multi backend reads fallback and migrates to primary" {
  let primary : PrefixedStore = { prefix: "wb_primary" }
  let fallback : PrefixedStore = { prefix: "wb_fallback" }
  let multi = MultiSaveSlotStore::new(primary, fallback, migrate_on_read=true)

  primary.delete_slot("ns", "slot")
  fallback.delete_slot("ns", "slot")
  fallback.write_slot("ns", "slot", "legacy")

  assert_eq(multi.read_slot("ns", "slot"), Some("legacy"))
  assert_eq(primary.read_slot("ns", "slot"), Some("legacy"))
}

///|
test "multi backend list merges unique slots" {
  let primary : PrefixedStore = { prefix: "wb_primary_list" }
  let fallback : PrefixedStore = { prefix: "wb_fallback_list" }
  let multi = MultiSaveSlotStore::new(primary, fallback, migrate_on_read=false)

  primary.delete_slot("ns", "same")
  fallback.delete_slot("ns", "same")
  primary.write_slot("ns", "same", "p")
  fallback.write_slot("ns", "same", "f")
  fallback.write_slot("ns", "other", "o")

  let slots = multi.list_slots("ns")
  assert_true(slots.contains("same"))
  assert_true(slots.contains("other"))
  assert_eq(slots.filter(s => s == "same").length(), 1)
}

///|
test "indexeddb store cache read write list" {
  let store = IndexedDbSaveSlotStore::new(db_name="wb.indexed.cache")
  store.delete_slot("ns", "a")
  store.write_slot("ns", "a", "payload")
  assert_eq(store.read_slot("ns", "a"), Some("payload"))
  assert_true(store.list_slots("ns").contains("a"))
}

///|
test "indexeddb store cache metadata roundtrip" {
  let store = IndexedDbSaveSlotStore::new(db_name="wb.indexed.meta")
  let meta = save_slot_meta("T", "P", updated_at_ms=11.0)
  store.write_slot_meta("ns", "a", meta)
  assert_eq(store.read_slot_meta("ns", "a"), Some(meta))
}
