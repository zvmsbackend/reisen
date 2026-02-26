///|
test "director maps runtime events into ui and render state" {
  let a = label()
  let b = label()
  let end = label()
  let compiled : Script[Int] = script(builder => {
    builder.scene(dummy_bg("bg_school"))
    builder.show_figure_at(dummy_figure("alice"), Left, layer=1, scalars={
      ..ScalarState::default(),
      opacity: 0.9,
    })
    builder.play_music(dummy_music("bgm_theme"), true)
    builder.animate_opacity(dummy_figure("alice"), 120, 1.0)
    builder.menu("alice", "Where to?", [
      option("A route", a, id="a"),
      option("B route", b, id="b"),
    ])
    builder.label(a)
    builder.play_sfx(dummy_sfx("confirm"))
    builder.say("alice", "A")
    builder.jump(end)
    builder.label(b)
    builder.say("alice", "B")
    builder.label(end)
  })

  let director = Director::new(Runtime::new(compiled, GameState::new(0)))

  assert_eq(director.step(), BackgroundShown("bg_school"))
  assert_eq(director.background(), Some("bg_school"))

  assert_true(director.step() is FigureShown("alice", _))
  assert_eq(
    director.figure("alice"),
    Some({
      pos: Left,
      layer: 1,
      scalars: { ..ScalarState::default(), opacity: 0.9 },
    }),
  )

  assert_eq(director.step(), MusicPlayed("bgm_theme", true))
  assert_eq(director.music(), Some(("bgm_theme", true)))

  assert_true(director.step() is AnimatedPixi("alice", _))
  assert_eq(director.animations().length(), 1)

  assert_eq(
    director.step(),
    Said(
      speaker="alice",
      text="Where to?",
      typewriter=true,
      append=false,
      voice=None,
    ),
  )
  assert_eq(
    director.dialog(),
    Some({
      speaker: "alice",
      text: "Where to?",
      typewriter: true,
      append: false,
      proceed_on_done: false,
    }),
  )

  assert_true(director.step() is ChoicePrompt(_))
  assert_eq(director.choices().length(), 2)

  assert_eq(director.choose("a"), SfxPlayed("confirm", false))
  assert_eq(director.last_sfx(), Some("confirm"))

  assert_eq(
    director.step(),
    Said(speaker="alice", text="A", typewriter=true, append=false, voice=None),
  )
}

///|
test "director branch false path through choose" {
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

  let director = Director::new(Runtime::new(compiled, GameState::new(0)))
  ignore(director.step())
  ignore(director.step())
  assert_eq(
    director.choose("right"),
    Said(speaker="guide", text="R", typewriter=true, append=false, voice=None),
  )
  assert_eq(
    director.dialog(),
    Some({
      speaker: "guide",
      text: "R",
      typewriter: true,
      append: false,
      proceed_on_done: false,
    }),
  )
}

///|
test "director save json resumes runtime position" {
  let script : Script[Int] = script(builder => {
    builder.say("n", "a")
    builder.say("n", "b")
  })

  let director = Director::new(Runtime::new(script, GameState::new(0)))
  assert_eq(
    director.step(),
    Said(speaker="n", text="a", typewriter=true, append=false, voice=None),
  )
  let saved = director.save_json()

  let restored : Director[Int] = director_from_save_json(script, saved)
  assert_eq(
    restored.step(),
    Said(speaker="n", text="b", typewriter=true, append=false, voice=None),
  )
}

///|
test "director appends dialog text" {
  let script : Script[Int] = script(builder => {
    builder.say("n", "Hello")
    builder.say("n", " world", append=true)
  })
  let director = Director::new(Runtime::new(script, GameState::new(0)))
  assert_eq(
    director.step(),
    Said(speaker="n", text="Hello", typewriter=true, append=false, voice=None),
  )
  assert_eq(
    director.step(),
    Said(speaker="n", text=" world", typewriter=true, append=true, voice=None),
  )
  assert_eq(
    director.dialog(),
    Some({
      speaker: "n",
      text: "Hello world",
      typewriter: true,
      append: true,
      proceed_on_done: false,
    }),
  )
}

///|
test "director toggles text box visibility" {
  let script : Script[Int] = script(builder => {
    builder.hide_text_box()
    builder.show_text_box()
  })
  let director = Director::new(Runtime::new(script, GameState::new(0)))
  assert_true(director.text_box_visible())
  assert_eq(director.step(), TextBoxHidden)
  assert_true(!director.text_box_visible())
  assert_eq(director.step(), TextBoxShown)
  assert_true(director.text_box_visible())
}

///|
test "director tracks avatar id" {
  let script : Script[Int] = script(builder => {
    builder.show_avatar("/avatar.png")
    builder.hide_avatar()
  })
  let director = Director::new(Runtime::new(script, GameState::new(0)))
  assert_eq(director.step(), AvatarShown("/avatar.png"))
  assert_eq(director.avatar_id(), Some("/avatar.png"))
  assert_eq(director.step(), AvatarHidden)
  assert_eq(director.avatar_id(), None)
}

///|
test "director tracks dom figure state" {
  let script : Script[Int] = script(builder => {
    builder.show_figure(
      dom_figure("#promo"),
      place_left(layer=3, scalars={ ..ScalarState::default(), opacity: 0.7 }),
    )
    builder.hide_figure(dom_figure("promo"))
  })
  let director = Director::new(Runtime::new(script, GameState::new(0)))
  assert_true(director.step() is DomFigureShown("promo", _, false))
  assert_eq(
    director.dom_figures().get("promo"),
    Some({
      placement: {
        pos: Left,
        layer: 3,
        scalars: { ..ScalarState::default(), opacity: 0.7 },
      },
      interactive: false,
    }),
  )
  assert_eq(director.step(), DomFigureHidden("promo"))
  assert_eq(director.dom_figures().get("promo"), None)
}

///|
test "director updates dom figure interactive without placement change" {
  let script : Script[Int] = script(builder => {
    builder.show_figure(dom_figure("promo"), place_center(layer=2))
    builder.set_figure_interactive(dom_figure("promo"), true)
  })
  let director = Director::new(Runtime::new(script, GameState::new(0)))
  ignore(director.step())
  let before = director.dom_figures().get("promo")
  assert_eq(director.step(), DomFigureInteractiveSet("promo", true))
  let after = director.dom_figures().get("promo")
  match (before, after) {
    (Some(b), Some(a)) => {
      assert_eq(a.interactive, true)
      assert_eq(a.placement, b.placement)
    }
    _ => fail("Expected dom figure state")
  }
}

///|
test "director tracks live2d motion and expression events" {
  let script : Script[Int] = script(builder => {
    builder.play_live2d_motion("hero", "tap_body", index=1)
    builder.set_live2d_expression("hero", id="smile")
  })
  let director = Director::new(Runtime::new(script, GameState::new(0)))
  assert_eq(director.step(), Live2dMotionPlayed("hero", "tap_body", Some(1)))
  assert_eq(director.live2d_motions(), [("hero", "tap_body", Some(1))])
  assert_eq(director.step(), Live2dExpressionSet("hero", Some("smile")))
  assert_eq(director.live2d_expressions(), [("hero", Some("smile"))])
}
