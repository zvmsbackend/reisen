///|
test "director maps runtime events into ui and render state" {
  let a = label()
  let b = label()
  let end = label()
  let compiled : Script[Int] = script(builder => {
    builder.scene(dummy_bg("bg_school"))
    builder.show_figure_at(dummy_figure("alice"), Left, layer=1, opacity=0.9)
    builder.play_music(dummy_music("bgm_theme"), true)
    builder.animate_opacity(dummy_figure("alice"), 120)
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
    Some({ pos: Left, layer: 1, opacity: 0.9, scale: 1.0 }),
  )

  assert_eq(director.step(), MusicPlayed("bgm_theme", true))
  assert_eq(director.music(), Some(("bgm_theme", true)))

  assert_true(director.step() is Animated("alice", _))
  assert_eq(director.animations().length(), 1)

  assert_eq(director.step(), Said("alice", "Where to?", true, false))
  assert_eq(
    director.dialog(),
    Some({
      speaker: "alice",
      text: "Where to?",
      typewriter: true,
      append: false,
    }),
  )

  assert_true(director.step() is ChoicePrompt(_))
  assert_eq(director.choices().length(), 2)

  assert_eq(director.choose("a"), SfxPlayed("confirm"))
  assert_eq(director.last_sfx(), Some("confirm"))

  assert_eq(director.step(), Said("alice", "A", true, false))
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
  assert_eq(director.choose("right"), Said("guide", "R", true, false))
  assert_eq(
    director.dialog(),
    Some({ speaker: "guide", text: "R", typewriter: true, append: false }),
  )
}

///|
test "director save json resumes runtime position" {
  let script : Script[Int] = script(builder => {
    builder.say("n", "a")
    builder.say("n", "b")
  })

  let director = Director::new(Runtime::new(script, GameState::new(0)))
  assert_eq(director.step(), Said("n", "a", true, false))
  let saved = director.save_json()

  let restored : Director[Int] = director_from_save_json(script, saved)
  assert_eq(restored.step(), Said("n", "b", true, false))
}

///|
test "director appends dialog text" {
  let script : Script[Int] = script(builder => {
    builder.say("n", "Hello")
    builder.say("n", " world", append=true)
  })
  let director = Director::new(Runtime::new(script, GameState::new(0)))
  assert_eq(director.step(), Said("n", "Hello", true, false))
  assert_eq(director.step(), Said("n", " world", true, true))
  assert_eq(
    director.dialog(),
    Some({ speaker: "n", text: "Hello world", typewriter: true, append: true }),
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
    builder.show_avatar(Figure::{ id: "hero" })
    builder.hide_avatar()
  })
  let director = Director::new(Runtime::new(script, GameState::new(0)))
  assert_eq(director.step(), AvatarShown("hero"))
  assert_eq(director.avatar_id(), Some("hero"))
  assert_eq(director.step(), AvatarHidden)
  assert_eq(director.avatar_id(), None)
}
