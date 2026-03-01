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
extern "js" fn js_strict_eq(lhs : @js.Value, rhs : @js.Value) -> Bool =
  #| (lhs, rhs) => lhs === rhs

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
      if js_strict_eq(lhs, rhs) {
        js_truthy()
      } else {
        @js.Cast::from(false)
      }
    _ => @js.Cast::from(false)
  }
}

///|
fn[T] host_set_int(
  state : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  match args {
    [var_name, value] if @js.Cast::into(var_name) is Some(var_name) &&
      @js.Cast::into(value) is Some(value) => {
      state.set_int_var(var_name, value)
      @js.Cast::from(true)
    }
    _ => @js.Cast::from(false)
  }
}

///|
fn[T] host_true(_ : @state.GameState[T], _ : ArrayView[@js.Value]) -> @js.Value {
  @js.Cast::from(true)
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

///|
test "sexp jump-if executes host expression" {
  let parser = SexpScriptParser::new()
  parser.register_function("int-var", host_int_var)
  parser.register_function("eq", host_eq)
  let script : Script[Unit] = reisen_parse_sexp_script_with_parser(
    "(jump-if good (eq (int-var \"answer\") 42)) (say n \"bad\") (label good) (say n \"ok\")",
    parser,
  )
  let state = @state.GameState::new(())
  state.set_int_var("answer", 42)
  let runtime = Runtime::new(script, state)
  assert_true(runtime.step() is Said(speaker="n", text="ok", ..))
}

///|
test "sexp run-code executes host side effect" {
  let parser = SexpScriptParser::new()
  parser.register_function("set-int", host_set_int)
  let script : Script[Unit] = reisen_parse_sexp_script_with_parser(
    "(run-code (set-int \"score\" 7)) (say n \"done\")", parser,
  )
  let state = @state.GameState::new(())
  let runtime = Runtime::new(script, state)
  assert_true(runtime.step() is Said(speaker="n", text="done", ..))
  assert_eq(state.int_var("score"), 7)
}

///|
test "sexp custom-event predicate uses payload" {
  let parser = SexpScriptParser::new()
  parser.register_function("eq", host_eq)
  let script : Script[Unit] = reisen_parse_sexp_script_with_parser(
    "(wait-custom-event route (eq payload \"open\")) (say n \"opened\")", parser,
  )
  let runtime = Runtime::new(script, @state.GameState::new(()))
  assert_eq(runtime.step(), WaitCustomEventStarted("route"))
  assert_eq(
    runtime.submit_custom_event("route", "closed"),
    Custom("route", "closed"),
  )
  assert_eq(runtime.step(), Noop)
  assert_eq(
    runtime.submit_custom_event("route", "open"),
    Custom("route", "open"),
  )
  assert_true(runtime.step() is Said(speaker="n", text="opened", ..))
}

///|
test "sexp custom-event jump selector uses payload" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(wait-custom-event-jump route payload) (label left) (say n \"L\") (label right) (say n \"R\")",
  )
  let runtime = Runtime::new(script, @state.GameState::new(()))
  assert_eq(runtime.step(), WaitCustomEventStarted("route"))
  assert_eq(
    runtime.submit_custom_event("route", "right"),
    Custom("route", "right"),
  )
  assert_true(runtime.step() is Said(speaker="n", text="R", ..))
}

///|
test "sexp parse intro textbox avatar input and choice" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(intro \"prologue\") (show-text-box) (hide-text-box) (show-avatar \"hero.png\") (hide-avatar) (input-text \"name\" \"who?\") (choice (\"A\" a) (\"B\" b)) (label a) (label b)",
  )
  assert_eq(script.instructions.length(), 9)
  assert_true(script.instructions[0] is Intro("prologue"))
  assert_true(script.instructions[1] is ShowTextBox)
  assert_true(script.instructions[2] is HideTextBox)
  assert_true(script.instructions[3] is ShowAvatar("hero.png"))
  assert_true(script.instructions[4] is HideAvatar)
  assert_true(script.instructions[5] is InputText("name", "who?"))
  assert_true(script.instructions[6] is Choice(_))
}

///|
test "sexp parse say option flags" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(say guide \"line\" :typewriter #f :append #t :voice \"v1\")",
  )
  assert_eq(script.instructions.length(), 1)
  assert_true(
    script.instructions[0]
    is Say(
      speaker="guide",
      text="line",
      typewriter=false,
      append=true,
      voice=Some("v1"),
      ..
    ),
  )
}

///|
test "sexp parse position variants" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(show-figure a (left)) (show-figure b (center)) (show-figure c (custom 1.2 -0.5)) (show-figure d nope)",
  )
  assert_eq(script.instructions.length(), 4)
  assert_true(script.instructions[0] is ShowFigure(_, { pos: Left, .. }))
  assert_true(script.instructions[1] is ShowFigure(_, { pos: Center, .. }))
  assert_true(
    script.instructions[2] is ShowFigure(_, { pos: Custom(1.2, -0.5), .. }),
  )
  assert_true(script.instructions[3] is ShowFigure(_, { pos: Center, .. }))
}

///|
test "sexp parse malformed or unknown forms are ignored" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "42 (label) (jump) (unknown-cmd 1 2 3) (play-video) (effect) (menu)",
  )
  assert_eq(script.instructions.length(), 0)
}

///|
test "sexp parse many error returns empty builder output" {
  let script : Script[Unit] = reisen_parse_sexp_script("(label start")
  assert_eq(script.instructions.length(), 0)
  assert_eq(script.labels.length(), 0)
}

///|
test "sexp parse play-video single arg defaults can-skip false" {
  let script : Script[Unit] = reisen_parse_sexp_script("(play-video intro.mp4)")
  assert_eq(script.instructions.length(), 1)
  assert_true(script.instructions[0] is PlayVideo("intro.mp4", false))
}

///|
test "sexp parse malformed arities hit fallbacks" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(jump-if) (run-code) (wait-custom-event route) (wait-custom-event-jump route) (wait) (wait-click) (unlock-cg) (intro) (show-avatar) (say onlyspeaker) (scene) (show-figure x) (hide-figure) (play-live2d-motion hero) (play-live2d-motion hero tap) (play-live2d-motion hero tap 1 2) (set-live2d-expression) (play-music bgm) (play-music) (play-sfx door) (play-sfx) (effect hero glow garbage) (animate hero x 200 0 1) (animate hero) (input-text)",
  )
  assert_eq(script.instructions.length(), 6)
  assert_true(script.instructions[0] is WaitForClick(true))
  assert_true(script.instructions[1] is PlayLive2dMotion("hero", "tap", None))
  assert_true(script.instructions[2] is PlayMusic("bgm", false))
  assert_true(script.instructions[3] is PlaySfx("door", false))
  assert_true(script.instructions[4] is ApplyEffect("hero", _))
  assert_true(script.instructions[5] is AnimatePixi("hero", _))
}

///|
test "sexp parse position custom and unknown list defaults center" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(show-figure a (custom 1)) (show-figure b (mystery))",
  )
  assert_eq(script.instructions.length(), 2)
  assert_true(script.instructions[0] is ShowFigure(_, { pos: Center, .. }))
  assert_true(script.instructions[1] is ShowFigure(_, { pos: Center, .. }))
}

///|
test "sexp parse choice ignores non-list item" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(choice bad (\"A\" a)) (label a)",
  )
  assert_eq(script.instructions.length(), 2)
  assert_true(script.instructions[0] is Choice(_))
  assert_true(script.instructions[1] is Label("a"))
}

///|
test "sexp parse narrate command" {
  let script : Script[Unit] = reisen_parse_sexp_script("(narrate \"line\")")
  assert_eq(script.instructions.length(), 1)
  assert_true(
    script.instructions[0]
    is Say(speaker="", text="line", typewriter=true, append=false, ..),
  )
}

///|
test "sexp typed fallback conversion branches" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(label 1) (wait #t) (wait-click bad) (show-figure hero (custom x y)) (effect hero glow (strength bad))",
  )
  assert_eq(script.instructions.length(), 4)
  assert_true(script.instructions[0] is Wait(0))
  assert_true(script.instructions[1] is WaitForClick(true))
  assert_true(
    script.instructions[2] is ShowFigure(_, { pos: Custom(0.0, 0.0), .. }),
  )
  match script.instructions[3] {
    ApplyEffect(_, spec) => assert_eq(spec.params, [("strength", 0.0)])
    _ => fail("Expected ApplyEffect")
  }
}

///|
test "sexp runtime eval covers doubles chars and list fallbacks" {
  let parser = SexpScriptParser::new()
  parser.register_function("always", host_true)
  parser.register_function("set-int", host_set_int)
  let script : Script[Unit] = reisen_parse_sexp_script_with_parser(
    "(run-code (set-int score 7)) (run-code (unknown-fn 1)) (run-code ((1 2) 3)) (jump-if ok (always 1.5 #\\a)) (say n \"bad\") (label ok) (say n \"ok\")",
    parser,
  )
  let state = @state.GameState::new(())
  let runtime = Runtime::new(script, state)
  assert_true(runtime.step() is Said(speaker="n", text="ok", ..))
  assert_eq(state.int_var("score"), 7)
}

///|
test "sexp say unknown option key is ignored" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(say guide \"line\" :weird 1)",
  )
  assert_eq(script.instructions.length(), 1)
  assert_true(
    script.instructions[0]
    is Say(speaker="guide", text="line", typewriter=true, append=false, ..),
  )
}

///|
test "sexp builtins int-var and eq work without manual registration" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(jump-if good (eq (int-var \"answer\") 42)) (say n \"bad\") (label good) (say n \"ok\")",
  )
  let state = @state.GameState::new(())
  state.set_int_var("answer", 42)
  let runtime = Runtime::new(script, state)
  assert_true(runtime.step() is Said(speaker="n", text="ok", ..))
}

///|
test "sexp builtins set-int and add run in run-code" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(run-code (set-int \"score\" (add 3 4))) (say n \"done\")",
  )
  let state = @state.GameState::new(())
  let runtime = Runtime::new(script, state)
  assert_true(runtime.step() is Said(speaker="n", text="done", ..))
  assert_eq(state.int_var("score"), 7)
}

///|
test "sexp builtins use payload keyword directly in custom event" {
  let script : Script[Unit] = reisen_parse_sexp_script(
    "(wait-custom-event route (eq payload \"open\")) (say n \"opened\")",
  )
  let runtime = Runtime::new(script, @state.GameState::new(()))
  assert_eq(runtime.step(), WaitCustomEventStarted("route"))
  assert_eq(
    runtime.submit_custom_event("route", "closed"),
    Custom("route", "closed"),
  )
  assert_eq(runtime.step(), Noop)
  assert_eq(
    runtime.submit_custom_event("route", "open"),
    Custom("route", "open"),
  )
  assert_true(runtime.step() is Said(speaker="n", text="opened", ..))
}
