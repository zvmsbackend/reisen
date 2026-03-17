///|
pub fn[T] ScriptBuilder::label(self : ScriptBuilder[T], label : Label) -> Unit {
  self.instructions.push(Label(label.0))
}

///|
pub fn[T] ScriptBuilder::jump(self : ScriptBuilder[T], label : Label) -> Unit {
  self.instructions.push(Jump(label.0))
}

///|
pub fn[T] ScriptBuilder::jump_if(
  self : ScriptBuilder[T],
  label : Label,
  predicate : ScriptPredicate[T],
) -> Unit {
  self.instructions.push(JumpIf(label.0, predicate))
}

///|
pub fn[T] ScriptBuilder::jump_by(
  self : ScriptBuilder[T],
  selector : ScriptJumpSelector[T],
) -> Unit {
  self.instructions.push(JumpBy(selector))
}

///|
pub fn[T] ScriptBuilder::branch(
  self : ScriptBuilder[T],
  then_label : Label,
  else_label : Label,
  predicate : ScriptPredicate[T],
) -> Unit {
  self.instructions.push(JumpIf(then_label.0, predicate))
  self.instructions.push(Jump(else_label.0))
}

///|
pub fn[T] ScriptBuilder::wait(self : ScriptBuilder[T], ms : Int) -> Unit {
  self.instructions.push(Wait(ms))
}

///|
pub fn[T] ScriptBuilder::wait_click(
  self : ScriptBuilder[T],
  can_skip? : Bool = true,
) -> Unit {
  self.instructions.push(WaitForClick(can_skip))
}

///|
pub fn[T] ScriptBuilder::wait_custom_event(
  self : ScriptBuilder[T],
  name : String,
  predicate : PayloadPredicate[T],
) -> Unit {
  self.instructions.push(WaitCustomEvent(name, predicate))
}

///|
pub fn[T] ScriptBuilder::wait_custom_event_jump(
  self : ScriptBuilder[T],
  name : String,
  selector : PayloadJumpSelector[T],
) -> Unit {
  self.instructions.push(WaitCustomEventJump(name, selector))
}

///|
pub fn[T] ScriptBuilder::unlock_cg(
  self : ScriptBuilder[T],
  image : GalleryImage,
) -> Unit {
  self.instructions.push(UnlockCg(image.id))
}

///|
pub fn[T] ScriptBuilder::intro(self : ScriptBuilder[T], text : String) -> Unit {
  self.instructions.push(text |> DialogText::new |> Intro)
}

///|
pub fn[T] ScriptBuilder::narrate(
  self : ScriptBuilder[T],
  text : String,
  typewriter? : Bool = true,
  append? : Bool = false,
  voice? : String = "",
  proceed_on_done? : Bool = false,
) -> Unit {
  let voice_url = match voice {
    "" => None
    _ => Some(voice)
  }
  self.instructions.push(
    Say(
      speaker=DialogText::empty(),
      text=DialogText::new(text),
      typewriter~,
      append~,
      voice=voice_url,
      proceed_on_done~,
    ),
  )
}

///|
pub fn[T] ScriptBuilder::say(
  self : ScriptBuilder[T],
  speaker : String,
  text : String,
  typewriter? : Bool = true,
  append? : Bool = false,
  voice? : String = "",
  proceed_on_done? : Bool = false,
) -> Unit {
  let voice_url = match voice {
    "" => None
    _ => Some(voice)
  }
  self.instructions.push(
    Say(
      speaker=DialogText::new(speaker),
      text=DialogText::new(text),
      typewriter~,
      append~,
      voice=voice_url,
      proceed_on_done~,
    ),
  )
}

///|
pub fn[T] ScriptBuilder::say_many(
  self : ScriptBuilder[T],
  speaker : String,
  texts : Array[String],
  typewriter? : Bool = true,
  append? : Bool = false,
  voice? : String = "",
  proceed_on_done? : Bool = false,
) -> Unit {
  let voice_url = match voice {
    "" => None
    _ => Some(voice)
  }
  for text in texts {
    self.instructions.push(
      Say(
        speaker=DialogText::new(speaker),
        text=DialogText::new(text),
        typewriter~,
        append~,
        voice=voice_url,
        proceed_on_done~,
      ),
    )
  }
}

///|
pub fn[T] ScriptBuilder::apply(
  self : ScriptBuilder[T],
  f : (ScriptBuilder[T]) -> Unit,
) -> Unit {
  f(self)
}

///|
pub fn[T] ScriptBuilder::menu(
  self : ScriptBuilder[T],
  speaker : String,
  prompt : String,
  options : Array[ChoiceOption],
) -> Unit {
  self.instructions.push(
    Say(
      speaker=DialogText::new(speaker),
      text=DialogText::new(prompt),
      typewriter=true,
      append=false,
      voice=None,
      proceed_on_done=false,
    ),
  )
  self.instructions.push(Choice(options))
}

///|
pub fn[T] ScriptBuilder::choice(
  self : ScriptBuilder[T],
  options : Array[ChoiceOption],
) -> Unit {
  self.instructions.push(Choice(options))
}

///|
pub fn[T] ScriptBuilder::input_text(
  self : ScriptBuilder[T],
  variable_name : String,
  prompt : String,
) -> Unit {
  self.instructions.push(InputText(variable_name, DialogText::new(prompt)))
}

///|
pub fn[T] ScriptBuilder::run_code(
  self : ScriptBuilder[T],
  hook : ScriptHook[T],
) -> Unit {
  self.instructions.push(RunCode(hook))
}
