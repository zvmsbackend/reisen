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
  updated_at_ms : Int64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct SaveSlotEntry {
  slot : String
  meta : SaveSlotMeta?
} derive(Debug, Eq)

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
fn save_slot_time_label(ms : Int64) -> String {
  @time.ZonedDateTime::from_unix_second(
    ms / 1000,
    nanosecond=(ms % 1000).to_int() * 1000,
  )
  .to_string()
  .replace(old="T", new=" ")
  .replace(old="Z", new="") catch {
    _ => ""
  }
}

///|
pub fn save_slot_meta(
  title : String,
  preview : String,
  updated_at_ms? : Int64 = @env.now().reinterpret_as_int64(),
) -> SaveSlotMeta {
  let resolved_title = match title {
    "" => save_slot_time_label(updated_at_ms)
    _ => title
  }
  { title: resolved_title, preview, updated_at_ms }
}

///|
pub fn SaveSlotEntry::new(
  slot : String,
  meta? : SaveSlotMeta,
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
