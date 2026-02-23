///|
test "runtime step and choose" {
  let script : Script[Int] = script(builder => {
    let left = label(name="left")
    let right = label(name="right")
    let end = label(name="end")
    builder.choice([
      option("Go left", left, id="left"),
      option("Go right", right, id="right"),
    ])
    builder.label(left)
    builder.say("narrator", "left")
    builder.jump(end)
    builder.label(right)
    builder.say("narrator", "right")
    builder.label(end)
  })
  let state = GameState::new(0)
  let runtime = Runtime::new(script, state)

  let e1 = runtime.step()
  assert_true(e1 is ChoicePrompt(_))

  let e2 = runtime.choose("right")
  assert_eq(e2, Said("narrator", "right", true, false))
}

///|
test "script helper builds runnable script" {
  let compiled : Script[Int] = script(builder => {
    builder.say("narrator", "hello")
  })
  let runtime = Runtime::new(compiled, GameState::new(0))
  assert_eq(runtime.step(), Said("narrator", "hello", true, false))
}

///|
test "branch helper routes to then label when predicate is true" {
  let then = label()
  let else_ = label()
  let end = label()
  let compiled : Script[Int] = script(builder => {
    builder.branch(then, else_, gs => gs.flag("go_then"))
    builder.label(then)
    builder.say("narrator", "then")
    builder.jump(end)
    builder.label(else_)
    builder.say("narrator", "else")
    builder.label(end)
  })

  let state = GameState::new(0)
  state.set_flag("go_then", true)
  let runtime = Runtime::new(compiled, state)
  assert_eq(runtime.step(), Said("narrator", "then", true, false))
}

///|
test "branch helper routes to else label when predicate is false" {
  let then = label()
  let else_ = label()
  let end = label()
  let compiled : Script[Int] = script(builder => {
    builder.branch(then, else_, gs => gs.flag("go_then"))
    builder.label(then)
    builder.say("narrator", "then")
    builder.jump(end)
    builder.label(else_)
    builder.say("narrator", "else")
    builder.label(end)
  })

  let state = GameState::new(0)
  let runtime = Runtime::new(compiled, state)
  assert_eq(runtime.step(), Said("narrator", "else", true, false))
}

///|
test "menu helper yields prompt then choice" {
  let a = label()
  let b = label()
  let end = label()
  let compiled : Script[Int] = script(builder => {
    builder.menu("guide", "Which path?", [
      option("Path A", a, id="a"),
      option("Path B", b, id="b"),
    ])
    builder.label(a)
    builder.say("guide", "A")
    builder.jump(end)
    builder.label(b)
    builder.say("guide", "B")
    builder.label(end)
  })

  let runtime = Runtime::new(compiled, GameState::new(0))
  assert_eq(runtime.step(), Said("guide", "Which path?", true, false))
  assert_true(runtime.step() is ChoicePrompt(_))
  assert_eq(runtime.choose("b"), Said("guide", "B", true, false))
}

///|
test "runtime save and restore json" {
  let script : Script[Int] = script_from_instructions([
    Label("start"),
    Wait(100),
    RunCode(gs => gs.set_int_var("count", gs.int_var("count") + 1)),
    Say("narrator", "done", true, false),
  ])
  let state = GameState::new(0)
  let runtime = Runtime::new(script, state)

  assert_eq(runtime.step(), WaitStarted(100))
  let save_json = runtime.save_json()

  let restored_result : Result[Runtime[Int], Error] = try? Runtime::from_json_string(
    script, save_json,
  )
  guard restored_result is Ok(restored) else { fail("restore failed") }

  assert_eq(
    restored.step(elapsed_ms=100),
    Said("narrator", "done", true, false),
  )
}

///|
test "runtime say supports disabling typewriter" {
  let script : Script[Int] = script(builder => {
    builder.say("n", "instant", typewriter=false)
  })
  let runtime = Runtime::new(script, GameState::new(0))
  assert_eq(runtime.step(), Said("n", "instant", false, false))
}

///|
test "runtime intro yields intro event" {
  let script : Script[Int] = script(builder => builder.intro("Prelude"))
  let runtime = Runtime::new(script, GameState::new(0))
  assert_eq(runtime.step(), IntroShown("Prelude"))
}
