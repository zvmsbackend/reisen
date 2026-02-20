///|
test "runtime step and choose" {
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.choice([
      option("left", "Go left", "left"),
      option("right", "Go right", "right"),
    ])
    builder.label("left")
    builder.say("narrator", "left")
    builder.jump("end")
    builder.label("right")
    builder.say("narrator", "right")
    builder.label("end")
  })
  let state = GameState::new(0)
  let runtime = Runtime::new(script, state)

  let e1 = runtime.step()
  assert_true(e1 is ChoicePrompt(_))

  let e2 = runtime.choose("right")
  assert_eq(e2, Said("narrator", "right"))
}

///|
test "script helper builds runnable script" {
  let compiled : Script[Int] = script(builder => {
    builder.label("start")
    builder.say("narrator", "hello")
  })
  let runtime = Runtime::new(compiled, GameState::new(0))
  assert_eq(runtime.step(), Said("narrator", "hello"))
}

///|
test "branch helper routes to then label when predicate is true" {
  let compiled : Script[Int] = script(builder => {
    builder.label("start")
    builder.branch("then", "else", gs => gs.flag("go_then"))
    builder.label("then")
    builder.say("narrator", "then")
    builder.jump("end")
    builder.label("else")
    builder.say("narrator", "else")
    builder.label("end")
  })

  let state = GameState::new(0)
  state.set_flag("go_then", true)
  let runtime = Runtime::new(compiled, state)
  assert_eq(runtime.step(), Said("narrator", "then"))
}

///|
test "branch helper routes to else label when predicate is false" {
  let compiled : Script[Int] = script(builder => {
    builder.label("start")
    builder.branch("then", "else", gs => gs.flag("go_then"))
    builder.label("then")
    builder.say("narrator", "then")
    builder.jump("end")
    builder.label("else")
    builder.say("narrator", "else")
    builder.label("end")
  })

  let state = GameState::new(0)
  let runtime = Runtime::new(compiled, state)
  assert_eq(runtime.step(), Said("narrator", "else"))
}

///|
test "menu helper yields prompt then choice" {
  let compiled : Script[Int] = script(builder => {
    builder.label("start")
    builder.menu("guide", "Which path?", [
      option("a", "Path A", "path_a"),
      option("b", "Path B", "path_b"),
    ])
    builder.label("path_a")
    builder.say("guide", "A")
    builder.jump("end")
    builder.label("path_b")
    builder.say("guide", "B")
    builder.label("end")
  })

  let runtime = Runtime::new(compiled, GameState::new(0))
  assert_eq(runtime.step(), Said("guide", "Which path?"))
  assert_true(runtime.step() is ChoicePrompt(_))
  assert_eq(runtime.choose("b"), Said("guide", "B"))
}

///|
test "runtime save and restore json" {
  let script : Script[Int] = script_from_instructions([
    Label("start"),
    Wait(100),
    RunCode("inc", gs => gs.set_int_var("count", gs.int_var("count") + 1)),
    Say("narrator", "done"),
  ])
  let state = GameState::new(0)
  let runtime = Runtime::new(script, state)

  assert_eq(runtime.step(), WaitStarted(100))
  let save_json = runtime.save_json()

  let restored_result : Result[Runtime[Int], Error] = try? Runtime::from_json_string(
    script, save_json,
  )
  guard restored_result is Ok(restored) else { fail("restore failed") }

  assert_eq(restored.step(elapsed_ms=100), Said("narrator", "done"))
}
