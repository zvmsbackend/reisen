///|
using @assets_web {type WebAssetStore}

///|
using @debug {assert_eq}

///|
using @util {gensym}

///|
using @storage {persistent_delete_in, settings_write_in}

///|
using @core {label, type RuntimeEvent}

///|
struct TestAudio {
  mut bgm_gain : Double
}

///|
fn TestAudio::new() -> TestAudio {
  { bgm_gain: -1.0 }
}

///|
impl @audio.AudioPort for TestAudio with set_bgm_gain(self, gain) {
  self.bgm_gain = gain
}

///|
impl @audio.AudioPort for TestAudio with set_sfx_gain(self, gain) {
  ignore(self)
  ignore(gain)
}

///|
impl @audio.AudioPort for TestAudio with has_active_sfx(_) {
  false
}

///|
impl @audio.AudioPort for TestAudio with handle_command(_, _) {

}

///|
let dummy_assets : WebAssetStore = WebAssetStore::new()

///|
struct DummyMenuFactory {}

///|
struct DummyStartMenu {}

///|
impl StartMenu for DummyStartMenu with set_ui_strings(_, _) {

}

///|
impl StartMenu for DummyStartMenu with render_gate(_) {

}

///|
impl StartMenu for DummyStartMenu with clear_gate(_) {

}

///|
impl StartMenu for DummyStartMenu with take_gate_action(_) {
  NoAction
}

///|
impl StartMenu for DummyStartMenu with render_logo(_, _, _) {

}

///|
impl StartMenu for DummyStartMenu with clear_logo(_) {

}

///|
impl StartMenu for DummyStartMenu with take_logo_action(_) {
  NoAction
}

///|
impl StartMenu for DummyStartMenu with render_locale_picker(_, _) {

}

///|
impl StartMenu for DummyStartMenu with clear_locale_picker(_) {

}

///|
impl StartMenu for DummyStartMenu with take_locale_action(_) {
  NoAction
}

///|
impl StartMenu for DummyStartMenu with render(_) {

}

///|
impl StartMenu for DummyStartMenu with clear(_) {

}

///|
impl StartMenu for DummyStartMenu with take_action(_) {
  NoAction
}

///|
struct DummyGalleryMenu {}

///|
impl GalleryMenu for DummyGalleryMenu with set_ui_strings(_, _) {

}

///|
impl GalleryMenu for DummyGalleryMenu with set_script_localization(
  _,
  script_locale_json~,
  script_default_locale_json~,
) {
  ignore(script_locale_json)
  ignore(script_default_locale_json)
}

///|
impl GalleryMenu for DummyGalleryMenu with render(_) {

}

///|
impl GalleryMenu for DummyGalleryMenu with clear(_) {

}

///|
impl GalleryMenu for DummyGalleryMenu with take_action(_) {
  NoAction
}

///|
struct DummySettingsMenu {}

///|
impl SettingsMenu for DummySettingsMenu with set_ui_strings(_, _) {

}

///|
impl SettingsMenu for DummySettingsMenu with set_script_localization(
  _,
  script_locale_json~,
  script_default_locale_json~,
) {
  ignore(script_locale_json)
  ignore(script_default_locale_json)
}

///|
impl SettingsMenu for DummySettingsMenu with set_languages(_, _) {

}

///|
impl SettingsMenu for DummySettingsMenu with set_locale(_, _) {

}

///|
impl SettingsMenu for DummySettingsMenu with set_context(_, _) {

}

///|
impl SettingsMenu for DummySettingsMenu with set_view_mode(_, _) {

}

///|
impl SettingsMenu for DummySettingsMenu with render(_) {

}

///|
impl SettingsMenu for DummySettingsMenu with clear(_) {

}

///|
impl SettingsMenu for DummySettingsMenu with take_action(_) {
  NoAction
}

///|
struct DummyCreditsMenu {}

///|
impl CreditsMenu for DummyCreditsMenu with set_ui_strings(_, _) {

}

///|
impl CreditsMenu for DummyCreditsMenu with render(_, _) {

}

///|
impl CreditsMenu for DummyCreditsMenu with clear(_) {

}

///|
impl CreditsMenu for DummyCreditsMenu with take_action(_) {
  NoAction
}

///|
struct DummyLoadingMenu {}

///|
impl LoadingMenu for DummyLoadingMenu with render(_, _) {

}

///|
impl LoadingMenu for DummyLoadingMenu with clear(_) {

}

///|
impl MenuFactory for DummyMenuFactory with create_start_menu(
  _,
  save_store~,
  background~,
  show_credits~,
) {
  ignore(save_store)
  ignore(background)
  ignore(show_credits)
  DummyStartMenu::{  }
}

///|
impl MenuFactory for DummyMenuFactory with create_gallery_menu(_, background~) {
  ignore(background)
  DummyGalleryMenu::{  }
}

///|
impl MenuFactory for DummyMenuFactory with create_settings_menu(
  _,
  audio~,
  background~,
  show_credits~,
) {
  ignore(audio)
  ignore(background)
  ignore(show_credits)
  DummySettingsMenu::{  }
}

///|
impl MenuFactory for DummyMenuFactory with create_credits_menu(_, background~) {
  ignore(background)
  DummyCreditsMenu::{  }
}

///|
impl MenuFactory for DummyMenuFactory with create_loading_menu(_) {
  DummyLoadingMenu::{  }
}

///|
let dummy_menu_factory : &MenuFactory = DummyMenuFactory::{  }

///|
test "app controller applies stored bgm gain on startup" {
  settings_write_in("app_test_bgm_init", try! GameSettings::new(50, 0.37, 0.91))
  let audio = TestAudio::new()
  ignore(
    AppController::new(
      () => script(builder => builder.say("n", "hello")),
      () => GameState::new(0),
      dummy_ui_port_factory,
      dummy_assets,
      dummy_menu_factory,
      audio~,
      save_namespace="app_test_bgm_init",
    ),
  )
  assert_eq(audio.bgm_gain, 0.37)
}

///|
async test "app controller enters game on new game action" {
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let app = AppController::new(
    () => script,
    () => GameState::new(0),
    dummy_ui_port_factory,
    dummy_assets,
    dummy_menu_factory,
  )

  assert_eq(app.phase(), AppPhase::StartGate)
  app.enter_start_menu()
  app.handle_menu_action(NewGame)
  assert_eq(app.phase(), AppPhase::InGame)
}

///|
async test "app controller stays in menu when loading missing slot" {
  default_save_slot_storage().delete_slot("app_test_ns_missing", "slot1")
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let app = AppController::new(
    () => script,
    () => GameState::new(0),
    dummy_ui_port_factory,
    dummy_assets,
    dummy_menu_factory,
  )
  // Load from start menu now goes to settings
  app.enter_start_menu()
  app.handle_menu_action(NoAction)
  assert_eq(app.phase(), AppPhase::StartMenu)
}

///|
async test "app controller can continue from saved slot" {
  default_save_slot_storage().delete_slot("app_test_ns_continue", "slot1")
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
  save_runner_to_slot(runner, "slot1", save_namespace="app_test_ns_continue")

  let app = AppController::new(
    () => script,
    () => GameState::new(0),
    dummy_ui_port_factory,
    save_namespace="app_test_ns_continue",
    dummy_assets,
    dummy_menu_factory,
  )
  app.enter_start_menu()
  app.handle_menu_action(Continue("slot1"))
  assert_eq(app.phase(), AppPhase::InGame)
}

///|
async test "app controller opens gallery when entries exist" {
  "assets/cg_dummy.jpg" |> GalleryImage::new |> @gallery.register_image
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let app = AppController::new(
    () => script,
    () => GameState::new(0),
    dummy_ui_port_factory,
    dummy_assets,
    dummy_menu_factory,
  )
  app.enter_start_menu()
  app.handle_menu_action(Gallery)
  assert_eq(app.phase(), AppPhase::Gallery)
}

///|
async test "gallery replay uses app controller state factory by default" {
  let replay_label = gensym(prefix="replay_default")
  let start_label = label(name=gensym(prefix="start_default"))
  let replay_target = label(name=replay_label)
  let script : Script[Int] = script(builder => {
    builder
    ..label(start_label)
    ..say("n", "start")
    ..label(replay_target)
    .say("n", "{who}")
  })
  let image = GalleryImage::new("assets/cg_default.jpg", replay_label~)
  @gallery.register_image(image)
  @gallery.unlock_image(image)
  let app = AppController::new(
    () => script,
    () => {
      let state = GameState::new(0)
      state.set_text_var("who", "default")
      state
    },
    dummy_ui_port_factory,
    dummy_assets,
    dummy_menu_factory,
  )

  app.start_gallery_replay(replay_label)
  assert_eq(app.phase(), AppPhase::InGame)
  match app.runner {
    Some(runner) =>
      assert_eq(
        runner.step(),
        Said(
          speaker=DialogText::String("n"),
          text=DialogText::String("default"),
          typewriter=true,
          append=false,
          voice=None,
        ),
      )
    None => fail("Expected runner after replay")
  }
}

///|
async test "gallery replay uses image-specific state factory key" {
  let replay_label = gensym(prefix="replay_custom")
  let start_label = label(name=gensym(prefix="start_custom"))
  let replay_target = label(name=replay_label)
  let script : Script[Int] = script(builder => {
    builder
    ..label(start_label)
    ..say("n", "start")
    ..label(replay_target)
    .say("n", "{who}")
  })
  let replay_state_factories = ReplayStateFactories::new()
  let _custom_factory = replay_state_factories.register(
    () => {
      let state = GameState::new(0)
      state.set_text_var("who", "custom")
      state
    },
    key="custom_factory",
  )
  let image = GalleryImage::new(
    "assets/cg_custom.jpg",
    replay_label~,
    replay_state_factory_key=@gallery.ReplayStateFactoryKey::new(
      "custom_factory",
    ),
  )
  @gallery.register_image(image)
  @gallery.unlock_image(image)
  let app = AppController::new(
    () => script,
    () => {
      let state = GameState::new(0)
      state.set_text_var("who", "default")
      state
    },
    dummy_ui_port_factory,
    dummy_assets,
    dummy_menu_factory,
    gallery_replay_state_factories=replay_state_factories,
  )

  app.start_gallery_replay(replay_label)
  assert_eq(app.phase(), AppPhase::InGame)
  match app.runner {
    Some(runner) =>
      assert_eq(
        runner.step(),
        Said(
          speaker=DialogText::String("n"),
          text=DialogText::String("custom"),
          typewriter=true,
          append=false,
          voice=None,
        ),
      )
    None => fail("Expected runner after replay")
  }
}

///|
async test "app controller submit custom event only works in game" {
  let script : Script[Int] = script(builder => {
    builder
    ..wait_custom_event("evt", (_, payload) => payload == "ok")
    .say("n", "done")
  })
  let seen : Array[RuntimeEvent] = []
  let app = AppController::new(
    () => script,
    () => GameState::new(0),
    dummy_ui_port_factory,
    dummy_assets,
    dummy_menu_factory,
    event_hook=event => seen.push(event),
  )

  assert_eq(app.submit_custom_event("evt", "ok"), false)
  app.enter_start_menu()
  app.handle_menu_action(NewGame)
  assert_eq(app.phase(), AppPhase::InGame)
  if app.runner is Some(runner) {
    assert_eq(runner.step(), WaitCustomEventStarted("evt"))
  } else {
    fail("Expected runner")
  }
  assert_eq(app.submit_custom_event("evt", "no"), true)
  assert_eq(app.submit_custom_event("evt", "ok"), true)
  assert_eq(seen.contains(Custom("evt", "no")), true)
  assert_eq(seen.contains(Custom("evt", "ok")), true)
  match app.runner {
    Some(runner) =>
      assert_eq(
        runner.step(),
        Said(
          speaker=DialogText::String("n"),
          text=DialogText::String("done"),
          typewriter=true,
          append=false,
          voice=None,
        ),
      )
    None => fail("Expected runner")
  }
}

///|
async test "app controller custom event jump resumes on next step" {
  let left = label(name="left")
  let right = label(name="right")
  let script : Script[Int] = script(builder => {
    builder
    ..wait_custom_event_jump("route", (_, payload) => {
      if payload == "left" {
        left
      } else {
        right
      }
    })
    ..label(left)
    ..say("n", "L")
    ..label(right)
    .say("n", "R")
  })
  let app = AppController::new(
    () => script,
    () => GameState::new(0),
    dummy_ui_port_factory,
    dummy_assets,
    dummy_menu_factory,
  )
  app.enter_start_menu()
  app.handle_menu_action(NewGame)
  if app.runner is Some(runner) {
    assert_eq(runner.step(), WaitCustomEventStarted("route"))
  } else {
    fail("Expected runner")
  }

  assert_eq(app.submit_custom_event("route", "left"), true)
  match app.runner {
    Some(runner) =>
      assert_eq(
        runner.step(),
        Said(
          speaker=DialogText::String("n"),
          text=DialogText::String("L"),
          typewriter=true,
          append=false,
          voice=None,
        ),
      )
    None => fail("Expected runner")
  }
}

///|
test "start logo sequence advances one logo per skip" {
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let app = AppController::new(
    () => script,
    () => GameState::new(0),
    dummy_ui_port_factory,
    dummy_assets,
    dummy_menu_factory,
    start_logo_urls=["logo_a.png", "logo_b.png", "logo_c.png"],
    start_logo_duration_ms=5000,
  )

  app.enter_start_logo()
  assert_eq(app.phase(), AppPhase::StartLogo)
  assert_eq(app.start_logo_index, 0)

  app.advance_start_logo()
  assert_eq(app.phase(), AppPhase::StartLogo)
  assert_eq(app.start_logo_index, 1)

  app.advance_start_logo()
  assert_eq(app.phase(), AppPhase::StartLogo)
  assert_eq(app.start_logo_index, 2)

  app.advance_start_logo()
  assert_eq(app.phase(), AppPhase::StartMenu)
}

///|
async test "start logo timeout advances sequence before menu" {
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let app = AppController::new(
    () => script,
    () => GameState::new(0),
    dummy_ui_port_factory,
    dummy_assets,
    dummy_menu_factory,
    start_logo_urls=["logo_a.png", "logo_b.png"],
    start_logo_duration_ms=100,
  )

  app.enter_start_logo()
  assert_eq(app.phase(), AppPhase::StartLogo)
  assert_eq(app.start_logo_index, 0)

  ignore(app.tick(elapsed_ms=100))
  assert_eq(app.phase(), AppPhase::StartLogo)
  assert_eq(app.start_logo_index, 1)

  ignore(app.tick(elapsed_ms=100))
  assert_eq(app.phase(), AppPhase::StartMenu)
}

///|
async test "script factory is lazy and cached" {
  let calls = Ref::new(0)
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let app = AppController::new(
    () => {
      calls.val = calls.val + 1
      script
    },
    () => GameState::new(0),
    dummy_ui_port_factory,
    dummy_assets,
    dummy_menu_factory,
  )

  assert_eq(calls.val, 0)
  app.enter_start_menu()
  app.handle_menu_action(NewGame)
  assert_eq(app.phase(), AppPhase::InGame)
  assert_eq(calls.val, 1)

  app.runner = None
  app.phase = AppPhase::StartMenu
  app.handle_menu_action(NewGame)
  assert_eq(app.phase(), AppPhase::InGame)
  assert_eq(calls.val, 1)
}

///|
test "start logo urls normalize by removing empty entries" {
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let app = AppController::new(
    () => script,
    () => GameState::new(0),
    dummy_ui_port_factory,
    dummy_assets,
    dummy_menu_factory,
    start_logo_urls=["", "logo_a.png", "", "logo_b.png", ""],
  )
  assert_eq(app.start_logo_urls, ["logo_a.png", "logo_b.png"])
}

///|
test "app controller enters locale select when language not chosen" {
  persistent_delete_in("app_test_locale", "locale")
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let app = AppController::new(
    () => script,
    () => GameState::new(0),
    dummy_ui_port_factory,
    dummy_assets,
    dummy_menu_factory,
    save_namespace="app_test_locale",
    languages=[("English", "en"), ("Japanese", "ja")],
  )
  assert_eq(app.phase(), AppPhase::LocaleSelect)
  assert_eq(persistent_get_text_in("app_test_locale", "locale"), "")
}

///|
test "app controller skips locale select when language already chosen" {
  persistent_set_text_in("app_test_locale2", "locale", "ja")
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let app = AppController::new(
    () => script,
    () => GameState::new(0),
    dummy_ui_port_factory,
    dummy_assets,
    dummy_menu_factory,
    save_namespace="app_test_locale2",
    languages=[("English", "en"), ("Japanese", "ja")],
  )
  assert_eq(app.phase(), AppPhase::StartGate)
}

///|
test "app controller switches script localization from cache on web locale change" {
  persistent_delete_in("app_test_script_locale_cache", "locale")
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let app = AppController::new(
    () => script,
    () => GameState::new(0),
    dummy_ui_port_factory,
    dummy_assets,
    dummy_menu_factory,
    save_namespace="app_test_script_locale_cache",
    languages=[("English", "en"), ("Japanese", "ja")],
    script_locale_json="{\"demo.line\":\"Hello\"}",
    script_default_locale_json="{\"demo.line\":\"Hello\"}",
  )

  app.set_script_locale_cache([
    ("en", "{\"demo.line\":\"Hello\"}"),
    ("ja", "{\"demo.line\":\"こんにちは\"}"),
  ])

  app.apply_locale("ja")

  assert_eq(app.script_locale_json, Some("{\"demo.line\":\"こんにちは\"}"))
  assert_eq(app.script_default_locale_json, Some("{\"demo.line\":\"Hello\"}"))
}

///|
async test "app controller emits ui click sfx on menu action" {
  let assets = WebAssetStore::new()
  let click_sfx_url = "assets/ui_click.ogg"
  let seen : Array[RuntimeEvent] = []
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let app = AppController::new(
    () => script,
    () => GameState::new(0),
    dummy_ui_port_factory,
    assets,
    dummy_menu_factory,
    ui_click_sfx_url=click_sfx_url,
    event_hook=event => seen.push(event),
  )
  app.enter_start_menu()
  app.handle_menu_action(NewGame)
  assert_eq(seen.contains(SfxPlayed(click_sfx_url, false)), true)
}
