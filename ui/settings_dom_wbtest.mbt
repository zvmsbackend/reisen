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
  assert_eq(read, Some(settings))
  settings_write(GameSettings::default())
}

///|
test "settings write read with custom values" {
  let custom = try! GameSettings::new(80, 0.5, 0.9)
  settings_write(custom)
  let read = settings_read()
  assert_eq(read, Some(custom))
  settings_write(GameSettings::default())
}

///|
test "settings are isolated by namespace" {
  let settings_a = try! GameSettings::new(30, 0.3, 0.3)
  let settings_b = try! GameSettings::new(90, 0.9, 0.9)
  settings_write_in("game_a", settings_a)
  settings_write_in("game_b", settings_b)

  assert_eq(settings_read_in("game_a"), Some(settings_a))
  assert_eq(settings_read_in("game_b"), Some(settings_b))
  assert_eq(settings_read(), Some(GameSettings::default()))
}

///|
test "settings overwrite previous values" {
  let first = try! GameSettings::new(25, 0.4, 0.5)
  let second = try! GameSettings::new(75, 0.6, 0.7)

  settings_write(first)
  assert_eq(settings_read(), Some(first))

  settings_write(second)
  assert_eq(settings_read(), Some(second))
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
