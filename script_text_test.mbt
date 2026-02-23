///|
test "parse empty string" {
  let script : Script[Unit] = reisen_parse_text_script("")
  assert_eq(script.labels.length(), 0)
  assert_eq(script.instructions.length(), 0)
}

///|
test "parse label" {
  let script : Script[Unit] = reisen_parse_text_script("label: start")
  assert_true(script.labels.contains("start"))
  assert_eq(script.instructions.length(), 1)
}

///|
test "parse scene" {
  let script : Script[Unit] = reisen_parse_text_script("scene: bg_temple")
  assert_eq(script.instructions.length(), 1)
}

///|
test "parse say" {
  let script : Script[Unit] = reisen_parse_text_script(
    "say: Speaker, Hello world",
  )
  assert_eq(script.instructions.length(), 1)
}

///|
test "parse say without typewriter" {
  let script : Script[Unit] = reisen_parse_text_script(
    "say: Speaker, Hello world, false",
  )
  assert_eq(script.instructions.length(), 1)
  assert_true(
    script.instructions[0] is Say("Speaker", "Hello world", false, false),
  )
}

///|
test "parse say append" {
  let script : Script[Unit] = reisen_parse_text_script(
    "say: Speaker, continues, append",
  )
  assert_eq(script.instructions.length(), 1)
  assert_true(script.instructions[0] is Say("Speaker", "continues", true, true))
}

///|
test "parse multiline say" {
  let script : Script[Unit] = reisen_parse_text_script(
    "say: Speaker, Line one\n| Line two\n| Line three",
  )
  assert_eq(script.instructions.length(), 1)
  assert_true(
    script.instructions[0]
    is Say("Speaker", "Line one\nLine two\nLine three", true, false),
  )
}

///|
test "parse intro multiline" {
  let script : Script[Unit] = reisen_parse_text_script(
    "intro: Welcome\n| to the void",
  )
  assert_eq(script.instructions.length(), 1)
  assert_true(script.instructions[0] is Intro("Welcome\nto the void"))
}

///|
test "parse textbox show hide" {
  let script : Script[Unit] = reisen_parse_text_script(
    "show_textbox\nhide_textbox\ntextbox: show\ntextbox: hide",
  )
  assert_eq(script.instructions.length(), 4)
  assert_true(script.instructions[0] is ShowTextBox)
  assert_true(script.instructions[1] is HideTextBox)
  assert_true(script.instructions[2] is ShowTextBox)
  assert_true(script.instructions[3] is HideTextBox)
}

///|
test "parse avatar show hide" {
  let script : Script[Unit] = reisen_parse_text_script(
    "avatar: hero\navatar: hide\nshow_avatar: ally\nhide_avatar",
  )
  assert_eq(script.instructions.length(), 4)
  assert_true(script.instructions[0] is ShowAvatar("hero"))
  assert_true(script.instructions[1] is HideAvatar)
  assert_true(script.instructions[2] is ShowAvatar("ally"))
  assert_true(script.instructions[3] is HideAvatar)
}

///|
test "parse narrate" {
  let script : Script[Unit] = reisen_parse_text_script(
    "narrate: This is narration",
  )
  assert_eq(script.instructions.length(), 1)
}

///|
test "parse jump" {
  let script : Script[Unit] = reisen_parse_text_script(
    "label: start\njump: end\nlabel: end",
  )
  assert_eq(script.instructions.length(), 3)
}

///|
test "parse show figure" {
  let script : Script[Unit] = reisen_parse_text_script("show: miko, center")
  assert_eq(script.instructions.length(), 1)
}

///|
test "parse hide figure" {
  let script : Script[Unit] = reisen_parse_text_script("hide: miko")
  assert_eq(script.instructions.length(), 1)
}

///|
test "parse music play" {
  let script : Script[Unit] = reisen_parse_text_script("music: bgm_temple")
  assert_eq(script.instructions.length(), 1)
}

///|
test "parse music stop" {
  let script : Script[Unit] = reisen_parse_text_script("music: stop")
  assert_eq(script.instructions.length(), 1)
}

///|
test "parse sfx" {
  let script : Script[Unit] = reisen_parse_text_script("sfx: door_close")
  assert_eq(script.instructions.length(), 1)
}

///|
test "parse comment" {
  let script : Script[Unit] = reisen_parse_text_script(
    "# this is a comment\nlabel: start",
  )
  assert_eq(script.instructions.length(), 1)
  assert_true(script.labels.contains("start"))
}

///|
test "parse multiline" {
  let script : Script[Unit] = reisen_parse_text_script(
    "label: start\nscene: bg\nsay: Speaker, Text",
  )
  assert_eq(script.instructions.length(), 3)
}

///|
test "parse stop_music" {
  let script : Script[Unit] = reisen_parse_text_script("stop_music")
  assert_eq(script.instructions.length(), 1)
}

///|
test "parse wait" {
  let script : Script[Unit] = reisen_parse_text_script("wait: 120")
  assert_eq(script.instructions.length(), 1)
  assert_true(script.instructions[0] is Wait(120))
}

///|
test "parse animate range" {
  let script : Script[Unit] = reisen_parse_text_script(
    "animate: hero, opacity, 400, 0.2, 0.8",
  )
  assert_eq(script.instructions.length(), 1)
  match script.instructions[0] {
    Animate(_, spec) => {
      inspect(spec.prop, content="Opacity")
      assert_eq(spec.duration_ms, 400)
      assert_eq(spec.from, Some([0.2]))
      assert_eq(spec.to, Some([0.8]))
    }
    _ => fail("Expected Animate instruction")
  }
}
