///|
/// Director layer that maps `RuntimeEvent` to presentation-facing state.
/// WebGL renderers can read render state while HTML UI can read dialog/choices.

///|
struct DialogLine {
  speaker : String
  text : String
  typewriter : Bool
  append : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
priv struct UiState {
  mut dialog : DialogLine?
  mut choices : Array[ChoiceOption]
  mut text_input : (String, String)?
  mut intro_text : String?
}

///|
pub struct RenderState {
  mut background : String?
  figures : Map[String, FigurePlacement]
  mut music : (String, Bool)?
  mut last_sfx : String?
  animations : Array[(String, AnimationSpec)]
} derive(ToJson, FromJson)

///|
pub struct DirectorSave[T] {
  runtime : RuntimeSave[T]
  render : RenderState
  dialog : DialogLine?
  intro_text : String?
} derive(ToJson, FromJson)

///|
struct Director[T] {
  runtime : Runtime[T]
  ui : UiState
  render : RenderState
  mut last_event_said : Bool
}

///|
pub fn[T] Director::new(runtime : Runtime[T]) -> Director[T] {
  {
    runtime,
    ui: { dialog: None, choices: [], text_input: None, intro_text: None },
    render: {
      background: None,
      figures: {},
      music: None,
      last_sfx: None,
      animations: [],
    },
    last_event_said: false,
  }
}

///|
fn[T] Director::apply_event(self : Director[T], event : RuntimeEvent) -> Unit {
  if event is Said(_, _, _, _) {
    self.last_event_said = true
  } else if !(event is Noop) {
    self.last_event_said = false
  }
  match event {
    Noop => ()
    Said(speaker, text, typewriter, append) => {
      let (resolved_speaker, resolved_text) = match self.ui.dialog {
        Some(prev) if append => (prev.speaker, prev.text + text)
        _ => (speaker, text)
      }
      self.ui.dialog = Some({
        speaker: resolved_speaker,
        text: resolved_text,
        typewriter,
        append,
      })
      self.ui.intro_text = None
      self.ui.choices = []
      self.ui.text_input = None
    }
    ChoicePrompt(options) => {
      self.ui.intro_text = None
      self.ui.choices = options
      self.ui.text_input = None
    }
    TextInputPrompt(var_name, prompt) => {
      self.ui.intro_text = None
      self.ui.text_input = Some((var_name, prompt))
      self.ui.choices = []
    }
    IntroShown(text) => {
      self.ui.intro_text = Some(text)
      self.ui.dialog = None
      self.ui.choices = []
      self.ui.text_input = None
    }
    BackgroundShown(id) => self.render.background = Some(id)
    FigureShown(id, placement) => self.render.figures.set(id, placement)
    FigureHidden(id) => self.render.figures.remove(id)
    MusicPlayed(id, should_loop) => self.render.music = Some((id, should_loop))
    MusicStopped => self.render.music = None
    SfxPlayed(id) => self.render.last_sfx = Some(id)
    Animated(target, spec) => self.render.animations.push((target, spec))
    WaitStarted(_) => ()
    ScriptEnded => ()
  }
}

///|
pub fn[T] Director::step(
  self : Director[T],
  elapsed_ms? : Int = 0,
) -> RuntimeEvent raise ScriptRuntimeError {
  let event = self.runtime.step(elapsed_ms~)
  self.apply_event(event)
  event
}

///|
pub fn[T] Director::choose(
  self : Director[T],
  id : String,
) -> RuntimeEvent raise ScriptRuntimeError {
  let event = self.runtime.choose(id)
  self.ui.choices = []
  self.apply_event(event)
  event
}

///|
pub fn[T] Director::dialog(self : Director[T]) -> DialogLine? {
  self.ui.dialog
}

///|
pub fn[T] Director::intro_text(self : Director[T]) -> String? {
  self.ui.intro_text
}

///|
pub fn[T] Director::clear_dialog(self : Director[T]) -> Unit {
  self.ui.dialog = None
}

///|
pub fn[T] Director::choices(self : Director[T]) -> Array[ChoiceOption] {
  self.ui.choices
}

///|
pub fn[T] Director::text_input(self : Director[T]) -> (String, String)? {
  self.ui.text_input
}

///|
pub fn[T] Director::is_waiting(self : Director[T]) -> Bool {
  self.runtime.is_waiting()
}

///|
pub fn[T] Director::skip_wait(self : Director[T]) -> Unit {
  self.runtime.skip_wait()
}

///|
pub fn[T] Director::submit_text_input(
  self : Director[T],
  value : String,
) -> RuntimeEvent raise ScriptRuntimeError {
  let event = self.runtime.submit_text_input(value)
  self.apply_event(event)
  event
}

///|
pub fn[T] Director::background(self : Director[T]) -> String? {
  self.render.background
}

///|
pub fn[T] Director::figure(self : Director[T], id : String) -> FigurePlacement? {
  self.render.figures.get(id)
}

///|
pub fn[T] Director::figures(self : Director[T]) -> Map[String, FigurePlacement] {
  self.render.figures
}

///|
pub fn[T] Director::music(self : Director[T]) -> (String, Bool)? {
  self.render.music
}

///|
pub fn[T] Director::last_sfx(self : Director[T]) -> String? {
  self.render.last_sfx
}

///|
pub fn[T] Director::animations(
  self : Director[T],
) -> Array[(String, AnimationSpec)] {
  self.render.animations
}

///|
pub fn[T : ToJson] Director::save_json(self : Director[T]) -> String {
  let save : DirectorSave[T] = {
    runtime: self.runtime.save(),
    render: {
      background: self.render.background,
      figures: self.render.figures,
      music: self.render.music,
      last_sfx: self.render.last_sfx,
      animations: self.render.animations,
    },
    dialog: self.ui.dialog,
    intro_text: self.ui.intro_text,
  }
  save.to_json().stringify()
}

///|
pub fn[T] Director::from_save(
  script : Script[T],
  save : DirectorSave[T],
) -> Director[T] raise ScriptRuntimeError {
  let runtime = Runtime::from_save(script, save.runtime)
  {
    runtime,
    ui: {
      dialog: save.dialog,
      choices: [],
      text_input: None,
      intro_text: save.intro_text,
    },
    render: save.render,
    last_event_said: true,
  }
}

///|
pub fn[T : FromJson] director_from_save_json(
  script : Script[T],
  save_json : String,
) -> Director[T] raise {
  let parsed = @json.parse(save_json)
  Director::from_save(script, @json.from_json(parsed)) catch {
    _ => {
      let runtime = Runtime::from_json_string(script, save_json)
      Director::new(runtime)
    }
  }
}
