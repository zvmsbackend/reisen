///|
pub struct PixiFigure(String) derive(Debug, Eq, ToJson, FromJson)

///|
pub struct Live2dFigure(String) derive(Debug, Eq, ToJson, FromJson)

///|
pub struct DomFigure(String) derive(Debug, Eq, ToJson, FromJson)

///|
pub fn DomFigure::new(id : String) -> DomFigure {
  id.trim_start(chars="#").to_string()
}

///|
pub struct Background {
  id : String
  url : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct Music(String) derive(Debug, Eq, ToJson, FromJson)

///|
pub struct Sfx(String) derive(Debug, Eq, ToJson, FromJson)

///|
pub fn dom_figure(id : String) -> DomFigure {
  DomFigure::new(id)
}
