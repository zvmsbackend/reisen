///|
pub struct PixiFigure(String) derive(Show, Eq, ToJson, FromJson)

///|
pub struct Live2dFigure(String) derive(Show, Eq, ToJson, FromJson)

///|
pub struct DomFigure(String) derive(Show, Eq, ToJson, FromJson)

///|
pub fn DomFigure::new(id : String) -> DomFigure {
  id.trim_start(chars="#").to_string()
}

///|
pub struct Background {
  id : String
  url : String
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct Music(String) derive(Show, Eq, ToJson, FromJson)

///|
pub struct Sfx(String) derive(Show, Eq, ToJson, FromJson)

///|
pub fn dom_figure(id : String) -> DomFigure {
  DomFigure::new(id)
}
