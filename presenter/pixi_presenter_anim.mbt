///|
priv struct ScalarAnim {
  start_ms : Int
  duration_ms : Int
  easing : Easing
  from : Double?
  to : Double?
}

///|
priv struct PositionAnim {
  start_ms : Int
  duration_ms : Int
  easing : Easing
  from_x : Double?
  from_y : Double?
  to_x : Double?
  to_y : Double?
}

///|
priv struct ScaleAnim {
  start_ms : Int
  duration_ms : Int
  easing : Easing
  from : Double?
  to : Double?
  anchor_x : Double
  anchor_y : Double
}

///|
priv struct ScalarAccumulator {
  mut opacity : Double
  mut rotation : Double
  mut blur : Double
  mut brightness : Double
  mut contrast : Double
  mut saturation : Double
  mut gamma : Double
  mut color_r : Double
  mut color_g : Double
  mut color_b : Double
}

///|
fn ScalarAccumulator::from_scalar_state(
  state : ScalarState,
) -> ScalarAccumulator {
  {
    opacity: state.opacity,
    rotation: state.rotation,
    blur: state.blur,
    brightness: state.brightness,
    contrast: state.contrast,
    saturation: state.saturation,
    gamma: state.gamma,
    color_r: state.color_r,
    color_g: state.color_g,
    color_b: state.color_b,
  }
}

///|
fn apply_scalar_animation(
  base_value : Double,
  now_ms : Int,
  anim : ScalarAnim,
) -> (Double, Bool) {
  let (p, done) = animation_progress(
    now_ms,
    anim.start_ms,
    anim.duration_ms,
    anim.easing,
  )
  match (anim.from, anim.to) {
    (None, None) =>
      if done {
        (base_value, true)
      } else {
        (base_value * p, false)
      }
    _ => {
      let from = anim.from.unwrap_or(base_value)
      let to = anim.to.unwrap_or(base_value)
      let value = if done { to } else { from + (to - from) * p }
      (value, done)
    }
  }
}

///|
fn anim_value(values : Array[Double]?, idx : Int) -> Double? {
  values.bind(arr => if idx < arr.length() { Some(arr[idx]) } else { None })
}

///|
fn anim_anchor(values : Array[Double]?) -> (Double, Double) {
  let x = anim_value(values, 0).unwrap_or(0.5)
  let y = anim_value(values, 1).unwrap_or(0.5)
  (x, y)
}

///|
fn apply_position_animation(
  x : Double,
  y : Double,
  offset_ratio : Double,
  viewport_h : Double,
  viewport_w : Double,
  rect_w : Double,
  rect_h : Double,
  now_ms : Int,
  anim : PositionAnim,
) -> (Double, Double, Bool) {
  let (p, done) = animation_progress(
    now_ms,
    anim.start_ms,
    anim.duration_ms,
    anim.easing,
  )
  match (anim.from_x, anim.from_y, anim.to_x, anim.to_y) {
    (None, None, None, None) => {
      let start_y = y + viewport_h * offset_ratio
      let animated_y = start_y + (y - start_y) * p
      if done {
        (x, y, true)
      } else {
        (x, animated_y, false)
      }
    }
    _ => {
      let custom_bias = 1000.0
      let custom_threshold = 900.0
      let (start_x, start_y) = match (anim.from_x, anim.from_y) {
        (Some(raw_x), Some(raw_y)) =>
          if raw_x >= custom_threshold && raw_y >= custom_threshold {
            custom_to_canvas_pos(
              raw_x - custom_bias,
              raw_y - custom_bias,
              viewport_w,
              viewport_h,
              rect_w,
              rect_h,
            )
          } else {
            (raw_x * viewport_w, raw_y * viewport_h)
          }
        _ =>
          (
            anim.from_x.map(v => v * viewport_w).unwrap_or(x),
            anim.from_y.map(v => v * viewport_h).unwrap_or(y),
          )
      }
      let (end_x, end_y) = match (anim.to_x, anim.to_y) {
        (Some(raw_x), Some(raw_y)) =>
          if raw_x >= custom_threshold && raw_y >= custom_threshold {
            custom_to_canvas_pos(
              raw_x - custom_bias,
              raw_y - custom_bias,
              viewport_w,
              viewport_h,
              rect_w,
              rect_h,
            )
          } else {
            (raw_x * viewport_w, raw_y * viewport_h)
          }
        _ =>
          (
            anim.to_x.map(v => v * viewport_w).unwrap_or(x),
            anim.to_y.map(v => v * viewport_h).unwrap_or(y),
          )
      }
      let animated_x = start_x + (end_x - start_x) * p
      let animated_y = start_y + (end_y - start_y) * p
      if done {
        (end_x, end_y, true)
      } else {
        (animated_x, animated_y, false)
      }
    }
  }
}

///|
fn apply_scale_animation(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  base_value : Double,
  entry_scale : Double,
  now_ms : Int,
  anim : ScaleAnim,
) -> (Double, Double, Double, Double, Bool) {
  let (p, done) = animation_progress(
    now_ms,
    anim.start_ms,
    anim.duration_ms,
    anim.easing,
  )
  let s = match (anim.from, anim.to) {
    (None, None) =>
      if done {
        1.0
      } else {
        entry_scale + (1.0 - entry_scale) * p
      }
    _ => {
      let from = anim.from.unwrap_or(base_value)
      let to = anim.to.unwrap_or(1.0)
      if done {
        to
      } else {
        from + (to - from) * p
      }
    }
  }
  let sw = w * s
  let sh = h * s
  let ax = x + w * anim.anchor_x
  let ay = y + h * anim.anchor_y
  let sx = ax - sw * anim.anchor_x
  let sy = ay - sh * anim.anchor_y
  (sx, sy, sw, sh, done)
}
