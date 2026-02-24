///|
fn dummy_bg(id : String) -> Background {
  { id, }
}

///|
fn dummy_figure(id : String) -> Figure {
  { id, }
}

///|
fn dummy_sfx(id : String) -> Sfx {
  { id, }
}

///|
fn dummy_music(id : String) -> Music {
  { id, }
}

fn dummy_galley_image(id : String) -> GalleryImage {
  { id, image_id: id, title: "", thumbnail_id: None, replay_label: None }
}

///|
test "builder duplicate label raises" {
  let builder : ScriptBuilder[Int] = ScriptBuilder::new()
  let start = label(name="start")
  builder.label(start)
  builder.label(start)

  let built : Result[Script[Int], ScriptBuildError] = try? builder.build()
  assert_true(built is Err(ScriptBuildError::DuplicateLabel(name="start")))
}

///|
test "option helper builds expected choice option" {
  let got = option("Go left", label(name="left_path"))
  assert_eq(got.text, "Go left")
  assert_eq(got.jump, "left_path")
}

///|
test "placement helpers produce expected placement values" {
  assert_eq(place_left(), {
    pos: Left,
    layer: 0,
    scalars: ScalarState::default(),
  })
  assert_eq(place_center(layer=2), {
    pos: Center,
    layer: 2,
    scalars: ScalarState::default(),
  })
  assert_eq(place_right(opacity=0.6), {
    pos: Right,
    layer: 0,
    scalars: { ..ScalarState::default(), opacity: 0.6 },
  })
  assert_eq(place_custom(0.25, 0.75, layer=3, opacity=0.5), {
    pos: Custom(0.25, 0.75),
    layer: 3,
    scalars: { ..ScalarState::default(), opacity: 0.5 },
  })
}

///|
test "animation helpers produce expected animation specs" {
  assert_eq(anim_opacity(120, None, 1.0), {
    prop: Opacity,
    duration_ms: 120,
    easing: Linear,
    from: None,
    to: Some([1.0]),
    anchor: None,
    blocking: false,
  })
  assert_eq(anim_position(240, None, (0.0, 0.0), easing=EaseInOut), {
    prop: Position,
    duration_ms: 240,
    easing: EaseInOut,
    from: None,
    to: Some([0.0, 0.0]),
    anchor: None,
    blocking: false,
  })
  assert_eq(anim_scale(360, None, 1.0, easing=EaseOut), {
    prop: Scale,
    duration_ms: 360,
    easing: EaseOut,
    from: None,
    to: Some([1.0]),
    anchor: Some([0.5, 0.5]),
    blocking: false,
  })
  assert_eq(anim_opacity(100, Some(0.1), 0.9), {
    prop: Opacity,
    duration_ms: 100,
    easing: Linear,
    from: Some([0.1]),
    to: Some([0.9]),
    anchor: None,
    blocking: false,
  })
  assert_eq(anim_position(200, Some((-0.1, 0.0)), (0.0, 0.0)), {
    prop: Position,
    duration_ms: 200,
    easing: Linear,
    from: Some([-0.1, 0.0]),
    to: Some([0.0, 0.0]),
    anchor: None,
    blocking: false,
  })
  assert_eq(anim_scale(150, Some(0.5), 1.0), {
    prop: Scale,
    duration_ms: 150,
    easing: Linear,
    from: Some([0.5]),
    to: Some([1.0]),
    anchor: Some([0.5, 0.5]),
    blocking: false,
  })
}

///|
test "branch helper emits jump_if and jump instructions" {
  let then = label(name="then")
  let else_ = label(name="else")
  let built : Script[Int] = script(builder => {
    builder.branch(then, else_, _ => true)
    builder.label(then)
    builder.label(else_)
  })

  assert_eq(built.instructions.length(), 4)
  assert_true(built.instructions[0] is JumpIf("then", _))
  assert_true(built.instructions[1] is Jump("else"))
}

///|
test "menu helper emits say then choice" {
  let built : Script[Int] = script(builder => {
    builder.label(label(name="start"))
    builder.menu("narrator", "Pick one", [
      option("A", label(name="label_a")),
      option("B", label(name="label_b")),
    ])
  })

  assert_true(
    built.instructions[1]
    is Say(
      speaker="narrator",
      text="Pick one",
      typewriter=true,
      append=false,
      voice=None
    ),
  )
  assert_true(built.instructions[2] is Choice(_))
}

///|
test "scene/figure and animation shorthand helpers emit expected instructions" {
  let built : Script[Int] = script(builder => {
    builder.scene(dummy_bg("bg_school"))
    builder.show_figure_at(dummy_figure("alice"), Left, layer=2, opacity=0.7)
    builder.animate_opacity(dummy_figure("alice"), 120, 1.0)
    builder.animate_position(
      dummy_figure("alice"),
      180,
      (0.0, 0.0),
      easing=EaseInOut,
    )
    builder.animate_scale(dummy_figure("alice"), 240, 1.0, easing=EaseOut)
    builder.narrate("done")
  })

  assert_true(built.instructions[0] is ShowBackground("bg_school"))
  match built.instructions[1] {
    ShowFigure("alice", placement) => {
      assert_eq(placement.pos, Left)
      assert_eq(placement.layer, 2)
      assert_eq(placement.scalars, { ..ScalarState::default(), opacity: 0.7 })
    }
    _ => fail("Expected ShowFigure for alice")
  }
  assert_true(
    built.instructions[2]
    is Animate("alice", { prop: Opacity, duration_ms: 120, easing: Linear, .. }),
  )
  assert_true(
    built.instructions[3]
    is Animate(
      "alice",
      { prop: Position, duration_ms: 180, easing: EaseInOut, .. }
    ),
  )
  assert_true(
    built.instructions[4]
    is Animate("alice", { prop: Scale, duration_ms: 240, easing: EaseOut, .. }),
  )
  assert_true(
    built.instructions[5]
    is Say(speaker="", text="done", typewriter=true, append=false, voice=None),
  )
}

///|
test "effect helper emits apply effect" {
  let built : Script[Int] = script(builder => {
    builder.effect(dummy_figure("alice"), effect("glow"), [
      effect_param("intensity", 0.6),
      effect_param("radius", 8.0),
    ])
  })

  assert_true(
    built.instructions[0]
    is ApplyEffect(
      "alice",
      {
        id: "glow",
        params: [("intensity", 0.6), ("radius", 8.0)],
        phase: Some(EffectPhase::Post),
        duration_ms: None,
        easing: Some(Linear),
        blocking: false,
      }
    ),
  )
}

///|
test "builder unlock cg emits instruction" {
  let built : Script[Int] = script(builder => builder.unlock_cg(dummy_galley_image("cg_secret")))
  assert_true(built.instructions[0] is UnlockCg("cg_secret"))
}
