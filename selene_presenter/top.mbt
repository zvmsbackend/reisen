///|
using @core {animation_progress, type Position}

///|
using @engine {
  type CoreRenderSnapshot,
  type RenderSyncHook,
  type RenderExtensionHook,
  type RenderExtensionView,
  type RenderExtensionUpdate,
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
  from : Array[Double]
  to : Array[Double]
  mut elapsed_ms : Int
}

///|
pub struct SelenePresenter {
  config : SelenePresenterConfig
  background_handles : Map[String, @selene_asset_types.ImageHandle]
  figure_handles : Map[String, @selene_asset_types.ImageHandle]
  active_animations : Map[String, ActiveAnimation]
}

///|
pub fn SelenePresenter::new(
  config? : SelenePresenterConfig = SelenePresenterConfig::default(),
) -> SelenePresenter {
  { config, background_handles: {}, figure_handles: {}, active_animations: {} }
}

///|
pub fn SelenePresenter::register_background_image(
  self : SelenePresenter,
  id : String,
  handle : @selene_asset_types.ImageHandle,
) -> Unit {
  self.background_handles[id] = handle
}

///|
pub fn SelenePresenter::register_figure_image(
  self : SelenePresenter,
  id : String,
  handle : @selene_asset_types.ImageHandle,
) -> Unit {
  self.figure_handles[id] = handle
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
  alpha : Double,
) -> @selene_render2d_types.DrawCommand2D {
  Image({
    image: handle,
    destination,
    source: None,
    transform: @selene_math.Transform::identity(),
    repeat: @selene_math.RepeatMode::NoRepeat,
    color: { r: 255, g: 255, b: 255, a: alpha },
  })
}

///|
fn placeholder_rect_command(
  rect : @selene_math.Rect,
  color : @selene_render.Color,
) -> @selene_render2d_types.DrawCommand2D {
  Rect({
    rect,
    transform: @selene_math.Transform::identity(),
    fill_color: color,
    stroke_color: None,
  })
}

///|
fn scalar_anim_target(spec : @core.AnimationSpec) -> Double? {
  match spec.to {
    Some(values) => if values.is_empty() { None } else { Some(values[0]) }
    None => None
  }
}

///|
fn scalar_anim_source(spec : @core.AnimationSpec) -> Double? {
  match spec.from {
    Some(values) => if values.is_empty() { None } else { Some(values[0]) }
    None => None
  }
}

///|
fn position_anim_target(spec : @core.AnimationSpec) -> (Double, Double)? {
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
fn position_anim_source(spec : @core.AnimationSpec) -> (Double, Double)? {
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
fn scalar_state_value(
  scalars : @core.ScalarState,
  prop : @core.AnimProp,
) -> Double {
  match prop {
    @core.AnimProp::Opacity => scalars.opacity
    @core.AnimProp::Scale => scalars.scale
    @core.AnimProp::Rotation => scalars.rotation
    @core.AnimProp::Blur => scalars.blur
    @core.AnimProp::Brightness => scalars.brightness
    @core.AnimProp::Contrast => scalars.contrast
    @core.AnimProp::Saturation => scalars.saturation
    @core.AnimProp::Gamma => scalars.gamma
    @core.AnimProp::ColorRed => scalars.color_r
    @core.AnimProp::ColorGreen => scalars.color_g
    @core.AnimProp::ColorBlue => scalars.color_b
    @core.AnimProp::Position => 0.0
  }
}

///|
fn animation_key(target : String, prop : @core.AnimProp) -> String {
  let suffix = match prop {
    @core.AnimProp::Position => "position"
    @core.AnimProp::Scale => "scale"
    @core.AnimProp::Opacity => "opacity"
    @core.AnimProp::Rotation => "rotation"
    @core.AnimProp::Blur => "blur"
    @core.AnimProp::Brightness => "brightness"
    @core.AnimProp::Contrast => "contrast"
    @core.AnimProp::Saturation => "saturation"
    @core.AnimProp::Gamma => "gamma"
    @core.AnimProp::ColorRed => "color_r"
    @core.AnimProp::ColorGreen => "color_g"
    @core.AnimProp::ColorBlue => "color_b"
  }
  "\{target}::\{suffix}"
}

///|
fn lerp(from : Double, to : Double, p : Double) -> Double {
  from + (to - from) * p
}

///|
fn apply_scalar_to_state(
  scalars : @core.ScalarState,
  prop : @core.AnimProp,
  value : Double,
) -> @core.ScalarState {
  match prop {
    @core.AnimProp::Opacity => { ..scalars, opacity: value }
    @core.AnimProp::Scale => { ..scalars, scale: value }
    @core.AnimProp::Rotation => { ..scalars, rotation: value }
    @core.AnimProp::Blur => { ..scalars, blur: value }
    @core.AnimProp::Brightness => { ..scalars, brightness: value }
    @core.AnimProp::Contrast => { ..scalars, contrast: value }
    @core.AnimProp::Saturation => { ..scalars, saturation: value }
    @core.AnimProp::Gamma => { ..scalars, gamma: value }
    @core.AnimProp::ColorRed => { ..scalars, color_r: value }
    @core.AnimProp::ColorGreen => { ..scalars, color_g: value }
    @core.AnimProp::ColorBlue => { ..scalars, color_b: value }
    @core.AnimProp::Position => scalars
  }
}

///|
fn apply_figure_animation(
  placement : @core.FigurePlacement,
  prop : @core.AnimProp,
  values : Array[Double],
) -> @core.FigurePlacement {
  match prop {
    @core.AnimProp::Position =>
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
    @core.AnimProp::Position => background
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
  match spec.prop {
    @core.AnimProp::Position => {
      let to = position_anim_target(spec)
      if to is None {
        return
      }
      let from = match position_anim_source(spec) {
        Some(pair) => Some(pair)
        None =>
          match figure {
            Some(placement) =>
              match placement.pos {
                Custom(x, y) => Some((x, y))
                _ => None
              }
            None => None
          }
      }
      match (from, to) {
        (Some((fx, fy)), Some((tx, ty))) =>
          self.active_animations.set(animation_key(target, spec.prop), {
            target,
            prop: spec.prop,
            easing: spec.easing,
            duration_ms,
            from: [fx, fy],
            to: [tx, ty],
            elapsed_ms: 0,
          })
        _ => ()
      }
    }
    _ => {
      let to = scalar_anim_target(spec)
      if to is None {
        return
      }
      let from = match scalar_anim_source(spec) {
        Some(value) => Some(value)
        None =>
          match figure {
            Some(placement) =>
              Some(scalar_state_value(placement.scalars, spec.prop))
            None =>
              match background {
                Some(state) =>
                  Some(scalar_state_value(state.scalars, spec.prop))
                None => None
              }
          }
      }
      match (from, to) {
        (Some(f), Some(t)) =>
          self.active_animations.set(animation_key(target, spec.prop), {
            target,
            prop: spec.prop,
            easing: spec.easing,
            duration_ms,
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
  let values : Array[Double] = []
  let p = progress.clamp(min=0.0, max=1.0)
  for i in 0..<anim.from.length() {
    values.push(lerp(anim.from[i], anim.to[i], p))
  }
  values
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
      self.config.animation_step_ms
    }
    anim.elapsed_ms = anim.elapsed_ms + step_ms
    let (progress, done) = animation_progress(
      anim.elapsed_ms,
      0,
      anim.duration_ms,
      anim.easing,
    )
    let values = animation_values(anim, progress)
    if next_figures.get(anim.target) is Some(placement) {
      next_figures.set(
        anim.target,
        apply_figure_animation(placement, anim.prop, values),
      )
    } else {
      match next_background {
        Some(state) if state.id == anim.target =>
          next_background = Some(
            apply_background_animation(state, anim.prop, values),
          )
        _ => ()
      }
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
      match background {
        Some(state) if state.id == target => Some(state)
        _ => None
      },
    )
  }

  let (next_figures, next_background) = self.advance_active_animations(
    figures, background, skip_mode,
  )

  match next_background {
    Some(state) =>
      extension.apply(RenderExtensionUpdate::SetBackgroundState(state))
    None => ()
  }

  for entry in next_figures {
    let (target, placement) = entry
    extension.apply(
      RenderExtensionUpdate::SetFigurePlacement(target, placement),
    )
  }
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
  match snapshot.background {
    Some(state) =>
      match self.background_handles.get(state.id) {
        Some(handle) =>
          commands.push(image_command(handle, bg_rect, state.scalars.opacity))
        None =>
          commands.push(
            placeholder_rect_command(
              bg_rect,
              base_color_with_alpha(
                self.config.placeholder_background_color,
                state.scalars.opacity,
              ),
            ),
          )
      }
    None => ()
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
    match self.figure_handles.get(id) {
      Some(handle) =>
        commands.push(image_command(handle, rect, placement.scalars.opacity))
      None =>
        commands.push(
          placeholder_rect_command(
            rect,
            base_color_with_alpha(
              self.config.placeholder_figure_color,
              placement.scalars.opacity,
            ),
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
  let frame2d : @selene_render2d_types.RenderFrame2D = {
    world_commands: self.build_world_commands(snapshot),
    ui_commands: [],
  }
  let frame = { ..@selene_render_pipeline.empty_render_frame(), frame2d, }
  @selene_platform_render.submit_frame(frame)
}

///|
pub fn SelenePresenter::submit_core_snapshot(
  self : SelenePresenter,
  snapshot : CoreRenderSnapshot,
) -> Unit {
  self.submit_frame(snapshot)
}

///|
pub fn SelenePresenter::as_core_render_sync_hook(
  self : SelenePresenter,
) -> RenderSyncHook {
  (snapshot, _skip_mode) => self.submit_frame(snapshot)
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
