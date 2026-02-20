///|
/// Browser/local save-slot storage. Uses `localStorage` when available and
/// falls back to an in-memory map for non-browser test/runtime environments.

///|
let save_slot_prefix = "reisen.save."

///|
let save_slot_meta_prefix = "reisen.save.meta."

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
fn slot_key(slot : String) -> String {
  save_slot_prefix + slot
}

///|
fn slot_meta_key(slot : String) -> String {
  save_slot_meta_prefix + slot
}

///|
pub fn save_slot_write(slot : String, value : String) -> Unit {
  storage_set_item(slot_key(slot), value)
}

///|
pub fn save_slot_read(slot : String) -> String? {
  storage_get_item(slot_key(slot)).to_option()
}

///|
pub fn save_slot_delete(slot : String) -> Unit {
  storage_remove_item(slot_key(slot))
  storage_remove_item(slot_meta_key(slot))
}

///|
pub fn save_slot_list() -> Array[String] {
  storage_list_slots(save_slot_prefix)
}

///|
pub fn save_slot_write_meta(slot : String, meta : SaveSlotMeta) -> Unit {
  storage_set_item(slot_meta_key(slot), meta.to_json().stringify())
}

///|
pub fn save_slot_read_meta(slot : String) -> SaveSlotMeta? {
  match storage_get_item(slot_meta_key(slot)).to_option() {
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
pub fn save_slot_entries() -> Array[SaveSlotEntry] {
  save_slot_list().map(slot => { slot, meta: save_slot_read_meta(slot) })
}
