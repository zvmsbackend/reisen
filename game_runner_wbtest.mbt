///|
test "runner drives script and choice flow" {
  let compiled : Script[Int] = script(builder => {
    builder.label("start")
    builder.menu("guide", "Pick", [
      option("left", "Left", "left"),
      option("right", "Right", "right"),
    ])
    builder.label("left")
    builder.say("guide", "L")
    builder.jump("end")
    builder.label("right")
    builder.say("guide", "R")
    builder.label("end")
  })

  let runtime = Runtime::new(compiled, GameState::new(0))
  let runner = GameRunner::new(Director::new(runtime), UiDom::new("app"))

  assert_eq(runner.step(), Said("guide", "Pick"))
  assert_true(runner.step() is ChoicePrompt(_))
  assert_eq(runner.submit_choice("right"), Said("guide", "R"))
}

///|
test "runner stays on choice prompt until choice submitted" {
  let compiled : Script[Int] = script(builder => {
    builder.label("start")
    builder.choice([option("a", "A", "a"), option("b", "B", "b")])
    builder.label("a")
    builder.say("narrator", "A")
    builder.label("b")
  })
  let runtime = Runtime::new(compiled, GameState::new(0))
  let runner = GameRunner::new(Director::new(runtime), UiDom::new("app"))

  assert_true(runner.step() is ChoicePrompt(_))
  assert_true(runner.step() is ChoicePrompt(_))
}

///|
test "runner render sync hook is called on ui sync and step" {
  let compiled : Script[Int] = script(builder => {
    builder.label("start")
    builder.say("narrator", "hello")
  })
  let calls : Array[Int] = []
  let hook : RenderSyncHook[Int] = _ => calls.push(1)
  let runner = GameRunner::new_with_render_sync(
    Director::new(Runtime::new(compiled, GameState::new(0))),
    UiDom::new("app"),
    hook,
  )

  runner.sync_ui()
  assert_eq(calls.length(), 1)
  assert_eq(runner.step(), Said("narrator", "hello"))
  assert_eq(calls.length(), 2)
}
