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
  layer : Int
}

///|
priv struct RenderPipeline {
  program : ShaderProgram
  u_model : WebGLUniformLocation
  u_opacity : WebGLUniformLocation
  u_texel : WebGLUniformLocation
  u_blur : WebGLUniformLocation
  u_brightness : WebGLUniformLocation
  u_contrast : WebGLUniformLocation
  u_saturation : WebGLUniformLocation
  u_gamma : WebGLUniformLocation
  u_color : WebGLUniformLocation
}

///|
priv struct Renderer {
  gl : WebGL
  mesh : QuadMesh
  pipe : RenderPipeline
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
      gl.get_uniform_location(program.program, "u_texel"),
      gl.get_uniform_location(program.program, "u_blur"),
      gl.get_uniform_location(program.program, "u_brightness"),
      gl.get_uniform_location(program.program, "u_contrast"),
      gl.get_uniform_location(program.program, "u_saturation"),
      gl.get_uniform_location(program.program, "u_gamma"),
      gl.get_uniform_location(program.program, "u_color"),
    ) {
    (
      Some(u_model),
      Some(u_opacity),
      Some(u_texel),
      Some(u_blur),
      Some(u_brightness),
      Some(u_contrast),
      Some(u_saturation),
      Some(u_gamma),
      Some(u_color),
    ) =>
      {
        program,
        u_model,
        u_opacity,
        u_texel,
        u_blur,
        u_brightness,
        u_contrast,
        u_saturation,
        u_gamma,
        u_color,
      }
    _ => raise RenderError::MissingUniform(name="u_model or filters")
  }
}

///|
fn renderer_new(gl : WebGL, mesh : QuadMesh, pipe : RenderPipeline) -> Renderer {
  { gl, mesh, pipe, items: [] }
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
  rotation : Double,
  vw : Double,
  vh : Double,
) -> Array[Double] {
  let sx = w / vw
  let sy = h / vh
  let cx = (x + w / 2.0) / vw * 2.0 - 1.0
  let cy = 1.0 - (y + h / 2.0) / vh * 2.0
  let aspect = if vh == 0.0 { 1.0 } else { vw / vh }
  let cos_r = @math.cos(rotation)
  let sin_r = @math.sin(rotation)
  let m00 = cos_r * sx
  let m10 = sin_r * aspect * sx
  let m01 = -sin_r / aspect * sy
  let m11 = cos_r * sy
  // Column-major 4x4:
  // [ m00, m01, 0, 0,
  //   m10, m11, 0, 0,
  //   0, 0, 1, 0,
  //   cx, cy, 0, 1 ]
  [m00, m10, 0.0, 0.0, m01, m11, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, cx, cy, 0.0, 1.0]
}

///|
fn Renderer::draw_with_viewport(
  self : Renderer,
  vw : Double,
  vh : Double,
) -> Unit {
  self.gl.enable(self.gl.constant("BLEND"))
  self.gl.blend_func(
    self.gl.constant("SRC_ALPHA"),
    self.gl.constant("ONE_MINUS_SRC_ALPHA"),
  )

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
      item.rotation,
      vw,
      vh,
    )
    let mat_f32 = js_float32_array(mat)
    self.gl.uniform_matrix4(self.pipe.u_model, false, mat_f32)
    self.gl.uniform1f(self.pipe.u_opacity, item.opacity)
    self.gl.uniform2f(self.pipe.u_texel, item.texel_x, item.texel_y)
    self.gl.uniform1f(self.pipe.u_blur, item.blur)
    self.gl.uniform1f(self.pipe.u_brightness, item.brightness)
    self.gl.uniform1f(self.pipe.u_contrast, item.contrast)
    self.gl.uniform1f(self.pipe.u_saturation, item.saturation)
    self.gl.uniform1f(self.pipe.u_gamma, item.gamma)
    self.gl.uniform3f(
      self.pipe.u_color,
      item.color_r,
      item.color_g,
      item.color_b,
    )

    self.gl.draw_arrays(
      self.gl.constant("TRIANGLES"),
      0,
      self.mesh.vertex_count,
    )
  }
}
