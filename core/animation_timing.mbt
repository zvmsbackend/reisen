///|
pub fn easing_apply(easing : Easing, x : Double) -> Double {
  let t = if x < 0.0 { 0.0 } else if x > 1.0 { 1.0 } else { x }
  match easing {
    Linear => t
    EaseIn => t * t
    EaseOut => 1.0 - (1.0 - t) * (1.0 - t)
    EaseInOut =>
      if t < 0.5 {
        2.0 * t * t
      } else {
        1.0 - (-2.0 * t + 2.0) * (-2.0 * t + 2.0) / 2.0
      }
  }
}

///|
pub fn animation_progress(
  now_ms : Int,
  start_ms : Int,
  duration_ms : Int,
  easing : Easing,
) -> (Double, Bool) {
  if duration_ms <= 0 {
    return (1.0, true)
  }
  let t = now_ms - start_ms
  if t <= 0 {
    return (0.0, false)
  }
  if t >= duration_ms {
    return (1.0, true)
  }
  let p = t.to_double() / duration_ms.to_double()
  (easing_apply(easing, p), false)
}
