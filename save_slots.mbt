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
extern "js" fn save_slot_now_ms() -> Double =
  #| () => Date.now()

///|
pub fn save_slot_meta(
  title : String,
  preview : String,
  updated_at_ms? : Double = save_slot_now_ms(),
) -> SaveSlotMeta {
  { title, preview, updated_at_ms }
}

///|
extern "js" fn storage_set_item(key : String, value : String) -> Unit =
  #| (key, value) => {
  #|   if (!globalThis.__reisenStorageMirror) {
  #|     globalThis.__reisenStorageMirror = new Map();
  #|   }
  #|   globalThis.__reisenStorageMirror.set(key, value);
  #|   const ls = globalThis.localStorage;
  #|   if (ls && ls.setItem) {
  #|     ls.setItem(key, value);
  #|     return;
  #|   }
  #|   if (!globalThis.__reisenStorage) {
  #|     globalThis.__reisenStorage = new Map();
  #|   }
  #|   globalThis.__reisenStorage.set(key, value);
  #| }

///|
extern "js" fn storage_get_item(key : String) -> @js.Nullable[String] =
  #| (key) => {
  #|   const ls = globalThis.localStorage;
  #|   if (ls && ls.getItem) {
  #|     const value = ls.getItem(key);
  #|     if (value !== null) return value;
  #|   }
  #|   const bag = globalThis.__reisenStorageMirror ?? globalThis.__reisenStorage;
  #|   if (!bag) return null;
  #|   return bag.has(key) ? bag.get(key) : null;
  #| }

///|
extern "js" fn storage_remove_item(key : String) -> Unit =
  #| (key) => {
  #|   const mirror = globalThis.__reisenStorageMirror;
  #|   if (mirror) mirror.delete(key);
  #|   const ls = globalThis.localStorage;
  #|   if (ls && ls.removeItem) {
  #|     ls.removeItem(key);
  #|     return;
  #|   }
  #|   const bag = globalThis.__reisenStorage;
  #|   if (!bag) return;
  #|   bag.delete(key);
  #| }

///|
extern "js" fn storage_list_slots(prefix : String) -> Array[String] =
  #| (prefix) => {
  #|   const out = new Set();
  #|   const suffix = (key) => key.slice(prefix.length);
  #|   const ls = globalThis.localStorage;
  #|   if (ls && ls.length !== undefined && ls.key) {
  #|     for (let i = 0; i < ls.length; i++) {
  #|       const k = ls.key(i);
  #|       if (k && k.startsWith(prefix)) out.add(suffix(k));
  #|     }
  #|   }
  #|   const bag = globalThis.__reisenStorageMirror ?? globalThis.__reisenStorage;
  #|   if (bag) {
  #|     for (const k of bag.keys()) {
  #|       if (k.startsWith(prefix)) out.add(suffix(k));
  #|     }
  #|   }
  #|   return Array.from(out);
  #| }

///|
fn namespaced_prefix(ns : String) -> String {
  save_slot_prefix + ns + "."
}

///|
fn namespaced_meta_prefix(ns : String) -> String {
  save_slot_meta_prefix + ns + "."
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
pub fn save_slot_write_in(ns : String, slot : String, value : String) -> Unit {
  storage_set_item(slot_key(ns, slot), value)
}

///|
pub fn save_slot_read_in(ns : String, slot : String) -> String? {
  storage_get_item(slot_key(ns, slot)).to_option()
}

///|
pub fn save_slot_delete_in(ns : String, slot : String) -> Unit {
  storage_remove_item(slot_key(ns, slot))
  storage_remove_item(slot_meta_key(ns, slot))
}

///|
pub fn save_slot_list_in(ns : String) -> Array[String] {
  storage_list_slots(namespaced_prefix(ns))
}

///|
pub fn save_slot_write_meta_in(
  ns : String,
  slot : String,
  meta : SaveSlotMeta,
) -> Unit {
  storage_set_item(slot_meta_key(ns, slot), meta.to_json().stringify())
}

///|
pub fn save_slot_read_meta_in(ns : String, slot : String) -> SaveSlotMeta? {
  match storage_get_item(slot_meta_key(ns, slot)).to_option() {
    Some(raw) => {
      let parsed : Result[SaveSlotMeta, Error] = try? @json.from_json(
        @json.parse(raw),
      )
      match parsed {
        Ok(meta) => Some(meta)
        Err(_) => None
      }
    }
    None => None
  }
}

///|
pub fn save_slot_entries_in(ns : String) -> Array[SaveSlotEntry] {
  save_slot_list_in(ns).map(slot => {
    slot,
    meta: save_slot_read_meta_in(ns, slot),
  })
}

///|
pub fn save_slot_write(slot : String, value : String) -> Unit {
  save_slot_write_in(default_save_namespace, slot, value)
}

///|
pub fn save_slot_read(slot : String) -> String? {
  save_slot_read_in(default_save_namespace, slot)
}

///|
pub fn save_slot_delete(slot : String) -> Unit {
  save_slot_delete_in(default_save_namespace, slot)
}

///|
pub fn save_slot_list() -> Array[String] {
  save_slot_list_in(default_save_namespace)
}

///|
pub fn save_slot_write_meta(slot : String, meta : SaveSlotMeta) -> Unit {
  save_slot_write_meta_in(default_save_namespace, slot, meta)
}

///|
pub fn save_slot_read_meta(slot : String) -> SaveSlotMeta? {
  save_slot_read_meta_in(default_save_namespace, slot)
}

///|
pub fn save_slot_entries() -> Array[SaveSlotEntry] {
  save_slot_entries_in(default_save_namespace)
}

///|
/// Game settings persisted to localStorage.
pub struct GameSettings {
  text_speed : Int
  bgm_volume : Double
  sfx_volume : Double
  skip_mode : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn game_settings_default() -> GameSettings {
  { text_speed: 50, bgm_volume: 0.7, sfx_volume: 0.8, skip_mode: false }
}

///|
fn settings_key(ns : String) -> String {
  settings_prefix + ns
}

///|
fn settings_key_in(ns : String) -> String {
  settings_prefix + ns + ".json"
}

///|
pub fn settings_write_in(ns : String, settings : GameSettings) -> Unit {
  storage_set_item(settings_key_in(ns), settings.to_json().stringify())
}

///|
pub fn settings_read_in(ns : String) -> GameSettings? {
  match storage_get_item(settings_key_in(ns)).to_option() {
    Some(raw) => {
      let parsed : Result[GameSettings, Error] = try? @json.from_json(
        @json.parse(raw),
      )
      match parsed {
        Ok(s) => Some(s)
        Err(_) => None
      }
    }
    None => None
  }
}

///|
pub fn settings_write(settings : GameSettings) -> Unit {
  settings_write_in(default_save_namespace, settings)
}

///|
pub fn settings_read() -> GameSettings? {
  settings_read_in(default_save_namespace)
}
