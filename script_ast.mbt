///|
/// Script AST and compiled metadata for the visual novel runtime.

///|
pub(all) enum Position {
  Left
  Center
  Right
  Custom(Double, Double)
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) enum Easing {
  Linear
  EaseIn
  EaseOut
  EaseInOut
} derive(Show, Eq, ToJson, FromJson)

///|
pub enum AnimProp {
  Opacity
  Position
  Scale
  Rotation
  Blur
  Brightness
  Contrast
  Saturation
  Gamma
  ColorRed
  ColorGreen
  ColorBlue
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct AnimationSpec {
  prop : AnimProp
  duration_ms : Int
  easing : Easing
  from : Array[Double]?
  to : Array[Double]?
  anchor : Array[Double]?
  blocking : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
pub(all) struct ScalarState {
  opacity : Double
  scale : Double
  rotation : Double
  blur : Double
  brightness : Double
  contrast : Double
  saturation : Double
  gamma : Double
  color_r : Double
  color_g : Double
  color_b : Double
} derive(Show, Eq, ToJson, FromJson)

///|
pub impl Default for ScalarState with default() {
  {
    opacity: 1.0,
    scale: 1.0,
    rotation: 0.0,
    blur: 0.0,
    brightness: 1.0,
    contrast: 1.0,
    saturation: 1.0,
    gamma: 1.0,
    color_r: 1.0,
    color_g: 1.0,
    color_b: 1.0,
  }
}

///|
pub(all) enum EffectPhase {
  Pre
  Post
} derive(Show, Eq, ToJson, FromJson)

///|
pub type EffectParam = (String, Double)

///|
pub struct EffectSpec {
  id : String
  params : Array[EffectParam]
  phase : EffectPhase
  duration_ms : Int?
  easing : Easing
  blocking : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct FigurePlacement {
  pos : Position
  layer : Int
  scalars : ScalarState
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct DomFigureState {
  placement : FigurePlacement
  interactive : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct BackgroundState {
  id : String
  scalars : ScalarState
} derive(Show, Eq, ToJson, FromJson)

///|
struct ChoiceOption {
  id : String
  text : String
  jump : String
} derive(Show, Eq, ToJson, FromJson)

///|
/// User-defined MoonBit code hook executed by the script runtime.
pub type ScriptHook[T] = (GameState[T]) -> Unit

///|
/// User-defined MoonBit predicate for branching.
pub type ScriptPredicate[T] = (GameState[T]) -> Bool

///|
/// User-defined payload predicate for custom-event waits.
pub type PayloadPredicate[T] = (GameState[T], String) -> Bool

///|
/// User-defined selector for custom-event waits that jump.
pub type PayloadJumpSelector[T] = (GameState[T], String) -> Label

///|
pub enum Instruction[T] {
  Label(String)
  Jump(String)
  JumpIf(String, ScriptPredicate[T])
  Wait(Int)
  WaitForClick(Bool)
  WaitCustomEvent(String, PayloadPredicate[T])
  WaitCustomEventJump(String, PayloadJumpSelector[T])
  Say(
    speaker~ : String,
    text~ : String,
    typewriter~ : Bool,
    append~ : Bool,
    voice~ : String?,
    proceed_on_done~ : Bool
  )
  Intro(String)
  ShowTextBox
  HideTextBox
  ShowAvatar(String)
  HideAvatar
  PlayVideo(String, Bool)
  Choice(Array[ChoiceOption])
  InputText(String, String)
  RunCode(ScriptHook[T])
  ShowBackground(String)
  ShowBackgroundState(BackgroundState)
  ShowFigure(String, FigurePlacement)
  HideFigure(String)
  ShowDomFigure(String, FigurePlacement, Bool)
  HideDomFigure(String)
  SetDomFigureInteractive(String, Bool)
  PlayMusic(String, Bool)
  StopMusic
  PlaySfx(String, Bool)
  UnlockCg(String)
  AnimatePixi(String, AnimationSpec)
  AnimateDom(String, AnimationSpec)
  ApplyEffect(String, EffectSpec)
  PlayLive2dMotion(String, String, Int?)
  SetLive2dExpression(String, String?)
}

///|
pub struct Script[T] {
  instructions : Array[Instruction[T]]
  labels : Map[String, Int]
}

///|
pub(all) suberror ScriptBuildError {
  DuplicateLabel(name~ : String)
  MissingJumpTarget(target~ : String)
  MissingChoiceTarget(choice_id~ : String, target~ : String)
  EffectUnsupportedOnDomTarget(target~ : String)
  SetInteractiveUnsupportedOnPixiTarget(target~ : String)
}

///|
fn[T] build_label_index(
  instructions : Array[Instruction[T]],
) -> Map[String, Int] raise ScriptBuildError {
  let labels : Map[String, Int] = Map::new()
  for i, inst in instructions {
    match inst {
      Label(name) => {
        if labels.contains(name) {
          raise ScriptBuildError::DuplicateLabel(name~)
        }
        labels.set(name, i)
      }
      _ => ()
    }
  }
  labels
}

///|
fn[T] validate_label_targets(
  instructions : Array[Instruction[T]],
  labels : Map[String, Int],
) -> Unit raise ScriptBuildError {
  for inst in instructions {
    match inst {
      Jump(target) | JumpIf(target, _) =>
        if !labels.contains(target) {
          raise ScriptBuildError::MissingJumpTarget(target~)
        }
      Choice(options) =>
        for option in options {
          if !labels.contains(option.jump) {
            raise ScriptBuildError::MissingChoiceTarget(
              choice_id=option.id,
              target=option.jump,
            )
          }
        }
      _ => ()
    }
  }
}

///|
pub fn[T] script_from_instructions(
  instructions : Array[Instruction[T]],
) -> Script[T] raise ScriptBuildError {
  let labels = build_label_index(instructions)
  validate_label_targets(instructions, labels)
  { instructions, labels }
}
