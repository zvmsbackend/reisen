///|
/// WebGL presenter that converts `Director` render state into draw calls.

///|
struct WebglPresenter {
  renderer : Renderer
  store : AssetStore
  textures : Map[String, WebGLTexture]
  viewport_w : Double
  viewport_h : Double
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
pub fn webgl_presenter_new(
  gl : WebGL,
  store : AssetStore,
  viewport_w : Double,
  viewport_h : Double,
) -> WebglPresenter raise RenderError {
  let mesh = create_quad_mesh(gl)
  let pipe = create_pipeline(gl, default_vert_shader, default_frag_shader)
  let renderer = renderer_new(gl, mesh, pipe, viewport_w, viewport_h)
  { renderer, store, textures: {}, viewport_w, viewport_h }
}

///|
fn WebglPresenter::texture_for(
  self : WebglPresenter,
  image_id : String,
) -> WebGLTexture raise RenderError {
  match self.textures.get(image_id) {
    Some(tex) => tex
    None => {
      let tex = create_texture_from_store(self.renderer.gl, self.store, image_id)
      self.textures.set(image_id, tex)
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
    Left => (viewport_w * 0.05, viewport_h - h, w, h)
    Center => ((viewport_w - w) / 2.0, viewport_h - h, w, h)
    Right => (viewport_w * 0.55, viewport_h - h, w, h)
    Custom(x, y) => (x * viewport_w, y * viewport_h, w, h)
  }
}

///|
fn[T] WebglPresenter::sync_impl(
  self : WebglPresenter,
  director : Director[T],
) -> Unit raise RenderError {
  self.renderer.clear()
  self.renderer.gl.clear_color(0.0, 0.0, 0.0, 1.0)
  self.renderer.gl.clear(self.renderer.gl.constant("COLOR_BUFFER_BIT"))

  match director.background() {
    Some(bg_id) => {
      let tex = self.texture_for(bg_id)
      self.renderer.add({
        texture: tex,
        x: 0.0,
        y: 0.0,
        w: self.viewport_w,
        h: self.viewport_h,
        opacity: 1.0,
        layer: -1000,
      })
    }
    None => ()
  }

  for id, placement in director.figures() {
    let tex = self.texture_for(id)
    let (x, y, w, h) = figure_rect(placement.pos, self.viewport_w, self.viewport_h)
    self.renderer.add({
      texture: tex,
      x,
      y,
      w,
      h,
      opacity: placement.opacity,
      layer: placement.layer,
    })
  }

  self.renderer.draw()
}

///|
pub fn[T] WebglPresenter::sync(
  self : WebglPresenter,
  director : Director[T],
) -> Unit raise RenderError {
  self.sync_impl(director)
}

///|
pub fn[T] WebglPresenter::sync_noraise(
  self : WebglPresenter,
  director : Director[T],
) -> Unit {
  ignore(try? self.sync_impl(director))
}

///|
pub fn[T] WebglPresenter::as_render_sync_hook(self : WebglPresenter) -> RenderSyncHook[T] {
  director => self.sync_noraise(director)
}
