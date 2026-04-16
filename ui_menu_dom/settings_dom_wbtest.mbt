///|
using @storage {settings_read, settings_write}

///|
test "settings default values" {
  let defaults = GameSettings::default()
  assert_eq(defaults.text_speed, 50)
  assert_eq(defaults.bgm_volume, 0.7)
  assert_eq(defaults.sfx_volume, 0.8)
}

///|
test "settings write read roundtrip" {
  let settings = GameSettings::default()
  settings_write(settings)
  let read = settings_read()
  assert_true(read is Some(_))
  if read is Some(v) {
    assert_eq(v.text_speed, settings.text_speed)
    assert_eq(v.bgm_volume, settings.bgm_volume)
    assert_eq(v.sfx_volume, settings.sfx_volume)
  }
  settings_write(GameSettings::default())
}

///|
test "settings write read with custom values" {
  let custom = try! GameSettings::new(80, 0.5, 0.9)
  settings_write(custom)
  let read = settings_read()
  assert_true(read is Some(_))
  if read is Some(v) {
    assert_eq(v.text_speed, custom.text_speed)
    assert_eq(v.bgm_volume, custom.bgm_volume)
    assert_eq(v.sfx_volume, custom.sfx_volume)
  }
  settings_write(GameSettings::default())
}

///|
test "settings are isolated by namespace" {
  let settings_a = try! GameSettings::new(30, 0.3, 0.3)
  let settings_b = try! GameSettings::new(90, 0.9, 0.9)
  settings_write_in("game_a", settings_a)
  settings_write_in("game_b", settings_b)

  let read_a = settings_read_in("game_a")
  assert_true(read_a is Some(_))
  if read_a is Some(v) {
    assert_eq(v.text_speed, settings_a.text_speed)
    assert_eq(v.bgm_volume, settings_a.bgm_volume)
    assert_eq(v.sfx_volume, settings_a.sfx_volume)
  }
  let read_b = settings_read_in("game_b")
  assert_true(read_b is Some(_))
  if read_b is Some(v) {
    assert_eq(v.text_speed, settings_b.text_speed)
    assert_eq(v.bgm_volume, settings_b.bgm_volume)
    assert_eq(v.sfx_volume, settings_b.sfx_volume)
  }
  let defaults = settings_read()
  assert_true(defaults is Some(_))
  if defaults is Some(v) {
    let def = GameSettings::default()
    assert_eq(v.text_speed, def.text_speed)
    assert_eq(v.bgm_volume, def.bgm_volume)
    assert_eq(v.sfx_volume, def.sfx_volume)
  }
}

///|
test "settings overwrite previous values" {
  let first = try! GameSettings::new(25, 0.4, 0.5)
  let second = try! GameSettings::new(75, 0.6, 0.7)

  settings_write(first)
  let read_first = settings_read()
  assert_true(read_first is Some(_))
  if read_first is Some(v) {
    assert_eq(v.text_speed, first.text_speed)
    assert_eq(v.bgm_volume, first.bgm_volume)
    assert_eq(v.sfx_volume, first.sfx_volume)
  }

  settings_write(second)
  let read_second = settings_read()
  assert_true(read_second is Some(_))
  if read_second is Some(v) {
    assert_eq(v.text_speed, second.text_speed)
    assert_eq(v.bgm_volume, second.bgm_volume)
    assert_eq(v.sfx_volume, second.sfx_volume)
  }
}

///|
test "game_settings JSON roundtrip" {
  let settings = try! GameSettings::new(60, 0.55, 0.85)
  let json_str = settings.to_json().stringify()
  let parsed = @json.parse(json_str)
  let read : GameSettings = @json.from_json(parsed)
  assert_eq(read.text_speed, settings.text_speed)
  assert_eq(read.bgm_volume, settings.bgm_volume)
  assert_eq(read.sfx_volume, settings.sfx_volume)
}

///|
test "settings menu localizes save preview key" {
  let menu = SettingsMenu::new("app")
  menu.set_script_localization(
    script_locale_json=Some("{\"save.preview.auto\":\"自动存档预览\"}"),
    script_default_locale_json=Some(
      "{\"save.preview.auto\":\"Autosave preview\"}",
    ),
  )
  assert_eq(
    menu.localize_save_preview("@save.preview.auto"),
    "自动存档预览",
  )
}

///|
test "settings menu save preview fallback to key" {
  let menu = SettingsMenu::new("app")
  menu.set_script_localization(
    script_locale_json=Some("{}"),
    script_default_locale_json=Some("{}"),
  )
  assert_eq(
    menu.localize_save_preview("@save.preview.auto"),
    "save.preview.auto",
  )
}
