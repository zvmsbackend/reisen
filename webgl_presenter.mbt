///|
/// WebGL presenter that converts `Director` render state into draw calls.

///|
priv struct WebglPresenter {
  renderer : Renderer
  store : AssetStore
  textures : Map[String, WebGLTexture]
  texture_sizes : Map[String, (Int, Int)]
  viewport_w : Double
  viewport_h : Double
  config : WebglPresenterConfig
  mut animation_cursor : Int
  mut timeline_ms : Int
  mut last_sync_ms : Int
  opacity_anims : Map[String, OpacityAnim]
  position_anims : Map[String, PositionAnim]
  scale_anims : Map[String, ScaleAnim]
}

///|
pub struct WebglPresenterConfig {
  position_entry_offset_ratio : Double
  scale_entry_from : Double
} derive(Show, Eq)

///|
pub fn webgl_presenter_default_config() -> WebglPresenterConfig {
  { position_entry_offset_ratio: 0.04, scale_entry_from: 0.0 }
}

///|
let default_vert_shader : String =
  #|attribute vec2 a_position;
  #|attribute vec2 a_uv;
  #|uniform mat4 u_model;
  #|varying vec2 v_uv;
  #|void main() {
  #|  gl_Position = u_model * vec4(a_position, 0.0, 1.0);
  #|  v_uv = a_uv;
  #|}

///|
let default_frag_shader : String =
  #|precision mediump float;
  #|varying vec2 v_uv;
  #|uniform sampler2D u_tex;
  #|uniform float u_opacity;
  #|void main() {
  #|  vec4 c = texture2D(u_tex, v_uv);
  #|  gl_FragColor = vec4(c.rgb, c.a * u_opacity);
  #|}

///|
priv struct OpacityAnim {
  start_ms : Int
  duration_ms : Int
  easing : Easing
}

///|
priv struct PositionAnim {
  start_ms : Int
  duration_ms : Int
  easing : Easing
}

///|
priv struct ScaleAnim {
  start_ms : Int
  duration_ms : Int
  easing : Easing
}

///|
extern "js" fn now_ms() -> Int =
  #| () => Math.floor((globalThis.performance?.now?.() ?? Date.now()))

///|
fn webgl_presenter_new(
  gl : WebGL,
  store : AssetStore,
  viewport_w : Double,
  viewport_h : Double,
  config : WebglPresenterConfig,
) -> WebglPresenter raise RenderError {
  let mesh = create_quad_mesh(gl)
  let pipe = create_pipeline(gl, default_vert_shader, default_frag_shader)
  let renderer = renderer_new(gl, mesh, pipe, viewport_w, viewport_h)
  {
    renderer,
    store,
    textures: {},
    texture_sizes: {},
    viewport_w,
    viewport_h,
    config,
    animation_cursor: 0,
    timeline_ms: 0,
    last_sync_ms: 0,
    opacity_anims: {},
    position_anims: {},
    scale_anims: {},
  }
}

///|
fn WebglPresenter::texture_for(
  self : WebglPresenter,
  image_id : String,
) -> WebGLTexture raise RenderError {
  match self.textures.get(image_id) {
    Some(tex) => tex
    None => {
      let (tex, size) = create_texture_from_store(
        self.renderer.gl,
        self.store,
        image_id,
      )
      self.textures.set(image_id, tex)
      self.texture_sizes.set(image_id, size)
      tex
    }
  }
}

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
fn apply_opacity_animation(
  base_opacity : Double,
  now_ms : Int,
  anim : OpacityAnim,
) -> (Double, Bool) {
  let (p, done) = animation_progress(
    now_ms,
    anim.start_ms,
    anim.duration_ms,
    anim.easing,
  )
  if done {
    (base_opacity, true)
  } else {
    (base_opacity * p, false)
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
fn apply_position_animation(
  x : Double,
  y : Double,
  offset_ratio : Double,
  viewport_h : Double,
  now_ms : Int,
  anim : PositionAnim,
) -> (Double, Double, Bool) {
  let (p, done) = animation_progress(
    now_ms,
    anim.start_ms,
    anim.duration_ms,
    anim.easing,
  )
  let start_y = y + viewport_h * offset_ratio
  let animated_y = start_y + (y - start_y) * p
  if done {
    (x, y, true)
  } else {
    (x, animated_y, false)
  }
}

///|
fn apply_scale_animation(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
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
  let s = if done { 1.0 } else { entry_scale + (1.0 - entry_scale) * p }
  let sw = w * s
  let sh = h * s
  let cx = x + w / 2.0
  let cy = y + h / 2.0
  let sx = cx - sw / 2.0
  let sy = cy - sh / 2.0
  if done {
    (x, y, w, h, true)
  } else {
    (sx, sy, sw, sh, false)
  }
}

///|
fn WebglPresenter::update_timeline(self : WebglPresenter) -> Unit {
  let now = now_ms()
  if self.last_sync_ms <= 0 {
    self.last_sync_ms = now
    return
  }
  let dt = now - self.last_sync_ms
  self.last_sync_ms = now
  if dt > 0 {
    self.timeline_ms = self.timeline_ms + dt
  }
}

///|
fn[T] WebglPresenter::pull_new_animations(
  self : WebglPresenter,
  director : Director[T],
) -> Unit {
  let all = director.animations()
  for i, entry in all {
    if i < self.animation_cursor {
      continue
    }
    let (target, spec) = entry
    match spec.prop {
      Opacity =>
        self.opacity_anims.set(target, {
          start_ms: self.timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
        })
      Position =>
        self.position_anims.set(target, {
          start_ms: self.timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
        })
      Scale =>
        self.scale_anims.set(target, {
          start_ms: self.timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
        })
    }
  }
  self.animation_cursor = all.length()
}

///|
fn fit_background(
  image_id : String,
  canvas_w : Double,
  canvas_h : Double,
  sizes : Map[String, (Int, Int)],
) -> (Double, Double, Double, Double) {
  match sizes.get(image_id) {
    Some((img_w, img_h)) => {
      let img_w = img_w.to_double()
      let img_h = img_h.to_double()
      let canvas_ratio = canvas_w / canvas_h
      let img_ratio = img_w / img_h
      let (scale_w, scale_h) = if img_ratio > canvas_ratio {
        // Image is wider - fit to width
        let scale = canvas_w / img_w
        (canvas_w, img_h * scale)
      } else {
        // Image is taller - fit to height
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
fn fit_figure(
  image_id : String,
  max_w : Double,
  max_h : Double,
  sizes : Map[String, (Int, Int)],
) -> (Double, Double) {
  match sizes.get(image_id) {
    Some((img_w, img_h)) => {
      let img_w = img_w.to_double()
      let img_h = img_h.to_double()
      let img_ratio = img_w / img_h
      let max_ratio = max_w / max_h
      if img_ratio > max_ratio {
        // Image is wider relative to max box - fit to width
        let scale = max_w / img_w
        (max_w, img_h * scale)
      } else {
        // Image is taller relative to max box - fit to height
        let scale = max_h / img_h
        (img_w * scale, max_h)
      }
    }
    None => (max_w, max_h)
  }
}

///|
fn[T] WebglPresenter::sync_impl(
  self : WebglPresenter,
  director : Director[T],
) -> Unit raise RenderError {
  let w = window_inner_width()
  let h = window_inner_height()

  self.update_timeline()
  self.pull_new_animations(director)

  self.renderer.clear()
  self.renderer.gl.viewport(0, 0, w.to_int(), h.to_int())
  self.renderer.gl.clear_color(0.0, 0.0, 0.0, 1.0)
  self.renderer.gl.clear(self.renderer.gl.constant("COLOR_BUFFER_BIT"))

  match director.background() {
    Some(bg_id) => {
      let tex = self.texture_for(bg_id)
      let (x, y, bg_w, bg_h) = fit_background(
        bg_id,
        w,
        h,
        self.texture_sizes,
      )
      self.renderer.add({
        texture: tex,
        x,
        y,
        w: bg_w,
        h: bg_h,
        opacity: 1.0,
        layer: -1000,
      })
    }
    None => ()
  }

  let finished_opacity : Array[String] = []
  let finished_position : Array[String] = []
  let finished_scale : Array[String] = []
  for id, placement in director.figures() {
    let tex = self.texture_for(id)
    let (base_x, base_y, max_w, max_h) = figure_rect(
      placement.pos,
      w,
      h,
    )
    let (actual_w, actual_h) = fit_figure(id, max_w, max_h, self.texture_sizes)
    let final_x = match placement.pos {
      Center => (w - actual_w) / 2.0
      Left => base_x + (max_w - actual_w) / 2.0
      Right => base_x + (max_w - actual_w) / 2.0
      _ => base_x
    }
    let (x1, y1) = match self.position_anims.get(id) {
      Some(anim) => {
        let (ax, ay, done) = apply_position_animation(
          base_x,
          base_y,
          self.config.position_entry_offset_ratio,
          h,
          self.timeline_ms,
          anim,
        )
        if done {
          finished_position.push(id)
        }
        (ax, ay)
      }
      None => (final_x, base_y)
    }
    let (x, y, w, h) = match self.scale_anims.get(id) {
      Some(anim) => {
        let (sx, sy, sw, sh, done) = apply_scale_animation(
          x1,
          y1,
          actual_w,
          actual_h,
          self.config.scale_entry_from,
          self.timeline_ms,
          anim,
        )
        if done {
          finished_scale.push(id)
        }
        (sx, sy, sw, sh)
      }
      None => (x1, y1, actual_w, actual_h)
    }
    let opacity = match self.opacity_anims.get(id) {
      Some(anim) => {
        let (animated, done) = apply_opacity_animation(
          placement.opacity,
          self.timeline_ms,
          anim,
        )
        if done {
          finished_opacity.push(id)
        }
        animated
      }
      None => placement.opacity
    }
    self.renderer.add({
      texture: tex,
      x,
      y,
      w,
      h,
      opacity,
      layer: placement.layer,
    })
  }
  for id in finished_opacity {
    self.opacity_anims.remove(id)
  }
  for id in finished_position {
    self.position_anims.remove(id)
  }
  for id in finished_scale {
    self.scale_anims.remove(id)
  }

  self.renderer.draw_with_viewport(w, h)
}

///|
fn[T] WebglPresenter::sync_noraise(
  self : WebglPresenter,
  director : Director[T],
) -> Unit {
  ignore(try? self.sync_impl(director))
}

///|
fn[T] WebglPresenter::as_render_sync_hook(
  self : WebglPresenter,
) -> RenderSyncHook[T] {
  director => self.sync_noraise(director)
}

///|
pub fn[T] make_webgl_render_sync_hook(
  gl : WebGL,
  store : AssetStore,
  viewport_w : Double,
  viewport_h : Double,
) -> RenderSyncHook[T] raise {
  let presenter = webgl_presenter_new(
    gl,
    store,
    viewport_w,
    viewport_h,
    webgl_presenter_default_config(),
  )
  presenter.as_render_sync_hook()
}

///|
pub fn[T] make_webgl_render_sync_hook_with_config(
  gl : WebGL,
  store : AssetStore,
  viewport_w : Double,
  viewport_h : Double,
  config : WebglPresenterConfig,
) -> RenderSyncHook[T] raise {
  let presenter = webgl_presenter_new(gl, store, viewport_w, viewport_h, config)
  presenter.as_render_sync_hook()
}

///|
pub fn[T] make_webgl_render_sync_hook_from_canvas(
  canvas_id : String,
  store : AssetStore,
) -> RenderSyncHook[T]? raise {
  let canvas = get_canvas_by_id(canvas_id)
  let gl = match canvas {
    Some(c) => c.get_webgl_context()
    None => None
  }
  match gl {
    Some(g) => {
      let w = window_inner_width()
      let h = window_inner_height()
      set_canvas_size(canvas_id, w.to_int(), h.to_int())
      Some(make_webgl_render_sync_hook(g, store, w, h))
    }
    None => None
  }
}

///|
pub fn[T] make_webgl_render_sync_hook_from_canvas_with_config(
  canvas_id : String,
  store : AssetStore,
  config : WebglPresenterConfig,
) -> RenderSyncHook[T]? raise {
  let canvas = get_canvas_by_id(canvas_id)
  let gl = match canvas {
    Some(c) => c.get_webgl_context()
    None => None
  }
  match gl {
    Some(g) => {
      let w = window_inner_width()
      let h = window_inner_height()
      set_canvas_size(canvas_id, w.to_int(), h.to_int())
      Some(make_webgl_render_sync_hook_with_config(g, store, w, h, config))
    }
    None => None
  }
}

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
