///|
/// Director layer that maps `RuntimeEvent` to presentation-facing state.
/// WebGL renderers can read render state while HTML UI can read dialog/choices.

///|
pub struct DialogLine {
  speaker : String
  text : String
} derive(Show, Eq)

///|
priv struct UiState {
  mut dialog : DialogLine?
  mut choices : Array[ChoiceOption]
}

///|
priv struct RenderState {
  mut background : String?
  figures : Map[String, FigurePlacement]
  mut music : (String, Bool)?
  mut last_sfx : String?
  animations : Array[(String, AnimationSpec)]
}

///|
struct Director[T] {
  runtime : Runtime[T]
  ui : UiState
  render : RenderState
}

///|
pub fn[T] Director::new(runtime : Runtime[T]) -> Director[T] {
  {
    runtime,
    ui: { dialog: None, choices: [] },
    render: {
      background: None,
      figures: {},
      music: None,
      last_sfx: None,
      animations: [],
    },
  }
}

///|
fn[T] Director::apply_event(self : Director[T], event : RuntimeEvent) -> Unit {
  match event {
    Noop => ()
    Said(speaker, text) => {
      self.ui.dialog = Some({ speaker, text })
      self.ui.choices = []
    }
    ChoicePrompt(options) => self.ui.choices = options
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
  self.apply_event(event)
  event
}

///|
pub fn[T] Director::dialog(self : Director[T]) -> DialogLine? {
  self.ui.dialog
}

///|
pub fn[T] Director::choices(self : Director[T]) -> Array[ChoiceOption] {
  self.ui.choices
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
