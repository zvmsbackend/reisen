///|
fn dummy_bg(id : String) -> Background {
  { id, url: "" }
}

///|
fn dummy_figure(id : String) -> Figure {
  WebglFigure(id)
}

///|
fn dummy_dom_figure(id : String) -> Figure {
  dom_figure(id)
}

///|
fn dummy_sfx(id : String) -> Sfx {
  { id, }
}

///|
fn dummy_music(id : String) -> Music {
  { id, }
}

///|
fn dummy_galley_image(id : String) -> GalleryImage {
  {
    id,
    image_url: id,
    title: "",
    thumbnail_url: None,
    replay_label: None,
    replay_state_factory_key: None,
  }
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
test "builder missing jump target raises" {
  let builder : ScriptBuilder[Int] = ScriptBuilder::new()
  builder.jump(label(name="missing"))

  let built : Result[Script[Int], ScriptBuildError] = try? builder.build()
  assert_true(
    built is Err(ScriptBuildError::MissingJumpTarget(target="missing")),
  )
}

///|
test "builder missing choice target raises" {
  let builder : ScriptBuilder[Int] = ScriptBuilder::new()
  builder.choice([option("A", label(name="route_a"), id="a")])

  let built : Result[Script[Int], ScriptBuildError] = try? builder.build()
  assert_true(
    built
    is Err(
      ScriptBuildError::MissingChoiceTarget(choice_id="a", target="route_a")
    ),
  )
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
  assert_eq(place_right(scalars={ ..ScalarState::default(), opacity: 0.6 }), {
    pos: Right,
    layer: 0,
    scalars: { ..ScalarState::default(), opacity: 0.6 },
  })
  assert_eq(
    place_custom(0.25, 0.75, layer=3, scalars={
      ..ScalarState::default(),
      opacity: 0.5,
    }),
    {
      pos: Custom(0.25, 0.75),
      layer: 3,
      scalars: { ..ScalarState::default(), opacity: 0.5 },
    },
  )
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
  assert_eq(anim_position(240, None, Custom(0.0, 0.0), easing=EaseInOut), {
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
  assert_eq(anim_position(200, Some(Custom(-0.1, 0.0)), Custom(0.0, 0.0)), {
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
  let label_a = label(name="label_a")
  let label_b = label(name="label_b")
  let built : Script[Int] = script(builder => {
    builder.label(label(name="start"))
    builder.menu("narrator", "Pick one", [
      option("A", label_a),
      option("B", label_b),
    ])
    builder.label(label_a)
    builder.label(label_b)
  })

  assert_true(
    built.instructions[1]
    is Say(
      speaker="narrator",
      text="Pick one",
      typewriter=true,
      append=false,
      voice=None,
      ..
    ),
  )
  assert_true(built.instructions[2] is Choice(_))
}

///|
test "scene/figure and animation shorthand helpers emit expected instructions" {
  let built : Script[Int] = script(builder => {
    builder.scene(dummy_bg("bg_school"))
    builder.show_figure_at(dummy_figure("alice"), Left, layer=2, scalars={
      ..ScalarState::default(),
      opacity: 0.7,
    })
    builder.animate_opacity(dummy_figure("alice"), 120, 1.0)
    builder.animate_position(
      dummy_figure("alice"),
      180,
      Custom(0.0, 0.0),
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
    is AnimateWebgl(
      "alice",
      { prop: Opacity, duration_ms: 120, easing: Linear, .. }
    ),
  )
  assert_true(
    built.instructions[3]
    is AnimateWebgl(
      "alice",
      { prop: Position, duration_ms: 180, easing: EaseInOut, .. }
    ),
  )
  assert_true(
    built.instructions[4]
    is AnimateWebgl(
      "alice",
      { prop: Scale, duration_ms: 240, easing: EaseOut, .. }
    ),
  )
  assert_true(
    built.instructions[5]
    is Say(speaker="", text="done", typewriter=true, append=false, voice=None, ..),
  )
}

///|
test "dom figure helper strips leading hash" {
  assert_true(dummy_dom_figure("panel") is DomFigure("panel"))
  assert_true(dummy_dom_figure("#panel") is DomFigure("panel"))
  assert_true(dummy_dom_figure("##panel") is DomFigure("panel"))
}

///|
test "dom figure show/hide emit expected instructions" {
  let built : Script[Int] = script(builder => {
    builder.show_figure(dummy_dom_figure("#promo"), place_center(layer=2))
    builder.hide_figure(dummy_dom_figure("promo"))
  })
  assert_true(built.instructions[0] is ShowDomFigure("promo", _, false))
  assert_true(built.instructions[1] is HideDomFigure("promo"))
}

///|
test "dom figure show can be interactive" {
  let built : Script[Int] = script(builder => {
    builder.show_figure(
      dummy_dom_figure("promo"),
      place_center(),
      interactive=true,
    )
  })
  assert_true(built.instructions[0] is ShowDomFigure("promo", _, true))
}

///|
test "set_figure_interactive emits dom instruction" {
  let built : Script[Int] = script(builder => {
    builder.set_figure_interactive(dummy_dom_figure("promo"), true)
    builder.set_figure_interactive(dummy_dom_figure("promo"), false)
  })
  assert_true(built.instructions[0] is SetDomFigureInteractive("promo", true))
  assert_true(built.instructions[1] is SetDomFigureInteractive("promo", false))
}

///|
test "set_figure_interactive on webgl figure raises build error" {
  let builder : ScriptBuilder[Int] = ScriptBuilder::new()
  builder.set_figure_interactive(dummy_figure("alice"), true)
  let built : Result[Script[Int], ScriptBuildError] = try? builder.build()
  assert_true(
    built
    is Err(
      ScriptBuildError::SetInteractiveUnsupportedOnWebglTarget(target="alice")
    ),
  )
}

///|
test "dom figure animations emit dom animation instruction" {
  let built : Script[Int] = script(builder => {
    builder.animate_opacity(dummy_dom_figure("promo"), 120, 1.0)
  })
  assert_true(
    built.instructions[0]
    is AnimateDom(
      "promo",
      { prop: Opacity, duration_ms: 120, easing: Linear, .. }
    ),
  )
}

///|
test "effect on dom figure raises build error" {
  let builder : ScriptBuilder[Int] = ScriptBuilder::new()
  builder.effect_with(dummy_dom_figure("promo"), { id: "glow" }, [])
  let built : Result[Script[Int], ScriptBuildError] = try? builder.build()
  assert_true(
    built is Err(ScriptBuildError::EffectUnsupportedOnDomTarget(target="promo")),
  )
}

///|
test "effect helper emits apply effect" {
  let built : Script[Int] = script(builder => {
    builder.effect_with(dummy_figure("alice"), { id: "glow" }, [
      ("intensity", 0.6),
      ("radius", 8.0),
    ])
  })

  assert_true(
    built.instructions[0]
    is ApplyEffect(
      "alice",
      {
        id: "glow",
        params: [("intensity", 0.6), ("radius", 8.0)],
        phase: EffectPhase::Post,
        duration_ms: None,
        easing: Linear,
        blocking: false,
      }
    ),
  )
}

///|
test "builder unlock cg emits instruction" {
  let built : Script[Int] = script(builder => {
    builder.unlock_cg(dummy_galley_image("cg_secret"))
  })
  assert_true(built.instructions[0] is UnlockCg("cg_secret"))
}
