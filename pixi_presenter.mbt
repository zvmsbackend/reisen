///|
/// Pixi presenter that mirrors `Director` render state.
///
/// Current migration scope:
/// - background + figure rendering
/// - layer ordering
/// - position/scale/opacity/rotation animation playback

///|
pub struct PixiPresenterConfig {
  antialias : Bool
  background_alpha : Double
  resolution : Double
  auto_density : Bool
  position_entry_offset_ratio : Double
  scale_entry_from : Double
} derive(Show, Eq)

///|
pub fn pixi_presenter_default_config() -> PixiPresenterConfig {
  {
    antialias: true,
    background_alpha: 0.0,
    resolution: 1.0,
    auto_density: true,
    position_entry_offset_ratio: 0.04,
    scale_entry_from: 0.0,
  }
}

///|
pub type PixiEffectApply = (PixiSprite, Array[EffectParam], Int) -> Bool

///|
let pixi_effect_appliers : Map[String, PixiEffectApply] = {}

///|
let pixi_effect_defaults : Map[String, Array[EffectParam]] = {}

///|
pub fn register_pixi_effect(
  id : String,
  apply : PixiEffectApply,
  defaults? : Array[EffectParam] = [],
) -> Unit {
  pixi_effect_appliers.set(id, apply)
  pixi_effect_defaults.set(id, defaults)
}

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
priv struct PixiPresenter {
  store : AssetStore
  config : PixiPresenterConfig
  app : PixiApplication
  stage : PixiContainer
  textures : Map[String, PixiTexture]
  texture_sizes : Map[String, (Double, Double)]
  figure_sprites : Map[String, PixiSprite]
  mut background_sprite : PixiSprite?
  mut background_cover_sprite : PixiSprite?
  blur_filters : Map[String, PixiBlurFilter]
  color_filters : Map[String, PixiColorMatrixFilter]
  mut last_background_id : String?
  mut render_epoch : String?
  mut animation_cursor : Int
  mut timeline_ms : Int
  mut last_sync_ms : Int
  opacity_anims : Map[String, ScalarAnim]
  position_anims : Map[String, PositionAnim]
  scale_anims : Map[String, ScaleAnim]
  rotation_anims : Map[String, ScalarAnim]
  blur_anims : Map[String, ScalarAnim]
  brightness_anims : Map[String, ScalarAnim]
  contrast_anims : Map[String, ScalarAnim]
  saturation_anims : Map[String, ScalarAnim]
  gamma_anims : Map[String, ScalarAnim]
  color_r_anims : Map[String, ScalarAnim]
  color_g_anims : Map[String, ScalarAnim]
  color_b_anims : Map[String, ScalarAnim]
  effect_start_ms : Map[String, Int]
  effect_signatures : Map[String, String]
  effect_from_params : Map[String, Array[EffectParam]]
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
extern "js" fn pixi_now_ms() -> Int =
  #| () => Math.floor((globalThis.performance?.now?.() ?? Date.now()))

///|
extern "js" fn set_canvas_size(
  canvas_id : String,
  width : Int,
  height : Int,
) -> Unit =
  #| (canvas_id, width, height) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const canvas = doc.getElementById(canvas_id);
  #|   if (!canvas) return;
  #|   canvas.width = width;
  #|   canvas.height = height;
  #|   canvas.style.width = width + 'px';
  #|   canvas.style.height = height + 'px';
  #| }

///|
extern "js" fn set_canvas_element_size(
  canvas : PixiCanvas,
  width : Int,
  height : Int,
) -> Unit =
  #| (canvas, width, height) => {
  #|   if (!canvas) return;
  #|   canvas.width = width;
  #|   canvas.height = height;
  #|   canvas.style.width = width + 'px';
  #|   canvas.style.height = height + 'px';
  #| }

///|
fn figure_rect(
  pos : Position,
  viewport_w : Double,
  viewport_h : Double,
) -> (Double, Double, Double, Double) {
  let w = viewport_w * 0.40
  let h = viewport_h * 0.90
  match pos {
    Left => (viewport_w * 0.05, 0.0, w, h)
    Center => ((viewport_w - w) / 2.0, 0.0, w, h)
    Right => (viewport_w * 0.55, 0.0, w, h)
    Custom(x, y) => (x * viewport_w, y * viewport_h, w, h)
  }
}

///|
fn fit_background(
  image_id : String,
  canvas_w : Double,
  canvas_h : Double,
  sizes : Map[String, (Double, Double)],
) -> (Double, Double, Double, Double) {
  match sizes.get(image_id) {
    Some((img_w, img_h)) => {
      let canvas_ratio = canvas_w / canvas_h
      let img_ratio = img_w / img_h
      let (scale_w, scale_h) = if img_ratio > canvas_ratio {
        let scale = canvas_w / img_w
        (canvas_w, img_h * scale)
      } else {
        let scale = canvas_h / img_h
        (img_w * scale, canvas_h)
      }
      let x = (canvas_w - scale_w) / 2.0
      let y = (canvas_h - scale_h) / 2.0
      (x, y, scale_w, scale_h)
    }
    None => (0.0, 0.0, canvas_w, canvas_h)
  }
}

///|
fn fit_background_cover(
  image_id : String,
  canvas_w : Double,
  canvas_h : Double,
  sizes : Map[String, (Double, Double)],
) -> (Double, Double, Double, Double) {
  match sizes.get(image_id) {
    Some((img_w, img_h)) => {
      let canvas_ratio = canvas_w / canvas_h
      let img_ratio = img_w / img_h
      let (scale_w, scale_h) = if img_ratio > canvas_ratio {
        let scale = canvas_h / img_h
        (img_w * scale, canvas_h)
      } else {
        let scale = canvas_w / img_w
        (canvas_w, img_h * scale)
      }
      let x = (canvas_w - scale_w) / 2.0
      let y = (canvas_h - scale_h) / 2.0
      (x, y, scale_w, scale_h)
    }
    None => (0.0, 0.0, canvas_w, canvas_h)
  }
}

///|
fn fit_figure(
  image_id : String,
  max_w : Double,
  max_h : Double,
  sizes : Map[String, (Double, Double)],
) -> (Double, Double) {
  match sizes.get(image_id) {
    Some((img_w, img_h)) => {
      let img_ratio = img_w / img_h
      let max_ratio = max_w / max_h
      if img_ratio > max_ratio {
        let scale = max_w / img_w
        (max_w, img_h * scale)
      } else {
        let scale = max_h / img_h
        (img_w * scale, max_h)
      }
    }
    None => (max_w, max_h)
  }
}

///|
fn easing_apply(easing : Easing, x : Double) -> Double {
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
fn animation_progress(
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
  match values {
    Some(arr) => if idx < arr.length() { Some(arr[idx]) } else { None }
    None => None
  }
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
      let from_x = anim.from_x.unwrap_or(0.0) * viewport_w
      let from_y = anim.from_y.unwrap_or(0.0) * viewport_h
      let to_x = anim.to_x.unwrap_or(0.0) * viewport_w
      let to_y = anim.to_y.unwrap_or(0.0) * viewport_h
      let start_x = x + from_x
      let start_y = y + from_y
      let end_x = x + to_x
      let end_y = y + to_y
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

///|
fn scale_rect_with_anchor(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  scale : Double,
  anchor_x : Double,
  anchor_y : Double,
) -> (Double, Double, Double, Double) {
  let sw = w * scale
  let sh = h * scale
  let ax = x + w * anchor_x
  let ay = y + h * anchor_y
  let sx = ax - sw * anchor_x
  let sy = ay - sh * anchor_y
  (sx, sy, sw, sh)
}

///|
fn clamp01(v : Double) -> Double {
  if v < 0.0 {
    0.0
  } else if v > 1.0 {
    1.0
  } else {
    v
  }
}

///|
fn rgb_multiplier_to_tint(r : Double, g : Double, b : Double) -> Int {
  let rr = (clamp01(r) * 255.0).to_int()
  let gg = (clamp01(g) * 255.0).to_int()
  let bb = (clamp01(b) * 255.0).to_int()
  (rr << 16) | (gg << 8) | bb
}

///|
fn effect_key(target : String, id : String) -> String {
  target + "::" + id
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
  let params : Array[String] = []
  for entry in spec.params {
    let (name, value) = entry
    params.push(name + "=" + value.to_string())
  }
  spec.id + "|" + phase + "|" + duration + "|" + easing + "|" + params.join(";")
}

///|
fn PixiPresenter::new(
  canvas : PixiCanvas,
  store : AssetStore,
  config : PixiPresenterConfig,
) -> PixiPresenter {
  let app = pixi_new_application()
  ignore(
    app.init_with_canvas_promise(
      @js.Value::cast_from(canvas),
      window_inner_width().to_int(),
      window_inner_height().to_int(),
      config.antialias,
      config.background_alpha,
      config.resolution,
      config.auto_density,
    ),
  )
  let stage = app.stage()
  stage.set_sortable_children(true)
  {
    store,
    config,
    app,
    stage,
    textures: {},
    texture_sizes: {},
    figure_sprites: {},
    background_sprite: None,
    background_cover_sprite: None,
    blur_filters: {},
    color_filters: {},
    last_background_id: None,
    render_epoch: None,
    animation_cursor: 0,
    timeline_ms: 0,
    last_sync_ms: 0,
    opacity_anims: {},
    position_anims: {},
    scale_anims: {},
    rotation_anims: {},
    blur_anims: {},
    brightness_anims: {},
    contrast_anims: {},
    saturation_anims: {},
    gamma_anims: {},
    color_r_anims: {},
    color_g_anims: {},
    color_b_anims: {},
    effect_start_ms: {},
    effect_signatures: {},
    effect_from_params: {},
  }
}

///|
fn PixiPresenter::update_timeline(self : PixiPresenter) -> Unit {
  let now = pixi_now_ms()
  if self.last_sync_ms <= 0 {
    self.last_sync_ms = now
    return
  }
  let dt = now - self.last_sync_ms
  self.last_sync_ms = now
  if dt > 0 {
    self.timeline_ms += dt
  }
}

///|
fn PixiPresenter::reset_render_state(self : PixiPresenter) -> Unit {
  self.animation_cursor = 0
  self.timeline_ms = 0
  self.last_sync_ms = 0
  self.last_background_id = None
  self.opacity_anims.clear()
  self.position_anims.clear()
  self.scale_anims.clear()
  self.rotation_anims.clear()
  self.blur_anims.clear()
  self.brightness_anims.clear()
  self.contrast_anims.clear()
  self.saturation_anims.clear()
  self.gamma_anims.clear()
  self.color_r_anims.clear()
  self.color_g_anims.clear()
  self.color_b_anims.clear()
  self.effect_start_ms.clear()
  self.effect_signatures.clear()
  self.effect_from_params.clear()
  self.blur_filters.clear()
  self.color_filters.clear()
  match self.background_sprite {
    Some(sprite) => sprite.set_visible(false)
    None => ()
  }
  match self.background_cover_sprite {
    Some(sprite) => sprite.set_visible(false)
    None => ()
  }
  let ids : Array[String] = []
  for id in self.figure_sprites.keys() {
    ids.push(id)
  }
  for id in ids {
    match self.figure_sprites.get(id) {
      Some(sprite) => self.stage.remove_sprite(sprite)
      None => ()
    }
    self.figure_sprites.remove(id)
  }
}

///|
fn PixiPresenter::remove_target_animation_state(
  self : PixiPresenter,
  id : String,
) -> Unit {
  self.opacity_anims.remove(id)
  self.position_anims.remove(id)
  self.scale_anims.remove(id)
  self.rotation_anims.remove(id)
  self.blur_anims.remove(id)
  self.brightness_anims.remove(id)
  self.contrast_anims.remove(id)
  self.saturation_anims.remove(id)
  self.gamma_anims.remove(id)
  self.color_r_anims.remove(id)
  self.color_g_anims.remove(id)
  self.color_b_anims.remove(id)
  let prefix = id + "::"
  let keys : Array[String] = []
  for key in self.effect_start_ms.keys() {
    if key.has_prefix(prefix) {
      keys.push(key)
    }
  }
  for key in keys {
    self.effect_start_ms.remove(key)
    self.effect_signatures.remove(key)
    self.effect_from_params.remove(key)
  }
}

///|
fn PixiPresenter::apply_scalar_visuals(
  self : PixiPresenter,
  key : String,
  sprite : PixiSprite,
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
  let tint = rgb_multiplier_to_tint(
    scalar_acc.color_r,
    scalar_acc.color_g,
    scalar_acc.color_b,
  )
  sprite.set_tint(tint)
  let need_color = scalar_acc.brightness != 1.0 ||
    scalar_acc.contrast != 1.0 ||
    scalar_acc.saturation != 1.0 ||
    scalar_acc.gamma != 1.0
  let filters : Array[@js.Value] = []
  if blur_value > 0.0 {
    let blur_filter = match self.blur_filters.get(key) {
      Some(filter) => filter
      None => {
        let filter = pixi_new_blur_filter()
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
        let filter = pixi_new_color_matrix_filter()
        self.color_filters.set(key, filter)
        filter
      }
    }
    color_filter.apply_adjustments(
      scalar_acc.brightness,
      scalar_acc.contrast,
      scalar_acc.saturation,
      scalar_acc.gamma,
    )
    filters.push(@js.Value::cast_from(color_filter))
  }
  sprite.set_filters(filters)
}

///|
fn PixiPresenter::apply_effects_to_sprite(
  self : PixiPresenter,
  target_id : String,
  sprite : PixiSprite,
  effects : Array[EffectSpec],
  active_effects : Set[String],
) -> Bool {
  let mut skip_base = false
  for spec in effects {
    let key = effect_key(target_id, spec.id)
    let signature = effect_signature(spec)
    active_effects.add(key)
    match self.effect_signatures.get(key) {
      Some(prev) =>
        if prev != signature {
          self.effect_signatures.set(key, signature)
          self.effect_start_ms.set(key, self.timeline_ms)
          let defaults = match pixi_effect_defaults.get(spec.id) {
            Some(list) if list.length() > 0 => list
            _ => spec.params
          }
          self.effect_from_params.set(key, defaults)
        }
      None => {
        self.effect_signatures.set(key, signature)
        self.effect_start_ms.set(key, self.timeline_ms)
        let defaults = match pixi_effect_defaults.get(spec.id) {
          Some(list) if list.length() > 0 => list
          _ => spec.params
        }
        self.effect_from_params.set(key, defaults)
      }
    }
    let progress = match (spec.duration_ms, self.effect_start_ms.get(key)) {
      (Some(duration), Some(start_ms)) => {
        let (p, done) = animation_progress(
          self.timeline_ms,
          start_ms,
          duration,
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
    let render_params = if spec.duration_ms is Some(_) {
      let from = self.effect_from_params.get_or_default(key, [])
      let from_map = Map::from_array(from)
      spec.params.map(entry => {
        let (name, value) = entry
        let start = from_map.get(name).unwrap_or(value)
        let animated = start + (value - start) * progress
        (name, animated)
      })
    } else {
      spec.params
    }
    if spec.phase is Pre {
      match pixi_effect_appliers.get(spec.id) {
        Some(apply) =>
          if apply(sprite, render_params, self.timeline_ms) {
            skip_base = true
          }
        None => ()
      }
    }
  }
  skip_base
}

///|
fn PixiPresenter::texture_for(
  self : PixiPresenter,
  id : String,
) -> PixiTexture? {
  match self.textures.get(id) {
    Some(texture) => Some(texture)
    None => {
      let maybe_texture = match self.store.get_image(id) {
        Some(image) => Some(pixi_texture_from(@js.Value::cast_from(image)))
        None =>
          match self.store.get_video(id) {
            Some(video) => Some(pixi_texture_from(@js.Value::cast_from(video)))
            None => None
          }
      }
      match maybe_texture {
        Some(texture) => {
          let w = texture.width()
          let h = texture.height()
          self.textures.set(id, texture)
          self.texture_sizes.set(id, (w, h))
          Some(texture)
        }
        None => None
      }
    }
  }
}

///|
fn PixiPresenter::refresh_video_texture_if_any(
  self : PixiPresenter,
  id : String,
) -> Unit {
  match self.store.get_video(id) {
    Some(_) =>
      match self.textures.get(id) {
        Some(texture) => texture.update()
        None => ()
      }
    None => ()
  }
}

///|
fn[T] PixiPresenter::pull_new_animations(
  self : PixiPresenter,
  director : Director[T],
) -> Unit {
  let all = director.animations()
  for i, entry in all {
    if i < self.animation_cursor {
      continue
    }
    let (target, spec) = entry
    let target_map = match spec.prop {
      Position => {
        self.position_anims.set(target, {
          start_ms: self.timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from_x: anim_value(spec.from, 0),
          from_y: anim_value(spec.from, 1),
          to_x: anim_value(spec.to, 0),
          to_y: anim_value(spec.to, 1),
        })
        continue
      }
      Scale => {
        let (anchor_x, anchor_y) = anim_anchor(spec.anchor)
        self.scale_anims.set(target, {
          start_ms: self.timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from: anim_value(spec.from, 0),
          to: anim_value(spec.to, 0),
          anchor_x,
          anchor_y,
        })
        continue
      }
      Opacity => self.opacity_anims
      Rotation => self.rotation_anims
      Blur => self.blur_anims
      Brightness => self.brightness_anims
      Contrast => self.contrast_anims
      Saturation => self.saturation_anims
      Gamma => self.gamma_anims
      ColorRed => self.color_r_anims
      ColorGreen => self.color_g_anims
      ColorBlue => self.color_b_anims
    }
    target_map[target] = {
      start_ms: self.timeline_ms,
      duration_ms: spec.duration_ms,
      easing: spec.easing,
      from: anim_value(spec.from, 0),
      to: anim_value(spec.to, 0),
    }
  }
  self.animation_cursor = all.length()
}

///|
fn PixiPresenter::update_scalar_state(
  self : PixiPresenter,
  init_state : ScalarState,
  id : String,
) -> (Bool, ScalarState, ScalarAccumulator) {
  let mut changed = false
  let mut next_state = init_state
  let scalar_acc = ScalarAccumulator::from_scalar_state(init_state)
  fn apply_scalar_anim_to_state(
    anim_map : Map[String, ScalarAnim],
    get_value : (ScalarState) -> Double,
    set_value : (ScalarState, Double) -> ScalarState,
    set_acc : (Double) -> Unit,
  ) -> Unit {
    match anim_map.get(id) {
      Some(anim) => {
        let (animated, done) = apply_scalar_animation(
          get_value(next_state),
          self.timeline_ms,
          anim,
        )
        set_acc(animated)
        if done {
          anim_map.remove(id)
          match anim.to {
            Some(value) => {
              changed = true
              next_state = set_value(next_state, value)
            }
            None => ()
          }
        }
      }
      None => set_acc(get_value(next_state))
    }
  }
  apply_scalar_anim_to_state(
    self.opacity_anims,
    s => s.opacity,
    (s, v) => { ..s, opacity: v },
    v => scalar_acc.opacity = v,
  )
  apply_scalar_anim_to_state(
    self.rotation_anims,
    s => s.rotation,
    (s, v) => { ..s, rotation: v },
    v => scalar_acc.rotation = v,
  )
  apply_scalar_anim_to_state(
    self.blur_anims,
    s => s.blur,
    (s, v) => { ..s, blur: v },
    v => scalar_acc.blur = v,
  )
  apply_scalar_anim_to_state(
    self.brightness_anims,
    s => s.brightness,
    (s, v) => { ..s, brightness: v },
    v => scalar_acc.brightness = v,
  )
  apply_scalar_anim_to_state(
    self.contrast_anims,
    s => s.contrast,
    (s, v) => { ..s, contrast: v },
    v => scalar_acc.contrast = v,
  )
  apply_scalar_anim_to_state(
    self.saturation_anims,
    s => s.saturation,
    (s, v) => { ..s, saturation: v },
    v => scalar_acc.saturation = v,
  )
  apply_scalar_anim_to_state(
    self.gamma_anims,
    s => s.gamma,
    (s, v) => { ..s, gamma: v },
    v => scalar_acc.gamma = v,
  )
  apply_scalar_anim_to_state(
    self.color_r_anims,
    s => s.color_r,
    (s, v) => { ..s, color_r: v },
    v => scalar_acc.color_r = v,
  )
  apply_scalar_anim_to_state(
    self.color_g_anims,
    s => s.color_g,
    (s, v) => { ..s, color_g: v },
    v => scalar_acc.color_g = v,
  )
  apply_scalar_anim_to_state(
    self.color_b_anims,
    s => s.color_b,
    (s, v) => { ..s, color_b: v },
    v => scalar_acc.color_b = v,
  )
  (changed, next_state, scalar_acc)
}

///|
fn apply_sprite_transform(
  sprite : PixiSprite,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  rotation : Double,
  opacity : Double,
  visible : Bool,
  z_index : Int,
) -> Unit {
  sprite.set_size(w, h)
  sprite.set_position(x + w / 2.0, y + h / 2.0)
  sprite.set_rotation(rotation)
  sprite.set_alpha(opacity)
  sprite.set_visible(visible)
  sprite.set_z_index(z_index)
}

///|
fn[T] PixiPresenter::sync_background(
  self : PixiPresenter,
  director : Director[T],
  viewport_w : Double,
  viewport_h : Double,
  active_effects : Set[String],
) -> Unit {
  match director.background_state() {
    Some(bg_state) => {
      let id = bg_state.id
      match self.last_background_id {
        Some(prev) => if prev != id { self.remove_target_animation_state(prev) }
        None => ()
      }
      self.last_background_id = Some(id)
      match self.texture_for(id) {
        Some(texture) => {
          self.refresh_video_texture_if_any(id)
          let cover_sprite = match self.background_cover_sprite {
            Some(sprite) => sprite
            None => {
              let sprite = pixi_new_sprite(texture)
              sprite.set_anchor(0.5, 0.5)
              self.stage.add_sprite(sprite)
              self.background_cover_sprite = Some(sprite)
              sprite
            }
          }
          let sprite = match self.background_sprite {
            Some(sprite) => sprite
            None => {
              let sprite = pixi_new_sprite(texture)
              sprite.set_anchor(0.5, 0.5)
              self.stage.add_sprite(sprite)
              self.background_sprite = Some(sprite)
              sprite
            }
          }
          cover_sprite.set_texture(texture)
          sprite.set_texture(texture)
          let (cover_x, cover_y, cover_w, cover_h) = fit_background_cover(
            id,
            viewport_w,
            viewport_h,
            self.texture_sizes,
          )
          let (base_x, base_y, base_w, base_h) = fit_background(
            id,
            viewport_w,
            viewport_h,
            self.texture_sizes,
          )
          let mut next_bg_state = bg_state
          let mut update_bg_state = false
          let mut x = base_x
          let mut y = base_y
          let mut w = base_w
          let mut h = base_h
          let base_scale = bg_state.scalars.scale
          if base_scale != 1.0 {
            let (sx, sy, sw, sh) = scale_rect_with_anchor(
              x, y, w, h, base_scale, 0.5, 0.5,
            )
            x = sx
            y = sy
            w = sw
            h = sh
          }
          match self.position_anims.get(id) {
            Some(anim) => {
              let (ax, ay, done) = apply_position_animation(
                x,
                y,
                self.config.position_entry_offset_ratio,
                viewport_h,
                viewport_w,
                self.timeline_ms,
                anim,
              )
              x = ax
              y = ay
              if done {
                self.position_anims.remove(id)
              }
            }
            None => ()
          }
          match self.scale_anims.get(id) {
            Some(anim) => {
              let (sx, sy, sw, sh, done) = apply_scale_animation(
                base_x,
                base_y,
                base_w,
                base_h,
                bg_state.scalars.scale,
                self.config.scale_entry_from,
                self.timeline_ms,
                anim,
              )
              x = sx
              y = sy
              w = sw
              h = sh
              if done {
                self.scale_anims.remove(id)
                match anim.to {
                  Some(value) => {
                    next_bg_state = {
                      id: next_bg_state.id,
                      scalars: { ..next_bg_state.scalars, scale: value },
                    }
                    update_bg_state = true
                  }
                  None => ()
                }
              }
            }
            None => ()
          }
          let (changed, next_scalars, scalar_acc) = self.update_scalar_state(
            next_bg_state.scalars,
            id,
          )
          let next_bg_state = { ..next_bg_state, scalars: next_scalars }
          update_bg_state = update_bg_state || changed
          if update_bg_state {
            director.set_background_state(next_bg_state)
          }
          apply_sprite_transform(
            cover_sprite,
            cover_x,
            cover_y,
            cover_w,
            cover_h,
            scalar_acc.rotation,
            scalar_acc.opacity,
            true,
            -1001,
          )
          self.apply_scalar_visuals(
            id + "#cover",
            cover_sprite,
            scalar_acc,
            extra_blur=2.0,
          )
          let effects = director.effects(id)
          let cover_skip = self.apply_effects_to_sprite(
            id, cover_sprite, effects, active_effects,
          )
          if cover_skip {
            cover_sprite.set_visible(false)
          }
          apply_sprite_transform(
            sprite,
            x,
            y,
            w,
            h,
            scalar_acc.rotation,
            scalar_acc.opacity,
            true,
            -1000,
          )
          self.apply_scalar_visuals(id, sprite, scalar_acc)
          let base_skip = self.apply_effects_to_sprite(
            id, sprite, effects, active_effects,
          )
          if base_skip {
            sprite.set_visible(false)
          }
        }
        None => {
          self.last_background_id = None
          match self.background_cover_sprite {
            Some(sprite) => sprite.set_visible(false)
            None => ()
          }
          match self.background_sprite {
            Some(sprite) => sprite.set_visible(false)
            None => ()
          }
        }
      }
    }
    None => {
      self.last_background_id = None
      match self.background_cover_sprite {
        Some(sprite) => sprite.set_visible(false)
        None => ()
      }
      match self.background_sprite {
        Some(sprite) => sprite.set_visible(false)
        None => ()
      }
    }
  }
}

///|
fn[T] PixiPresenter::sync_figures(
  self : PixiPresenter,
  director : Director[T],
  viewport_w : Double,
  viewport_h : Double,
  active_effects : Set[String],
) -> Unit {
  let figures = director.figures()
  let stale_ids : Array[String] = []
  for id in self.figure_sprites.keys() {
    if !figures.contains(id) {
      stale_ids.push(id)
    }
  }
  for id in stale_ids {
    match self.figure_sprites.get(id) {
      Some(sprite) => self.stage.remove_sprite(sprite)
      None => ()
    }
    self.figure_sprites.remove(id)
    self.remove_target_animation_state(id)
    self.blur_filters.remove(id)
    self.color_filters.remove(id)
  }

  let updated_figures : Array[(String, FigurePlacement)] = []
  let finished_position : Array[String] = []
  let finished_scale : Array[String] = []

  for id, placement in figures {
    match self.texture_for(id) {
      Some(texture) => {
        self.refresh_video_texture_if_any(id)
        let sprite = match self.figure_sprites.get(id) {
          Some(sprite) => sprite
          None => {
            let sprite = pixi_new_sprite(texture)
            sprite.set_anchor(0.5, 0.5)
            self.stage.add_sprite(sprite)
            self.figure_sprites.set(id, sprite)
            sprite
          }
        }
        sprite.set_texture(texture)
        let (base_x, base_y, max_w, max_h) = figure_rect(
          placement.pos,
          viewport_w,
          viewport_h,
        )
        let (actual_w, actual_h) = fit_figure(
          id,
          max_w,
          max_h,
          self.texture_sizes,
        )
        let base_scale = placement.scalars.scale
        let base_scaled_w = actual_w * base_scale
        let base_scaled_h = actual_h * base_scale
        let (aligned_x, aligned_y) = match placement.pos {
          Center =>
            (
              (viewport_w - base_scaled_w) / 2.0,
              base_y + (max_h - base_scaled_h) / 2.0,
            )
          Left | Right =>
            (
              base_x + (max_w - base_scaled_w) / 2.0,
              base_y + (max_h - base_scaled_h) / 2.0,
            )
          _ => (base_x, base_y)
        }

        let mut next_placement = placement
        let mut update_placement = false
        let (x1, y1) = match self.position_anims.get(id) {
          Some(anim) => {
            let (ax, ay, done) = apply_position_animation(
              aligned_x,
              aligned_y,
              self.config.position_entry_offset_ratio,
              viewport_h,
              viewport_w,
              self.timeline_ms,
              anim,
            )
            if done {
              finished_position.push(id)
              let has_custom = anim.from_x is Some(_) ||
                anim.from_y is Some(_) ||
                anim.to_x is Some(_) ||
                anim.to_y is Some(_)
              if has_custom {
                next_placement = {
                  ..next_placement,
                  pos: Custom(ax / viewport_w, ay / viewport_h),
                }
                update_placement = true
              }
            }
            (ax, ay)
          }
          None => (aligned_x, aligned_y)
        }

        let (x, y, w, h) = match self.scale_anims.get(id) {
          Some(anim) => {
            let (sx, sy, sw, sh, done) = apply_scale_animation(
              aligned_x,
              aligned_y,
              actual_w,
              actual_h,
              next_placement.scalars.scale,
              self.config.scale_entry_from,
              self.timeline_ms,
              anim,
            )
            if done {
              finished_scale.push(id)
              let anchor_changed = anim.anchor_x != 0.5 || anim.anchor_y != 0.5
              match anim.to {
                Some(value) => {
                  let next_pos = if anchor_changed {
                    Position::Custom(sx / viewport_w, sy / viewport_h)
                  } else {
                    next_placement.pos
                  }
                  next_placement = {
                    pos: next_pos,
                    layer: next_placement.layer,
                    scalars: { ..next_placement.scalars, scale: value },
                  }
                  update_placement = true
                }
                None => ()
              }
            }
            (sx, sy, sw, sh)
          }
          None => (x1, y1, base_scaled_w, base_scaled_h)
        }

        let (changed, scalar_state, scalar_acc) = self.update_scalar_state(
          next_placement.scalars,
          id,
        )
        if changed {
          next_placement = { ..next_placement, scalars: scalar_state }
          update_placement = true
        }

        apply_sprite_transform(
          sprite,
          x,
          y,
          w,
          h,
          scalar_acc.rotation,
          scalar_acc.opacity,
          true,
          placement.layer,
        )
        self.apply_scalar_visuals(id, sprite, scalar_acc)
        let effects = director.effects(id)
        let skip = self.apply_effects_to_sprite(
          id, sprite, effects, active_effects,
        )
        if skip {
          sprite.set_visible(false)
        }
        if update_placement {
          updated_figures.push((id, next_placement))
        }
      }
      None =>
        match self.figure_sprites.get(id) {
          Some(sprite) => sprite.set_visible(false)
          None => ()
        }
    }
  }

  for id in finished_position {
    if self.last_background_id != Some(id) {
      self.position_anims.remove(id)
    }
  }
  for id in finished_scale {
    if self.last_background_id != Some(id) {
      self.scale_anims.remove(id)
    }
  }
  for entry in updated_figures {
    let (id, placement) = entry
    figures.set(id, placement)
  }
}

///|
fn[T] PixiPresenter::sync_noraise(
  self : PixiPresenter,
  director : Director[T],
) -> Unit {
  let epoch = director.render_epoch()
  match self.render_epoch {
    Some(prev) =>
      if prev != epoch {
        self.reset_render_state()
        self.render_epoch = Some(epoch)
      }
    None => self.render_epoch = Some(epoch)
  }

  self.update_timeline()
  self.pull_new_animations(director)
  let active_effects : Set[String] = Set::new()

  let viewport_w = window_inner_width()
  let viewport_h = window_inner_height()
  self.app.renderer_resize(viewport_w.to_int(), viewport_h.to_int())
  self.sync_background(director, viewport_w, viewport_h, active_effects)
  self.sync_figures(director, viewport_w, viewport_h, active_effects)
  for key in self.effect_start_ms.keys() {
    if !active_effects.contains(key) {
      self.effect_start_ms.remove(key)
      self.effect_signatures.remove(key)
      self.effect_from_params.remove(key)
    }
  }
}

///|
fn[T] PixiPresenter::as_render_sync_hook(
  self : PixiPresenter,
) -> RenderSyncHook[T] {
  director => self.sync_noraise(director)
}

///|
pub fn[T] make_pixi_render_sync_hook_from_canvas(
  canvas_id : String,
  store : AssetStore,
) -> RenderSyncHook[T]? {
  make_pixi_render_sync_hook_from_canvas_with_config(
    canvas_id,
    store,
    pixi_presenter_default_config(),
  )
}

///|
pub fn[T] make_pixi_render_sync_hook_from_canvas_with_config(
  canvas_id : String,
  store : AssetStore,
  config : PixiPresenterConfig,
) -> RenderSyncHook[T]? {
  let canvas = get_canvas_by_id(canvas_id)
  match canvas {
    Some(c) =>
      Some(
        make_pixi_render_sync_hook_from_canvas_element_with_config(
          c, store, config,
        ),
      )
    None => None
  }
}

///|
pub fn[T] make_pixi_render_sync_hook_from_canvas_element(
  canvas : PixiCanvas,
  store : AssetStore,
) -> RenderSyncHook[T] {
  make_pixi_render_sync_hook_from_canvas_element_with_config(
    canvas,
    store,
    pixi_presenter_default_config(),
  )
}

///|
pub fn[T] make_pixi_render_sync_hook_from_canvas_element_with_config(
  canvas : PixiCanvas,
  store : AssetStore,
  config : PixiPresenterConfig,
) -> RenderSyncHook[T] {
  let w = window_inner_width()
  let h = window_inner_height()
  set_canvas_element_size(canvas, w.to_int(), h.to_int())
  let presenter = PixiPresenter::new(canvas, store, config)
  presenter.as_render_sync_hook()
}
