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
extern "js" fn js_storage_get_item(key : String) -> @js.Nullable[String] =
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
fn storage_get_item(key : String) -> String? {
  js_storage_get_item(key).to_option()
}

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
