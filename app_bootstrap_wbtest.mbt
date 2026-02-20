///|
test "start_game_with_render_sync wires runner and performs initial sync" {
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.say("narrator", "hello")
  })
  let calls : Array[Int] = []
  let hook : RenderSyncHook[Int] = _ => calls.push(1)
  let runner = start_game_with_render_sync(
    script,
    GameState::new(0),
    "app",
    hook,
  )

  // Initial sync in bootstrap.
  assert_eq(calls.length(), 1)
  assert_eq(runner.step(), Said("narrator", "hello"))
  assert_eq(calls.length(), 2)
}

///|
test "start_game_with_hooks wires event hook" {
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.say("narrator", "hello")
  })
  let events : Array[RuntimeEvent] = []
  let runner = start_game_with_hooks(
    script,
    GameState::new(0),
    "app",
    _ => (),
    event => events.push(event),
  )

  assert_eq(runner.step(), Said("narrator", "hello"))
  assert_eq(events.length(), 1)
}

///|
test "validate_script_image_assets succeeds when all ids exist" {
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.scene("bg_school")
    builder.show_figure_at("alice", Left)
  })
  let store = AssetStore::new()
  let dummy : Image = @js.Value::cast_from(0).cast()
  store.put_image("bg_school", dummy)
  store.put_image("alice", dummy)

  let result : Result[Unit, AppBootstrapError] = try? validate_script_image_assets(
    script, store,
  )
  assert_true(result is Ok(_))
}

///|
test "validate_script_image_assets fails on missing image id" {
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.scene("missing_bg")
  })
  let store = AssetStore::new()

  let result : Result[Unit, AppBootstrapError] = try? validate_script_image_assets(
    script, store,
  )
  assert_true(
    result is Err(AppBootstrapError::MissingImageAsset(id="missing_bg")),
  )
}

///|
test "validate_script_audio_assets succeeds when audio ids exist" {
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.play_music("bgm_theme", true)
    builder.play_sfx("click")
  })
  let store = AssetStore::new()
  store.put_bytes("bgm_theme", Bytes::from_array([1, 2, 3]))
  store.put_bytes("click", Bytes::from_array([4, 5]))

  let result : Result[Unit, AppBootstrapError] = try? validate_script_audio_assets(
    script, store,
  )
  assert_true(result is Ok(_))
}

///|
test "validate_script_audio_assets fails on missing audio id" {
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.play_music("missing_bgm", true)
  })
  let store = AssetStore::new()

  let result : Result[Unit, AppBootstrapError] = try? validate_script_audio_assets(
    script, store,
  )
  assert_true(
    result is Err(AppBootstrapError::MissingAudioAsset(id="missing_bgm")),
  )
}
