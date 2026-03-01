///|
using @core {type Script}

///|
test "parse sexp basic label jump" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(label start) (jump end) (label end)",
  )
  assert_true(script.labels.contains("start"))
  assert_true(script.labels.contains("end"))
  assert_eq(script.instructions.length(), 3)
}

///|
test "parse sexp say and scene" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(scene bg_temple) (say Speaker \"Hello world\")",
  )
  assert_eq(script.instructions.length(), 2)
  assert_true(script.instructions[0] is ShowBackground("bg_temple"))
  assert_true(
    script.instructions[1]
    is Say(
      speaker="Speaker",
      text="Hello world",
      typewriter=true,
      append=false,
      voice=None,
      ..
    ),
  )
}

///|
test "parse sexp wait and wait-click" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(wait 120) (wait-click #f)",
  )
  assert_eq(script.instructions.length(), 2)
  assert_true(script.instructions[0] is Wait(120))
  assert_true(script.instructions[1] is WaitForClick(false))
}

///|
test "parse sexp unlock cg" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(unlock-cg cg_ending_1)",
  )
  assert_eq(script.instructions.length(), 1)
  assert_true(script.instructions[0] is UnlockCg("cg_ending_1"))
}

///|
test "parse sexp choice and menu" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(menu guide \"Pick\" (\"A\" a :id a) (\"B\" b :id b)) (label a) (label b)",
  )
  assert_eq(script.instructions.length(), 4)
  assert_true(script.instructions[0] is Say(..))
  assert_true(script.instructions[1] is Choice(_))
}

///|
extern "js" fn js_truthy() -> @js.Value = "() => true"

///|
fn[T] host_int_var(
  state : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  match args {
    [var_name] if @js.Cast::into(var_name) is Some(var_name) =>
      @js.Value::cast_from(state.int_var(var_name))
    _ => @js.Value::cast_from(0)
  }
}

///|
fn[T] host_eq(
  _ : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  match args {
    [lhs, rhs] =>
      if @js.Cast::into(lhs) is Some(lhs) &&
        @js.Cast::into(rhs) is Some(rhs) &&
        Int::equal(lhs, rhs) {
        js_truthy()
      } else {
        @js.Cast::from(false)
      }
    _ => @js.Cast::from(false)
  }
}

///|
test "parse sexp jump-if with host functions" {
  let parser = SexpScriptParser::new()
  parser.register_function("int-var", host_int_var)
  parser.register_function("eq", host_eq)
  let script : Script[Unit] = reisen_parse_sexp_script_with_parser(
    "(jump-if good (eq (int-var \"answer\") 42)) (label good)", parser,
  )
  assert_eq(script.instructions.length(), 2)
  assert_true(script.instructions[0] is JumpIf(_, _))
}

///|
test "parse sexp wait-custom-event with payload symbol" {
  let parser = SexpScriptParser::new()
  parser.register_function("eq", host_eq)
  let script : Script[Unit] = reisen_parse_sexp_script_with_parser(
    "(wait-custom-event route (eq payload \"open\"))", parser,
  )
  assert_eq(script.instructions.length(), 1)
  assert_true(script.instructions[0] is WaitCustomEvent(_, _))
}

///|
test "parse sexp audio and video commands" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(play-music bgm_theme #t) (play-sfx door_close #t) (play-video intro.mp4 #f) (stop-music)",
  )
  assert_eq(script.instructions.length(), 4)
  assert_true(script.instructions[0] is PlayMusic("bgm_theme", true))
  assert_true(script.instructions[1] is PlaySfx("door_close", true))
  assert_true(script.instructions[2] is PlayVideo("intro.mp4", false))
  assert_true(script.instructions[3] is StopMusic)
}

///|
test "parse sexp live2d commands" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(play-live2d-motion hero tap 2) (set-live2d-expression hero smile) (set-live2d-expression hero)",
  )
  assert_eq(script.instructions.length(), 3)
  assert_true(
    script.instructions[0] is PlayLive2dMotion("hero", "tap", Some(2)),
  )
  assert_true(
    script.instructions[1] is SetLive2dExpression("hero", Some("smile")),
  )
  assert_true(script.instructions[2] is SetLive2dExpression("hero", None))
}

///|
test "parse sexp show and hide figure" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(show-figure miko (right)) (hide-figure miko)",
  )
  assert_eq(script.instructions.length(), 2)
  match script.instructions[0] {
    ShowFigure(id, placement) => {
      assert_eq(id, "miko")
      assert_eq(placement.pos, Right)
    }
    _ => fail("Expected ShowFigure")
  }
  assert_true(script.instructions[1] is HideFigure("miko"))
}

///|
test "parse sexp effect and animate" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(effect hero glow (intensity 0.6) (radius 8)) (animate hero opacity 400 0.2 0.8)",
  )
  assert_eq(script.instructions.length(), 2)
  match script.instructions[0] {
    ApplyEffect(target, spec) => {
      assert_eq(target, "hero")
      assert_eq(spec.id, "glow")
      assert_eq(spec.params, [("intensity", 0.6), ("radius", 8.0)])
    }
    _ => fail("Expected ApplyEffect")
  }
  match script.instructions[1] {
    AnimatePixi(target, spec) => {
      assert_eq(target, "hero")
      assert_eq(spec.prop, Opacity)
      assert_eq(spec.duration_ms, 400)
      assert_eq(spec.from, Some([0.2]))
      assert_eq(spec.to, Some([0.8]))
    }
    _ => fail("Expected AnimatePixi")
  }
}

///|
test "parse sexp run-code emits runtime hook" {
  let parser = SexpScriptParser::new()
  parser.register_function("int-var", host_int_var)
  let script : Script[Unit] = reisen_parse_sexp_script_with_parser(
    "(run-code (int-var answer))", parser,
  )
  assert_eq(script.instructions.length(), 1)
  assert_true(script.instructions[0] is RunCode(_))
}

///|
test "wait-custom-event-jump supports payload as reserved symbol" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(wait-custom-event-jump route payload) (label left) (label right)",
  )
  assert_eq(script.instructions.length(), 3)
  assert_true(script.instructions[0] is WaitCustomEventJump("route", _))
}

///|
test "builder load_sexp appends parsed instructions" {
  let builder : ScriptBuilder[Unit] = ScriptBuilder::new()
  builder.load_sexp("(label start) (say guide \"hello\")")
  let script = builder.build()
  assert_eq(script.instructions.length(), 2)
  assert_true(script.instructions[0] is Label("start"))
  assert_true(script.instructions[1] is Say(speaker="guide", text="hello", ..))
}
