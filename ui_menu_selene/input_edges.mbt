///|
priv struct SeleneInputEdgeState {
  mut last_enter_down : Bool
  mut last_space_down : Bool
  mut last_up_down : Bool
  mut last_down_down : Bool
  mut last_left_down : Bool
  mut last_right_down : Bool
  mut last_escape_down : Bool
  mut last_mouse_left_down : Bool
  mut last_mouse_right_down : Bool
}

///|
fn SeleneInputEdgeState::new() -> SeleneInputEdgeState {
  {
    last_enter_down: false,
    last_space_down: false,
    last_up_down: false,
    last_down_down: false,
    last_left_down: false,
    last_right_down: false,
    last_escape_down: false,
    last_mouse_left_down: false,
    last_mouse_right_down: false,
  }
}

///|
fn SeleneInputEdgeState::take_up_edge(
  self : SeleneInputEdgeState,
  down : Bool,
) -> Bool {
  let edge = down && !self.last_up_down
  self.last_up_down = down
  edge
}

///|
fn SeleneInputEdgeState::take_down_edge(
  self : SeleneInputEdgeState,
  down : Bool,
) -> Bool {
  let edge = down && !self.last_down_down
  self.last_down_down = down
  edge
}

///|
fn SeleneInputEdgeState::take_left_edge(
  self : SeleneInputEdgeState,
  down : Bool,
) -> Bool {
  let edge = down && !self.last_left_down
  self.last_left_down = down
  edge
}

///|
fn SeleneInputEdgeState::take_right_edge(
  self : SeleneInputEdgeState,
  down : Bool,
) -> Bool {
  let edge = down && !self.last_right_down
  self.last_right_down = down
  edge
}

///|
fn SeleneInputEdgeState::take_mouse_left_edge(
  self : SeleneInputEdgeState,
  down : Bool,
) -> Bool {
  let edge = down && !self.last_mouse_left_down
  self.last_mouse_left_down = down
  edge
}

///|
fn SeleneInputEdgeState::take_mouse_right_edge(
  self : SeleneInputEdgeState,
  down : Bool,
) -> Bool {
  let edge = down && !self.last_mouse_right_down
  self.last_mouse_right_down = down
  edge
}
