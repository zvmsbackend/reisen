///|
extern "js" fn script_locale_warn_missing(
  locale : String,
  default_locale : String,
  key : String,
) -> Unit =
  #| (locale, default_locale, key) => {
  #|   if (typeof console !== 'undefined' && console.warn) {
  #|     console.warn(`[reisen:i18n] missing script key '${key}' for locale='${locale}' (default='${default_locale}')`);
  #|   }
  #| }

///|
fn UiDom::localize_script_text(self : UiDom, text : DialogText) -> DialogText {
  match text {
    String(s) => String(self.localize_script_text_string(s))
    _ => text
  }
}

///|
fn UiDom::localize_script_text_string(self : UiDom, raw : String) -> String {
  let (localized, key, found) = script_locale_resolve_at(
    raw,
    self.script_locale_json,
    self.script_default_locale_json,
  )
  let selected_locale = self.script_locale
  let default_locale = self.script_default_locale
  if key is Some(missing_key) && !found {
    script_locale_warn_missing(selected_locale, default_locale, missing_key)
  }
  localized
}

///|
pub fn UiDom::localize_vocal_url(self : UiDom, raw : String) -> String {
  if !raw.has_prefix("@") {
    return raw
  }
  let key = try! raw[1:].to_string()
  if key == "" {
    return raw
  }
  if self.vocal_locale_dir == "" {
    return key
  }
  let locale = if self.script_locale != "" {
    self.script_locale
  } else {
    self.script_default_locale
  }
  if locale == "" {
    "\{self.vocal_locale_dir}/\{key}"
  } else {
    "\{self.vocal_locale_dir}/\{locale}/\{key}"
  }
}
