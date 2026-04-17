///|
fn effect_key(target : String, id : String) -> String {
  "\{target}::\{id}"
}

///|
fn effect_signature(spec : @core.EffectSpec) -> String {
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
fn scalar_param_value(scalars : @core.ScalarState, name : String) -> Double? {
  match name.to_lower() {
    "opacity" => Some(scalars.opacity)
    "brightness" => Some(scalars.brightness)
    "color_r" | "colorred" | "red" => Some(scalars.color_r)
    "color_g" | "colorgreen" | "green" => Some(scalars.color_g)
    "color_b" | "colorblue" | "blue" => Some(scalars.color_b)
    _ => None
  }
}

///|
fn apply_scalar_param(
  scalars : @core.ScalarState,
  name : String,
  value : Double,
) -> @core.ScalarState? {
  match name.to_lower() {
    "opacity" => Some({ ..scalars, opacity: value })
    "brightness" => Some({ ..scalars, brightness: value })
    "color_r" | "colorred" | "red" => Some({ ..scalars, color_r: value })
    "color_g" | "colorgreen" | "green" => Some({ ..scalars, color_g: value })
    "color_b" | "colorblue" | "blue" => Some({ ..scalars, color_b: value })
    _ => None
  }
}

///|
fn current_timeline_ms() -> Int {
  (@selene_time.elapsed_raw() * 1000.0).to_int()
}

///|
fn SelenePresenter::warn_once(
  self : SelenePresenter,
  key : String,
  title : String,
  detail : String,
) -> Unit {
  if self.warned_capabilities.contains(key) {
    return
  }
  self.warned_capabilities.add(key)
  @selene_platform_render.capability_warning(title, detail)
}

///|
fn SelenePresenter::apply_effects_to_scalars(
  self : SelenePresenter,
  target : String,
  base : @core.ScalarState,
  effects : Array[@core.EffectSpec],
  skip_mode : Bool,
) -> EffectApplyResult {
  let mut scalars = base
  let mut has_active_timed_effect = false
  let active_effect_keys : Set[String] = Set::new()
  let now_ms = current_timeline_ms()
  for spec in effects {
    let key = effect_key(target, spec.id)
    active_effect_keys.add(key)
    let signature = effect_signature(spec)
    if self.effect_signatures.get(key) is Some(prev) {
      if prev != signature {
        self.effect_signatures.set(key, signature)
        self.effect_start_ms.set(key, now_ms)
        let from_params = spec.params.map(entry => {
          let (name, value) = entry
          let from = scalar_param_value(scalars, name).unwrap_or(value)
          (name, from)
        })
        self.effect_from_params.set(key, from_params)
      }
    } else {
      self.effect_signatures.set(key, signature)
      self.effect_start_ms.set(key, now_ms)
      let from_params = spec.params.map(entry => {
        let (name, value) = entry
        let from = scalar_param_value(scalars, name).unwrap_or(value)
        (name, from)
      })
      self.effect_from_params.set(key, from_params)
    }

    let progress = match (spec.duration_ms, self.effect_start_ms.get(key)) {
      (Some(duration), Some(start_ms)) => {
        let duration = if skip_mode { 0 } else { duration }
        let (p, done) = animation_sample(
          now_ms,
          start_ms,
          duration,
          spec.easing,
        )
        if done {
          1.0
        } else {
          has_active_timed_effect = true
          p
        }
      }
      _ => 1.0
    }

    let render_params = match spec.duration_ms {
      Some(_) => {
        let from_map = Map::from_array(
          self.effect_from_params.get_or_default(key, []),
        )
        spec.params.map(entry => {
          let (name, value) = entry
          let start = from_map.get(name).unwrap_or(value)
          let animated = animation_lerp(start, value, progress)
          (name, animated)
        })
      }
      None => spec.params
    }

    let mut any_supported = false
    for entry in render_params {
      let (name, value) = entry
      if apply_scalar_param(scalars, name, value) is Some(next) {
        scalars = next
        any_supported = true
      } else {
        self.warn_once(
          "effect-param::\{name.to_lower()}",
          "selene_presenter effect fallback",
          "unsupported effect param '\{name}' on target '\{target}'",
        )
      }
    }
    if !any_supported {
      self.warn_once(
        "effect-id::\{spec.id}",
        "selene_presenter effect fallback",
        "effect '\{spec.id}' has no supported scalar params on this backend",
      )
    }
  }
  { scalars, has_active_timed_effect, active_effect_keys }
}

///|
fn SelenePresenter::cleanup_stale_effect_state(
  self : SelenePresenter,
  active_effect_keys : Set[String],
) -> Unit {
  let stale : Array[String] = []
  for entry in self.effect_signatures {
    let (key, _) = entry
    if !active_effect_keys.contains(key) {
      stale.push(key)
    }
  }
  for key in stale {
    self.effect_signatures.remove(key)
    self.effect_start_ms.remove(key)
    self.effect_from_params.remove(key)
  }
}

///|
fn SelenePresenter::sync_render_extension(
  self : SelenePresenter,
  extension : RenderExtensionView,
  skip_mode : Bool,
) -> Unit {
  let figures : Map[String, @core.FigurePlacement] = {}
  for entry in extension.figure_entries() {
    let (id, placement) = entry
    figures[id] = placement
  }
  let background = extension.background_state()

  for entry in extension.animations() {
    let (target, spec) = entry
    self.upsert_active_animation(
      target,
      spec,
      figures.get(target),
      background.filter(state => state.id == target),
    )
  }

  let (next_figures, next_background) = self.advance_active_animations(
    figures, background, skip_mode,
  )

  let active_effect_keys : Set[String] = Set::new()
  let mut has_active_timed_effects = false
  for entry in next_figures {
    let (target, placement) = entry
    let effects = extension.effects(target)
    if effects.is_empty() {
      continue
    }
    let applied = self.apply_effects_to_scalars(
      target,
      placement.scalars,
      effects,
      skip_mode,
    )
    for key in applied.active_effect_keys {
      active_effect_keys.add(key)
    }
    if applied.has_active_timed_effect {
      has_active_timed_effects = true
    }
    extension.apply(
      RenderExtensionUpdate::SetFigurePlacement(target, {
        ..placement,
        scalars: applied.scalars,
      }),
    )
  }

  if next_background is Some(state) {
    let effects = extension.effects(state.id)
    if effects.is_empty() {
      extension.apply(RenderExtensionUpdate::SetBackgroundState(state))
    } else {
      let applied = self.apply_effects_to_scalars(
        state.id,
        state.scalars,
        effects,
        skip_mode,
      )
      for key in applied.active_effect_keys {
        active_effect_keys.add(key)
      }
      if applied.has_active_timed_effect {
        has_active_timed_effects = true
      }
      extension.apply(
        RenderExtensionUpdate::SetBackgroundState({
          ..state,
          scalars: applied.scalars,
        }),
      )
    }
  }

  self.cleanup_stale_effect_state(active_effect_keys)
  self.has_active_timed_effects = has_active_timed_effects
}
