///|
pub type DefaultSaveSlotStore = LocalSaveSlotStore

///|
pub fn default_save_slot_store() -> DefaultSaveSlotStore {
  local_save_slot_store()
}

///|
pub fn default_save_slot_storage() -> &SaveSlotStore {
  local_save_slot_store()
}

///|
pub fn preload_default_save_slot_store_namespace(_ns : String) -> Unit {
  ()
}
