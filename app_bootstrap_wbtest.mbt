///|
test "start_game wires runner and performs initial sync" {
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.say("narrator", "hello")
  })
  let calls : Array[Int] = []
  let hook : RenderSyncHook[Int] = _ => calls.push(1)
  let runner = start_game(script, GameState::new(0), "app", render_sync=hook)

  // Initial sync in bootstrap.
  assert_eq(calls.length(), 1)
  assert_eq(runner.step(), Said("narrator", "hello"))
  assert_eq(calls.length(), 2)
}

///|
test "start_game supports optional hooks" {
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.say("narrator", "hello")
  })
  let calls : Array[Int] = []
  let events : Array[RuntimeEvent] = []
  let runner = start_game(
    script,
    GameState::new(0),
    "app",
    render_sync=_ => calls.push(1),
    event_hook=event => events.push(event),
  )

  assert_eq(calls.length(), 1)
  assert_eq(runner.step(), Said("narrator", "hello"))
  assert_eq(calls.length(), 2)
  assert_eq(events.length(), 1)
}

///|
test "start_game_from_save resumes script" {
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.say("n", "a")
    builder.say("n", "b")
  })
  let runtime = Runtime::new(script, GameState::new(0))
  assert_eq(runtime.step(), Said("n", "a"))
  let saved = runtime.save_json()

  let runner = start_game_from_save(script, saved, "app")
  assert_eq(runner.step(), Said("n", "b"))
}

///|
test "save_runner_to_slot and start_game_from_slot roundtrip" {
  save_slot_delete("wb_slot_roundtrip")
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.say("n", "a")
    builder.say("n", "b")
  })

  let runner = start_game(script, GameState::new(0), "app")
  assert_eq(runner.step(), Said("n", "a"))
  save_runner_to_slot(runner, "wb_slot_roundtrip")

  let resumed = start_game_from_slot(script, "wb_slot_roundtrip", "app")
  assert_eq(resumed.step(), Said("n", "b"))
}

///|
test "save_runner_to_slot_with_meta writes slot metadata" {
  save_slot_delete("wb_slot_meta")
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.say("n", "line")
  })
  let runner = start_game(script, GameState::new(0), "app")
  save_runner_to_slot_with_meta(
    runner,
    "wb_slot_meta",
    title="Slot 1",
    preview="line",
  )

  let meta = save_slot_read_meta("wb_slot_meta")
  assert_true(meta is Some(_))
  match meta {
    Some(m) => {
      assert_eq(m.title, "Slot 1")
      assert_eq(m.preview, "line")
    }
    None => fail("missing slot metadata")
  }
}

///|
test "start_game_from_slot raises on missing slot" {
  save_slot_delete("wb_slot_missing")
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.say("n", "hello")
  })
  let result : Result[GameRunner[Int], Error] = try? start_game_from_slot(
    script, "wb_slot_missing", "app",
  )
  assert_true(
    result is Err(AppBootstrapError::MissingSaveSlot(slot="wb_slot_missing")),
  )
}

///|
test "start_game_from_slot respects save namespace" {
  save_slot_delete_in("game_a", "shared_slot")
  save_slot_delete_in("game_b", "shared_slot")
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.say("n", "a")
    builder.say("n", "b")
  })
  let runner = start_game(script, GameState::new(0), "app")
  assert_eq(runner.step(), Said("n", "a"))
  save_runner_to_slot(runner, "shared_slot", save_namespace="game_a")

  let ok = start_game_from_slot(
    script,
    "shared_slot",
    "app",
    save_namespace="game_a",
  )
  assert_eq(ok.step(), Said("n", "b"))

  let bad : Result[GameRunner[Int], Error] = try? start_game_from_slot(
    script,
    "shared_slot",
    "app",
    save_namespace="game_b",
  )
  assert_true(
    bad is Err(AppBootstrapError::MissingSaveSlot(slot="shared_slot")),
  )
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
