///|
/// Director layer that maps `RuntimeEvent` to presentation-facing state.
/// WebGL renderers can read render state while HTML UI can read dialog/choices.

///|
struct DialogLine {
  speaker : String
  text : String
  typewriter : Bool
  append : Bool
  proceed_on_done : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
priv struct UiState {
  mut dialog : DialogLine?
  mut choices : Array[ChoiceOption]
  mut text_input : (String, String)?
  mut intro_text : String?
  mut video : (String, Bool)?
  mut text_box_visible : Bool
  mut avatar_id : String?
}

///|
pub struct RenderState {
  mut background : BackgroundState?
  figures : Map[String, FigurePlacement]
  dom_figures : Map[String, DomFigureState]
  mut music : (String, Bool)?
  mut last_sfx : String?
  mut last_sfx_interrupted : Bool
  webgl_animations : Array[(String, AnimationSpec)]
  dom_animations : Array[(String, AnimationSpec)]
  effects : Map[String, Array[EffectSpec]]
  live2d_motions : Array[(String, String, Int?)]
  live2d_expressions : Array[(String, String?)]
  render_epoch : String
} derive(ToJson, FromJson)

///|
pub struct DirectorSave[T] {
  runtime : RuntimeSave[T]
  render : RenderState
  dialog : DialogLine?
  intro_text : String?
  video : (String, Bool)?
  text_box_visible : Bool
  avatar_id : String?
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
    ui: {
      dialog: None,
      choices: [],
      text_input: None,
      intro_text: None,
      video: None,
      text_box_visible: true,
      avatar_id: None,
    },
    render: {
      background: None,
      figures: {},
      dom_figures: {},
      music: None,
      last_sfx: None,
      last_sfx_interrupted: false,
      webgl_animations: [],
      dom_animations: [],
      effects: {},
      live2d_motions: [],
      live2d_expressions: [],
      render_epoch: gensym(prefix="render"),
    },
    last_event_said: false,
  }
}

///|
fn[T] Director::apply_event(self : Director[T], event : RuntimeEvent) -> Unit {
  if event is Said(_) {
    self.last_event_said = true
  } else if !(event is Noop) {
    self.last_event_said = false
  }
  match event {
    Noop => ()
    Said(speaker~, text~, typewriter~, append~, voice~) => {
      let (resolved_speaker, resolved_text) = match self.ui.dialog {
        Some(prev) if append => (prev.speaker, prev.text + text)
        _ => (speaker, text)
      }
      self.ui.dialog = Some({
        speaker: resolved_speaker,
        text: resolved_text,
        typewriter,
        append,
        proceed_on_done: self.runtime.last_say_proceed_on_done(),
      })
      self.ui.intro_text = None
      self.ui.choices = []
      self.ui.text_input = None
      self.render.last_sfx = voice
      self.render.last_sfx_interrupted = false
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
      self.ui.video = None
      self.ui.dialog = None
      self.ui.choices = []
      self.ui.text_input = None
    }
    VideoStarted(url, can_skip) => {
      self.ui.video = Some((url, can_skip))
      self.ui.intro_text = None
      self.ui.dialog = None
      self.ui.choices = []
      self.ui.text_input = None
    }
    VideoEnded(_) => self.ui.video = None
    TextBoxShown => self.ui.text_box_visible = true
    TextBoxHidden => self.ui.text_box_visible = false
    AvatarShown(id) => self.ui.avatar_id = Some(id)
    AvatarHidden => self.ui.avatar_id = None
    BackgroundShown(id) =>
      self.render.background = Some({ id, scalars: ScalarState::default() })
    BackgroundShownState(state) => self.render.background = Some(state)
    FigureShown(id, placement) => self.render.figures.set(id, placement)
    FigureHidden(id) => self.render.figures.remove(id)
    DomFigureShown(id, placement, interactive) =>
      self.render.dom_figures.set(id, { placement, interactive })
    DomFigureHidden(id) => self.render.dom_figures.remove(id)
    DomFigureInteractiveSet(id, interactive) =>
      match self.render.dom_figures.get(id) {
        Some(state) =>
          self.render.dom_figures.set(id, {
            placement: state.placement,
            interactive,
          })
        None => ()
      }
    MusicPlayed(id, should_loop) => self.render.music = Some((id, should_loop))
    MusicStopped => self.render.music = None
    SfxPlayed(id, _) => {
      self.render.last_sfx = Some(id)
      self.render.last_sfx_interrupted = false
    }
    SfxStopped =>
      self.render.last_sfx_interrupted = self.render.last_sfx is Some(_)
    CgUnlocked(_) => ()
    AnimatedWebgl(target, spec) =>
      self.render.webgl_animations.push((target, spec))
    AnimatedDom(target, spec) => self.render.dom_animations.push((target, spec))
    EffectApplied(target, spec) => {
      let current = self.render.effects.get(target).unwrap_or([])
      let mut replaced = false
      let updated : Array[EffectSpec] = []
      for entry in current {
        if entry.id == spec.id {
          updated.push(spec)
          replaced = true
        } else {
          updated.push(entry)
        }
      }
      if !replaced {
        updated.push(spec)
      }
      self.render.effects.set(target, updated)
    }
    Live2dMotionPlayed(target, group, index) =>
      self.render.live2d_motions.push((target, group, index))
    Live2dExpressionSet(target, id) =>
      self.render.live2d_expressions.push((target, id))
    WaitStarted(_) => ()
    WaitForClickStarted => ()
    WaitCustomEventStarted(_) => ()
    Custom(_, _) => ()
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
pub fn[T] Director::jump_to_label(
  self : Director[T],
  label : String,
) -> Unit raise ScriptRuntimeError {
  self.runtime.jump_to_label(label)
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
pub fn[T] Director::video(self : Director[T]) -> (String, Bool)? {
  self.ui.video
}

///|
pub fn[T] Director::text_box_visible(self : Director[T]) -> Bool {
  self.ui.text_box_visible
}

///|
pub fn[T] Director::avatar_id(self : Director[T]) -> String? {
  self.ui.avatar_id
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
pub fn[T] Director::is_waiting_video(self : Director[T]) -> Bool {
  self.runtime.is_waiting_video()
}

///|
pub fn[T] Director::complete_video_wait(
  self : Director[T],
  skipped : Bool,
) -> RuntimeEvent {
  let event = self.runtime.complete_video_wait(skipped)
  self.apply_event(event)
  event
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
pub fn[T] Director::submit_custom_event(
  self : Director[T],
  name : String,
  payload : String,
) -> RuntimeEvent {
  let event = self.runtime.submit_custom_event(name, payload)
  self.apply_event(event)
  event
}

///|
pub fn[T] Director::background(self : Director[T]) -> String? {
  match self.render.background {
    Some(state) => Some(state.id)
    None => None
  }
}

///|
pub fn[T] Director::background_state(self : Director[T]) -> BackgroundState? {
  self.render.background
}

///|
pub fn[T] Director::set_background_state(
  self : Director[T],
  state : BackgroundState,
) -> Unit {
  self.render.background = Some(state)
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
pub fn[T] Director::dom_figures(
  self : Director[T],
) -> Map[String, DomFigureState] {
  self.render.dom_figures
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
pub fn[T] Director::take_interrupted_sfx(self : Director[T]) -> String? {
  if self.render.last_sfx_interrupted {
    self.render.last_sfx_interrupted = false
    self.render.last_sfx
  } else {
    None
  }
}

///|
pub fn[T] Director::animations(
  self : Director[T],
) -> Array[(String, AnimationSpec)] {
  self.render.webgl_animations
}

///|
pub fn[T] Director::dom_animations(
  self : Director[T],
) -> Array[(String, AnimationSpec)] {
  self.render.dom_animations
}

///|
pub fn[T] Director::effects(
  self : Director[T],
  id : String,
) -> Array[EffectSpec] {
  self.render.effects.get(id).unwrap_or([])
}

///|
pub fn[T] Director::live2d_motions(
  self : Director[T],
) -> Array[(String, String, Int?)] {
  self.render.live2d_motions
}

///|
pub fn[T] Director::live2d_expressions(
  self : Director[T],
) -> Array[(String, String?)] {
  self.render.live2d_expressions
}

///|
pub fn[T] Director::render_epoch(self : Director[T]) -> String {
  self.render.render_epoch
}

///|
pub fn[T] Director::clear_render(self : Director[T]) -> Unit {
  self.render.background = None
  self.render.figures.clear()
  self.render.dom_figures.clear()
  self.render.music = None
  self.render.last_sfx = None
  self.render.last_sfx_interrupted = false
  self.render.webgl_animations.clear()
  self.render.dom_animations.clear()
  self.render.effects.clear()
  self.render.live2d_motions.clear()
  self.render.live2d_expressions.clear()
}

///|
pub fn[T : ToJson] Director::save_json(self : Director[T]) -> String {
  let save : DirectorSave[T] = {
    runtime: self.runtime.save(),
    render: self.render,
    dialog: self.ui.dialog,
    intro_text: self.ui.intro_text,
    video: self.ui.video,
    text_box_visible: self.ui.text_box_visible,
    avatar_id: self.ui.avatar_id,
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
      video: save.video,
      text_box_visible: save.text_box_visible,
      avatar_id: save.avatar_id,
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
