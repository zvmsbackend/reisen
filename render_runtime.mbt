///|
/// Minimal renderer runtime: renderable list, layering, and draw pass.
/// Depends on render_bootstrap + webgl.

///|
priv struct Renderable {
  texture : WebGLTexture
  x : Double
  y : Double
  w : Double
  h : Double
  opacity : Double
  layer : Int
}

///|
priv struct RenderPipeline {
  program : ShaderProgram
  u_model : WebGLUniformLocation
  u_opacity : WebGLUniformLocation
}

///|
priv struct Renderer {
  gl : WebGL
  mesh : QuadMesh
  pipe : RenderPipeline
  viewport_w : Double
  viewport_h : Double
  items : Array[Renderable]
}

///|
fn create_pipeline(
  gl : WebGL,
  vert_src : String,
  frag_src : String,
) -> RenderPipeline raise RenderError {
  let program = create_program(gl, vert_src, frag_src)
  match
    (
      gl.get_uniform_location(program.program, "u_model"),
      gl.get_uniform_location(program.program, "u_opacity"),
    ) {
    (Some(u_model), Some(u_opacity)) => { program, u_model, u_opacity }
    _ => raise RenderError::MissingUniform(name="u_model or u_opacity")
  }
}

///|
fn renderer_new(
  gl : WebGL,
  mesh : QuadMesh,
  pipe : RenderPipeline,
  viewport_w : Double,
  viewport_h : Double,
) -> Renderer {
  { gl, mesh, pipe, viewport_w, viewport_h, items: [] }
}

///|
fn Renderer::clear(self : Renderer) -> Unit {
  self.items.clear()
}

///|
fn Renderer::add(self : Renderer, item : Renderable) -> Unit {
  self.items.push(item)
}

///|
fn sort_by_layer(items : Array[Renderable]) -> Unit {
  items.sort_by_key(item => item.layer)
}

///|
fn model_matrix(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  vw : Double,
  vh : Double,
) -> Array[Double] {
  let sx = w / vw
  let sy = h / vh
  let cx = (x + w / 2.0) / vw * 2.0 - 1.0
  let cy = 1.0 - (y + h / 2.0) / vh * 2.0
  // Column-major 4x4:
  // [ sx, 0, 0, 0,
  //   0, sy, 0, 0,
  //   0, 0, 1, 0,
  //   cx, cy, 0, 1 ]
  [sx, 0.0, 0.0, 0.0, 0.0, sy, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, cx, cy, 0.0, 1.0]
}

///|
fn Renderer::draw(self : Renderer) -> Unit {
  sort_by_layer(self.items)
  self.gl.use_program(self.pipe.program.program)
  bind_quad_attributes(self.gl, self.pipe.program, self.mesh)
  self.gl.uniform1i(self.pipe.program.u_tex, 0)

  for item in self.items {
    self.gl.active_texture(self.gl.constant("TEXTURE0"))
    self.gl.bind_texture(self.gl.constant("TEXTURE_2D"), item.texture)

    let mat = model_matrix(
      item.x,
      item.y,
      item.w,
      item.h,
      self.viewport_w,
      self.viewport_h,
    )
    let mat_f32 = js_float32_array(mat)
    self.gl.uniform_matrix4(self.pipe.u_model, false, mat_f32)
    self.gl.uniform1f(self.pipe.u_opacity, item.opacity)

    self.gl.draw_arrays(
      self.gl.constant("TRIANGLES"),
      0,
      self.mesh.vertex_count,
    )
  }
}
