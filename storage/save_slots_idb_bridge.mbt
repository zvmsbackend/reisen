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
extern "js" fn idb_preload_namespace_fire_and_forget(
  db_name : String,
  slot_prefix : String,
  meta_prefix : String,
) -> Unit =
  #| (db_name, slot_prefix, meta_prefix) => {
  #|   const root = globalThis;
  #|   const idb = root.indexedDB;
  #|   if (!idb) return;
  #|   if (!root.__reisenIdbOpenPromises) root.__reisenIdbOpenPromises = new Map();
  #|   const openDb = async () => {
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
  #|   (async () => {
  #|     const db = await openDb();
  #|     if (!db) return;
  #|     if (!root.__reisenIdbSlotCache) root.__reisenIdbSlotCache = new Map();
  #|     if (!root.__reisenIdbMetaCache) root.__reisenIdbMetaCache = new Map();
  #|     let slotCache = root.__reisenIdbSlotCache.get(db_name);
  #|     if (!slotCache) {
  #|       slotCache = new Map();
  #|       root.__reisenIdbSlotCache.set(db_name, slotCache);
  #|     }
  #|     let metaCache = root.__reisenIdbMetaCache.get(db_name);
  #|     if (!metaCache) {
  #|       metaCache = new Map();
  #|       root.__reisenIdbMetaCache.set(db_name, metaCache);
  #|     }
  #|     const loadStore = (storeName, prefix, target) => new Promise((resolve) => {
  #|       try {
  #|         const tx = db.transaction(storeName, 'readonly');
  #|         const req = tx.objectStore(storeName).openCursor();
  #|         req.onsuccess = () => {
  #|           const cur = req.result;
  #|           if (!cur) {
  #|             resolve();
  #|             return;
  #|           }
  #|           const key = String(cur.key ?? '');
  #|           if (key.startsWith(prefix)) {
  #|             const value = cur.value;
  #|             if (typeof value === 'string') target.set(key, value);
  #|           }
  #|           cur.continue();
  #|         };
  #|         req.onerror = () => resolve();
  #|         tx.onabort = () => resolve();
  #|       } catch (_) {
  #|         resolve();
  #|       }
  #|     });
  #|     await loadStore('slots', slot_prefix, slotCache);
  #|     await loadStore('meta', meta_prefix, metaCache);
  #|   })();
  #| }
