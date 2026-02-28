///|
pub struct PixiFigure(String) derive(Show, Eq, ToJson, FromJson)

///|
pub fn PixiFigure::new(id : String) -> PixiFigure {
  id
}

///|
pub fn PixiFigure::id(self : PixiFigure) -> String {
  self.0
}

///|
pub struct Live2dFigure(String) derive(Show, Eq, ToJson, FromJson)

///|
pub fn Live2dFigure::new(id : String) -> Live2dFigure {
  id
}

///|
pub fn Live2dFigure::id(self : Live2dFigure) -> String {
  self.0
}

///|
pub struct DomFigure(String) derive(Show, Eq, ToJson, FromJson)

///|
pub fn DomFigure::new(id : String) -> DomFigure {
  id.trim_start(chars="#").to_string()
}

///|
pub fn DomFigure::id(self : DomFigure) -> String {
  self.0
}

///|
pub struct Background {
  id : String
  url : String
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn Background::new(id : String, url : String) -> Background {
  { id, url }
}

///|
pub struct Music(String) derive(Show, Eq, ToJson, FromJson)

///|
pub fn Music::new(id : String) -> Music {
  id
}

///|
pub fn Music::id(self : Music) -> String {
  self.0
}

///|
pub struct Sfx(String) derive(Show, Eq, ToJson, FromJson)

///|
pub fn Sfx::new(id : String) -> Sfx {
  id
}

///|
pub fn Sfx::id(self : Sfx) -> String {
  self.0
}

///|
pub fn dom_figure(id : String) -> DomFigure {
  DomFigure::new(id)
}
