///|
test "app controller enters game on new game action" {
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let app = AppController::new(script, () => GameState::new(0), "app")

  assert_eq(app.phase(), AppPhase::StartGate)
  app.enter_start_menu()
  app.handle_menu_action(StartMenuAction::NewGame)
  assert_eq(app.phase(), AppPhase::InGame)
}

///|
test "app controller stays in menu when loading missing slot" {
  save_slot_delete_in("app_test_ns_missing", "slot1")
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let app = AppController::new(script, () => GameState::new(0), "app")
  // Load from start menu now goes to settings
  app.enter_start_menu()
  app.handle_menu_action(StartMenuAction::NoAction)
  assert_eq(app.phase(), AppPhase::StartMenu)
}

///|
test "app controller can continue from saved slot" {
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
    script,
    () => GameState::new(0),
    "app",
    save_namespace="app_test_ns_continue",
  )
  app.enter_start_menu()
  app.handle_menu_action(StartMenuAction::Continue("slot1"))
  assert_eq(app.phase(), AppPhase::InGame)
}

///|
test "app controller opens gallery when entries exist" {
  gallery_register_image(
    GalleryImage::new(gensym(prefix="app_gallery"), "assets/cg_dummy.jpg"),
  )
  let script : Script[Int] = script(builder => builder.say("n", "hello"))
  let app = AppController::new(script, () => GameState::new(0), "app")
  app.enter_start_menu()
  app.handle_menu_action(StartMenuAction::Gallery)
  assert_eq(app.phase(), AppPhase::Gallery)
}

///|
test "gallery replay uses app controller state factory by default" {
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
  gallery_register_image(image)
  gallery_unlock_image(image)
  let app = AppController::new(
    script,
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
test "gallery replay uses image-specific state factory key" {
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
    replay_state_factory_key="custom_factory",
  )
  gallery_register_image(image)
  gallery_unlock_image(image)
  let app = AppController::new(
    script,
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
test "app controller submit custom event only works in game" {
  let script : Script[Int] = script(builder => {
    builder.wait_custom_event("evt", (_, payload) => payload == "ok")
    builder.say("n", "done")
  })
  let seen : Array[RuntimeEvent] = []
  let app = AppController::new(script, () => GameState::new(0), "app", event_hook=event => {
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
test "app controller custom event jump resumes on next step" {
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
  let app = AppController::new(script, () => GameState::new(0), "app")
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
