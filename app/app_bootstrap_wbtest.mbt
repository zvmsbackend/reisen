///|
using @core {script}

///|
fn dummy_bg(id : String) -> @assets.Background {
  @js.Object::from_iter([("id", id), ("url", "")].iter()).to_value().cast()
}

///|
fn dummy_figure(id : String) -> @assets.PixiFigure {
  @js.Value::cast_from(id).cast()
}

///|
fn dummy_music(id : String) -> @assets.Music {
  @js.Value::cast_from(id).cast()
}

///|
fn dummy_sfx(id : String) -> @assets.Sfx {
  @js.Value::cast_from(id).cast()
}

///|
async test "start_game wires runner and performs initial sync" {
  let script : Script[Int] = script(builder => builder.say("narrator", "hello"))
  let calls : Array[Int] = []
  let hook : RenderSyncHook = (_, _) => calls.push(1)
  let runner = start_game(
    script,
    GameState::new(0),
    "app",
    core_render_sync=hook,
  )

  // Initial sync in bootstrap.
  assert_eq(calls.length(), 1)
  assert_eq(
    runner.step(),
    Said(
      speaker=DialogText::String("narrator"),
      text=DialogText::String("hello"),
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
    core_render_sync=(_, _) => calls.push(1),
    event_hook=event => events.push(event),
  )

  assert_eq(calls.length(), 1)
  assert_eq(
    runner.step(),
    Said(
      speaker=DialogText::String("narrator"),
      text=DialogText::String("hello"),
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
    builder..say("n", "a").say("n", "b")
  })
  let runtime = Runtime::new(script, GameState::new(0))
  assert_eq(
    runtime.step(),
    Said(
      speaker=DialogText::String("n"),
      text=DialogText::String("a"),
      typewriter=true,
      append=false,
      voice=None,
    ),
  )
  let saved = runtime.save_json()

  let runner = start_game_from_save(script, saved, "app")
  assert_eq(
    runner.step(),
    Said(
      speaker=DialogText::String("n"),
      text=DialogText::String("b"),
      typewriter=true,
      append=false,
      voice=None,
    ),
  )
}

///|
async test "save_runner_to_slot and start_game_from_slot roundtrip" {
  let store = default_save_slot_storage()
  store.delete_slot("global", "wb_slot_roundtrip")
  let script : Script[Int] = script(builder => {
    builder..say("n", "a").say("n", "b")
  })

  let runner = start_game(script, GameState::new(0), "app")
  assert_eq(
    runner.step(),
    Said(
      speaker=DialogText::String("n"),
      text=DialogText::String("a"),
      typewriter=true,
      append=false,
      voice=None,
    ),
  )
  save_runner_to_slot(runner, "wb_slot_roundtrip")

  let resumed = start_game_from_slot(script, "wb_slot_roundtrip", "app")
  assert_eq(
    resumed.step(),
    Said(
      speaker=DialogText::String("n"),
      text=DialogText::String("a"),
      typewriter=true,
      append=false,
      voice=None,
    ),
  )
}

///|
async test "save slot payload is wrapped with version" {
  let store = default_save_slot_storage()
  store.delete_slot("global", "wb_slot_payload")
  let script : Script[Int] = script(builder => builder.say("n", "a"))
  let runner = start_game(script, GameState::new(0), "app")
  save_runner_to_slot(runner, "wb_slot_payload")

  let raw = store.read_slot("global", "wb_slot_payload")
  assert_true(raw is Some(_))
  match raw {
    Some(s) => {
      let payload : SaveSlotPayload = s |> @json.parse |> @json.from_json
      assert_eq(payload.version, 2)
      assert_true(payload.director_json != "")
      assert_eq(payload.dialog_history, [])
    }
    None => fail("missing payload")
  }
}

///|
async test "start_game_from_slot restores dialog history from payload" {
  let store = default_save_slot_storage()
  store.delete_slot("global", "wb_slot_history")
  let script : Script[Int] = script(builder => {
    builder..say("n", "a").say("n", "b")
  })

  let runner = start_game(script, GameState::new(0), "app")
  assert_eq(
    runner.step(),
    Said(
      speaker=DialogText::String("n"),
      text=DialogText::String("a"),
      typewriter=true,
      append=false,
      voice=None,
    ),
  )
  save_runner_to_slot(runner, "wb_slot_history")

  let resumed = start_game_from_slot(script, "wb_slot_history", "app")
  assert_eq(resumed.dialog_history(), [{ speaker: "n", text: "a" }])
}

///|
async test "save_runner_to_slot_with_meta writes slot metadata" {
  let store = default_save_slot_storage()
  store.delete_slot("global", "wb_slot_meta")
  let script : Script[Int] = script(builder => builder.say("n", "line"))
  let runner = start_game(script, GameState::new(0), "app")
  save_runner_to_slot_with_meta(
    runner,
    "wb_slot_meta",
    title="Slot 1",
    preview="line",
  )

  let meta = store.read_slot_meta("global", "wb_slot_meta")
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
  let store = default_save_slot_storage()
  store.delete_slot("global", "wb_slot_missing")
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
  let store = default_save_slot_storage()
  store.delete_slot("game_a", "shared_slot")
  store.delete_slot("game_b", "shared_slot")
  let script : Script[Int] = script(builder => {
    builder..say("n", "a").say("n", "b")
  })
  let runner = start_game(script, GameState::new(0), "app")
  assert_eq(
    runner.step(),
    Said(
      speaker=DialogText::String("n"),
      text=DialogText::String("a"),
      typewriter=true,
      append=false,
      voice=None,
    ),
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
    Said(
      speaker=DialogText::String("n"),
      text=DialogText::String("a"),
      typewriter=true,
      append=false,
      voice=None,
    ),
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
async test "start_game_from_save raises on corrupt json" {
  let script : Script[Int] = script(builder => builder.say("n", "hi"))
  let result : Result[GameRunner[Int], Error] = try? start_game_from_save(
    script, "{not valid json", "app",
  )
  assert_true(result is Err(_))
}

///|
async test "start_game_from_save raises when ip is out of bounds in json" {
  let script : Script[Int] = script(builder => builder.say("n", "hi"))
  let bad_json = "{\"ip\":999,\"state\":{\"int_vars\":{},\"text_vars\":{},\"flags\":{},\"payload\":0},\"pending_choices\":[],\"pending_text_input\":null,\"wait_ms\":0,\"wait_for_click\":false,\"wait_for_click_can_skip\":true,\"wait_custom_name\":null,\"wait_video\":false,\"last_say_proceed_on_done\":false,\"ended\":false}"
  let result : Result[GameRunner[Int], Error] = try? start_game_from_save(
    script, bad_json, "app",
  )
  assert_true(result is Err(_))
}

///|
test "validate_script_image_assets succeeds when all ids exist" {
  let script : Script[Int] = script(builder => {
    builder
    ..scene(dummy_bg("bg_school"))
    .show_figure_at(dummy_figure("alice"), Left)
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
    builder
    ..play_music(dummy_music("bgm_theme"), true)
    .play_sfx(dummy_sfx("click"))
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
