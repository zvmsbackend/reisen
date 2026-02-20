///|
test "director maps runtime events into ui and render state" {
  let compiled : Script[Int] = script(builder => {
    builder.label("start")
    builder.scene("bg_school")
    builder.show_figure_at("alice", Left, layer=1, opacity=0.9)
    builder.play_music("bgm_theme", true)
    builder.animate_opacity("alice", 120)
    builder.menu("alice", "Where to?", [
      option("a", "A route", "route_a"),
      option("b", "B route", "route_b"),
    ])
    builder.label("route_a")
    builder.play_sfx("confirm")
    builder.say("alice", "A")
    builder.jump("end")
    builder.label("route_b")
    builder.say("alice", "B")
    builder.label("end")
  })

  let director = Director::new(Runtime::new(compiled, GameState::new(0)))

  assert_eq(director.step(), BackgroundShown("bg_school"))
  assert_eq(director.background(), Some("bg_school"))

  assert_true(director.step() is FigureShown("alice", _))
  assert_eq(
    director.figure("alice"),
    Some({ pos: Left, layer: 1, opacity: 0.9 }),
  )

  assert_eq(director.step(), MusicPlayed("bgm_theme", true))
  assert_eq(director.music(), Some(("bgm_theme", true)))

  assert_true(director.step() is Animated("alice", _))
  assert_eq(director.animations().length(), 1)

  assert_eq(director.step(), Said("alice", "Where to?"))
  assert_eq(director.dialog(), Some({ speaker: "alice", text: "Where to?" }))

  assert_true(director.step() is ChoicePrompt(_))
  assert_eq(director.choices().length(), 2)

  assert_eq(director.choose("a"), SfxPlayed("confirm"))
  assert_eq(director.last_sfx(), Some("confirm"))

  assert_eq(director.step(), Said("alice", "A"))
}

///|
test "director branch false path through choose" {
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

  let director = Director::new(Runtime::new(compiled, GameState::new(0)))
  ignore(director.step())
  ignore(director.step())
  assert_eq(director.choose("right"), Said("guide", "R"))
  assert_eq(director.dialog(), Some({ speaker: "guide", text: "R" }))
}

///|
test "director save json resumes runtime position" {
  let script : Script[Int] = script(builder => {
    builder.label("start")
    builder.say("n", "a")
    builder.say("n", "b")
  })

  let director = Director::new(Runtime::new(script, GameState::new(0)))
  assert_eq(director.step(), Said("n", "a"))
  let saved = director.save_json()

  let restored : Director[Int] = director_from_save_json(script, saved)
  assert_eq(restored.step(), Said("n", "b"))
}
