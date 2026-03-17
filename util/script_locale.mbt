///|
extern "js" fn script_locale_lookup_raw(
  locale_json : String,
  key : String,
) -> @js.Nullable[String] =
  #| (locale_json, key) => {
  #|   try {
  #|     if (!globalThis.__reisenScriptLocaleTableCache) {
  #|       globalThis.__reisenScriptLocaleTableCache = { raw: '', parsed: null };
  #|     }
  #|     const cache = globalThis.__reisenScriptLocaleTableCache;
  #|     if (cache.raw !== locale_json) {
  #|       cache.raw = locale_json;
  #|       cache.parsed = locale_json ? JSON.parse(locale_json) : null;
  #|     }
  #|     const parsed = cache.parsed;
  #|     if (!parsed || typeof parsed !== 'object') return null;
  #|     const value = parsed[key];
  #|     return typeof value === 'string' ? value : null;
  #|   } catch {
  #|     return null;
  #|   }
  #| }

///|
pub fn script_locale_lookup(locale_json : String, key : String) -> String? {
  script_locale_lookup_raw(locale_json, key).to_option()
}

///|
pub fn script_locale_resolve_at(
  raw : String,
  selected_locale_json : String?,
  default_locale_json : String?,
) -> (String, String?, Bool) {
  if !raw.has_prefix("@") {
    return (raw, None, true)
  }
  let key = match raw {
    "" => ""
    _ => raw[1:].to_string()
  }
  match key {
    "" => return (raw, None, true)
    _ => ()
  }
  match selected_locale_json {
    Some(locale_json) =>
      match script_locale_lookup(locale_json, key) {
        Some(value) => (value, Some(key), true)
        None =>
          match default_locale_json {
            Some(default_json) =>
              match script_locale_lookup(default_json, key) {
                Some(value) => (value, Some(key), true)
                None => (key, Some(key), false)
              }
            None => (key, Some(key), false)
          }
      }
    None =>
      match default_locale_json {
        Some(default_json) =>
          match script_locale_lookup(default_json, key) {
            Some(value) => (value, Some(key), true)
            None => (key, Some(key), false)
          }
        None => (key, Some(key), false)
      }
  }
}
