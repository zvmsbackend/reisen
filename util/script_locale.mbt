///|
fn script_locale_table(locale_json : String) -> Map[String, String]? {
  let parsed = try? @json.parse(locale_json)
  guard parsed is Ok(parsed) else { None }
  let table : Result[Map[String, String], _] = try? @json.from_json(parsed)
  guard table is Ok(table) else { None }
  Some(table)
}

///|
pub fn script_locale_lookup(locale_json : String, key : String) -> String? {
  script_locale_table(locale_json).bind(table => table.get(key))
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
  fn fallback_default() {
    guard default_locale_json is Some(default_json) else {
      return (key, Some(key), false)
    }
    match script_locale_lookup(default_json, key) {
      Some(value) => (value, Some(key), true)
      None => (key, Some(key), false)
    }
  }
  guard selected_locale_json is Some(locale_json) else {
    return fallback_default()
  }
  match script_locale_lookup(locale_json, key) {
    Some(value) => (value, Some(key), true)
    None => fallback_default()
  }
}
