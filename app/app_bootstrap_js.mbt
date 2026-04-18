///|
async fn load_optional_text(path : String) -> String raise AppBootstrapError {
  if path == "" {
    return ""
  }
  load_text(path) catch {
    error => raise LocalizationLoadFailed(message=error.message())
  }
}

///|
pub async fn preload_localization(
  save_namespace? : String = "global",
  languages? : Array[(String, String)] = [],
  ui_locale_path? : String = "locales/ui.json",
  script_locale_dir? : String = "locales",
) -> LocalizationPayload {
  let (locale, default_locale) = resolve_selected_locale(
    save_namespace, languages,
  )
  let selected_path = match (script_locale_dir, locale) {
    ("", _) => ""
    (_, "") => ""
    _ => "\{script_locale_dir}/\{locale}.json"
  }
  let default_path = match (script_locale_dir, default_locale) {
    ("", _) => ""
    (_, "") => ""
    _ => "\{script_locale_dir}/\{default_locale}.json"
  }
  {
    locale,
    default_locale,
    ui_locales_json: load_optional_text(ui_locale_path) catch {
      LocalizationLoadFailed(message~) => {
        log_app_warn("failed to load ui locale '\{ui_locale_path}': \{message}")
        ""
      }
      _ => ""
    },
    script_locale_json: load_optional_text(selected_path) catch {
      LocalizationLoadFailed(message~) => {
        log_app_warn(
          "failed to load script locale '\{selected_path}': \{message}",
        )
        ""
      }
      _ => ""
    },
    script_default_locale_json: load_optional_text(default_path) catch {
      LocalizationLoadFailed(message~) => {
        log_app_warn(
          "failed to load default script locale '\{default_path}': \{message}",
        )
        ""
      }
      _ => ""
    },
  }
}
