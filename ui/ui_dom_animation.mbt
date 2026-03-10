///|
priv struct DomScalarAnim {
  start_ms : Int
  duration_ms : Int
  easing : Easing
  from : Double
  to : Double
}

///|
priv struct DomPositionAnim {
  start_ms : Int
  duration_ms : Int
  easing : Easing
  from_x : Double
  from_y : Double
  to_x : Double
  to_y : Double
}

///|
fn scalar_at(now_ms : Int, anim : DomScalarAnim) -> (Double, Bool) {
  let (p, done) = animation_progress(
    now_ms,
    anim.start_ms,
    anim.duration_ms,
    anim.easing,
  )
  (anim.from + (anim.to - anim.from) * p, done)
}

///|
fn pos_at(now_ms : Int, anim : DomPositionAnim) -> (Double, Double, Bool) {
  let (p, done) = animation_progress(
    now_ms,
    anim.start_ms,
    anim.duration_ms,
    anim.easing,
  )
  (
    anim.from_x + (anim.to_x - anim.from_x) * p,
    anim.from_y + (anim.to_y - anim.from_y) * p,
    done,
  )
}

///|
fn dom_pos_tuple(pos : Position) -> (Double, Double) {
  match pos {
    Left => (@core.DOM_POS_LEFT_X, @core.DOM_POS_MID_Y)
    Center => (@core.DOM_POS_CENTER_X, @core.DOM_POS_MID_Y)
    Right => (@core.DOM_POS_RIGHT_X, @core.DOM_POS_MID_Y)
    Custom(x, y) => (x, y)
  }
}

///|
fn anim_value(values : Array[Double]?, index : Int) -> Double? {
  match values {
    Some(xs) =>
      if index >= 0 && index < xs.length() {
        Some(xs[index])
      } else {
        None
      }
    None => None
  }
}

///|
fn clone_dom_figures(
  src : Map[String, DomFigureState],
) -> Map[String, DomFigureState] {
  let out : Map[String, DomFigureState] = {}
  for id, state in src {
    out.set(id, state)
  }
  out
}

///|
fn UiDom::pull_new_dom_animations(self : UiDom, snapshot : UiSnapshot) -> Unit {
  let all = snapshot.dom_animations
  if self.dom_animation_cursor > all.length() {
    self.dom_animation_cursor = 0
  }
  for i, entry in all {
    if i < self.dom_animation_cursor {
      continue
    }
    let (target, spec) = entry
    let eff_duration = if self.is_skip_active() { 0 } else { spec.duration_ms }
    let dom_figures = snapshot.dom_figures
    match spec.prop {
      Position => {
        let (cur_x, cur_y) = match dom_figures.get(target) {
          Some(state) => dom_pos_tuple(state.placement.pos)
          None => (0.5, 0.5)
        }
        let from_x = anim_value(spec.from, 0).unwrap_or(cur_x)
        let from_y = anim_value(spec.from, 1).unwrap_or(cur_y)
        let to_x = anim_value(spec.to, 0).unwrap_or(from_x)
        let to_y = anim_value(spec.to, 1).unwrap_or(from_y)
        self.dom_position_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: eff_duration,
          easing: spec.easing,
          from_x,
          from_y,
          to_x,
          to_y,
        })
      }
      Opacity => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(state.placement.scalars.opacity)
          None => anim_value(spec.from, 0).unwrap_or(1.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_opacity_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: eff_duration,
          easing: spec.easing,
          from,
          to,
        })
      }
      Scale => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(state.placement.scalars.scale)
          None => anim_value(spec.from, 0).unwrap_or(1.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_scale_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: eff_duration,
          easing: spec.easing,
          from,
          to,
        })
      }
      Rotation => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(state.placement.scalars.rotation)
          None => anim_value(spec.from, 0).unwrap_or(0.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_rotation_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: eff_duration,
          easing: spec.easing,
          from,
          to,
        })
      }
      Blur => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(state.placement.scalars.blur)
          None => anim_value(spec.from, 0).unwrap_or(0.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_blur_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: eff_duration,
          easing: spec.easing,
          from,
          to,
        })
      }
      Brightness => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(
              state.placement.scalars.brightness,
            )
          None => anim_value(spec.from, 0).unwrap_or(1.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_brightness_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: eff_duration,
          easing: spec.easing,
          from,
          to,
        })
      }
      Contrast => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(state.placement.scalars.contrast)
          None => anim_value(spec.from, 0).unwrap_or(1.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_contrast_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: eff_duration,
          easing: spec.easing,
          from,
          to,
        })
      }
      Saturation => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(
              state.placement.scalars.saturation,
            )
          None => anim_value(spec.from, 0).unwrap_or(1.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_saturation_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: eff_duration,
          easing: spec.easing,
          from,
          to,
        })
      }
      Gamma => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(state.placement.scalars.gamma)
          None => anim_value(spec.from, 0).unwrap_or(1.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_gamma_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: eff_duration,
          easing: spec.easing,
          from,
          to,
        })
      }
      ColorRed => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(state.placement.scalars.color_r)
          None => anim_value(spec.from, 0).unwrap_or(1.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_color_r_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: eff_duration,
          easing: spec.easing,
          from,
          to,
        })
      }
      ColorGreen => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(state.placement.scalars.color_g)
          None => anim_value(spec.from, 0).unwrap_or(1.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_color_g_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: eff_duration,
          easing: spec.easing,
          from,
          to,
        })
      }
      ColorBlue => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(state.placement.scalars.color_b)
          None => anim_value(spec.from, 0).unwrap_or(1.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_color_b_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: eff_duration,
          easing: spec.easing,
          from,
          to,
        })
      }
    }
  }
  self.dom_animation_cursor = all.length()
}

///|
pub fn UiDom::advance_dom_animation_timer(
  self : UiDom,
  elapsed_ms : Int,
) -> Unit {
  if elapsed_ms > 0 {
    self.dom_timeline_ms += elapsed_ms
  }
}

///|
pub fn UiDom::has_active_dom_animations(self : UiDom) -> Bool {
  !self.dom_position_anims.is_empty() ||
  !self.dom_opacity_anims.is_empty() ||
  !self.dom_scale_anims.is_empty() ||
  !self.dom_rotation_anims.is_empty() ||
  !self.dom_blur_anims.is_empty() ||
  !self.dom_brightness_anims.is_empty() ||
  !self.dom_contrast_anims.is_empty() ||
  !self.dom_saturation_anims.is_empty() ||
  !self.dom_gamma_anims.is_empty() ||
  !self.dom_color_r_anims.is_empty() ||
  !self.dom_color_g_anims.is_empty() ||
  !self.dom_color_b_anims.is_empty()
}

///|
fn UiDom::apply_active_dom_animations(
  self : UiDom,
  dom_figures : Map[String, DomFigureState],
) -> Unit {
  let finished_position : Array[String] = []
  let finished_opacity : Array[String] = []
  let finished_scale : Array[String] = []
  let finished_rotation : Array[String] = []
  let finished_blur : Array[String] = []
  let finished_brightness : Array[String] = []
  let finished_contrast : Array[String] = []
  let finished_saturation : Array[String] = []
  let finished_gamma : Array[String] = []
  let finished_color_r : Array[String] = []
  let finished_color_g : Array[String] = []
  let finished_color_b : Array[String] = []

  for id, state in dom_figures {
    let mut next = state.placement
    match self.dom_position_anims.get(id) {
      Some(anim) => {
        let (x, y, done) = pos_at(self.dom_timeline_ms, anim)
        next = { ..next, pos: Custom(x, y) }
        if done {
          finished_position.push(id)
        }
      }
      None => ()
    }

    match self.dom_opacity_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, opacity: value } }
        if done {
          finished_opacity.push(id)
        }
      }
      None => ()
    }
    match self.dom_scale_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, scale: value } }
        if done {
          finished_scale.push(id)
        }
      }
      None => ()
    }
    match self.dom_rotation_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, rotation: value } }
        if done {
          finished_rotation.push(id)
        }
      }
      None => ()
    }
    match self.dom_blur_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, blur: value } }
        if done {
          finished_blur.push(id)
        }
      }
      None => ()
    }
    match self.dom_brightness_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, brightness: value } }
        if done {
          finished_brightness.push(id)
        }
      }
      None => ()
    }
    match self.dom_contrast_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, contrast: value } }
        if done {
          finished_contrast.push(id)
        }
      }
      None => ()
    }
    match self.dom_saturation_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, saturation: value } }
        if done {
          finished_saturation.push(id)
        }
      }
      None => ()
    }
    match self.dom_gamma_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, gamma: value } }
        if done {
          finished_gamma.push(id)
        }
      }
      None => ()
    }
    match self.dom_color_r_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, color_r: value } }
        if done {
          finished_color_r.push(id)
        }
      }
      None => ()
    }
    match self.dom_color_g_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, color_g: value } }
        if done {
          finished_color_g.push(id)
        }
      }
      None => ()
    }
    match self.dom_color_b_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, color_b: value } }
        if done {
          finished_color_b.push(id)
        }
      }
      None => ()
    }
    dom_figures.set(id, { placement: next, interactive: state.interactive })
  }

  for id in finished_position {
    self.dom_position_anims.remove(id)
  }
  for id in finished_opacity {
    self.dom_opacity_anims.remove(id)
  }
  for id in finished_scale {
    self.dom_scale_anims.remove(id)
  }
  for id in finished_rotation {
    self.dom_rotation_anims.remove(id)
  }
  for id in finished_blur {
    self.dom_blur_anims.remove(id)
  }
  for id in finished_brightness {
    self.dom_brightness_anims.remove(id)
  }
  for id in finished_contrast {
    self.dom_contrast_anims.remove(id)
  }
  for id in finished_saturation {
    self.dom_saturation_anims.remove(id)
  }
  for id in finished_gamma {
    self.dom_gamma_anims.remove(id)
  }
  for id in finished_color_r {
    self.dom_color_r_anims.remove(id)
  }
  for id in finished_color_g {
    self.dom_color_g_anims.remove(id)
  }
  for id in finished_color_b {
    self.dom_color_b_anims.remove(id)
  }
}
