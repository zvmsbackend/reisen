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
      proceed_on_done=false,
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
test "runtime wait_click can_skip controls skip_wait" {
  let script : Script[Int] = script(builder => {
    builder.wait_click(can_skip=false)
    builder.say("n", "done")
  })
  let runtime = Runtime::new(script, GameState::new(0))
  assert_eq(runtime.step(), WaitForClickStarted)
  assert_true(!runtime.can_skip_wait())
  runtime.skip_wait()
  assert_eq(
    runtime.step(),
    Said(speaker="n", text="done", typewriter=true, append=false, voice=None),
  )
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
  let entry = GalleryImage::new(cg_id, "img_cg", title="CG")
  @gallery.lock_image(entry)
  let script : Script[Int] = script(builder => builder.unlock_cg(entry))
  let runtime = Runtime::new(script, GameState::new(0))
  assert_eq(runtime.step(), CgUnlocked(cg_id))
  assert_eq(@gallery.is_image_unlocked(entry), true)
  @gallery.lock_image(entry)
}

///|
test "runtime dom figure events" {
  let script : Script[Int] = script(builder => {
    builder.show_figure(
      dom_figure("promo"),
      place_right(layer=1, scalars={ ..ScalarState::default(), opacity: 0.8 }),
    )
    builder.hide_figure(dom_figure("#promo"))
  })
  let runtime = Runtime::new(script, GameState::new(0))
  match runtime.step() {
    DomFigureShown(id, placement, interactive) => {
      assert_eq(id, "promo")
      assert_eq(placement.pos, Right)
      assert_eq(placement.layer, 1)
      assert_eq(placement.scalars.opacity, 0.8)
      assert_eq(interactive, false)
    }
    _ => fail("Expected DomFigureShown")
  }
  assert_eq(runtime.step(), DomFigureHidden("promo"))
}

///|
test "runtime dom figure interactive update event" {
  let script : Script[Int] = script(builder => {
    builder.show_figure(dom_figure("promo"), place_center())
    builder.set_figure_interactive(dom_figure("promo"), true)
  })
  let runtime = Runtime::new(script, GameState::new(0))
  ignore(runtime.step())
  assert_eq(runtime.step(), DomFigureInteractiveSet("promo", true))
}

///|
test "runtime live2d motion and expression events" {
  let script : Script[Int] = script(builder => {
    let hero = Live2dFigure::new("hero")
    builder.play_live2d_motion(hero, "tap_body", index=2)
    builder.set_live2d_expression(hero, id="smile")
    builder.set_live2d_expression(hero)
  })
  let runtime = Runtime::new(script, GameState::new(0))
  assert_eq(runtime.step(), Live2dMotionPlayed("hero", "tap_body", Some(2)))
  assert_eq(runtime.step(), Live2dExpressionSet("hero", Some("smile")))
  assert_eq(runtime.step(), Live2dExpressionSet("hero", None))
}

///|
test "runtime waits for custom event until predicate matches" {
  let script : Script[Int] = script(builder => {
    builder.wait_custom_event("door", (_, payload) => payload == "open")
    builder.say("n", "opened")
  })
  let runtime = Runtime::new(script, GameState::new(0))

  assert_eq(runtime.step(), WaitCustomEventStarted("door"))
  assert_eq(runtime.step(), Noop)
  assert_eq(
    runtime.submit_custom_event("door", "closed"),
    Custom("door", "closed"),
  )
  assert_eq(runtime.step(), Noop)
  assert_eq(runtime.submit_custom_event("door", "open"), Custom("door", "open"))
  assert_eq(
    runtime.step(),
    Said(speaker="n", text="opened", typewriter=true, append=false, voice=None),
  )
}

///|
test "runtime save restore preserves custom event wait" {
  let script : Script[Int] = script(builder => {
    builder.wait_custom_event("evt", (_, payload) => payload == "ok")
    builder.say("n", "ready")
  })
  let runtime = Runtime::new(script, GameState::new(0))
  assert_eq(runtime.step(), WaitCustomEventStarted("evt"))
  let save_json = runtime.save_json()

  let restored_result : Result[Runtime[Int], Error] = try? Runtime::from_json_string(
    script, save_json,
  )
  guard restored_result is Ok(restored) else { fail("restore failed") }

  assert_eq(restored.step(), Noop)
  assert_eq(restored.submit_custom_event("evt", "ok"), Custom("evt", "ok"))
  assert_eq(
    restored.step(),
    Said(speaker="n", text="ready", typewriter=true, append=false, voice=None),
  )
}

///|
test "runtime custom event jump resumes at selected label on next step" {
  let left = label(name="left")
  let right = label(name="right")
  let script : Script[Int] = script(builder => {
    builder.wait_custom_event_jump("route", (_, payload) => {
      if payload == "L" {
        left
      } else {
        right
      }
    })
    builder.label(left)
    builder.say("n", "left")
    builder.label(right)
    builder.say("n", "right")
  })
  let runtime = Runtime::new(script, GameState::new(0))

  assert_eq(runtime.step(), WaitCustomEventStarted("route"))
  assert_eq(runtime.submit_custom_event("route", "L"), Custom("route", "L"))
  assert_eq(
    runtime.step(),
    Said(speaker="n", text="left", typewriter=true, append=false, voice=None),
  )
}

///|
test "runtime records jump_if flow trace" {
  let target = label(name="target")
  let script : Script[Int] = script(builder => {
    builder.jump_if(target, _ => true)
    builder.say("n", "skip")
    builder.label(target)
    builder.say("n", "ok")
  })
  let runtime = Runtime::new(script, GameState::new(0))
  assert_eq(
    runtime.step(),
    Said(speaker="n", text="ok", typewriter=true, append=false, voice=None),
  )
  assert_eq(runtime.flow_trace(), [
    ScriptFlowTrace::JumpIfResolved(ip=0, target="target", taken=true),
  ])
}

///|
test "runtime records choice flow trace" {
  let a = label(name="a")
  let b = label(name="b")
  let script : Script[Int] = script(builder => {
    builder.choice([option("A", a, id="a"), option("B", b, id="b")])
    builder.label(a)
    builder.say("n", "A")
    builder.label(b)
    builder.say("n", "B")
  })
  let runtime = Runtime::new(script, GameState::new(0))
  assert_true(runtime.step() is ChoicePrompt(_))
  ignore(runtime.choose("b"))
  assert_eq(runtime.flow_trace(), [
    ScriptFlowTrace::ChoiceResolved(ip=0, choice_id="b"),
  ])
}

///|
test "runtime records custom jump flow trace" {
  let left = label(name="left")
  let right = label(name="right")
  let script : Script[Int] = script(builder => {
    builder.wait_custom_event_jump("route", (_, payload) => {
      if payload == "L" {
        left
      } else {
        right
      }
    })
    builder.label(left)
    builder.say("n", "left")
    builder.label(right)
    builder.say("n", "right")
  })
  let runtime = Runtime::new(script, GameState::new(0))
  assert_eq(runtime.step(), WaitCustomEventStarted("route"))
  assert_eq(runtime.submit_custom_event("route", "R"), Custom("route", "R"))
  assert_eq(runtime.flow_trace(), [
    ScriptFlowTrace::CustomJumpResolved(ip=0, name="route", target="right"),
  ])
}
