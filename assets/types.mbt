///|
pub(all) struct PixiFigure(String) derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct Live2dFigure(String) derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct DomFigure(String) derive(Debug, Eq, ToJson, FromJson)

///|
pub fn DomFigure::new(id : String) -> DomFigure {
  id.trim_start(chars="#").to_string()
}

///|
pub(all) struct Background {
  id : String
  url : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct Music(String) derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct Sfx(String) derive(Debug, Eq, ToJson, FromJson)

///|
pub fn dom_figure(id : String) -> DomFigure {
  DomFigure::new(id)
}
