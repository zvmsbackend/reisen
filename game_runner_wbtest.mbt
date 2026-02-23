///|
extern "js" fn read_sfx_gain() -> Double =
  #| () => globalThis.__reisenSfxGain ?? -1

///|
extern "js" fn set_dummy_bgm() -> Unit =
  #| () => {
  #|   globalThis.__reisenBgm = { volume: 0 };
  #| }

///|
extern "js" fn read_bgm_volume() -> Double =
  #| () => (globalThis.__reisenBgm?.volume ?? -1)

///|
test "runner drives script and choice flow" {
  let left = label()
  let right = label()
  let end = label()
  let compiled : Script[Int] = script(builder => {
    builder.menu("guide", "Pick", [
      option("Left", left, id="left"),
      option("Right", right, id="right"),
    ])
    builder.label(left)
    builder.say("guide", "L")
    builder.jump(end)
    builder.label(right)
    builder.say("guide", "R")
    builder.label(end)
  })

  let runtime = Runtime::new(compiled, GameState::new(0))
  let ui = UiDom::new("app")
  let runner = GameRunner::new(Director::new(runtime), ui)

  assert_eq(runner.step(), Said("guide", "Pick"))
  ui.complete_typewriter()
  ui.simulate_click()
  assert_true(runner.step() is ChoicePrompt(_))
  assert_eq(runner.submit_choice("right"), Said("guide", "R"))
}

///|
test "runner apply settings updates text speed and audio gains" {
  let runtime = Runtime::new(script(_ => ()), GameState::new(0))
  let ui = UiDom::new("app")
  let runner = GameRunner::new(Director::new(runtime), ui)

  set_dummy_bgm()
  runner.apply_settings({ text_speed: 25, bgm_volume: 0.42, sfx_volume: 0.33 })

  assert_eq(ui.text_speed_ms_per_char(), 2000 / 25)
  let bgm = read_bgm_volume()
  let sfx = read_sfx_gain()
  if bgm < 0.4199 || bgm > 0.4201 {
    fail("Expected bgm volume ~0.42")
  }
  if sfx < 0.3299 || sfx > 0.3301 {
    fail("Expected sfx gain ~0.33")
  }
}

///|
test "runner stays on choice prompt until choice submitted" {
  let a = label()
  let b = label()
  let compiled : Script[Int] = script(builder => {
    builder.choice([option("A", a), option("B", b)])
    builder.label(a)
    builder.say("narrator", "A")
    builder.label(b)
  })
  let runtime = Runtime::new(compiled, GameState::new(0))
  let runner = GameRunner::new(Director::new(runtime), UiDom::new("app"))

  assert_true(runner.step() is ChoicePrompt(_))
  assert_true(runner.step() is ChoicePrompt(_))
}

///|
test "runner render sync hook is called on ui sync and step" {
  let compiled : Script[Int] = script(builder => {
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
  assert_eq(calls.length(), 1)
}

///|
test "runner tick returns false when script ends" {
  let compiled : Script[Int] = script(builder => {
    builder.say("narrator", "only line")
  })
  let ui = UiDom::new("app")
  let runner = GameRunner::new(
    Director::new(Runtime::new(compiled, GameState::new(0))),
    ui,
  )

  assert_true(runner.tick())
  ui.complete_typewriter()
  ui.simulate_click()
  assert_true(!runner.tick())
}

///|
test "runner event hook receives emitted events" {
  let script : Script[Int] = script(builder => builder.say("n", "t"))
  let seen : Array[RuntimeEvent] = []
  let runner = GameRunner::new_with_hooks(
    Director::new(Runtime::new(script, GameState::new(0))),
    UiDom::new("app"),
    _ => (),
    event => seen.push(event),
  )
  assert_eq(runner.step(), Said("n", "t"))
  assert_eq(seen.length(), 1)
  assert_eq(seen[0], Said("n", "t"))
}

///|
test "runner keeps rendering during animations" {
  let calls : Array[Int] = []
  let hook : RenderSyncHook[Int] = _ => calls.push(1)
  let script : Script[Int] = script(builder => {
    builder.animate_opacity(Figure::{ id: "hero" }, 200)
  })
  let runner = GameRunner::new_with_render_sync(
    Director::new(Runtime::new(script, GameState::new(0))),
    UiDom::new("app"),
    hook,
  )

  let _ = runner.step()
  let before = calls.length()
  ignore(runner.tick(elapsed_ms=16))
  let after = calls.length()

  assert_true(after > before)
}
