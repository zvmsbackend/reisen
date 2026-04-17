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
  @ui_game.localize_script_text(
    text,
    self.script_locale_json,
    self.script_default_locale_json,
  )
}

///|
fn UiDom::localize_script_text_string(self : UiDom, raw : String) -> String {
  let (localized, key, found) = @ui_game.resolve_script_string(
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
  @ui_game.localize_vocal_url(
    raw,
    self.vocal_locale_dir,
    self.script_locale,
    self.script_default_locale,
  )
}
