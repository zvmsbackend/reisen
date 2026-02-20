///|
test "builder duplicate label raises" {
  let builder : ScriptBuilder[Int] = ScriptBuilder::new()
  builder.label("start")
  builder.label("start")

  let built : Result[Script[Int], ScriptBuildError] = try? builder.build()
  assert_true(built is Err(ScriptBuildError::DuplicateLabel(name="start")))
}

///|
test "option helper builds expected choice option" {
  let got = option("left", "Go left", "left_path")
  let expected : ChoiceOption = {
    id: "left",
    text: "Go left",
    jump: "left_path",
  }
  assert_eq(got, expected)
}

///|
test "placement helpers produce expected placement values" {
  assert_eq(place_left(), { pos: Left, layer: 0, opacity: 1.0 })
  assert_eq(place_center(layer=2), { pos: Center, layer: 2, opacity: 1.0 })
  assert_eq(place_right(opacity=0.6), { pos: Right, layer: 0, opacity: 0.6 })
  assert_eq(place_custom(0.25, 0.75, layer=3, opacity=0.5), {
    pos: Custom(0.25, 0.75),
    layer: 3,
    opacity: 0.5,
  })
}

///|
test "animation helpers produce expected animation specs" {
  assert_eq(anim_opacity(120), {
    prop: Opacity,
    duration_ms: 120,
    easing: Linear,
  })
  assert_eq(anim_position(240, easing=EaseInOut), {
    prop: Position,
    duration_ms: 240,
    easing: EaseInOut,
  })
  assert_eq(anim_scale(360, easing=EaseOut), {
    prop: Scale,
    duration_ms: 360,
    easing: EaseOut,
  })
}
