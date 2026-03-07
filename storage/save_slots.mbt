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
extern "js" fn idb_cache_set_slot(
  db_name : String,
  key : String,
  value : String,
) -> Unit =
  #| (db_name, key, value) => {
  #|   const root = globalThis;
  #|   if (!root.__reisenIdbSlotCache) root.__reisenIdbSlotCache = new Map();
  #|   let dbCache = root.__reisenIdbSlotCache.get(db_name);
  #|   if (!dbCache) {
  #|     dbCache = new Map();
  #|     root.__reisenIdbSlotCache.set(db_name, dbCache);
  #|   }
  #|   dbCache.set(key, value);
  #| }

///|
extern "js" fn idb_cache_get_slot(
  db_name : String,
  key : String,
) -> @js.Nullable[String] =
  #| (db_name, key) => {
  #|   const cacheRoot = globalThis.__reisenIdbSlotCache;
  #|   if (!cacheRoot) return null;
  #|   const dbCache = cacheRoot.get(db_name);
  #|   if (!dbCache) return null;
  #|   return dbCache.has(key) ? dbCache.get(key) : null;
  #| }

///|
extern "js" fn idb_cache_delete_slot(db_name : String, key : String) -> Unit =
  #| (db_name, key) => {
  #|   const cacheRoot = globalThis.__reisenIdbSlotCache;
  #|   if (!cacheRoot) return;
  #|   const dbCache = cacheRoot.get(db_name);
  #|   if (!dbCache) return;
  #|   dbCache.delete(key);
  #| }

///|
extern "js" fn idb_cache_list_slots(
  db_name : String,
  prefix : String,
) -> Array[String] =
  #| (db_name, prefix) => {
  #|   const out = [];
  #|   const cacheRoot = globalThis.__reisenIdbSlotCache;
  #|   if (!cacheRoot) return out;
  #|   const dbCache = cacheRoot.get(db_name);
  #|   if (!dbCache) return out;
  #|   for (const key of dbCache.keys()) {
  #|     if (key.startsWith(prefix)) {
  #|       out.push(key.slice(prefix.length));
  #|     }
  #|   }
  #|   return out;
  #| }

///|
extern "js" fn idb_cache_set_meta(
  db_name : String,
  key : String,
  value : String,
) -> Unit =
  #| (db_name, key, value) => {
  #|   const root = globalThis;
  #|   if (!root.__reisenIdbMetaCache) root.__reisenIdbMetaCache = new Map();
  #|   let dbCache = root.__reisenIdbMetaCache.get(db_name);
  #|   if (!dbCache) {
  #|     dbCache = new Map();
  #|     root.__reisenIdbMetaCache.set(db_name, dbCache);
  #|   }
  #|   dbCache.set(key, value);
  #| }

///|
extern "js" fn idb_cache_get_meta(
  db_name : String,
  key : String,
) -> @js.Nullable[String] =
  #| (db_name, key) => {
  #|   const cacheRoot = globalThis.__reisenIdbMetaCache;
  #|   if (!cacheRoot) return null;
  #|   const dbCache = cacheRoot.get(db_name);
  #|   if (!dbCache) return null;
  #|   return dbCache.has(key) ? dbCache.get(key) : null;
  #| }

///|
extern "js" fn idb_cache_delete_meta(db_name : String, key : String) -> Unit =
  #| (db_name, key) => {
  #|   const cacheRoot = globalThis.__reisenIdbMetaCache;
  #|   if (!cacheRoot) return;
  #|   const dbCache = cacheRoot.get(db_name);
  #|   if (!dbCache) return;
  #|   dbCache.delete(key);
  #| }

///|
extern "js" fn idb_flush_put_slot(
  db_name : String,
  key : String,
  value : String,
) -> Unit =
  #| (db_name, key, value) => {
  #|   (async () => {
  #|     const openDb = async () => {
  #|       const root = globalThis;
  #|       const idb = root.indexedDB;
  #|       if (!idb) return null;
  #|       if (!root.__reisenIdbOpenPromises) root.__reisenIdbOpenPromises = new Map();
  #|       if (root.__reisenIdbOpenPromises.has(db_name)) {
  #|         return root.__reisenIdbOpenPromises.get(db_name);
  #|       }
  #|       const promise = new Promise((resolve) => {
  #|         try {
  #|           const req = idb.open(db_name, 1);
  #|           req.onupgradeneeded = () => {
  #|             const db = req.result;
  #|             if (!db.objectStoreNames.contains('slots')) db.createObjectStore('slots');
  #|             if (!db.objectStoreNames.contains('meta')) db.createObjectStore('meta');
  #|           };
  #|           req.onsuccess = () => resolve(req.result);
  #|           req.onerror = () => resolve(null);
  #|         } catch (_) {
  #|           resolve(null);
  #|         }
  #|       });
  #|       root.__reisenIdbOpenPromises.set(db_name, promise);
  #|       return promise;
  #|     };
  #|     const db = await openDb();
  #|     if (!db) return;
  #|     await new Promise((resolve) => {
  #|       try {
  #|         const tx = db.transaction('slots', 'readwrite');
  #|         tx.objectStore('slots').put(value, key);
  #|         tx.oncomplete = () => resolve();
  #|         tx.onerror = () => resolve();
  #|         tx.onabort = () => resolve();
  #|       } catch (_) {
  #|         resolve();
  #|       }
  #|     });
  #|   })();
  #| }

///|
extern "js" fn idb_flush_put_meta(
  db_name : String,
  key : String,
  value : String,
) -> Unit =
  #| (db_name, key, value) => {
  #|   (async () => {
  #|     const openDb = async () => {
  #|       const root = globalThis;
  #|       const idb = root.indexedDB;
  #|       if (!idb) return null;
  #|       if (!root.__reisenIdbOpenPromises) root.__reisenIdbOpenPromises = new Map();
  #|       if (root.__reisenIdbOpenPromises.has(db_name)) {
  #|         return root.__reisenIdbOpenPromises.get(db_name);
  #|       }
  #|       const promise = new Promise((resolve) => {
  #|         try {
  #|           const req = idb.open(db_name, 1);
  #|           req.onupgradeneeded = () => {
  #|             const db = req.result;
  #|             if (!db.objectStoreNames.contains('slots')) db.createObjectStore('slots');
  #|             if (!db.objectStoreNames.contains('meta')) db.createObjectStore('meta');
  #|           };
  #|           req.onsuccess = () => resolve(req.result);
  #|           req.onerror = () => resolve(null);
  #|         } catch (_) {
  #|           resolve(null);
  #|         }
  #|       });
  #|       root.__reisenIdbOpenPromises.set(db_name, promise);
  #|       return promise;
  #|     };
  #|     const db = await openDb();
  #|     if (!db) return;
  #|     await new Promise((resolve) => {
  #|       try {
  #|         const tx = db.transaction('meta', 'readwrite');
  #|         tx.objectStore('meta').put(value, key);
  #|         tx.oncomplete = () => resolve();
  #|         tx.onerror = () => resolve();
  #|         tx.onabort = () => resolve();
  #|       } catch (_) {
  #|         resolve();
  #|       }
  #|     });
  #|   })();
  #| }

///|
extern "js" fn idb_flush_delete_slot(
  db_name : String,
  value_key : String,
  meta_key : String,
) -> Unit =
  #| (db_name, value_key, meta_key) => {
  #|   (async () => {
  #|     const openDb = async () => {
  #|       const root = globalThis;
  #|       const idb = root.indexedDB;
  #|       if (!idb) return null;
  #|       if (!root.__reisenIdbOpenPromises) root.__reisenIdbOpenPromises = new Map();
  #|       if (root.__reisenIdbOpenPromises.has(db_name)) {
  #|         return root.__reisenIdbOpenPromises.get(db_name);
  #|       }
  #|       const promise = new Promise((resolve) => {
  #|         try {
  #|           const req = idb.open(db_name, 1);
  #|           req.onupgradeneeded = () => {
  #|             const db = req.result;
  #|             if (!db.objectStoreNames.contains('slots')) db.createObjectStore('slots');
  #|             if (!db.objectStoreNames.contains('meta')) db.createObjectStore('meta');
  #|           };
  #|           req.onsuccess = () => resolve(req.result);
  #|           req.onerror = () => resolve(null);
  #|         } catch (_) {
  #|           resolve(null);
  #|         }
  #|       });
  #|       root.__reisenIdbOpenPromises.set(db_name, promise);
  #|       return promise;
  #|     };
  #|     const db = await openDb();
  #|     if (!db) return;
  #|     await new Promise((resolve) => {
  #|       try {
  #|         const tx = db.transaction(['slots', 'meta'], 'readwrite');
  #|         tx.objectStore('slots').delete(value_key);
  #|         tx.objectStore('meta').delete(meta_key);
  #|         tx.oncomplete = () => resolve();
  #|         tx.onerror = () => resolve();
  #|         tx.onabort = () => resolve();
  #|       } catch (_) {
  #|         resolve();
  #|       }
  #|     });
  #|   })();
  #| }

///|
extern "js" fn idb_preload_namespace_into_cache(
  db_name : String,
  slot_prefix : String,
  meta_prefix : String,
) -> @js.Promise =
  #| async (db_name, slot_prefix, meta_prefix) => {
  #|   const openDb = async () => {
  #|     const root = globalThis;
  #|     const idb = root.indexedDB;
  #|     if (!idb) return null;
  #|     if (!root.__reisenIdbOpenPromises) root.__reisenIdbOpenPromises = new Map();
  #|     if (root.__reisenIdbOpenPromises.has(db_name)) {
  #|       return root.__reisenIdbOpenPromises.get(db_name);
  #|     }
  #|     const promise = new Promise((resolve) => {
  #|       try {
  #|         const req = idb.open(db_name, 1);
  #|         req.onupgradeneeded = () => {
  #|           const db = req.result;
  #|           if (!db.objectStoreNames.contains('slots')) db.createObjectStore('slots');
  #|           if (!db.objectStoreNames.contains('meta')) db.createObjectStore('meta');
  #|         };
  #|         req.onsuccess = () => resolve(req.result);
  #|         req.onerror = () => resolve(null);
  #|       } catch (_) {
  #|         resolve(null);
  #|       }
  #|     });
  #|     root.__reisenIdbOpenPromises.set(db_name, promise);
  #|     return promise;
  #|   };
  #|   const db = await openDb();
  #|   if (!db) return;
  #|   if (!globalThis.__reisenIdbSlotCache) globalThis.__reisenIdbSlotCache = new Map();
  #|   if (!globalThis.__reisenIdbMetaCache) globalThis.__reisenIdbMetaCache = new Map();
  #|   let slotCache = globalThis.__reisenIdbSlotCache.get(db_name);
  #|   if (!slotCache) {
  #|     slotCache = new Map();
  #|     globalThis.__reisenIdbSlotCache.set(db_name, slotCache);
  #|   }
  #|   let metaCache = globalThis.__reisenIdbMetaCache.get(db_name);
  #|   if (!metaCache) {
  #|     metaCache = new Map();
  #|     globalThis.__reisenIdbMetaCache.set(db_name, metaCache);
  #|   }
  #|   const loadStore = (storeName, prefix, target) => new Promise((resolve) => {
  #|     try {
  #|       const tx = db.transaction(storeName, 'readonly');
  #|       const req = tx.objectStore(storeName).openCursor();
  #|       req.onsuccess = () => {
  #|         const cur = req.result;
  #|         if (!cur) {
  #|           resolve();
  #|           return;
  #|         }
  #|         const key = String(cur.key ?? '');
  #|         if (key.startsWith(prefix)) {
  #|           const value = cur.value;
  #|           if (typeof value === 'string') target.set(key, value);
  #|         }
  #|         cur.continue();
  #|       };
  #|       req.onerror = () => resolve();
  #|       tx.onabort = () => resolve();
  #|     } catch (_) {
  #|       resolve();
  #|     }
  #|   });
  #|   await loadStore('slots', slot_prefix, slotCache);
  #|   await loadStore('meta', meta_prefix, metaCache);
  #| }

///|
extern "js" fn idb_preload_all_into_cache(db_name : String) -> @js.Promise =
  #| async (db_name) => {
  #|   const openDb = async () => {
  #|     const root = globalThis;
  #|     const idb = root.indexedDB;
  #|     if (!idb) return null;
  #|     if (!root.__reisenIdbOpenPromises) root.__reisenIdbOpenPromises = new Map();
  #|     if (root.__reisenIdbOpenPromises.has(db_name)) {
  #|       return root.__reisenIdbOpenPromises.get(db_name);
  #|     }
  #|     const promise = new Promise((resolve) => {
  #|       try {
  #|         const req = idb.open(db_name, 1);
  #|         req.onupgradeneeded = () => {
  #|           const db = req.result;
  #|           if (!db.objectStoreNames.contains('slots')) db.createObjectStore('slots');
  #|           if (!db.objectStoreNames.contains('meta')) db.createObjectStore('meta');
  #|         };
  #|         req.onsuccess = () => resolve(req.result);
  #|         req.onerror = () => resolve(null);
  #|       } catch (_) {
  #|         resolve(null);
  #|       }
  #|     });
  #|     root.__reisenIdbOpenPromises.set(db_name, promise);
  #|     return promise;
  #|   };
  #|   const db = await openDb();
  #|   if (!db) return;
  #|   if (!globalThis.__reisenIdbSlotCache) globalThis.__reisenIdbSlotCache = new Map();
  #|   if (!globalThis.__reisenIdbMetaCache) globalThis.__reisenIdbMetaCache = new Map();
  #|   let slotCache = globalThis.__reisenIdbSlotCache.get(db_name);
  #|   if (!slotCache) {
  #|     slotCache = new Map();
  #|     globalThis.__reisenIdbSlotCache.set(db_name, slotCache);
  #|   }
  #|   let metaCache = globalThis.__reisenIdbMetaCache.get(db_name);
  #|   if (!metaCache) {
  #|     metaCache = new Map();
  #|     globalThis.__reisenIdbMetaCache.set(db_name, metaCache);
  #|   }
  #|   const loadStore = (storeName, target) => new Promise((resolve) => {
  #|     try {
  #|       const tx = db.transaction(storeName, 'readonly');
  #|       const req = tx.objectStore(storeName).openCursor();
  #|       req.onsuccess = () => {
  #|         const cur = req.result;
  #|         if (!cur) {
  #|           resolve();
  #|           return;
  #|         }
  #|         const key = String(cur.key ?? '');
  #|         const value = cur.value;
  #|         if (typeof value === 'string') target.set(key, value);
  #|         cur.continue();
  #|       };
  #|       req.onerror = () => resolve();
  #|       tx.onabort = () => resolve();
  #|     } catch (_) {
  #|       resolve();
  #|     }
  #|   });
  #|   await loadStore('slots', slotCache);
  #|   await loadStore('meta', metaCache);
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
  match idb_cache_get_meta(self.db_name, slot_meta_key(ns, slot)).to_option() {
    Some(raw) => Some(@json.from_json(@json.parse(raw))) catch { _ => None }
    None => None
  }
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
pub async fn IndexedDbSaveSlotStore::preload_namespace(
  self : IndexedDbSaveSlotStore,
  ns : String,
) -> Unit {
  ignore(
    @js.Promise::wait(
      idb_preload_namespace_into_cache(
        self.db_name,
        namespaced_prefix(ns),
        namespaced_meta_prefix(ns),
      ),
    ),
  )
}

///|
pub async fn IndexedDbSaveSlotStore::preload_all(
  self : IndexedDbSaveSlotStore,
) -> Unit {
  ignore(@js.Promise::wait(idb_preload_all_into_cache(self.db_name)))
}

///|
pub impl[P : SaveSlotStore, F : SaveSlotStore] SaveSlotStore for MultiSaveSlotStore[
  P,
  F,
] with read_slot(self, ns, slot) {
  match self.primary.read_slot(ns, slot) {
    Some(value) => Some(value)
    None =>
      match self.fallback.read_slot(ns, slot) {
        Some(value) => {
          if self.migrate_on_read {
            self.primary.write_slot(ns, slot, value)
          }
          Some(value)
        }
        None => None
      }
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
  match self.primary.read_slot_meta(ns, slot) {
    Some(meta) => Some(meta)
    None =>
      match self.fallback.read_slot_meta(ns, slot) {
        Some(meta) => {
          if self.migrate_on_read {
            self.primary.write_slot_meta(ns, slot, meta)
          }
          Some(meta)
        }
        None => None
      }
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
pub fn default_save_slot_store() -> DefaultSaveSlotStore {
  MultiSaveSlotStore::new(
    indexeddb_save_slot_store(),
    local_save_slot_store(),
    migrate_on_read=true,
  )
}

///|
pub async fn preload_default_save_slot_store_namespace(ns : String) -> Unit {
  let store = default_save_slot_store()
  store.primary.preload_namespace(ns)
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
  storage_get_item(slot_key(ns, slot)).to_option()
}

///|
fn local_save_slot_delete_in(ns : String, slot : String) -> Unit {
  storage_remove_item(slot_key(ns, slot))
  storage_remove_item(slot_meta_key(ns, slot))
}

///|
fn local_save_slot_list_in(ns : String) -> Array[String] {
  storage_list_slots(namespaced_prefix(ns))
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
  match storage_get_item(slot_meta_key(ns, slot)).to_option() {
    Some(raw) => Some(@json.from_json(@json.parse(raw))) catch { _ => None }
    None => None
  }
}

///|
pub fn save_slot_write_in(ns : String, slot : String, value : String) -> Unit {
  save_slot_store_write_in(default_save_slot_store(), ns, slot, value)
}

///|
pub fn save_slot_read_in(ns : String, slot : String) -> String? {
  save_slot_store_read_in(default_save_slot_store(), ns, slot)
}

///|
pub fn save_slot_delete_in(ns : String, slot : String) -> Unit {
  save_slot_store_delete_in(default_save_slot_store(), ns, slot)
}

///|
pub fn save_slot_list_in(ns : String) -> Array[String] {
  save_slot_store_list_in(default_save_slot_store(), ns)
}

///|
pub fn save_slot_write_meta_in(
  ns : String,
  slot : String,
  meta : SaveSlotMeta,
) -> Unit {
  save_slot_store_write_meta_in(default_save_slot_store(), ns, slot, meta)
}

///|
pub fn save_slot_read_meta_in(ns : String, slot : String) -> SaveSlotMeta? {
  save_slot_store_read_meta_in(default_save_slot_store(), ns, slot)
}

///|
pub fn save_slot_entries_in(ns : String) -> Array[SaveSlotEntry] {
  save_slot_store_entries_in(default_save_slot_store(), ns)
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
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn GameSettings::new(
  text_speed : Int,
  bgm_volume : Double,
  sfx_volume : Double,
) -> GameSettings raise StorageValidationError {
  if text_speed < 10 || text_speed > 100 {
    raise StorageValidationError::InvalidTextSpeed(text_speed~)
  }
  if bgm_volume < 0.0 || bgm_volume > 1.0 {
    raise StorageValidationError::InvalidBgmVolume(bgm_volume~)
  }
  if sfx_volume < 0.0 || sfx_volume > 1.0 {
    raise StorageValidationError::InvalidSfxVolume(sfx_volume~)
  }
  { text_speed, bgm_volume, sfx_volume }
}

///|
pub impl Default for GameSettings with default() {
  { text_speed: 50, bgm_volume: 0.7, sfx_volume: 0.8 }
}

///|
fn settings_key_in(ns : String) -> String {
  settings_prefix + ns + ".json"
}

///|
fn persistent_key_in(ns : String, key : String) -> String {
  persistent_prefix + ns + "." + key
}

///|
pub fn persistent_set_flag_in(ns : String, key : String, value : Bool) -> Unit {
  storage_set_item(persistent_key_in(ns, key), if value { "1" } else { "0" })
}

///|
pub fn persistent_get_flag_in(
  ns : String,
  key : String,
  default? : Bool = false,
) -> Bool {
  match storage_get_item(persistent_key_in(ns, key)).to_option() {
    Some(raw) => raw == "1" || raw.to_lower() == "true"
    None => default
  }
}

///|
pub fn persistent_set_int_in(ns : String, key : String, value : Int) -> Unit {
  storage_set_item(persistent_key_in(ns, key), value.to_string())
}

///|
pub fn persistent_get_int_in(
  ns : String,
  key : String,
  default? : Int = 0,
) -> Int {
  match storage_get_item(persistent_key_in(ns, key)).to_option() {
    Some(raw) => @strconv.parse_int(raw) catch { _ => default }
    None => default
  }
}

///|
pub fn persistent_set_text_in(
  ns : String,
  key : String,
  value : String,
) -> Unit {
  storage_set_item(persistent_key_in(ns, key), value)
}

///|
pub fn persistent_get_text_in(
  ns : String,
  key : String,
  default? : String = "",
) -> String {
  match storage_get_item(persistent_key_in(ns, key)).to_option() {
    Some(raw) => raw
    None => default
  }
}

///|
pub fn persistent_delete_in(ns : String, key : String) -> Unit {
  storage_remove_item(persistent_key_in(ns, key))
}

///|
pub fn persistent_keys_in(ns : String) -> Array[String] {
  storage_list_slots(persistent_prefix + ns + ".")
}

///|
pub fn settings_write_in(ns : String, settings : GameSettings) -> Unit {
  storage_set_item(settings_key_in(ns), settings.to_json().stringify())
}

///|
pub fn settings_read_in(ns : String) -> GameSettings? {
  match storage_get_item(settings_key_in(ns)).to_option() {
    Some(raw) =>
      try {
        let decoded : GameSettings = @json.from_json(@json.parse(raw))
        Some(
          GameSettings::new(
            decoded.text_speed,
            decoded.bgm_volume,
            decoded.sfx_volume,
          ),
        )
      } catch {
        _ => None
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

///|
pub fn persistent_set_flag(key : String, value : Bool) -> Unit {
  persistent_set_flag_in(default_save_namespace, key, value)
}

///|
pub fn persistent_get_flag(key : String, default? : Bool = false) -> Bool {
  persistent_get_flag_in(default_save_namespace, key, default~)
}

///|
pub fn persistent_set_int(key : String, value : Int) -> Unit {
  persistent_set_int_in(default_save_namespace, key, value)
}

///|
pub fn persistent_get_int(key : String, default? : Int = 0) -> Int {
  persistent_get_int_in(default_save_namespace, key, default~)
}

///|
pub fn persistent_set_text(key : String, value : String) -> Unit {
  persistent_set_text_in(default_save_namespace, key, value)
}

///|
pub fn persistent_get_text(key : String, default? : String = "") -> String {
  persistent_get_text_in(default_save_namespace, key, default~)
}

///|
pub fn persistent_delete(key : String) -> Unit {
  persistent_delete_in(default_save_namespace, key)
}

///|
pub fn persistent_keys() -> Array[String] {
  persistent_keys_in(default_save_namespace)
}
