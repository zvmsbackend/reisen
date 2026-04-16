///|
fn namespaced_prefix(ns : String) -> String {
  "\{save_slot_prefix}\{ns}."
}

///|
fn namespaced_meta_prefix(ns : String) -> String {
  "\{save_slot_meta_prefix}\{ns}."
}

///|
fn slot_key(ns : String, slot : String) -> String {
  namespaced_prefix(ns) + slot
}

///|
fn slot_meta_key(ns : String, slot : String) -> String {
  namespaced_meta_prefix(ns) + slot
}

///|
fn merge_unique_slots(
  lhs : Array[String],
  rhs : Array[String],
) -> Array[String] {
  let seen = Set::new()
  let result = []
  for slot in lhs.iter().concat(rhs.iter()) {
    if !seen.contains(slot) {
      seen.add(slot)
      result.push(slot)
    }
  }
  result
}

///|
pub impl SaveSlotStore for LocalSaveSlotStore with read_slot(_, ns, slot) {
  local_save_slot_read_in(ns, slot)
}

///|
pub impl SaveSlotStore for LocalSaveSlotStore with write_slot(
  _,
  ns,
  slot,
  value,
) {
  local_save_slot_write_in(ns, slot, value)
}

///|
pub impl SaveSlotStore for LocalSaveSlotStore with delete_slot(_, ns, slot) {
  local_save_slot_delete_in(ns, slot)
}

///|
pub impl SaveSlotStore for LocalSaveSlotStore with list_slots(_, ns) {
  local_save_slot_list_in(ns)
}

///|
pub impl SaveSlotStore for LocalSaveSlotStore with read_slot_meta(_, ns, slot) {
  local_save_slot_read_meta_in(ns, slot)
}

///|
pub impl SaveSlotStore for LocalSaveSlotStore with write_slot_meta(
  _,
  ns,
  slot,
  meta,
) {
  local_save_slot_write_meta_in(ns, slot, meta)
}

///|
pub impl SaveSlotStore for LocalSaveSlotStore with preload_namespace(_, _) {
  ()
}

///|
pub impl[P : SaveSlotStore, F : SaveSlotStore] SaveSlotStore for MultiSaveSlotStore[
  P,
  F,
] with read_slot(self, ns, slot) {
  match self.primary.read_slot(ns, slot).bind(value => Some(value)) {
    Some(value) => Some(value)
    None =>
      self.fallback
      .read_slot(ns, slot)
      .map(value => {
        if self.migrate_on_read {
          self.primary.write_slot(ns, slot, value)
        }
        value
      })
  }
}

///|
pub impl[P : SaveSlotStore, F : SaveSlotStore] SaveSlotStore for MultiSaveSlotStore[
  P,
  F,
] with write_slot(self, ns, slot, value) {
  self.primary.write_slot(ns, slot, value)
}

///|
pub impl[P : SaveSlotStore, F : SaveSlotStore] SaveSlotStore for MultiSaveSlotStore[
  P,
  F,
] with delete_slot(self, ns, slot) {
  self.primary.delete_slot(ns, slot)
  self.fallback.delete_slot(ns, slot)
}

///|
pub impl[P : SaveSlotStore, F : SaveSlotStore] SaveSlotStore for MultiSaveSlotStore[
  P,
  F,
] with list_slots(self, ns) {
  merge_unique_slots(self.primary.list_slots(ns), self.fallback.list_slots(ns))
}

///|
pub impl[P : SaveSlotStore, F : SaveSlotStore] SaveSlotStore for MultiSaveSlotStore[
  P,
  F,
] with read_slot_meta(self, ns, slot) {
  match self.primary.read_slot_meta(ns, slot).bind(meta => Some(meta)) {
    Some(meta) => Some(meta)
    None =>
      self.fallback
      .read_slot_meta(ns, slot)
      .map(meta => {
        if self.migrate_on_read {
          self.primary.write_slot_meta(ns, slot, meta)
        }
        meta
      })
  }
}

///|
pub impl[P : SaveSlotStore, F : SaveSlotStore] SaveSlotStore for MultiSaveSlotStore[
  P,
  F,
] with write_slot_meta(self, ns, slot, meta) {
  self.primary.write_slot_meta(ns, slot, meta)
}

///|
pub impl[P : SaveSlotStore, F : SaveSlotStore] SaveSlotStore for MultiSaveSlotStore[
  P,
  F,
] with preload_namespace(self, ns) {
  self.primary.preload_namespace(ns)
  self.fallback.preload_namespace(ns)
}

///|
pub fn[S : SaveSlotStore] save_slot_store_write_in(
  store : S,
  ns : String,
  slot : String,
  value : String,
) -> Unit {
  store.write_slot(ns, slot, value)
}

///|
pub fn[S : SaveSlotStore] save_slot_store_read_in(
  store : S,
  ns : String,
  slot : String,
) -> String? {
  store.read_slot(ns, slot)
}

///|
pub fn[S : SaveSlotStore] save_slot_store_delete_in(
  store : S,
  ns : String,
  slot : String,
) -> Unit {
  store.delete_slot(ns, slot)
}

///|
pub fn[S : SaveSlotStore] save_slot_store_list_in(
  store : S,
  ns : String,
) -> Array[String] {
  store.list_slots(ns)
}

///|
pub fn[S : SaveSlotStore] save_slot_store_write_meta_in(
  store : S,
  ns : String,
  slot : String,
  meta : SaveSlotMeta,
) -> Unit {
  store.write_slot_meta(ns, slot, meta)
}

///|
pub fn[S : SaveSlotStore] save_slot_store_read_meta_in(
  store : S,
  ns : String,
  slot : String,
) -> SaveSlotMeta? {
  store.read_slot_meta(ns, slot)
}

///|
pub fn[S : SaveSlotStore] save_slot_store_entries_in(
  store : S,
  ns : String,
) -> Array[SaveSlotEntry] {
  store
  .list_slots(ns)
  .map(slot => { slot, meta: store.read_slot_meta(ns, slot) })
}

///|
fn local_save_slot_write_in(ns : String, slot : String, value : String) -> Unit {
  storage_set_item(slot_key(ns, slot), value)
}

///|
fn local_save_slot_read_in(ns : String, slot : String) -> String? {
  storage_get_item(slot_key(ns, slot))
}

///|
fn local_save_slot_delete_in(ns : String, slot : String) -> Unit {
  storage_remove_item(slot_key(ns, slot))
  storage_remove_item(slot_meta_key(ns, slot))
}

///|
fn local_save_slot_list_in(ns : String) -> Array[String] {
  ns |> namespaced_prefix |> storage_list_slots
}

///|
fn local_save_slot_write_meta_in(
  ns : String,
  slot : String,
  meta : SaveSlotMeta,
) -> Unit {
  storage_set_item(slot_meta_key(ns, slot), meta.to_json().stringify())
}

///|
fn local_save_slot_read_meta_in(ns : String, slot : String) -> SaveSlotMeta? {
  storage_get_item(slot_meta_key(ns, slot)).bind(raw => {
    (raw |> @json.parse |> @json.from_json |> Some) catch {
      _ => None
    }
  })
}
