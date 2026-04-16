///|
pub struct IndexedDbSaveSlotStore {
  db_name : String
}

///|
pub fn IndexedDbSaveSlotStore::new(
  db_name? : String = "reisen.save.indexeddb",
) -> IndexedDbSaveSlotStore {
  { db_name, }
}

///|
pub fn indexeddb_save_slot_store(
  db_name? : String = "reisen.save.indexeddb",
) -> IndexedDbSaveSlotStore {
  IndexedDbSaveSlotStore::new(db_name~)
}

///|
pub type DefaultSaveSlotStore = MultiSaveSlotStore[
  IndexedDbSaveSlotStore,
  LocalSaveSlotStore,
]

///|
pub fn default_save_slot_store() -> DefaultSaveSlotStore {
  MultiSaveSlotStore::new(
    indexeddb_save_slot_store(),
    local_save_slot_store(),
    migrate_on_read=true,
  )
}

///|
pub fn default_save_slot_storage() -> &SaveSlotStore {
  default_save_slot_store()
}

///|
pub async fn preload_default_save_slot_store_namespace(ns : String) -> Unit {
  let store = default_save_slot_store()
  store.primary.preload_namespace(ns)
}
