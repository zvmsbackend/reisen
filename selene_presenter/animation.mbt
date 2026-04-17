///|
fn fallback_animation_step_ms(configured : Int) -> Int {
  if configured <= 0 {
    16
  } else {
    configured
  }
}

///|
fn resolved_step_ms(configured : Int) -> Int {
  let raw_delta_ms = (@selene_time.raw_delta() * 1000.0).to_int()
  if raw_delta_ms > 0 {
    raw_delta_ms
  } else {
    fallback_animation_step_ms(configured)
  }
}

///|
fn scalar_state_value(
  scalars : @core.ScalarState,
  prop : @core.AnimProp,
) -> Double {
  match prop {
    Opacity => scalars.opacity
    Scale => scalars.scale
    Rotation => scalars.rotation
    Blur => scalars.blur
    Brightness => scalars.brightness
    Contrast => scalars.contrast
    Saturation => scalars.saturation
    Gamma => scalars.gamma
    ColorRed => scalars.color_r
    ColorGreen => scalars.color_g
    ColorBlue => scalars.color_b
    Position => 0.0
  }
}

///|
fn animation_key(target : String, prop : @core.AnimProp) -> String {
  let suffix = match prop {
    Position => "position"
    Scale => "scale"
    Opacity => "opacity"
    Rotation => "rotation"
    Blur => "blur"
    Brightness => "brightness"
    Contrast => "contrast"
    Saturation => "saturation"
    Gamma => "gamma"
    ColorRed => "color_r"
    ColorGreen => "color_g"
    ColorBlue => "color_b"
  }
  "\{target}::\{suffix}"
}

///|
fn apply_scalar_to_state(
  scalars : @core.ScalarState,
  prop : @core.AnimProp,
  value : Double,
) -> @core.ScalarState {
  match prop {
    Opacity => { ..scalars, opacity: value }
    Scale => { ..scalars, scale: value }
    Rotation => { ..scalars, rotation: value }
    Blur => { ..scalars, blur: value }
    Brightness => { ..scalars, brightness: value }
    Contrast => { ..scalars, contrast: value }
    Saturation => { ..scalars, saturation: value }
    Gamma => { ..scalars, gamma: value }
    ColorRed => { ..scalars, color_r: value }
    ColorGreen => { ..scalars, color_g: value }
    ColorBlue => { ..scalars, color_b: value }
    Position => scalars
  }
}

///|
fn apply_figure_animation(
  placement : @core.FigurePlacement,
  prop : @core.AnimProp,
  values : Array[Double],
) -> @core.FigurePlacement {
  match prop {
    Position =>
      if values.length() >= 2 {
        let x = values[0]
        let y = values[1]
        { ..placement, pos: @core.Position::Custom(x, y) }
      } else {
        placement
      }
    _ =>
      if values.length() >= 1 {
        let scalars = apply_scalar_to_state(placement.scalars, prop, values[0])
        { ..placement, scalars, }
      } else {
        placement
      }
  }
}

///|
fn apply_background_animation(
  background : @core.BackgroundState,
  prop : @core.AnimProp,
  values : Array[Double],
) -> @core.BackgroundState {
  match prop {
    Position => background
    _ =>
      if values.length() >= 1 {
        let scalars = apply_scalar_to_state(background.scalars, prop, values[0])
        { ..background, scalars, }
      } else {
        background
      }
  }
}

///|
fn SelenePresenter::upsert_active_animation(
  self : SelenePresenter,
  target : String,
  spec : @core.AnimationSpec,
  figure : @core.FigurePlacement?,
  background : @core.BackgroundState?,
) -> Unit {
  let duration_ms = if spec.duration_ms <= 0 { 1 } else { spec.duration_ms }
  let (anchor_x, anchor_y) = animation_anchor(spec)
  match spec.prop {
    Position => {
      let to = animation_vec2_target(spec)
      if to is None {
        return
      }

      let from = match animation_vec2_source(spec) {
        Some(pair) => Some(pair)
        None =>
          figure.bind(placement => {
            match placement.pos {
              Custom(x, y) => Some((x, y))
              _ => None
            }
          })
      }
      match (from, to) {
        (Some((fx, fy)), Some((tx, ty))) =>
          self.active_animations.set(animation_key(target, spec.prop), {
            target,
            prop: spec.prop,
            easing: spec.easing,
            duration_ms,
            anchor_x,
            anchor_y,
            from: [fx, fy],
            to: [tx, ty],
            elapsed_ms: 0,
          })
        _ => ()
      }
    }
    _ => {
      let to = animation_scalar_target(spec)
      if to is None {
        return
      }
      let from = match animation_scalar_source(spec) {
        Some(value) => Some(value)
        None =>
          match figure {
            Some(placement) =>
              Some(scalar_state_value(placement.scalars, spec.prop))
            None =>
              background.map(state => {
                scalar_state_value(state.scalars, spec.prop)
              })
          }
      }
      match (from, to) {
        (Some(f), Some(t)) =>
          self.active_animations.set(animation_key(target, spec.prop), {
            target,
            prop: spec.prop,
            easing: spec.easing,
            duration_ms,
            anchor_x,
            anchor_y,
            from: [f],
            to: [t],
            elapsed_ms: 0,
          })
        _ => ()
      }
    }
  }
}

///|
fn animation_values(anim : ActiveAnimation, progress : Double) -> Array[Double] {
  let p = progress.clamp(min=0.0, max=1.0)
  anim.from
  .iter()
  .zip(anim.to.iter())
  .map(entry => animation_lerp(entry.0, entry.1, p))
  .collect()
}

///|
fn figure_center(rect : @selene_math.Rect) -> (Double, Double) {
  (
    rect.position[@selene_math.X] + rect.size[@selene_math.X] / 2.0,
    rect.position[@selene_math.Y] + rect.size[@selene_math.Y] / 2.0,
  )
}

///|
fn custom_from_canvas(
  x : Double,
  y : Double,
  viewport_w : Double,
  viewport_h : Double,
) -> Position {
  let cx = if viewport_w <= 0.0 { 0.5 } else { x / viewport_w }
  let cy = if viewport_h <= 0.0 { 0.5 } else { y / viewport_h }
  Custom(cx, cy)
}

///|
fn SelenePresenter::apply_anchored_scale(
  self : SelenePresenter,
  placement : @core.FigurePlacement,
  new_scale : Double,
  anchor_x : Double,
  anchor_y : Double,
) -> @core.FigurePlacement {
  let old_scale = placement.scalars.scale
  let next_scalars = apply_scalar_to_state(placement.scalars, Scale, new_scale)
  if (anchor_x - 0.5).abs() <= 0.000001 && (anchor_y - 0.5).abs() <= 0.000001 {
    return { ..placement, scalars: next_scalars }
  }
  let old_rect = figure_rect(
    placement.pos,
    self.config.viewport_w,
    self.config.viewport_h,
    old_scale,
  )
  let (center_x, center_y) = figure_center(old_rect)
  let base_w = self.config.viewport_w * 0.32
  let base_h = self.config.viewport_h * 0.78
  let delta = new_scale - old_scale
  let dx = (0.5 - anchor_x) * base_w * delta
  let dy = (0.5 - anchor_y) * base_h * delta
  {
    ..placement,
    pos: custom_from_canvas(
      center_x + dx,
      center_y + dy,
      self.config.viewport_w,
      self.config.viewport_h,
    ),
    scalars: next_scalars,
  }
}

///|
fn SelenePresenter::advance_active_animations(
  self : SelenePresenter,
  figures : Map[String, @core.FigurePlacement],
  background : @core.BackgroundState?,
  skip_mode : Bool,
) -> (Map[String, @core.FigurePlacement], @core.BackgroundState?) {
  let next_figures = figures
  let mut next_background = background
  let completed : Array[String] = []
  for entry in self.active_animations {
    let (key, anim) = entry
    let step_ms = if skip_mode {
      anim.duration_ms
    } else {
      resolved_step_ms(self.config.animation_step_ms)
    }
    anim.elapsed_ms = anim.elapsed_ms + step_ms
    let (progress, done) = animation_sample(
      anim.elapsed_ms,
      0,
      anim.duration_ms,
      anim.easing,
    )
    let values = animation_values(anim, progress)
    if next_figures.get(anim.target) is Some(placement) {
      if anim.prop is Scale && values.length() >= 1 {
        next_figures.set(
          anim.target,
          self.apply_anchored_scale(
            placement,
            values[0],
            anim.anchor_x,
            anim.anchor_y,
          ),
        )
      } else {
        next_figures.set(
          anim.target,
          apply_figure_animation(placement, anim.prop, values),
        )
      }
    } else if next_background is Some(state) && state.id == anim.target {
      next_background = Some(
        apply_background_animation(state, anim.prop, values),
      )
    }
    if done {
      completed.push(key)
    }
  }
  for key in completed {
    self.active_animations.remove(key)
  }
  (next_figures, next_background)
}
