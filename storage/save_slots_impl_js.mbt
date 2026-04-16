///|
pub impl SaveSlotStore for IndexedDbSaveSlotStore with read_slot(self, ns, slot) {
  idb_cache_get_slot(self.db_name, slot_key(ns, slot)).to_option()
}

///|
pub impl SaveSlotStore for IndexedDbSaveSlotStore with write_slot(
  self,
  ns,
  slot,
  value,
) {
  let key = slot_key(ns, slot)
  idb_cache_set_slot(self.db_name, key, value)
  idb_flush_put_slot(self.db_name, key, value)
}

///|
pub impl SaveSlotStore for IndexedDbSaveSlotStore with delete_slot(
  self,
  ns,
  slot,
) {
  let value_key = slot_key(ns, slot)
  let meta_key = slot_meta_key(ns, slot)
  idb_cache_delete_slot(self.db_name, value_key)
  idb_cache_delete_meta(self.db_name, meta_key)
  idb_flush_delete_slot(self.db_name, value_key, meta_key)
}

///|
pub impl SaveSlotStore for IndexedDbSaveSlotStore with list_slots(self, ns) {
  idb_cache_list_slots(self.db_name, namespaced_prefix(ns))
}

///|
pub impl SaveSlotStore for IndexedDbSaveSlotStore with read_slot_meta(
  self,
  ns,
  slot,
) {
  idb_cache_get_meta(self.db_name, slot_meta_key(ns, slot))
  .to_option()
  .bind(raw => {
    (raw |> @json.parse |> @json.from_json |> Some) catch {
      _ => None
    }
  })
}

///|
pub impl SaveSlotStore for IndexedDbSaveSlotStore with write_slot_meta(
  self,
  ns,
  slot,
  meta,
) {
  let key = slot_meta_key(ns, slot)
  let raw = meta.to_json().stringify()
  idb_cache_set_meta(self.db_name, key, raw)
  idb_flush_put_meta(self.db_name, key, raw)
}

///|
pub impl SaveSlotStore for IndexedDbSaveSlotStore with preload_namespace(
  self,
  ns,
) {
  idb_preload_namespace_fire_and_forget(
    self.db_name,
    namespaced_prefix(ns),
    namespaced_meta_prefix(ns),
  )
}

///|
pub async fn IndexedDbSaveSlotStore::preload_namespace(
  self : IndexedDbSaveSlotStore,
  ns : String,
) -> Unit {
  @js_async.Promise::wait(
    idb_preload_namespace_into_cache(
      self.db_name,
      namespaced_prefix(ns),
      namespaced_meta_prefix(ns),
    ),
  )
}

///|
pub async fn IndexedDbSaveSlotStore::preload_all(
  self : IndexedDbSaveSlotStore,
) -> Unit {
  self.db_name |> idb_preload_all_into_cache |> @js_async.Promise::wait
}
