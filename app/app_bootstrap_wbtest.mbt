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
struct DummyUiBackend {}

///|
impl @ui_game.UiBackend for DummyUiBackend with localize_vocal_url(_, raw) {
  raw
}

///|
impl @ui_game.UiBackend for DummyUiBackend with render(_, view) {
  ignore(view)
}

///|
impl @ui_game.UiBackend for DummyUiBackend with view_model_from_snapshot(
  _,
  snapshot,
) {
  ignore(snapshot)
  {
    speaker: @state.DialogText::empty(),
    text: @state.DialogText::empty(),
    dialog_seq: 0,
    typewriter: false,
    intro_text: None,
    video: None,
    append: false,
    text_box_visible: true,
    avatar_id: None,
    choices: [],
    text_input: None,
    dialog_history: [],
    dom_figures: [],
    auto_mode: false,
    skip_mode: false,
    log_visible: false,
    dirty_speaker: false,
    dirty_text: false,
    dirty_choices: false,
    dirty_text_input: false,
    dirty_action_buttons: false,
  }
}

///|
impl @ui_game.UiBackend for DummyUiBackend with take_selected_choice(_) {
  None
}

///|
impl @ui_game.UiBackend for DummyUiBackend with take_submitted_text_input(_) {
  None
}

///|
impl @ui_game.UiBackend for DummyUiBackend with take_action(_) {
  None
}

///|
impl @ui_game.UiBackend for DummyUiBackend with take_video_action(_) {
  None
}

///|
impl @ui_game.UiBackend for DummyUiBackend with check_typewriter_click(_) {
  false
}

///|
impl @ui_game.UiBackend for DummyUiBackend with check_intro_done(_) {
  false
}

///|
impl @ui_game.UiBackend for DummyUiBackend with reveal_intro_line(_) {
  false
}

///|
impl @ui_game.UiBackend for DummyUiBackend with clear_game_ui(_) {

}

///|
impl @ui_game.UiBackend for DummyUiBackend with set_ui_strings(_, ui_strings) {
  ignore(ui_strings)
}

///|
impl @ui_game.UiBackend for DummyUiBackend with set_script_localization(
  _,
  script_locale_json~,
  script_default_locale_json~,
  vocal_locale_dir~,
  script_locale~,
  script_default_locale~,
) {
  ignore(script_locale_json)
  ignore(script_default_locale_json)
  ignore(vocal_locale_dir)
  ignore(script_locale)
  ignore(script_default_locale)
}

///|
impl @ui_game.UiBackend for DummyUiBackend with simulate_click(_) {

}

///|
impl @ui_game.UiPlatformHooks for DummyUiBackend with advance_ui_animation_timer(
  _,
  elapsed_ms,
) {
  ignore(elapsed_ms)
}

///|
impl @ui_game.UiPlatformHooks for DummyUiBackend with has_active_ui_animations(
  _,
) {
  false
}

///|
impl @ui_game.UiPlatformHooks for DummyUiBackend with set_media_volume(
  _,
  volume,
) {
  ignore(volume)
}

///|
let dummy_ui_backend : DummyUiBackend = DummyUiBackend::{  }

///|
struct DummyUiPortFactory {}

///|
impl @ui_game.UiPortFactory for DummyUiPortFactory with create_port(
  _,
  ui_strings~,
  script_locale_json~,
  script_default_locale_json~,
  vocal_locale_dir~,
  script_locale~,
  script_default_locale~,
) {
  ignore(ui_strings)
  ignore(script_locale_json)
  ignore(script_default_locale_json)
  ignore(vocal_locale_dir)
  ignore(script_locale)
  ignore(script_default_locale)
  @ui_game.UiPort::from_backend(dummy_ui_backend, dummy_ui_backend)
}

///|
let dummy_ui_port_factory : &@ui_game.UiPortFactory = DummyUiPortFactory::{  }

///|
async test "start_game wires runner and performs initial sync" {
  let script : Script[Int] = script(builder => builder.say("narrator", "hello"))
  let calls : Array[Int] = []
  let hook : RenderSyncHook = (_, _) => calls.push(1)
  let runner = start_game(
    script,
    GameState::new(0),
    dummy_ui_port_factory,
    @audio.dummy,
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
    dummy_ui_port_factory,
    @audio.dummy,
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

  let runner = start_game_from_save(
    script, saved, dummy_ui_port_factory, @audio.dummy,
  )
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

  let runner = start_game(
    script,
    GameState::new(0),
    dummy_ui_port_factory,
    @audio.dummy,
  )
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

  let resumed = start_game_from_slot(
    script, "wb_slot_roundtrip", dummy_ui_port_factory, @audio.dummy,
  )
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
  let runner = start_game(
    script,
    GameState::new(0),
    dummy_ui_port_factory,
    @audio.dummy,
  )
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

  let runner = start_game(
    script,
    GameState::new(0),
    dummy_ui_port_factory,
    @audio.dummy,
  )
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

  let resumed = start_game_from_slot(
    script, "wb_slot_history", dummy_ui_port_factory, @audio.dummy,
  )
  assert_eq(resumed.dialog_history(), [{ speaker: "n", text: "a" }])
}

///|
async test "save_runner_to_slot_with_meta writes slot metadata" {
  let store = default_save_slot_storage()
  store.delete_slot("global", "wb_slot_meta")
  let script : Script[Int] = script(builder => builder.say("n", "line"))
  let runner = start_game(
    script,
    GameState::new(0),
    dummy_ui_port_factory,
    @audio.dummy,
  )
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
    script, "wb_slot_missing", dummy_ui_port_factory, @audio.dummy,
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
  let runner = start_game(
    script,
    GameState::new(0),
    dummy_ui_port_factory,
    @audio.dummy,
  )
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
    dummy_ui_port_factory,
    @audio.dummy,
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
    dummy_ui_port_factory,
    @audio.dummy,
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
    script, "{not valid json", dummy_ui_port_factory, @audio.dummy,
  )
  assert_true(result is Err(_))
}

///|
async test "start_game_from_save raises when ip is out of bounds in json" {
  let script : Script[Int] = script(builder => builder.say("n", "hi"))
  let bad_json = "{\"ip\":999,\"state\":{\"int_vars\":{},\"text_vars\":{},\"flags\":{},\"payload\":0},\"pending_choices\":[],\"pending_text_input\":null,\"wait_ms\":0,\"wait_for_click\":false,\"wait_for_click_can_skip\":true,\"wait_custom_name\":null,\"wait_video\":false,\"last_say_proceed_on_done\":false,\"ended\":false}"
  let result : Result[GameRunner[Int], Error] = try? start_game_from_save(
    script, bad_json, dummy_ui_port_factory, @audio.dummy,
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
  let store = @assets_web.WebAssetStore::new()
  let dummy : @assets_web.Image = @js.Value::cast_from(0).cast()
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
  let store = @assets_web.WebAssetStore::new()

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
  let store = @assets_web.WebAssetStore::new()
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
  let store = @assets_web.WebAssetStore::new()

  let result : Result[Unit, AppBootstrapError] = try? validate_script_audio_assets(
    script, store,
  )
  assert_true(
    result is Err(AppBootstrapError::MissingAudioAsset(id="missing_bgm")),
  )
}
