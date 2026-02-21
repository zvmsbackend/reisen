///|
/// Script AST and compiled metadata for the visual novel runtime.

///|
pub enum Position {
  Left
  Center
  Right
  Custom(Double, Double)
} derive(Show, Eq)

///|
pub(all) enum Easing {
  Linear
  EaseIn
  EaseOut
  EaseInOut
} derive(Show, Eq)

///|
pub enum AnimProp {
  Opacity
  Position
  Scale
} derive(Show, Eq)

///|
pub struct AnimationSpec {
  prop : AnimProp
  duration_ms : Int
  easing : Easing
} derive(Show, Eq)

///|
pub struct FigurePlacement {
  pos : Position
  layer : Int
  opacity : Double
} derive(Show, Eq)

///|
pub struct ChoiceOption {
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
pub enum Instruction[T] {
  Label(String)
  Jump(String)
  JumpIf(String, ScriptPredicate[T])
  Wait(Int)
  Say(String, String)
  Choice(Array[ChoiceOption])
  InputText(String, String)
  RunCode(String, ScriptHook[T])
  ShowBackground(String)
  ShowFigure(String, FigurePlacement)
  HideFigure(String)
  PlayMusic(String, Bool)
  StopMusic
  PlaySfx(String)
  Animate(String, AnimationSpec)
}

///|
pub struct Script[T] {
  instructions : Array[Instruction[T]]
  labels : Map[String, Int]
}

///|
pub(all) suberror ScriptBuildError {
  DuplicateLabel(name~ : String)
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
pub fn[T] script_from_instructions(
  instructions : Array[Instruction[T]],
) -> Script[T] raise ScriptBuildError {
  { instructions, labels: build_label_index(instructions) }
}
