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
  "\{settings_prefix}\{ns}.json"
}

///|
fn persistent_key_in(ns : String, key : String) -> String {
  "\{persistent_prefix}\{ns}.\{key}"
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
  storage_list_slots("\{persistent_prefix}\{ns}.")
}

///|
pub fn settings_write_in(ns : String, settings : GameSettings) -> Unit {
  storage_set_item(settings_key_in(ns), settings.to_json().stringify())
}

///|
pub fn settings_read_in(ns : String) -> GameSettings? {
  (ns |> settings_key_in |> storage_get_item)
  .to_option()
  .bind(raw => {
    try {
      let decoded : GameSettings = raw |> @json.parse |> @json.from_json
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
  })
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
