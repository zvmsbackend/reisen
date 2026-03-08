///|
/// Browser/local save-slot storage. Uses `localStorage` when available and
/// falls back to an in-memory map for non-browser test/runtime environments.

///|
let save_slot_prefix = "reisen.save."

///|
let save_slot_meta_prefix = "reisen.save.meta."

///|
let default_save_namespace = "global"

///|
let settings_prefix = "reisen.settings."

///|
let persistent_prefix = "reisen.persist."

///|
pub struct SaveSlotMeta {
  title : String
  preview : String
  updated_at_ms : Double
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct SaveSlotEntry {
  slot : String
  meta : SaveSlotMeta?
} derive(Show, Eq)

///|
/// Storage interface for save slot payloads + metadata.
///
/// This trait is backend-agnostic and is the migration target for multi-backend
/// implementations (for example localStorage + IndexedDB).
pub trait SaveSlotStore {
  read_slot(Self, ns : String, slot : String) -> String?
  write_slot(Self, ns : String, slot : String, value : String) -> Unit
  delete_slot(Self, ns : String, slot : String) -> Unit
  list_slots(Self, ns : String) -> Array[String]
  read_slot_meta(Self, ns : String, slot : String) -> SaveSlotMeta?
  write_slot_meta(Self, ns : String, slot : String, meta : SaveSlotMeta) -> Unit
  preload_namespace(Self, ns : String) -> Unit
}

///|
/// Current built-in backend (localStorage + test fallback mirror).
pub struct LocalSaveSlotStore {}

///|
pub fn local_save_slot_store() -> LocalSaveSlotStore {
  LocalSaveSlotStore::{  }
}

///|
/// IndexedDB-backed store with synchronous cache reads.
///
/// Reads and list operations are served from an in-memory cache.
/// Writes/deletes update cache immediately and flush to IndexedDB asynchronously.
/// Use `preload_namespace`/`preload_all` to hydrate cache on startup.
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
/// Composite backend with primary + fallback stores.
///
/// Read path:
/// - Try primary first.
/// - Fallback to secondary when primary misses.
/// - Optionally migrate fallback value into primary on read.
///
/// Write path:
/// - Writes go to primary only.
pub struct MultiSaveSlotStore[P, F] {
  primary : P
  fallback : F
  migrate_on_read : Bool
}

///|
pub type DefaultSaveSlotStore = MultiSaveSlotStore[
  IndexedDbSaveSlotStore,
  LocalSaveSlotStore,
]

///|
pub fn[P, F] MultiSaveSlotStore::new(
  primary : P,
  fallback : F,
  migrate_on_read? : Bool = true,
) -> MultiSaveSlotStore[P, F] {
  { primary, fallback, migrate_on_read }
}

///|
pub suberror StorageValidationError {
  InvalidSaveSlotName(slot~ : String)
  InvalidTextSpeed(text_speed~ : Int)
  InvalidBgmVolume(bgm_volume~ : Double)
  InvalidSfxVolume(sfx_volume~ : Double)
}

///|
extern "js" fn save_slot_now_ms() -> Double =
  #| () => Date.now()

///|
extern "js" fn save_slot_time_label(ms : Double) -> String =
  #| (ms) => {
  #|   const d = new Date(ms);
  #|   return d.toISOString().replace('T', ' ').replace('Z', '');
  #| }

///|
pub fn save_slot_meta(
  title : String,
  preview : String,
  updated_at_ms? : Double = save_slot_now_ms(),
) -> SaveSlotMeta {
  let resolved_title = if title == "" {
    save_slot_time_label(updated_at_ms)
  } else {
    title
  }
  { title: resolved_title, preview, updated_at_ms }
}

///|
pub fn SaveSlotEntry::new(
  slot : String,
  meta? : SaveSlotMeta? = None,
) -> SaveSlotEntry raise StorageValidationError {
  if slot == "" {
    raise StorageValidationError::InvalidSaveSlotName(slot~)
  }
  { slot, meta }
}

///|
#deprecated("Use SaveSlotStore DI APIs instead (save_slot_store_* or &SaveSlotStore).", skip_current_package=true)
pub fn save_slot_write_in(ns : String, slot : String, value : String) -> Unit {
  default_save_slot_storage().write_slot(ns, slot, value)
}

///|
#deprecated("Use SaveSlotStore DI APIs instead (save_slot_store_* or &SaveSlotStore).", skip_current_package=true)
pub fn save_slot_read_in(ns : String, slot : String) -> String? {
  default_save_slot_storage().read_slot(ns, slot)
}

///|
#deprecated("Use SaveSlotStore DI APIs instead (save_slot_store_* or &SaveSlotStore).", skip_current_package=true)
pub fn save_slot_delete_in(ns : String, slot : String) -> Unit {
  default_save_slot_storage().delete_slot(ns, slot)
}

///|
#deprecated("Use SaveSlotStore DI APIs instead (save_slot_store_* or &SaveSlotStore).", skip_current_package=true)
pub fn save_slot_list_in(ns : String) -> Array[String] {
  default_save_slot_storage().list_slots(ns)
}

///|
#deprecated("Use SaveSlotStore DI APIs instead (save_slot_store_* or &SaveSlotStore).", skip_current_package=true)
pub fn save_slot_write_meta_in(
  ns : String,
  slot : String,
  meta : SaveSlotMeta,
) -> Unit {
  default_save_slot_storage().write_slot_meta(ns, slot, meta)
}

///|
#deprecated("Use SaveSlotStore DI APIs instead (save_slot_store_* or &SaveSlotStore).", skip_current_package=true)
pub fn save_slot_read_meta_in(ns : String, slot : String) -> SaveSlotMeta? {
  default_save_slot_storage().read_slot_meta(ns, slot)
}

///|
#deprecated("Use SaveSlotStore DI APIs instead (save_slot_store_* or &SaveSlotStore).", skip_current_package=true)
pub fn save_slot_entries_in(ns : String) -> Array[SaveSlotEntry] {
  let store = default_save_slot_storage()
  store
  .list_slots(ns)
  .map(slot => { slot, meta: store.read_slot_meta(ns, slot) })
}

///|
#deprecated("Use SaveSlotStore DI APIs instead (save_slot_store_* or &SaveSlotStore).", skip_current_package=true)
pub fn save_slot_write(slot : String, value : String) -> Unit {
  save_slot_write_in(default_save_namespace, slot, value)
}

///|
#deprecated("Use SaveSlotStore DI APIs instead (save_slot_store_* or &SaveSlotStore).", skip_current_package=true)
pub fn save_slot_read(slot : String) -> String? {
  save_slot_read_in(default_save_namespace, slot)
}

///|
#deprecated("Use SaveSlotStore DI APIs instead (save_slot_store_* or &SaveSlotStore).", skip_current_package=true)
pub fn save_slot_delete(slot : String) -> Unit {
  save_slot_delete_in(default_save_namespace, slot)
}

///|
#deprecated("Use SaveSlotStore DI APIs instead (save_slot_store_* or &SaveSlotStore).", skip_current_package=true)
pub fn save_slot_list() -> Array[String] {
  save_slot_list_in(default_save_namespace)
}

///|
#deprecated("Use SaveSlotStore DI APIs instead (save_slot_store_* or &SaveSlotStore).", skip_current_package=true)
pub fn save_slot_write_meta(slot : String, meta : SaveSlotMeta) -> Unit {
  save_slot_write_meta_in(default_save_namespace, slot, meta)
}

///|
#deprecated("Use SaveSlotStore DI APIs instead (save_slot_store_* or &SaveSlotStore).", skip_current_package=true)
pub fn save_slot_read_meta(slot : String) -> SaveSlotMeta? {
  save_slot_read_meta_in(default_save_namespace, slot)
}

///|
#deprecated("Use SaveSlotStore DI APIs instead (save_slot_store_* or &SaveSlotStore).", skip_current_package=true)
pub fn save_slot_entries() -> Array[SaveSlotEntry] {
  save_slot_entries_in(default_save_namespace)
}
