///|
test "runtime step and choose" {
  let script : Script[Int] = script_from_instructions([
    Choice([
      { id: "left", text: DialogText::String("Go left"), jump: "left" },
      { id: "right", text: DialogText::String("Go right"), jump: "right" },
    ]),
    Label("left"),
    Say(
      speaker=DialogText::String("narrator"),
      text=DialogText::String("left"),
      typewriter=true,
      append=false,
      voice=None,
      proceed_on_done=false,
    ),
    Label("right"),
    Say(
      speaker=DialogText::String("narrator"),
      text=DialogText::String("right"),
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
      speaker=DialogText::String("narrator"),
      text=DialogText::String("right"),
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
      speaker=DialogText::String("narrator"),
      text=DialogText::String("done"),
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
      speaker=DialogText::String("narrator"),
      text=DialogText::String("done"),
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
      speaker=DialogText::String("n"),
      text=DialogText::String("left"),
      typewriter=true,
      append=false,
      voice=None,
      proceed_on_done=false,
    ),
    Label("right"),
    Say(
      speaker=DialogText::String("n"),
      text=DialogText::String("right"),
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
    Said(
      speaker=DialogText::String("n"),
      text=DialogText::String("left"),
      typewriter=true,
      append=false,
      voice=None,
    ),
  )
}

///|
test "runtime records flow trace" {
  let script : Script[Int] = script_from_instructions([
    JumpIf("target", _ => true),
    Say(
      speaker=DialogText::String("n"),
      text=DialogText::String("skip"),
      typewriter=true,
      append=false,
      voice=None,
      proceed_on_done=false,
    ),
    Label("target"),
    Say(
      speaker=DialogText::String("n"),
      text=DialogText::String("ok"),
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
      speaker=DialogText::String("n"),
      text=DialogText::String("left"),
      typewriter=true,
      append=false,
      voice=None,
      proceed_on_done=false,
    ),
    Label("right"),
    Say(
      speaker=DialogText::String("n"),
      text=DialogText::String("right"),
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
    Said(
      speaker=DialogText::String("n"),
      text=DialogText::String("left"),
      typewriter=true,
      append=false,
      voice=None,
    ),
  )
}

///|
test "runtime from_save rejects negative ip" {
  let script : Script[Int] = script_from_instructions([
    Say(
      speaker=DialogText::String("n"),
      text=DialogText::String("hi"),
      typewriter=true,
      append=false,
      voice=None,
      proceed_on_done=false,
    ),
  ])
  let runtime = Runtime::new(script, GameState::new(0))
  let save = runtime.save()
  let bad_save = { ..save, ip: -1 }
  let result : Result[Runtime[Int], ScriptRuntimeError] = try? Runtime::from_save(
    script, bad_save,
  )
  assert_true(
    result is Err(ScriptRuntimeError::InvalidInstructionPointer(ip=-1)),
  )
}

///|
test "runtime from_save rejects ip equal to instruction count" {
  let script : Script[Int] = script_from_instructions([
    Say(
      speaker=DialogText::String("n"),
      text=DialogText::String("hi"),
      typewriter=true,
      append=false,
      voice=None,
      proceed_on_done=false,
    ),
  ])
  let runtime = Runtime::new(script, GameState::new(0))
  let save = runtime.save()
  // script has 1 instruction (index 0); ip=1 is one past the end
  let bad_save = { ..save, ip: 1 }
  let result : Result[Runtime[Int], ScriptRuntimeError] = try? Runtime::from_save(
    script, bad_save,
  )
  assert_true(
    result is Err(ScriptRuntimeError::InvalidInstructionPointer(ip=1)),
  )
}

///|
test "runtime from_json_string rejects corrupt json" {
  let script : Script[Int] = script_from_instructions([Wait(50)])
  let result : Result[Runtime[Int], Error] = try? Runtime::from_json_string(
    script, "{not valid json",
  )
  assert_true(result is Err(_))
}

///|
test "runtime from_json_string rejects out-of-range ip in json" {
  let script : Script[Int] = script_from_instructions([Wait(50)])
  let bad_json = "{\"ip\":999,\"state\":{\"int_vars\":{},\"text_vars\":{},\"flags\":{},\"payload\":0},\"pending_choices\":[],\"pending_choice_ip\":null,\"pending_text_input\":null,\"wait_ms\":0,\"wait_for_click\":false,\"wait_for_click_can_skip\":true,\"wait_custom_name\":null,\"wait_video\":false,\"last_say_proceed_on_done\":false,\"ended\":false,\"flow_trace\":[]}"
  let result : Result[Runtime[Int], Error] = try? Runtime::from_json_string(
    script, bad_json,
  )
  assert_true(result is Err(_))
}

///|
test "runtime choose raises when no choice is active" {
  let script : Script[Int] = script_from_instructions([
    Say(
      speaker=DialogText::String("n"),
      text=DialogText::String("hi"),
      typewriter=true,
      append=false,
      voice=None,
      proceed_on_done=false,
    ),
  ])
  let runtime = Runtime::new(script, GameState::new(0))
  let result : Result[RuntimeEvent, ScriptRuntimeError] = try? runtime.choose(
    "any",
  )
  assert_true(result is Err(ScriptRuntimeError::ChoiceNotActive))
}

///|
test "runtime choose raises on unknown choice id" {
  let script : Script[Int] = script_from_instructions([
    Choice([{ id: "yes", text: DialogText::String("Yes"), jump: "end" }]),
    Label("end"),
    Say(
      speaker=DialogText::String("n"),
      text=DialogText::String("done"),
      typewriter=true,
      append=false,
      voice=None,
      proceed_on_done=false,
    ),
  ])
  let runtime = Runtime::new(script, GameState::new(0))
  assert_true(runtime.step() is ChoicePrompt(_))
  let result : Result[RuntimeEvent, ScriptRuntimeError] = try? runtime.choose(
    "no",
  )
  assert_true(result is Err(ScriptRuntimeError::ChoiceNotFound(id="no")))
}

///|
test "runtime submit_text_input raises when not waiting" {
  let script : Script[Int] = script_from_instructions([Wait(100)])
  let runtime = Runtime::new(script, GameState::new(0))
  ignore(runtime.step())
  let result : Result[RuntimeEvent, ScriptRuntimeError] = try? runtime.submit_text_input(
    "hello",
  )
  assert_true(result is Err(ScriptRuntimeError::ChoiceNotActive))
}

///|
test "runtime jump_to_label raises on missing label" {
  let script : Script[Int] = script_from_instructions([Wait(50)])
  let runtime = Runtime::new(script, GameState::new(0))
  let result : Result[Unit, ScriptRuntimeError] = try? runtime.jump_to_label(
    "nonexistent",
  )
  assert_true(
    result is Err(ScriptRuntimeError::LabelNotFound(label="nonexistent")),
  )
}
