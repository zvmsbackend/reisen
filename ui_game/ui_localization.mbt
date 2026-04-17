///|
pub fn resolve_script_string(
  raw : String,
  script_locale_json : String?,
  script_default_locale_json : String?,
) -> (String, String?, Bool) {
  @util.script_locale_resolve_at(
    raw, script_locale_json, script_default_locale_json,
  )
}

///|
pub fn localize_script_string(
  raw : String,
  script_locale_json : String?,
  script_default_locale_json : String?,
) -> String {
  let (localized, _, _) = resolve_script_string(
    raw, script_locale_json, script_default_locale_json,
  )
  localized
}

///|
pub fn localize_script_text(
  text : DialogText,
  script_locale_json : String?,
  script_default_locale_json : String?,
) -> DialogText {
  match text {
    String(s) =>
      DialogText::new(
        localize_script_string(
          s, script_locale_json, script_default_locale_json,
        ),
      )
    _ => text
  }
}

///|
pub fn localize_vocal_url(
  raw : String,
  vocal_locale_dir : String,
  script_locale : String,
  script_default_locale : String,
) -> String {
  if !raw.has_prefix("@") {
    return raw
  }
  let key = raw[1:].to_string()
  if key == "" {
    return raw
  }
  if vocal_locale_dir == "" {
    return key
  }
  let locale = match script_locale {
    "" => script_default_locale
    _ => script_locale
  }
  match locale {
    "" => "\{vocal_locale_dir}/\{key}"
    _ => "\{vocal_locale_dir}/\{locale}/\{key}"
  }
}
