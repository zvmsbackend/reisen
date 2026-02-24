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
  assert_eq(
    e2,
    Said(
      speaker="narrator",
      text="right",
      typewriter=true,
      append=false,
      voice=None,
    ),
  )
}

///|
test "script helper builds runnable script" {
  let compiled : Script[Int] = script(builder => {
    builder.say("narrator", "hello")
  })
  let runtime = Runtime::new(compiled, GameState::new(0))
  assert_eq(
    runtime.step(),
    Said(
      speaker="narrator",
      text="hello",
      typewriter=true,
      append=false,
      voice=None,
    ),
  )
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
  assert_eq(
    runtime.step(),
    Said(
      speaker="narrator",
      text="then",
      typewriter=true,
      append=false,
      voice=None,
    ),
  )
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
  assert_eq(
    runtime.step(),
    Said(
      speaker="narrator",
      text="else",
      typewriter=true,
      append=false,
      voice=None,
    ),
  )
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
  assert_eq(
    runtime.step(),
    Said(
      speaker="guide",
      text="Which path?",
      typewriter=true,
      append=false,
      voice=None,
    ),
  )
  assert_true(runtime.step() is ChoicePrompt(_))
  assert_eq(
    runtime.choose("b"),
    Said(speaker="guide", text="B", typewriter=true, append=false, voice=None),
  )
}

///|
test "runtime save and restore json" {
  let script : Script[Int] = script_from_instructions([
    Label("start"),
    Wait(100),
    RunCode(gs => gs.set_int_var("count", gs.int_var("count") + 1)),
    Say(
      speaker="narrator",
      text="done",
      typewriter=true,
      append=false,
      voice=None,
    ),
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
    Said(
      speaker="narrator",
      text="done",
      typewriter=true,
      append=false,
      voice=None,
    ),
  )
}

///|
test "runtime say supports disabling typewriter" {
  let script : Script[Int] = script(builder => {
    builder.say("n", "instant", typewriter=false)
  })
  let runtime = Runtime::new(script, GameState::new(0))
  assert_eq(
    runtime.step(),
    Said(
      speaker="n",
      text="instant",
      typewriter=false,
      append=false,
      voice=None,
    ),
  )
}

///|
test "runtime intro yields intro event" {
  let script : Script[Int] = script(builder => builder.intro("Prelude"))
  let runtime = Runtime::new(script, GameState::new(0))
  assert_eq(runtime.step(), IntroShown("Prelude"))
}

///|
test "runtime textbox events" {
  let script : Script[Int] = script(builder => {
    builder.hide_text_box()
    builder.show_text_box()
  })
  let runtime = Runtime::new(script, GameState::new(0))
  assert_eq(runtime.step(), TextBoxHidden)
  assert_eq(runtime.step(), TextBoxShown)
}

///|
test "runtime avatar events" {
  let script : Script[Int] = script(builder => {
    builder.show_avatar("/avatar.png")
    builder.hide_avatar()
  })
  let runtime = Runtime::new(script, GameState::new(0))
  assert_eq(runtime.step(), AvatarShown("/avatar.png"))
  assert_eq(runtime.step(), AvatarHidden)
}

///|
test "runtime say emits voice id" {
  let script : Script[Int] = script(builder => {
    builder.say("n", "hello", voice="voice_1")
  })
  let runtime = Runtime::new(script, GameState::new(0))
  assert_eq(
    runtime.step(),
    Said(
      speaker="n",
      text="hello",
      typewriter=true,
      append=false,
      voice=Some("voice_1"),
    ),
  )
}

///|
test "runtime unlock cg emits event and updates persistent state" {
  let cg_id = gensym(prefix="runtime_cg")
  gallery_lock_image(cg_id)
  let script : Script[Int] = script(builder => builder.unlock_cg(cg_id))
  let runtime = Runtime::new(script, GameState::new(0))
  assert_eq(runtime.step(), CgUnlocked(cg_id))
  assert_eq(gallery_is_image_unlocked(cg_id), true)
  gallery_lock_image(cg_id)
}
