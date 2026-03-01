///|
test "runtime step and choose" {
  let script : Script[Int] = script_from_instructions([
    Choice([
      { id: "left", text: "Go left", jump: "left" },
      { id: "right", text: "Go right", jump: "right" },
    ]),
    Label("left"),
    Say(
      speaker="narrator",
      text="left",
      typewriter=true,
      append=false,
      voice=None,
      proceed_on_done=false,
    ),
    Label("right"),
    Say(
      speaker="narrator",
      text="right",
      typewriter=true,
      append=false,
      voice=None,
      proceed_on_done=false,
    ),
  ])

  let runtime = Runtime::new(script, GameState::new(0))
  assert_true(runtime.step() is ChoicePrompt(_))
  assert_eq(
    runtime.choose("right"),
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
  let runtime = Runtime::new(script, GameState::new(0))
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
test "runtime custom event jump resumes at selected label" {
  let script : Script[Int] = script_from_instructions([
    WaitCustomEventJump("route", (_, payload) => {
      if payload == "L" {
        "left"
      } else {
        "right"
      }
    }),
    Label("left"),
    Say(
      speaker="n",
      text="left",
      typewriter=true,
      append=false,
      voice=None,
      proceed_on_done=false,
    ),
    Label("right"),
    Say(
      speaker="n",
      text="right",
      typewriter=true,
      append=false,
      voice=None,
      proceed_on_done=false,
    ),
  ])
  let runtime = Runtime::new(script, GameState::new(0))

  assert_eq(runtime.step(), WaitCustomEventStarted("route"))
  assert_eq(runtime.submit_custom_event("route", "L"), Custom("route", "L"))
  assert_eq(
    runtime.step(),
    Said(speaker="n", text="left", typewriter=true, append=false, voice=None),
  )
}

///|
test "runtime records flow trace" {
  let script : Script[Int] = script_from_instructions([
    JumpIf("target", _ => true),
    Say(
      speaker="n",
      text="skip",
      typewriter=true,
      append=false,
      voice=None,
      proceed_on_done=false,
    ),
    Label("target"),
    Say(
      speaker="n",
      text="ok",
      typewriter=true,
      append=false,
      voice=None,
      proceed_on_done=false,
    ),
  ])
  let runtime = Runtime::new(script, GameState::new(0))
  ignore(runtime.step())
  assert_eq(runtime.flow_trace(), [
    ScriptFlowTrace::JumpIfResolved(ip=0, target="target", taken=true),
  ])
}

///|
test "runtime jump_by resolves selector label" {
  let script : Script[Int] = script_from_instructions([
    JumpBy(state => if state.int_var("route") == 1 { "left" } else { "right" }),
    Label("left"),
    Say(
      speaker="n",
      text="left",
      typewriter=true,
      append=false,
      voice=None,
      proceed_on_done=false,
    ),
    Label("right"),
    Say(
      speaker="n",
      text="right",
      typewriter=true,
      append=false,
      voice=None,
      proceed_on_done=false,
    ),
  ])
  let state = GameState::new(0)
  state.set_int_var("route", 1)
  let runtime = Runtime::new(script, state)
  assert_eq(
    runtime.step(),
    Said(speaker="n", text="left", typewriter=true, append=false, voice=None),
  )
}
