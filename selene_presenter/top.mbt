///|
using @core {type Position}

///|
using @presenter_common {
  animation_anchor,
  animation_lerp,
  animation_sample,
  animation_scalar_source,
  animation_scalar_target,
  animation_vec2_source,
  animation_vec2_target,
}

///|
using @engine {
  type CoreRenderSnapshot,
  type RenderSyncHook,
  type RenderExtensionHook,
  type RenderExtensionView,
  type RenderExtensionUpdate,
}

///|
pub type UiOverlayProvider = () -> Array[@selene_render2d_types.DrawCommand2D]

///|
pub fn combine_ui_overlay_providers(
  primary : UiOverlayProvider?,
  secondary : UiOverlayProvider?,
) -> UiOverlayProvider? {
  match (primary, secondary) {
    (None, None) => None
    (Some(provider), None) => Some(provider)
    (None, Some(provider)) => Some(provider)
    (Some(a), Some(b)) =>
      Some(() => {
        let commands = a()
        for command in b() {
          commands.push(command)
        }
        commands
      })
  }
}

///|
pub struct SelenePresenterConfig {
  viewport_w : Double
  viewport_h : Double
  animation_step_ms : Int
  placeholder_background_color : @selene_render.Color
  placeholder_figure_color : @selene_render.Color
}

///|
pub fn SelenePresenterConfig::default() -> SelenePresenterConfig {
  {
    viewport_w: 1280.0,
    viewport_h: 720.0,
    animation_step_ms: 16,
    placeholder_background_color: { r: 32, g: 36, b: 48, a: 1.0 },
    placeholder_figure_color: { r: 220, g: 228, b: 242, a: 1.0 },
  }
}

///|
struct ActiveAnimation {
  target : String
  prop : @core.AnimProp
  easing : @core.Easing
  duration_ms : Int
  anchor_x : Double
  anchor_y : Double
  from : Array[Double]
  to : Array[Double]
  mut elapsed_ms : Int
}

///|
priv struct EffectApplyResult {
  scalars : @core.ScalarState
  has_active_timed_effect : Bool
  active_effect_keys : Set[String]
}

///|
pub struct SelenePresenter {
  config : SelenePresenterConfig
  background_handles : Map[String, @selene_asset_types.ImageHandle]
  figure_handles : Map[String, @selene_asset_types.ImageHandle]
  active_animations : Map[String, ActiveAnimation]
  effect_signatures : Map[String, String]
  effect_start_ms : Map[String, Int]
  effect_from_params : Map[String, Array[(String, Double)]]
  warned_capabilities : Set[String]
  mut ui_overlay_provider : UiOverlayProvider?
  mut has_active_timed_effects : Bool
  mut last_submitted_epoch : String?
  mut force_submit : Bool
}

///|
pub fn SelenePresenter::new(
  config? : SelenePresenterConfig = SelenePresenterConfig::default(),
) -> SelenePresenter {
  {
    config,
    background_handles: {},
    figure_handles: {},
    active_animations: {},
    effect_signatures: {},
    effect_start_ms: {},
    effect_from_params: {},
    warned_capabilities: Set::new(),
    ui_overlay_provider: None,
    has_active_timed_effects: false,
    last_submitted_epoch: None,
    force_submit: true,
  }
}

///|
pub fn SelenePresenter::set_ui_overlay_provider(
  self : SelenePresenter,
  provider : UiOverlayProvider?,
) -> Unit {
  self.ui_overlay_provider = provider
  self.force_submit = true
}

///|
pub fn SelenePresenter::set_ui_overlay_providers(
  self : SelenePresenter,
  primary : UiOverlayProvider?,
  secondary : UiOverlayProvider?,
) -> Unit {
  self.set_ui_overlay_provider(combine_ui_overlay_providers(primary, secondary))
}

///|
pub fn SelenePresenter::register_background_image(
  self : SelenePresenter,
  id : String,
  handle : @selene_asset_types.ImageHandle,
) -> Unit {
  self.background_handles[id] = handle
  self.force_submit = true
}

///|
pub fn SelenePresenter::register_figure_image(
  self : SelenePresenter,
  id : String,
  handle : @selene_asset_types.ImageHandle,
) -> Unit {
  self.figure_handles[id] = handle
  self.force_submit = true
}

///|
fn base_color_with_alpha(
  c : @selene_render.Color,
  alpha : Double,
) -> @selene_render.Color {
  { r: c.r, g: c.g, b: c.b, a: alpha }
}

///|
fn background_rect(
  viewport_w : Double,
  viewport_h : Double,
) -> @selene_math.Rect {
  {
    position: @selene_math.Vec2D(0.0, 0.0),
    size: @selene_math.Vec2D(viewport_w, viewport_h),
  }
}

///|
fn figure_rect(
  position : Position,
  viewport_w : Double,
  viewport_h : Double,
  scale : Double,
) -> @selene_math.Rect {
  let width = viewport_w * 0.32 * scale
  let height = viewport_h * 0.78 * scale
  let y = viewport_h - height
  let x = match position {
    Left => viewport_w * 0.18 - width / 2.0
    Center => viewport_w * 0.5 - width / 2.0
    Right => viewport_w * 0.82 - width / 2.0
    Custom(cx, cy) => {
      let px = viewport_w * cx - width / 2.0
      let py = viewport_h * cy - height / 2.0
      ignore(py)
      px
    }
  }
  let y = match position {
    Custom(_, cy) => viewport_h * cy - height / 2.0
    _ => y
  }
  {
    position: @selene_math.Vec2D(x, y),
    size: @selene_math.Vec2D(width, height),
  }
}

///|
fn image_command(
  handle : @selene_asset_types.ImageHandle,
  destination : @selene_math.Rect,
  color : @selene_render.Color,
  transform : @selene_math.Transform,
) -> @selene_render2d_types.DrawCommand2D {
  Image({
    image: handle,
    destination,
    source: None,
    transform,
    repeat: @selene_math.RepeatMode::NoRepeat,
    color,
  })
}

///|
fn placeholder_rect_command(
  rect : @selene_math.Rect,
  color : @selene_render.Color,
  transform : @selene_math.Transform,
) -> @selene_render2d_types.DrawCommand2D {
  Rect({ rect, transform, fill_color: color, stroke_color: None })
}

///|
fn to_color_component(value : Double) -> UInt {
  let v = value.clamp(min=0.0, max=1.0)
  (v * 255.0).to_int().reinterpret_as_uint()
}

///|
fn tint_from_scalars(scalars : @core.ScalarState) -> @selene_render.Color {
  {
    r: to_color_component(scalars.color_r * scalars.brightness),
    g: to_color_component(scalars.color_g * scalars.brightness),
    b: to_color_component(scalars.color_b * scalars.brightness),
    a: scalars.opacity.clamp(min=0.0, max=1.0),
  }
}

///|
fn rotation_transform(
  rect : @selene_math.Rect,
  rotation_deg : Double,
) -> @selene_math.Transform {
  if rotation_deg.abs() <= 0.000001 {
    return @selene_math.Transform::identity()
  }
  let center_x = rect.position[@selene_math.X] + rect.size[@selene_math.X] / 2.0
  let center_y = rect.position[@selene_math.Y] + rect.size[@selene_math.Y] / 2.0
  @selene_math.Transform::identity()
  .append_translation(-center_x, -center_y)
  .append_rotation_deg(rotation_deg)
  .append_translation(center_x, center_y)
}

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

///|
fn SelenePresenter::build_world_commands(
  self : SelenePresenter,
  snapshot : CoreRenderSnapshot,
) -> Array[@selene_render2d_types.DrawCommand2D] {
  let commands : Array[@selene_render2d_types.DrawCommand2D] = []
  let viewport_w = self.config.viewport_w
  let viewport_h = self.config.viewport_h
  let bg_rect = background_rect(viewport_w, viewport_h)
  if snapshot.background is Some(state) {
    if self.background_handles.get(state.id) is Some(handle) {
      commands.push(
        image_command(
          handle,
          bg_rect,
          tint_from_scalars(state.scalars),
          rotation_transform(bg_rect, state.scalars.rotation),
        ),
      )
    } else {
      commands.push(
        placeholder_rect_command(
          bg_rect,
          base_color_with_alpha(
            self.config.placeholder_background_color,
            state.scalars.opacity,
          ),
          rotation_transform(bg_rect, state.scalars.rotation),
        ),
      )
    }
  }
  let sorted_figures = snapshot.figures.iter2().to_array()
  sorted_figures.sort_by((lhs, rhs) => lhs.1.layer - rhs.1.layer)
  for entry in sorted_figures {
    let (id, placement) = entry
    let rect = figure_rect(
      placement.pos,
      viewport_w,
      viewport_h,
      placement.scalars.scale,
    )
    if self.figure_handles.get(id) is Some(handle) {
      commands.push(
        image_command(
          handle,
          rect,
          tint_from_scalars(placement.scalars),
          rotation_transform(rect, placement.scalars.rotation),
        ),
      )
    } else {
      commands.push(
        placeholder_rect_command(
          rect,
          base_color_with_alpha(
            self.config.placeholder_figure_color,
            placement.scalars.opacity,
          ),
          rotation_transform(rect, placement.scalars.rotation),
        ),
      )
    }
  }
  commands
}

///|
fn SelenePresenter::submit_frame(
  self : SelenePresenter,
  snapshot : CoreRenderSnapshot,
) -> Unit {
  let ui_commands = match self.ui_overlay_provider {
    Some(provider) => provider()
    None => []
  }
  let frame2d : @selene_render2d_types.RenderFrame2D = {
    world_commands: self.build_world_commands(snapshot),
    ui_commands,
  }
  let frame = { ..@selene_render_pipeline.empty_render_frame(), frame2d, }
  @selene_platform_render.submit_frame(frame)
}

///|
pub fn SelenePresenter::submit_core_snapshot(
  self : SelenePresenter,
  snapshot : CoreRenderSnapshot,
) -> Unit {
  if !self.force_submit &&
    self.active_animations.is_empty() &&
    !self.has_active_timed_effects {
    if self.last_submitted_epoch is Some(epoch) &&
      epoch == snapshot.render_epoch {
      return
    }
  }
  self.submit_frame(snapshot)
  self.last_submitted_epoch = Some(snapshot.render_epoch)
  self.force_submit = false
}

///|
pub fn SelenePresenter::as_core_render_sync_hook(
  self : SelenePresenter,
) -> RenderSyncHook {
  (snapshot, _skip_mode) => self.submit_core_snapshot(snapshot)
}

///|
pub fn SelenePresenter::as_render_hooks(
  self : SelenePresenter,
) -> (RenderSyncHook, RenderExtensionHook) {
  (
    self.as_core_render_sync_hook(),
    (extension, skip_mode) => self.sync_render_extension(extension, skip_mode),
  )
}
