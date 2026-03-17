///|
/// Serializable game state for branching/progression.
/// `user_data` carries game-specific state defined by the game author.

///|
pub struct GameState[T] {
  mut user_data : T
  flags : Map[String, Bool]
  ints : Map[String, Int]
  texts : Map[String, String]
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn[T] GameState::new(user_data : T) -> GameState[T] {
  { user_data, flags: Map::new(), ints: Map::new(), texts: Map::new() }
}

///|
pub fn[T] GameState::get_user_data(self : GameState[T]) -> T {
  self.user_data
}

///|
pub fn[T] GameState::set_user_data(self : GameState[T], user_data : T) -> Unit {
  self.user_data = user_data
}

///|
pub fn[T] GameState::flag(self : GameState[T], name : String) -> Bool {
  self.flags.get_or_default(name, false)
}

///|
pub fn[T] GameState::set_flag(
  self : GameState[T],
  name : String,
  value : Bool,
) -> Unit {
  self.flags.set(name, value)
}

///|
pub fn[T] GameState::int_var(
  self : GameState[T],
  name : String,
  default_value? : Int = 0,
) -> Int {
  self.ints.get_or_default(name, default_value)
}

///|
pub fn[T] GameState::set_int_var(
  self : GameState[T],
  name : String,
  value : Int,
) -> Unit {
  self.ints.set(name, value)
}

///|
pub fn[T] GameState::text_var(
  self : GameState[T],
  name : String,
  default_value? : String = "",
) -> String {
  self.texts.get_or_default(name, default_value)
}

///|
pub fn[T] GameState::set_text_var(
  self : GameState[T],
  name : String,
  value : String,
) -> Unit {
  self.texts.set(name, value)
}

///|
extern "js" fn escape_html(s : String) -> String =
  #| (s) => s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;')

///|
/// Interpolate text variables into a string.
/// Syntax: `{variable_name}` is replaced with the variable's value.
/// Undefined variables are left as-is.
pub fn[T] GameState::interpolate(
  self : GameState[T],
  text : DialogText,
) -> DialogText {
  match text {
    Interpolation(var_name) => {
      let value = match self.texts.get(var_name) {
        Some(text) => text
        None => @storage.persistent_get_text(var_name, default="{\{var_name}}")
      }
      String(value)
    }
    Concat(parts) => Concat(parts.map(part => self.interpolate(part)))
    Enhanced(base, style~) => Enhanced(self.interpolate(base), style~)
    _ => text
  }
}

///|
pub fn[T : ToJson] GameState::to_json_string(self : GameState[T]) -> String {
  self.to_json().stringify()
}

///|
pub fn[T : FromJson] game_state_from_json_string(
  s : String,
) -> GameState[T] raise {
  s |> @json.parse |> @json.from_json
}
