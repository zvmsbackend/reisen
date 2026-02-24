///|
/// WebGL presenter that converts `Director` render state into draw calls.

///|
priv struct WebglPresenter {
  renderer : Renderer
  store : AssetStore
  textures : Map[String, WebGLTexture]
  texture_sizes : Map[String, (Int, Int)]
  mesh : QuadMesh
  blur_pipe : RenderPipeline
  effect_pipelines : Map[String, CustomEffectPipeline]
  config : WebglPresenterConfig
  mut last_background_id : String?
  mut animation_cursor : Int
  mut timeline_ms : Int
  mut last_sync_ms : Int
  opacity_anims : Map[String, OpacityAnim]
  position_anims : Map[String, PositionAnim]
  scale_anims : Map[String, ScaleAnim]
  rotation_anims : Map[String, OpacityAnim]
  blur_anims : Map[String, OpacityAnim]
  brightness_anims : Map[String, OpacityAnim]
  contrast_anims : Map[String, OpacityAnim]
  saturation_anims : Map[String, OpacityAnim]
  gamma_anims : Map[String, OpacityAnim]
  color_r_anims : Map[String, OpacityAnim]
  color_g_anims : Map[String, OpacityAnim]
  color_b_anims : Map[String, OpacityAnim]
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
priv struct EffectPipeline {
  program : ShaderProgram
  u_model : WebGLUniformLocation?
  u_opacity : WebGLUniformLocation?
  u_texel : WebGLUniformLocation?
  u_blur : WebGLUniformLocation?
  u_brightness : WebGLUniformLocation?
  u_contrast : WebGLUniformLocation?
  u_saturation : WebGLUniformLocation?
  u_gamma : WebGLUniformLocation?
  u_color : WebGLUniformLocation?
}

///|
pub struct EffectDrawable {
  texture : WebGLTexture
  x : Double
  y : Double
  w : Double
  h : Double
  rotation : Double
  opacity : Double
  blur : Double
  brightness : Double
  contrast : Double
  saturation : Double
  gamma : Double
  color_r : Double
  color_g : Double
  color_b : Double
  texel_x : Double
  texel_y : Double
}

///|
pub type EffectApply = (
  WebGL,
  WebGLProgram,
  EffectDrawable,
  Array[EffectParam],
  Int,
) -> Bool

///|
priv struct CustomEffectPipeline {
  pipe : EffectPipeline
  apply : EffectApply
}

///|
type EffectFactory = (WebGL) -> CustomEffectPipeline raise RenderError

///|
let effect_factories : Map[String, EffectFactory] = {}

///|
fn register_webgl_effect(id : String, factory : EffectFactory) -> Unit {
  effect_factories.set(id, factory)
}

///|
pub fn register_webgl_effect_with_shaders(
  id : String,
  vert_src : String,
  frag_src : String,
  apply : EffectApply,
) -> Unit {
  register_webgl_effect(id, gl => {
    pipe: create_effect_pipeline(gl, vert_src, frag_src),
    apply,
  })
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
  #|uniform vec2 u_texel;
  #|uniform float u_blur;
  #|uniform float u_brightness;
  #|uniform float u_contrast;
  #|uniform float u_saturation;
  #|uniform float u_gamma;
  #|uniform vec3 u_color;
  #|vec3 apply_filters(vec3 color) {
  #|  color *= u_color;
  #|  color *= u_brightness;
  #|  color = (color - 0.5) * u_contrast + 0.5;
  #|  float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
  #|  color = mix(vec3(luma), color, u_saturation);
  #|  float safe_gamma = max(u_gamma, 0.0001);
  #|  color = pow(max(color, 0.0), vec3(1.0 / safe_gamma));
  #|  return color;
  #|}
  #|void main() {
  #|  vec4 c = vec4(0.0);
  #|  if (u_blur <= 0.0) {
  #|    c = texture2D(u_tex, v_uv);
  #|  } else {
  #|    vec2 offset = u_texel * u_blur;
  #|    c += texture2D(u_tex, v_uv + vec2(-offset.x, -offset.y));
  #|    c += texture2D(u_tex, v_uv + vec2(0.0, -offset.y));
  #|    c += texture2D(u_tex, v_uv + vec2(offset.x, -offset.y));
  #|    c += texture2D(u_tex, v_uv + vec2(-offset.x, 0.0));
  #|    c += texture2D(u_tex, v_uv);
  #|    c += texture2D(u_tex, v_uv + vec2(offset.x, 0.0));
  #|    c += texture2D(u_tex, v_uv + vec2(-offset.x, offset.y));
  #|    c += texture2D(u_tex, v_uv + vec2(0.0, offset.y));
  #|    c += texture2D(u_tex, v_uv + vec2(offset.x, offset.y));
  #|    c *= 1.0 / 9.0;
  #|  }
  #|  vec3 color = apply_filters(c.rgb);
  #|  gl_FragColor = vec4(color, c.a * u_opacity);
  #|}

///|
let blur_frag_shader : String =
  #|precision mediump float;
  #|varying vec2 v_uv;
  #|uniform sampler2D u_tex;
  #|uniform float u_opacity;
  #|uniform vec2 u_texel;
  #|uniform float u_blur;
  #|uniform float u_brightness;
  #|uniform float u_contrast;
  #|uniform float u_saturation;
  #|uniform float u_gamma;
  #|uniform vec3 u_color;
  #|vec3 apply_filters(vec3 color) {
  #|  color *= u_color;
  #|  color *= u_brightness;
  #|  color = (color - 0.5) * u_contrast + 0.5;
  #|  float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
  #|  color = mix(vec3(luma), color, u_saturation);
  #|  float safe_gamma = max(u_gamma, 0.0001);
  #|  color = pow(max(color, 0.0), vec3(1.0 / safe_gamma));
  #|  return color;
  #|}
  #|void main() {
  #|  vec4 c = vec4(0.0);
  #|  vec2 offset = u_texel * max(u_blur, 0.0);
  #|  c += texture2D(u_tex, v_uv + vec2(-offset.x, -offset.y));
  #|  c += texture2D(u_tex, v_uv + vec2(0.0, -offset.y));
  #|  c += texture2D(u_tex, v_uv + vec2(offset.x, -offset.y));
  #|  c += texture2D(u_tex, v_uv + vec2(-offset.x, 0.0));
  #|  c += texture2D(u_tex, v_uv);
  #|  c += texture2D(u_tex, v_uv + vec2(offset.x, 0.0));
  #|  c += texture2D(u_tex, v_uv + vec2(-offset.x, offset.y));
  #|  c += texture2D(u_tex, v_uv + vec2(0.0, offset.y));
  #|  c += texture2D(u_tex, v_uv + vec2(offset.x, offset.y));
  #|  c *= 1.0 / 9.0;
  #|  vec3 color = apply_filters(c.rgb);
  #|  gl_FragColor = vec4(color, c.a * u_opacity);
  #|}

///|
fn create_blur_pipeline(
  gl : WebGL,
  vert_src : String,
  frag_src : String,
) -> RenderPipeline raise RenderError {
  create_pipeline(gl, vert_src, frag_src)
}

///|
fn create_effect_pipeline(
  gl : WebGL,
  vert_src : String,
  frag_src : String,
) -> EffectPipeline raise RenderError {
  let program = create_program(gl, vert_src, frag_src)
  {
    program,
    u_model: gl.get_uniform_location(program.program, "u_model"),
    u_opacity: gl.get_uniform_location(program.program, "u_opacity"),
    u_texel: gl.get_uniform_location(program.program, "u_texel"),
    u_blur: gl.get_uniform_location(program.program, "u_blur"),
    u_brightness: gl.get_uniform_location(program.program, "u_brightness"),
    u_contrast: gl.get_uniform_location(program.program, "u_contrast"),
    u_saturation: gl.get_uniform_location(program.program, "u_saturation"),
    u_gamma: gl.get_uniform_location(program.program, "u_gamma"),
    u_color: gl.get_uniform_location(program.program, "u_color"),
  }
}

///|
priv struct OpacityAnim {
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
priv struct RenderTask {
  layer : Int
  order : Int
  item : Renderable
  effects : Array[EffectSpec]
  base_pipe : RenderPipeline
}

///|
extern "js" fn now_ms() -> Int =
  #| () => Math.floor((globalThis.performance?.now?.() ?? Date.now()))

///|
fn WebglPresenter::new(
  gl : WebGL,
  store : AssetStore,
  config : WebglPresenterConfig,
) -> WebglPresenter raise RenderError {
  let mesh = create_quad_mesh(gl)
  let pipe = create_pipeline(gl, default_vert_shader, default_frag_shader)
  let blur_pipe = create_blur_pipeline(
    gl, default_vert_shader, blur_frag_shader,
  )
  let renderer = Renderer::new(gl, pipe)
  let effect_pipelines : Map[String, CustomEffectPipeline] = {}
  for id, factory in effect_factories {
    effect_pipelines.set(id, factory(gl))
  }
  {
    renderer,
    store,
    textures: {},
    texture_sizes: {},
    mesh,
    blur_pipe,
    effect_pipelines,
    config,
    last_background_id: None,
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
  match (anim.from, anim.to) {
    (None, None) =>
      if done {
        (base_opacity, true)
      } else {
        (base_opacity * p, false)
      }
    _ => {
      let from = anim.from.unwrap_or(base_opacity)
      let to = anim.to.unwrap_or(base_opacity)
      let value = if done { to } else { from + (to - from) * p }
      (value, done)
    }
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
      let from = anim.from.unwrap_or(1.0)
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
fn apply_scalar_animation(
  base_value : Double,
  now_ms : Int,
  anim : OpacityAnim,
) -> (Double, Bool) {
  let (p, done) = animation_progress(
    now_ms,
    anim.start_ms,
    anim.duration_ms,
    anim.easing,
  )
  match (anim.from, anim.to) {
    (None, None) => (base_value, done)
    _ => {
      let from = anim.from.unwrap_or(base_value)
      let to = anim.to.unwrap_or(base_value)
      let value = if done { to } else { from + (to - from) * p }
      (value, done)
    }
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
          from: anim_value(spec.from, 0),
          to: anim_value(spec.to, 0),
        })
      Position =>
        self.position_anims.set(target, {
          start_ms: self.timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from_x: anim_value(spec.from, 0),
          from_y: anim_value(spec.from, 1),
          to_x: anim_value(spec.to, 0),
          to_y: anim_value(spec.to, 1),
        })
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
      }
      Rotation =>
        self.rotation_anims.set(target, {
          start_ms: self.timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from: anim_value(spec.from, 0),
          to: anim_value(spec.to, 0),
        })
      Blur =>
        self.blur_anims.set(target, {
          start_ms: self.timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from: anim_value(spec.from, 0),
          to: anim_value(spec.to, 0),
        })
      Brightness =>
        self.brightness_anims.set(target, {
          start_ms: self.timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from: anim_value(spec.from, 0),
          to: anim_value(spec.to, 0),
        })
      Contrast =>
        self.contrast_anims.set(target, {
          start_ms: self.timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from: anim_value(spec.from, 0),
          to: anim_value(spec.to, 0),
        })
      Saturation =>
        self.saturation_anims.set(target, {
          start_ms: self.timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from: anim_value(spec.from, 0),
          to: anim_value(spec.to, 0),
        })
      Gamma =>
        self.gamma_anims.set(target, {
          start_ms: self.timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from: anim_value(spec.from, 0),
          to: anim_value(spec.to, 0),
        })
      ColorRed =>
        self.color_r_anims.set(target, {
          start_ms: self.timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from: anim_value(spec.from, 0),
          to: anim_value(spec.to, 0),
        })
      ColorGreen =>
        self.color_g_anims.set(target, {
          start_ms: self.timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from: anim_value(spec.from, 0),
          to: anim_value(spec.to, 0),
        })
      ColorBlue =>
        self.color_b_anims.set(target, {
          start_ms: self.timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from: anim_value(spec.from, 0),
          to: anim_value(spec.to, 0),
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
fn fit_background_cover(
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
        // Image is wider - fit to height
        let scale = canvas_h / img_h
        (img_w * scale, canvas_h)
      } else {
        // Image is taller - fit to width
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
///|
fn WebglPresenter::draw_effect_pipeline(
  self : WebglPresenter,
  pipeline : CustomEffectPipeline,
  item : Renderable,
  params : Array[EffectParam],
  viewport_w : Double,
  viewport_h : Double,
) -> Bool {
  let drawable : EffectDrawable = {
    texture: item.texture,
    x: item.x,
    y: item.y,
    w: item.w,
    h: item.h,
    rotation: item.rotation,
    opacity: item.opacity,
    blur: item.blur,
    brightness: item.brightness,
    contrast: item.contrast,
    saturation: item.saturation,
    gamma: item.gamma,
    color_r: item.color_r,
    color_g: item.color_g,
    color_b: item.color_b,
    texel_x: item.texel_x,
    texel_y: item.texel_y,
  }
  let gl = self.renderer.gl
  gl.use_program(pipeline.pipe.program.program)
  bind_quad_attributes(gl, pipeline.pipe.program, self.mesh)
  gl.uniform1i(pipeline.pipe.program.u_tex, 0)
  gl.active_texture(gl.constant("TEXTURE0"))
  gl.bind_texture(gl.constant("TEXTURE_2D"), item.texture)

  let mat = model_matrix(
    item.x,
    item.y,
    item.w,
    item.h,
    item.rotation,
    viewport_w,
    viewport_h,
  )
  let mat_f32 = js_float32_array(mat)
  match pipeline.pipe.u_model {
    Some(loc) => gl.uniform_matrix4(loc, false, mat_f32)
    None => ()
  }
  match pipeline.pipe.u_opacity {
    Some(loc) => gl.uniform1f(loc, item.opacity)
    None => ()
  }
  match pipeline.pipe.u_texel {
    Some(loc) => gl.uniform2f(loc, item.texel_x, item.texel_y)
    None => ()
  }
  match pipeline.pipe.u_blur {
    Some(loc) => gl.uniform1f(loc, item.blur)
    None => ()
  }
  match pipeline.pipe.u_brightness {
    Some(loc) => gl.uniform1f(loc, item.brightness)
    None => ()
  }
  match pipeline.pipe.u_contrast {
    Some(loc) => gl.uniform1f(loc, item.contrast)
    None => ()
  }
  match pipeline.pipe.u_saturation {
    Some(loc) => gl.uniform1f(loc, item.saturation)
    None => ()
  }
  match pipeline.pipe.u_gamma {
    Some(loc) => gl.uniform1f(loc, item.gamma)
    None => ()
  }
  match pipeline.pipe.u_color {
    Some(loc) => gl.uniform3f(loc, item.color_r, item.color_g, item.color_b)
    None => ()
  }

  let skip_base = (pipeline.apply)(
    gl,
    pipeline.pipe.program.program,
    drawable,
    params,
    self.timeline_ms,
  )
  gl.draw_arrays(gl.constant("TRIANGLES"), 0, self.mesh.vertex_count)
  skip_base
}

///|
fn WebglPresenter::effect_pipeline(
  self : WebglPresenter,
  id : String,
) -> CustomEffectPipeline? raise RenderError {
  match self.effect_pipelines.get(id) {
    Some(pipeline) => Some(pipeline)
    None =>
      match effect_factories.get(id) {
        Some(factory) => {
          let pipeline = factory(self.renderer.gl)
          self.effect_pipelines.set(id, pipeline)
          Some(pipeline)
        }
        None => None
      }
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

  let finished_opacity : Array[String] = []
  let finished_position : Array[String] = []
  let finished_scale : Array[String] = []
  let tasks : Array[RenderTask] = []
  let mut order = 0

  match director.background() {
    Some(bg_id) => {
      match self.last_background_id {
        Some(prev) =>
          if prev != bg_id {
            self.opacity_anims.remove(prev)
            self.position_anims.remove(prev)
            self.scale_anims.remove(prev)
            self.rotation_anims.remove(prev)
            self.blur_anims.remove(prev)
            self.brightness_anims.remove(prev)
            self.contrast_anims.remove(prev)
            self.saturation_anims.remove(prev)
            self.gamma_anims.remove(prev)
            self.color_r_anims.remove(prev)
            self.color_g_anims.remove(prev)
            self.color_b_anims.remove(prev)
          }
        None => ()
      }
      self.last_background_id = Some(bg_id)
      let tex = self.texture_for(bg_id)
      let (bx, by, bw, bh) = fit_background_cover(
        bg_id,
        w,
        h,
        self.texture_sizes,
      )
      let (x, y, bg_w, bg_h) = fit_background(bg_id, w, h, self.texture_sizes)
      let mut cover_x = bx
      let mut cover_y = by
      let mut cover_w = bw
      let mut cover_h = bh
      let mut bg_x = x
      let mut bg_y = y
      let mut bg_width = bg_w
      let mut bg_height = bg_h
      let mut opacity = 1.0
      let mut rotation = 0.0
      let mut blur = 0.0
      let mut brightness = 1.0
      let mut contrast = 1.0
      let mut saturation = 1.0
      let mut gamma = 1.0
      let mut color_r = 1.0
      let mut color_g = 1.0
      let mut color_b = 1.0
      let (texel_x, texel_y) = match self.texture_sizes.get(bg_id) {
        Some((tex_w, tex_h)) => {
          let tx = if tex_w == 0 { 0.0 } else { 1.0 / tex_w.to_double() }
          let ty = if tex_h == 0 { 0.0 } else { 1.0 / tex_h.to_double() }
          (tx, ty)
        }
        None => (0.0, 0.0)
      }
      match self.position_anims.get(bg_id) {
        Some(anim) => {
          let (ax, ay, done) = apply_position_animation(
            bg_x,
            bg_y,
            self.config.position_entry_offset_ratio,
            h,
            w,
            self.timeline_ms,
            anim,
          )
          let dx = ax - bg_x
          let dy = ay - bg_y
          bg_x = ax
          bg_y = ay
          cover_x += dx
          cover_y += dy
          if done {
            finished_position.push(bg_id)
          }
        }
        None => ()
      }
      match self.scale_anims.get(bg_id) {
        Some(anim) => {
          let (sx, sy, sw, sh, done) = apply_scale_animation(
            bg_x,
            bg_y,
            bg_width,
            bg_height,
            self.config.scale_entry_from,
            self.timeline_ms,
            anim,
          )
          let scale = if bg_width == 0.0 { 1.0 } else { sw / bg_width }
          bg_x = sx
          bg_y = sy
          bg_width = sw
          bg_height = sh
          let (cx, cy, cw, ch) = scale_rect_with_anchor(
            cover_x,
            cover_y,
            cover_w,
            cover_h,
            scale,
            anim.anchor_x,
            anim.anchor_y,
          )
          cover_x = cx
          cover_y = cy
          cover_w = cw
          cover_h = ch
          if done {
            finished_scale.push(bg_id)
          }
        }
        None => ()
      }
      match self.opacity_anims.get(bg_id) {
        Some(anim) => {
          let (animated, done) = apply_opacity_animation(
            1.0,
            self.timeline_ms,
            anim,
          )
          opacity = animated
          if done {
            finished_opacity.push(bg_id)
          }
        }
        None => ()
      }
      match self.rotation_anims.get(bg_id) {
        Some(anim) => {
          let (animated, _done) = apply_scalar_animation(
            0.0,
            self.timeline_ms,
            anim,
          )
          rotation = animated
        }
        None => ()
      }
      match self.blur_anims.get(bg_id) {
        Some(anim) => {
          let (animated, _done) = apply_scalar_animation(
            0.0,
            self.timeline_ms,
            anim,
          )
          blur = animated
        }
        None => ()
      }
      match self.brightness_anims.get(bg_id) {
        Some(anim) => {
          let (animated, _done) = apply_scalar_animation(
            1.0,
            self.timeline_ms,
            anim,
          )
          brightness = animated
        }
        None => ()
      }
      match self.contrast_anims.get(bg_id) {
        Some(anim) => {
          let (animated, _done) = apply_scalar_animation(
            1.0,
            self.timeline_ms,
            anim,
          )
          contrast = animated
        }
        None => ()
      }
      match self.saturation_anims.get(bg_id) {
        Some(anim) => {
          let (animated, _done) = apply_scalar_animation(
            1.0,
            self.timeline_ms,
            anim,
          )
          saturation = animated
        }
        None => ()
      }
      match self.gamma_anims.get(bg_id) {
        Some(anim) => {
          let (animated, _done) = apply_scalar_animation(
            1.0,
            self.timeline_ms,
            anim,
          )
          gamma = animated
        }
        None => ()
      }
      match self.color_r_anims.get(bg_id) {
        Some(anim) => {
          let (animated, _done) = apply_scalar_animation(
            1.0,
            self.timeline_ms,
            anim,
          )
          color_r = animated
        }
        None => ()
      }
      match self.color_g_anims.get(bg_id) {
        Some(anim) => {
          let (animated, _done) = apply_scalar_animation(
            1.0,
            self.timeline_ms,
            anim,
          )
          color_g = animated
        }
        None => ()
      }
      match self.color_b_anims.get(bg_id) {
        Some(anim) => {
          let (animated, _done) = apply_scalar_animation(
            1.0,
            self.timeline_ms,
            anim,
          )
          color_b = animated
        }
        None => ()
      }
      let cover_blur = {
        let value = 2.0 + blur
        if value < 0.0 {
          0.0
        } else {
          value
        }
      }
      let effects = director.effects(bg_id)
      let cover_item : Renderable = {
        texture: tex,
        x: cover_x,
        y: cover_y,
        w: cover_w,
        h: cover_h,
        rotation,
        opacity,
        blur: cover_blur,
        brightness,
        contrast,
        saturation,
        gamma,
        color_r,
        color_g,
        color_b,
        texel_x,
        texel_y,
      }
      let base_item : Renderable = {
        texture: tex,
        x: bg_x,
        y: bg_y,
        w: bg_width,
        h: bg_height,
        rotation,
        opacity,
        blur,
        brightness,
        contrast,
        saturation,
        gamma,
        color_r,
        color_g,
        color_b,
        texel_x,
        texel_y,
      }
      tasks.push({
        layer: -1001,
        order,
        item: cover_item,
        effects,
        base_pipe: self.blur_pipe,
      })
      order += 1
      tasks.push({
        layer: -1000,
        order,
        item: base_item,
        effects,
        base_pipe: self.renderer.pipe,
      })
      order += 1
    }
    None => ()
  }
  let updated_figures : Array[(String, FigurePlacement)] = []
  let figures = director.figures()
  for id, placement in figures {
    let tex = self.texture_for(id)
    let (base_x, base_y, max_w, max_h) = figure_rect(placement.pos, w, h)
    let (actual_w, actual_h) = fit_figure(id, max_w, max_h, self.texture_sizes)
    let scaled_w = actual_w * placement.scale
    let scaled_h = actual_h * placement.scale
    let (aligned_x, aligned_y) = match placement.pos {
      Center => ((w - scaled_w) / 2.0, base_y + (max_h - scaled_h) / 2.0)
      Left =>
        (base_x + (max_w - scaled_w) / 2.0, base_y + (max_h - scaled_h) / 2.0)
      Right =>
        (base_x + (max_w - scaled_w) / 2.0, base_y + (max_h - scaled_h) / 2.0)
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
          h,
          w,
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
              pos: Custom(ax / w, ay / h),
              layer: placement.layer,
              opacity: placement.opacity,
              scale: placement.scale,
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
          x1,
          y1,
          scaled_w,
          scaled_h,
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
                Custom(sx / w, sy / h)
              } else {
                next_placement.pos
              }
              next_placement = {
                pos: next_pos,
                layer: next_placement.layer,
                opacity: next_placement.opacity,
                scale: value,
              }
              update_placement = true
            }
            None => ()
          }
        }
        (sx, sy, sw, sh)
      }
      None => (x1, y1, scaled_w, scaled_h)
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
          match anim.to {
            Some(value) => {
              next_placement = {
                pos: next_placement.pos,
                layer: next_placement.layer,
                opacity: value,
                scale: next_placement.scale,
              }
              update_placement = true
            }
            None => ()
          }
        }
        animated
      }
      None => placement.opacity
    }
    let rotation = match self.rotation_anims.get(id) {
      Some(anim) => {
        let (animated, _done) = apply_scalar_animation(
          0.0,
          self.timeline_ms,
          anim,
        )
        animated
      }
      None => 0.0
    }
    let blur = match self.blur_anims.get(id) {
      Some(anim) => {
        let (animated, _done) = apply_scalar_animation(
          0.0,
          self.timeline_ms,
          anim,
        )
        animated
      }
      None => 0.0
    }
    let brightness = match self.brightness_anims.get(id) {
      Some(anim) => {
        let (animated, _done) = apply_scalar_animation(
          1.0,
          self.timeline_ms,
          anim,
        )
        animated
      }
      None => 1.0
    }
    let contrast = match self.contrast_anims.get(id) {
      Some(anim) => {
        let (animated, _done) = apply_scalar_animation(
          1.0,
          self.timeline_ms,
          anim,
        )
        animated
      }
      None => 1.0
    }
    let saturation = match self.saturation_anims.get(id) {
      Some(anim) => {
        let (animated, _done) = apply_scalar_animation(
          1.0,
          self.timeline_ms,
          anim,
        )
        animated
      }
      None => 1.0
    }
    let gamma = match self.gamma_anims.get(id) {
      Some(anim) => {
        let (animated, _done) = apply_scalar_animation(
          1.0,
          self.timeline_ms,
          anim,
        )
        animated
      }
      None => 1.0
    }
    let color_r = match self.color_r_anims.get(id) {
      Some(anim) => {
        let (animated, _done) = apply_scalar_animation(
          1.0,
          self.timeline_ms,
          anim,
        )
        animated
      }
      None => 1.0
    }
    let color_g = match self.color_g_anims.get(id) {
      Some(anim) => {
        let (animated, _done) = apply_scalar_animation(
          1.0,
          self.timeline_ms,
          anim,
        )
        animated
      }
      None => 1.0
    }
    let color_b = match self.color_b_anims.get(id) {
      Some(anim) => {
        let (animated, _done) = apply_scalar_animation(
          1.0,
          self.timeline_ms,
          anim,
        )
        animated
      }
      None => 1.0
    }
    let (texel_x, texel_y) = match self.texture_sizes.get(id) {
      Some((tex_w, tex_h)) => {
        let tx = if tex_w == 0 { 0.0 } else { 1.0 / tex_w.to_double() }
        let ty = if tex_h == 0 { 0.0 } else { 1.0 / tex_h.to_double() }
        (tx, ty)
      }
      None => (0.0, 0.0)
    }
    let effects = director.effects(id)
    let item : Renderable = {
      texture: tex,
      x,
      y,
      w,
      h,
      rotation,
      opacity,
      blur,
      brightness,
      contrast,
      saturation,
      gamma,
      color_r,
      color_g,
      color_b,
      texel_x,
      texel_y,
    }
    tasks.push({
      layer: placement.layer,
      order,
      item,
      effects,
      base_pipe: self.renderer.pipe,
    })
    order += 1
    if update_placement {
      updated_figures.push((id, next_placement))
    }
  }
  for id in finished_opacity {
    if self.last_background_id != Some(id) {
      self.opacity_anims.remove(id)
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

  tasks.sort_by_key(task => task.layer * 1000000 + task.order)
  for task in tasks {
    let mut skip_base = false
    for spec in task.effects {
      match self.effect_pipeline(spec.id) {
        Some(pipeline) => {
          let skip = self.draw_effect_pipeline(
            pipeline,
            task.item,
            spec.params,
            w,
            h,
          )
          if skip {
            skip_base = true
          }
        }
        None => ()
      }
    }
    if !skip_base {
      draw_item_with_pipeline(
        self.renderer.gl,
        self.mesh,
        task.base_pipe,
        task.item,
        w,
        h,
      )
    }
  }
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
) -> RenderSyncHook[T] raise {
  let presenter = WebglPresenter::new(
    gl,
    store,
    webgl_presenter_default_config(),
  )
  presenter.as_render_sync_hook()
}

///|
pub fn[T] make_webgl_render_sync_hook_with_config(
  gl : WebGL,
  store : AssetStore,
  config : WebglPresenterConfig,
) -> RenderSyncHook[T] raise {
  let presenter = WebglPresenter::new(gl, store, config)
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
      Some(make_webgl_render_sync_hook(g, store))
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
      Some(make_webgl_render_sync_hook_with_config(g, store, config))
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
