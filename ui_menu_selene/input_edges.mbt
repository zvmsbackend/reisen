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
fn SeleneInputEdgeState::take_enter_edge(
  self : SeleneInputEdgeState,
  down : Bool,
) -> Bool {
  let edge = down && !self.last_enter_down
  self.last_enter_down = down
  edge
}

///|
fn SeleneInputEdgeState::take_space_edge(
  self : SeleneInputEdgeState,
  down : Bool,
) -> Bool {
  let edge = down && !self.last_space_down
  self.last_space_down = down
  edge
}

///|
fn SeleneInputEdgeState::take_escape_edge(
  self : SeleneInputEdgeState,
  down : Bool,
) -> Bool {
  let edge = down && !self.last_escape_down
  self.last_escape_down = down
  edge
}

///|
fn SeleneInputEdgeState::take_confirm_edge(
  self : SeleneInputEdgeState,
  enter_down : Bool,
  space_down : Bool,
) -> Bool {
  let enter_edge = self.take_enter_edge(enter_down)
  let space_edge = self.take_space_edge(space_down)
  enter_edge || space_edge
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
