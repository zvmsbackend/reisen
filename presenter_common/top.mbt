///|
using @core {animation_progress, type AnimationSpec, type Easing}

///|
pub fn animation_value(values : Array[Double]?, idx : Int) -> Double? {
  values.bind(arr => if idx < arr.length() { Some(arr[idx]) } else { None })
}

///|
pub fn animation_anchor_from_values(
  values : Array[Double]?,
) -> (Double, Double) {
  let x = animation_value(values, 0).unwrap_or(0.5)
  let y = animation_value(values, 1).unwrap_or(0.5)
  (x.clamp(min=0.0, max=1.0), y.clamp(min=0.0, max=1.0))
}

///|
pub fn animation_scalar_target(spec : AnimationSpec) -> Double? {
  match spec.to {
    Some(values) => if values.is_empty() { None } else { Some(values[0]) }
    None => None
  }
}

///|
pub fn animation_scalar_source(spec : AnimationSpec) -> Double? {
  match spec.from {
    Some(values) => if values.is_empty() { None } else { Some(values[0]) }
    None => None
  }
}

///|
pub fn animation_vec2_target(spec : AnimationSpec) -> (Double, Double)? {
  match spec.to {
    Some(values) =>
      if values.length() >= 2 {
        Some((values[0], values[1]))
      } else {
        None
      }
    None => None
  }
}

///|
pub fn animation_vec2_source(spec : AnimationSpec) -> (Double, Double)? {
  match spec.from {
    Some(values) =>
      if values.length() >= 2 {
        Some((values[0], values[1]))
      } else {
        None
      }
    None => None
  }
}

///|
pub fn animation_anchor(spec : AnimationSpec) -> (Double, Double) {
  animation_anchor_from_values(spec.anchor)
}

///|
pub fn animation_lerp(from : Double, to : Double, progress : Double) -> Double {
  from + (to - from) * progress
}

///|
pub fn animation_sample(
  now_ms : Int,
  start_ms : Int,
  duration_ms : Int,
  easing : Easing,
) -> (Double, Bool) {
  animation_progress(now_ms, start_ms, duration_ms, easing)
}

///|
pub fn animation_lerp_optional(
  base_value : Double,
  from : Double?,
  to : Double?,
  progress : Double,
  done : Bool,
) -> Double {
  let resolved_from = from.unwrap_or(base_value)
  let resolved_to = to.unwrap_or(base_value)
  if done {
    resolved_to
  } else {
    animation_lerp(resolved_from, resolved_to, progress)
  }
}
