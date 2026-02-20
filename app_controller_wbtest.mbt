///|
test "app controller enters game on new game action" {
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.say("n", "hello")
  })
  let app = AppController::new(script, () => GameState::new(0), "app")

  assert_eq(app.phase(), AppPhase::StartMenu)
  app.handle_menu_action(StartMenuAction::NewGame)
  assert_eq(app.phase(), AppPhase::InGame)
}

///|
test "app controller stays in menu when loading missing slot" {
  save_slot_delete_in("app_test_ns_missing", "slot1")
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.say("n", "hello")
  })
  let app = AppController::new(
    script,
    () => GameState::new(0),
    "app",
    save_namespace="app_test_ns_missing",
  )

  app.handle_menu_action(StartMenuAction::LoadSlot("slot1"))
  assert_eq(app.phase(), AppPhase::StartMenu)
}

///|
test "app controller can continue from saved slot" {
  save_slot_delete_in("app_test_ns_continue", "slot1")
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.say("n", "a")
    builder.say("n", "b")
  })
  let runner = start_game(script, GameState::new(0), "app")
  assert_eq(runner.step(), Said("n", "a"))
  save_runner_to_slot(runner, "slot1", save_namespace="app_test_ns_continue")

  let app = AppController::new(
    script,
    () => GameState::new(0),
    "app",
    save_namespace="app_test_ns_continue",
  )
  app.handle_menu_action(StartMenuAction::Continue("slot1"))
  assert_eq(app.phase(), AppPhase::InGame)
}

///|
test "app controller writes autosave when game ends" {
  save_slot_delete_in("app_test_ns_autosave", "autosave")
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.say("n", "line")
  })
  let app = AppController::new(
    script,
    () => GameState::new(0),
    "app",
    save_namespace="app_test_ns_autosave",
    autosave_slot="autosave",
  )

  app.handle_menu_action(StartMenuAction::NewGame)
  ignore(app.tick())
  ignore(app.tick())

  assert_true(save_slot_read_in("app_test_ns_autosave", "autosave") is Some(_))
}
