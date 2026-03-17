///|
fn effect_key(target : String, id : String) -> String {
  "\{target}::\{id}"
}

///|
fn effect_signature(spec : EffectSpec) -> String {
  let phase = match spec.phase {
    Pre => "pre"
    Post => "post"
  }
  let duration = match spec.duration_ms {
    Some(ms) => ms.to_string()
    None => "none"
  }
  let easing = match spec.easing {
    Linear => "linear"
    EaseIn => "easein"
    EaseOut => "easeout"
    EaseInOut => "easeinout"
  }
  let params = spec.params
    .map(entry => {
      let (name, value) = entry
      "\{name}=\{value}"
    })
    .join(";")
  "\{spec.id}|\{phase}|\{duration}|\{easing}|\{params}"
}

///|
fn PixiPresenter::apply_scalar_visuals(
  self : PixiPresenter,
  key : String,
  set_filters : (Array[@js.Value]) -> Unit,
  scalar_acc : ScalarAccumulator,
  extra_blur? : Double = 0.0,
) -> Unit {
  let blur_value = {
    let v = scalar_acc.blur + extra_blur
    if v < 0.0 {
      0.0
    } else {
      v
    }
  }
  let need_color = scalar_acc.brightness != 1.0 ||
    scalar_acc.contrast != 1.0 ||
    scalar_acc.saturation != 1.0 ||
    scalar_acc.gamma != 1.0 ||
    scalar_acc.color_r != 1.0 ||
    scalar_acc.color_g != 1.0 ||
    scalar_acc.color_b != 1.0
  let filters : Array[@js.Value] = []
  if blur_value > 0.0 {
    let blur_filter = match self.blur_filters.get(key) {
      Some(filter) => filter
      None => {
        let filter = PixiBlurFilter::new()
        self.blur_filters.set(key, filter)
        filter
      }
    }
    blur_filter.set_strength(blur_value)
    filters.push(@js.Value::cast_from(blur_filter))
  }
  if need_color {
    let color_filter = match self.color_filters.get(key) {
      Some(filter) => filter
      None => {
        let filter = PixiColorMatrixFilter::new()
        self.color_filters.set(key, filter)
        filter
      }
    }
    color_filter.apply_adjustments(
      scalar_acc.brightness,
      scalar_acc.contrast,
      scalar_acc.saturation,
      scalar_acc.gamma,
      clamp01(scalar_acc.color_r),
      clamp01(scalar_acc.color_g),
      clamp01(scalar_acc.color_b),
    )
    filters.push(@js.Value::cast_from(color_filter))
  }
  set_filters(filters)
}

///|
fn PixiPresenter::apply_scalar_visuals_sprite(
  self : PixiPresenter,
  key : String,
  sprite : PixiSprite,
  scalar_acc : ScalarAccumulator,
  extra_blur? : Double = 0.0,
) -> Unit {
  self.apply_scalar_visuals(
    key,
    filters => sprite.set_filters(filters),
    scalar_acc,
    extra_blur~,
  )
}

///|
fn PixiPresenter::apply_scalar_visuals_sprite_live2d(
  self : PixiPresenter,
  key : String,
  model : PixiLive2dModel,
  scalar_acc : ScalarAccumulator,
  extra_blur? : Double = 0.0,
) -> Unit {
  self.apply_scalar_visuals(
    key,
    filters => model.set_filters(filters),
    scalar_acc,
    extra_blur~,
  )
}

///|
fn PixiPresenter::apply_effects_to_target(
  self : PixiPresenter,
  target_id : String,
  target : PixiEffectTarget,
  effects : Array[EffectSpec],
  active_effects : Set[String],
  phase : EffectPhase,
) -> Bool {
  let mut skip_base = false
  for spec in effects {
    if spec.phase != phase {
      continue
    }
    let key = effect_key(target_id, spec.id)
    let signature = effect_signature(spec)
    active_effects.add(key)
    if self.effect_signatures.get(key) is Some(prev) {
      if prev != signature {
        self.effect_signatures.set(key, signature)
        self.effect_start_ms.set(key, self.timeline_ms)
        let defaults = pixi_effect_defaults_for(spec.id, spec.params)
        self.effect_from_params.set(key, defaults)
      }
    } else {
      self.effect_signatures.set(key, signature)
      self.effect_start_ms.set(key, self.timeline_ms)
      let defaults = pixi_effect_defaults_for(spec.id, spec.params)
      self.effect_from_params.set(key, defaults)
    }
    let progress = match (spec.duration_ms, self.effect_start_ms.get(key)) {
      (Some(duration), Some(start_ms)) => {
        let (p, done) = animation_progress(
          self.timeline_ms,
          start_ms,
          if self.skip_mode {
            0
          } else {
            duration
          },
          spec.easing,
        )
        if done {
          1.0
        } else {
          p
        }
      }
      _ => 1.0
    }
    let render_params = match spec.duration_ms {
      Some(_) => {
        let from = self.effect_from_params.get_or_default(key, [])
        let from_map = Map::from_array(from)
        spec.params.map(entry => {
          let (name, value) = entry
          let start = from_map.get(name).unwrap_or(value)
          let animated = start + (value - start) * progress
          (name, animated)
        })
      }
      None => spec.params
    }
    if pixi_apply_effect_to_target(
        target,
        spec.id,
        render_params,
        self.timeline_ms,
      ) {
      skip_base = true
    }
  }
  skip_base
}
