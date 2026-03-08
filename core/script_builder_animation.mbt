///|
pub fn option(
  text : String,
  jump : Label,
  id? : String = gensym(prefix="choice"),
) -> ChoiceOption {
  { id, text: DialogText::new(text), jump: jump.0 }
}

///|
pub fn place_left(
  layer? : Int = 0,
  scalars? : ScalarState = ScalarState::default(),
) -> FigurePlacement {
  { pos: Left, layer, scalars }
}

///|
pub fn place_center(
  layer? : Int = 0,
  scalars? : ScalarState = ScalarState::default(),
) -> FigurePlacement {
  { pos: Center, layer, scalars }
}

///|
pub fn place_right(
  layer? : Int = 0,
  scalars? : ScalarState = ScalarState::default(),
) -> FigurePlacement {
  { pos: Right, layer, scalars }
}

///|
pub fn place_custom(
  x : Double,
  y : Double,
  layer? : Int = 0,
  scalars? : ScalarState = ScalarState::default(),
) -> FigurePlacement {
  { pos: Custom(x, y), layer, scalars }
}

///|
fn position_to_anim_coords(pos : Position) -> (Double, Double) {
  match pos {
    Left => (PIXI_SLOT_LEFT_X, PIXI_SLOT_Y_RATIO)
    Center => (PIXI_SLOT_CENTER_X, PIXI_SLOT_Y_RATIO)
    Right => (PIXI_SLOT_RIGHT_X, PIXI_SLOT_Y_RATIO)
    Custom(x, y) =>
      (x + PIXI_CUSTOM_ANIM_COORD_BIAS, y + PIXI_CUSTOM_ANIM_COORD_BIAS)
  }
}

///|
fn position_to_dom_anim_coords(pos : Position) -> (Double, Double) {
  match pos {
    Left => (DOM_POS_LEFT_X, DOM_POS_MID_Y)
    Center => (DOM_POS_CENTER_X, DOM_POS_MID_Y)
    Right => (DOM_POS_RIGHT_X, DOM_POS_MID_Y)
    Custom(x, y) => (x, y)
  }
}

///|
pub fn anim_opacity(
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: Opacity,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_position(
  duration_ms : Int,
  from? : Position,
  to : Position,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  let to_coords = position_to_anim_coords(to)
  {
    prop: Position,
    duration_ms,
    easing,
    from: from.map(pos => {
      let (x, y) = position_to_anim_coords(pos)
      [x, y]
    }),
    to: Some([to_coords.0, to_coords.1]),
    anchor: None,
    blocking,
  }
}

///|
fn anim_position_dom(
  duration_ms : Int,
  from? : Position,
  to : Position,
  easing : Easing,
  blocking : Bool,
) -> AnimationSpec {
  let to_coords = position_to_dom_anim_coords(to)
  {
    prop: Position,
    duration_ms,
    easing,
    from: from.map(pos => {
      let (x, y) = position_to_dom_anim_coords(pos)
      [x, y]
    }),
    to: Some([to_coords.0, to_coords.1]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_scale(
  duration_ms : Int,
  from? : Double,
  to : Double,
  anchor? : (Double, Double) = (0.5, 0.5),
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: Scale,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: Some([anchor.0, anchor.1]),
    blocking,
  }
}

///|
pub fn anim_rotation(
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: Rotation,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_blur(
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: Blur,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_brightness(
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: Brightness,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_contrast(
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: Contrast,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_saturation(
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: Saturation,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_gamma(
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: Gamma,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_color_red(
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: ColorRed,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_color_green(
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: ColorGreen,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}

///|
pub fn anim_color_blue(
  duration_ms : Int,
  from? : Double,
  to : Double,
  easing? : Easing = Linear,
  blocking? : Bool = false,
) -> AnimationSpec {
  {
    prop: ColorBlue,
    duration_ms,
    easing,
    from: from.map(n => [n]),
    to: Some([to]),
    anchor: None,
    blocking,
  }
}
