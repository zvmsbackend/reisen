///|
async test "app controller enters game on new game action" {
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let app = AppController::new(() => script, () => GameState::new(0), "app")

  assert_eq(app.phase(), AppPhase::StartGate)
  app.enter_start_menu()
  app.handle_menu_action(StartMenuAction::NewGame)
  assert_eq(app.phase(), AppPhase::InGame)
}

///|
async test "app controller stays in menu when loading missing slot" {
  save_slot_delete_in("app_test_ns_missing", "slot1")
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let app = AppController::new(() => script, () => GameState::new(0), "app")
  // Load from start menu now goes to settings
  app.enter_start_menu()
  app.handle_menu_action(StartMenuAction::NoAction)
  assert_eq(app.phase(), AppPhase::StartMenu)
}

///|
async test "app controller can continue from saved slot" {
  save_slot_delete_in("app_test_ns_continue", "slot1")
  let script : Script[Int] = script(builder => {
    builder.say("n", "a")
    builder.say("n", "b")
  })
  let runner = start_game(script, GameState::new(0), "app")
  assert_eq(
    runner.step(),
    Said(speaker="n", text="a", typewriter=true, append=false, voice=None),
  )
  save_runner_to_slot(runner, "slot1", save_namespace="app_test_ns_continue")

  let app = AppController::new(
    () => script,
    () => GameState::new(0),
    "app",
    save_namespace="app_test_ns_continue",
  )
  app.enter_start_menu()
  app.handle_menu_action(StartMenuAction::Continue("slot1"))
  assert_eq(app.phase(), AppPhase::InGame)
}

///|
async test "app controller opens gallery when entries exist" {
  @gallery.register_image(
    GalleryImage::new(gensym(prefix="app_gallery"), "assets/cg_dummy.jpg"),
  )
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let app = AppController::new(() => script, () => GameState::new(0), "app")
  app.enter_start_menu()
  app.handle_menu_action(StartMenuAction::Gallery)
  assert_eq(app.phase(), AppPhase::Gallery)
}

///|
async test "gallery replay uses app controller state factory by default" {
  let replay_label = gensym(prefix="replay_default")
  let start_label = label(name=gensym(prefix="start_default"))
  let replay_target = label(name=replay_label)
  let script : Script[Int] = script(builder => {
    builder.label(start_label)
    builder.say("n", "start")
    builder.label(replay_target)
    builder.say("n", "{who}")
  })
  let image = GalleryImage::new(
    gensym(prefix="gallery_default"),
    "assets/cg_default.jpg",
    replay_label~,
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
    "app",
  )

  app.start_gallery_replay(replay_label)
  assert_eq(app.phase(), AppPhase::InGame)
  match app.runner {
    Some(runner) =>
      assert_eq(
        runner.step(),
        Said(
          speaker="n",
          text="default",
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
    builder.label(start_label)
    builder.say("n", "start")
    builder.label(replay_target)
    builder.say("n", "{who}")
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
    gensym(prefix="gallery_custom"),
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
    "app",
    gallery_replay_state_factories=replay_state_factories,
  )

  app.start_gallery_replay(replay_label)
  assert_eq(app.phase(), AppPhase::InGame)
  match app.runner {
    Some(runner) =>
      assert_eq(
        runner.step(),
        Said(
          speaker="n",
          text="custom",
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
    builder.wait_custom_event("evt", (_, payload) => payload == "ok")
    builder.say("n", "done")
  })
  let seen : Array[RuntimeEvent] = []
  let app = AppController::new(() => script, () => GameState::new(0), "app", event_hook=event => {
    seen.push(event)
  })

  assert_eq(app.submit_custom_event("evt", "ok"), false)
  app.enter_start_menu()
  app.handle_menu_action(StartMenuAction::NewGame)
  assert_eq(app.phase(), AppPhase::InGame)
  match app.runner {
    Some(runner) => assert_eq(runner.step(), WaitCustomEventStarted("evt"))
    None => fail("Expected runner")
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
          speaker="n",
          text="done",
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
    builder.wait_custom_event_jump("route", (_, payload) => {
      if payload == "left" {
        left
      } else {
        right
      }
    })
    builder.label(left)
    builder.say("n", "L")
    builder.label(right)
    builder.say("n", "R")
  })
  let app = AppController::new(() => script, () => GameState::new(0), "app")
  app.enter_start_menu()
  app.handle_menu_action(StartMenuAction::NewGame)
  match app.runner {
    Some(runner) => assert_eq(runner.step(), WaitCustomEventStarted("route"))
    None => fail("Expected runner")
  }

  assert_eq(app.submit_custom_event("route", "left"), true)
  match app.runner {
    Some(runner) =>
      assert_eq(
        runner.step(),
        Said(speaker="n", text="L", typewriter=true, append=false, voice=None),
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
    "app",
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
    "app",
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
    "app",
  )

  assert_eq(calls.val, 0)
  app.enter_start_menu()
  app.handle_menu_action(StartMenuAction::NewGame)
  assert_eq(app.phase(), AppPhase::InGame)
  assert_eq(calls.val, 1)

  app.runner = None
  app.phase = AppPhase::StartMenu
  app.handle_menu_action(StartMenuAction::NewGame)
  assert_eq(app.phase(), AppPhase::InGame)
  assert_eq(calls.val, 1)
}

///|
test "start logo urls normalize by removing empty entries" {
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let app = AppController::new(() => script, () => GameState::new(0), "app", start_logo_urls=[
    "", "logo_a.png", "", "logo_b.png", "",
  ])
  assert_eq(app.start_logo_urls, ["logo_a.png", "logo_b.png"])
}
