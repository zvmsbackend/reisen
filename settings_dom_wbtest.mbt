///|
test "settings default values" {
  let defaults = game_settings_default()
  assert_eq(defaults.text_speed, 50)
  assert_eq(defaults.bgm_volume, 0.7)
  assert_eq(defaults.sfx_volume, 0.8)
  assert_eq(defaults.skip_mode, false)
}

///|
test "settings write read roundtrip" {
  let settings = game_settings_default()
  settings_write(settings)
  let read = settings_read()
  assert_eq(read, Some(settings))
  settings_write(game_settings_default())
}

///|
test "settings write read with custom values" {
  let custom : GameSettings = {
    text_speed: 80,
    bgm_volume: 0.5,
    sfx_volume: 0.9,
    skip_mode: true,
  }
  settings_write(custom)
  let read = settings_read()
  assert_eq(read, Some(custom))
  settings_write(game_settings_default())
}

///|
test "settings are isolated by namespace" {
  let settings_a : GameSettings = {
    text_speed: 30,
    bgm_volume: 0.3,
    sfx_volume: 0.3,
    skip_mode: false,
  }
  let settings_b : GameSettings = {
    text_speed: 90,
    bgm_volume: 0.9,
    sfx_volume: 0.9,
    skip_mode: true,
  }
  settings_write_in("game_a", settings_a)
  settings_write_in("game_b", settings_b)

  assert_eq(settings_read_in("game_a"), Some(settings_a))
  assert_eq(settings_read_in("game_b"), Some(settings_b))
  assert_eq(settings_read(), Some(game_settings_default()))
}

///|
test "settings overwrite previous values" {
  let first : GameSettings = {
    text_speed: 25,
    bgm_volume: 0.4,
    sfx_volume: 0.5,
    skip_mode: false,
  }
  let second : GameSettings = {
    text_speed: 75,
    bgm_volume: 0.6,
    sfx_volume: 0.7,
    skip_mode: true,
  }

  settings_write(first)
  assert_eq(settings_read(), Some(first))

  settings_write(second)
  assert_eq(settings_read(), Some(second))
}

///|
test "game_settings JSON roundtrip" {
  let settings : GameSettings = {
    text_speed: 60,
    bgm_volume: 0.55,
    sfx_volume: 0.85,
    skip_mode: true,
  }
  let json_str = settings.to_json().stringify()
  let parsed = @json.parse(json_str)
  let read : GameSettings = @json.from_json(parsed)
  assert_eq(read.text_speed, settings.text_speed)
  assert_eq(read.bgm_volume, settings.bgm_volume)
  assert_eq(read.sfx_volume, settings.sfx_volume)
  assert_eq(read.skip_mode, settings.skip_mode)
}
