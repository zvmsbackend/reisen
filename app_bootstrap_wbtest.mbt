///|
using @storage {save_slot_delete, save_slot_read, save_slot_read_meta}

///|
async test "start_game wires runner and performs initial sync" {
  let script : Script[Int] = script(builder => builder.say("narrator", "hello"))
  let calls : Array[Int] = []
  let hook : RenderSyncHook[Int] = _ => calls.push(1)
  let runner = start_game(script, GameState::new(0), "app", render_sync=hook)

  // Initial sync in bootstrap.
  assert_eq(calls.length(), 1)
  assert_eq(
    runner.step(),
    Said(
      speaker="narrator",
      text="hello",
      typewriter=true,
      append=false,
      voice=None,
    ),
  )
  assert_eq(calls.length(), 1)
}

///|
async test "start_game supports optional hooks" {
  let script : Script[Int] = script(builder => builder.say("narrator", "hello"))
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
  assert_eq(
    runner.step(),
    Said(
      speaker="narrator",
      text="hello",
      typewriter=true,
      append=false,
      voice=None,
    ),
  )
  assert_eq(calls.length(), 1)
  assert_eq(events.length(), 1)
}

///|
async test "start_game_from_save resumes script" {
  let script : Script[Int] = script(builder => {
    builder.say("n", "a")
    builder.say("n", "b")
  })
  let runtime = Runtime::new(script, GameState::new(0))
  assert_eq(
    runtime.step(),
    Said(speaker="n", text="a", typewriter=true, append=false, voice=None),
  )
  let saved = runtime.save_json()

  let runner = start_game_from_save(script, saved, "app")
  assert_eq(
    runner.step(),
    Said(speaker="n", text="b", typewriter=true, append=false, voice=None),
  )
}

///|
async test "save_runner_to_slot and start_game_from_slot roundtrip" {
  save_slot_delete("wb_slot_roundtrip")
  let script : Script[Int] = script(builder => {
    builder.say("n", "a")
    builder.say("n", "b")
  })

  let runner = start_game(script, GameState::new(0), "app")
  assert_eq(
    runner.step(),
    Said(speaker="n", text="a", typewriter=true, append=false, voice=None),
  )
  save_runner_to_slot(runner, "wb_slot_roundtrip")

  let resumed = start_game_from_slot(script, "wb_slot_roundtrip", "app")
  assert_eq(
    resumed.step(),
    Said(speaker="n", text="a", typewriter=true, append=false, voice=None),
  )
}

///|
async test "save slot payload is wrapped with version" {
  save_slot_delete("wb_slot_payload")
  let script : Script[Int] = script(builder => builder.say("n", "a"))
  let runner = start_game(script, GameState::new(0), "app")
  save_runner_to_slot(runner, "wb_slot_payload")

  let raw = save_slot_read("wb_slot_payload")
  assert_true(raw is Some(_))
  match raw {
    Some(s) => {
      let payload : SaveSlotPayload = @json.from_json(@json.parse(s))
      assert_eq(payload.version, 1)
      assert_true(payload.director_json != "")
    }
    None => fail("missing payload")
  }
}

///|
async test "save_runner_to_slot_with_meta writes slot metadata" {
  save_slot_delete("wb_slot_meta")
  let script : Script[Int] = script(builder => builder.say("n", "line"))
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
async test "start_game_from_slot raises on missing slot" {
  save_slot_delete("wb_slot_missing")
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let result : Result[GameRunner[Int], Error] = try? start_game_from_slot(
    script, "wb_slot_missing", "app",
  )
  assert_true(
    result is Err(AppBootstrapError::MissingSaveSlot(slot="wb_slot_missing")),
  )
}

///|
async test "start_game_from_slot respects save namespace" {
  save_slot_delete_in("game_a", "shared_slot")
  save_slot_delete_in("game_b", "shared_slot")
  let script : Script[Int] = script(builder => {
    builder.say("n", "a")
    builder.say("n", "b")
  })
  let runner = start_game(script, GameState::new(0), "app")
  assert_eq(
    runner.step(),
    Said(speaker="n", text="a", typewriter=true, append=false, voice=None),
  )
  save_runner_to_slot(runner, "shared_slot", save_namespace="game_a")

  let ok = start_game_from_slot(
    script,
    "shared_slot",
    "app",
    save_namespace="game_a",
  )
  assert_eq(
    ok.step(),
    Said(speaker="n", text="a", typewriter=true, append=false, voice=None),
  )

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
    builder.scene(dummy_bg("bg_school"))
    builder.show_figure_at(dummy_figure("alice"), Left)
  })
  let store = AssetStore::new()
  let dummy : @assets.Image = @js.Value::cast_from(0).cast()
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
    builder.scene(dummy_bg("missing_bg"))
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
    builder.play_music(dummy_music("bgm_theme"), true)
    builder.play_sfx(dummy_sfx("click"))
  })
  let store = AssetStore::new()
  store.put_audio_url("bgm_theme", "bgm://theme")
  store.put_audio_url("click", "sfx://click")

  let result : Result[Unit, AppBootstrapError] = try? validate_script_audio_assets(
    script, store,
  )
  assert_true(result is Ok(_))
}

///|
test "validate_script_audio_assets fails on missing audio id" {
  let script : Script[Int] = script(builder => {
    builder.play_music(dummy_music("missing_bgm"), true)
  })
  let store = AssetStore::new()

  let result : Result[Unit, AppBootstrapError] = try? validate_script_audio_assets(
    script, store,
  )
  assert_true(
    result is Err(AppBootstrapError::MissingAudioAsset(id="missing_bgm")),
  )
}
