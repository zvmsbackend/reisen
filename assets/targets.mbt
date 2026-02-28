///|
pub enum RenderableKind {
  Pixi
  Dom
}

///|
pub trait AnimationTarget {
  id(Self) -> String
  kind(Self) -> RenderableKind
}

///|
#warnings("-unused_value")
pub trait PixiTarget: AnimationTarget {
  dummy(Self) -> Unit = _
}

///|
#warnings("-unused_value")
pub trait Figure: AnimationTarget {
  dummy(Self) -> Unit = _
}

///|
impl PixiTarget with dummy(_) {

}

///|
impl Figure with dummy(_) {

}

///|
pub impl AnimationTarget for PixiFigure with id(self) {
  self.id()
}

///|
pub impl AnimationTarget for PixiFigure with kind(_) {
  Pixi
}

///|
pub impl PixiTarget for PixiFigure

///|
pub impl Figure for PixiFigure

///|
pub impl AnimationTarget for Live2dFigure with id(self) {
  self.id()
}

///|
pub impl AnimationTarget for Live2dFigure with kind(_) {
  Pixi
}

///|
pub impl PixiTarget for Live2dFigure

///|
pub impl Figure for Live2dFigure

///|
pub impl AnimationTarget for DomFigure with id(self) {
  self.id()
}

///|
pub impl AnimationTarget for DomFigure with kind(_) {
  Dom
}

///|
pub impl Figure for DomFigure

///|
pub impl AnimationTarget for Background with id(self) {
  self.id
}

///|
pub impl AnimationTarget for Background with kind(_) {
  Pixi
}

///|
pub impl PixiTarget for Background
