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
fn Renderer::new(gl : WebGL, pipe : RenderPipeline) -> Renderer {
  { gl, pipe, items: [] }
}

///|
fn Renderer::clear(self : Renderer) -> Unit {
  self.items.clear()
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
fn draw_item_with_pipeline(
  gl : WebGL,
  mesh : QuadMesh,
  pipe : RenderPipeline,
  item : Renderable,
  vw : Double,
  vh : Double,
) -> Unit {
  gl.enable(gl.constant("BLEND"))
  gl.blend_func(gl.constant("SRC_ALPHA"), gl.constant("ONE_MINUS_SRC_ALPHA"))
  gl.use_program(pipe.program.program)
  bind_quad_attributes(gl, pipe.program, mesh)
  gl.uniform1i(pipe.program.u_tex, 0)
  gl.active_texture(gl.constant("TEXTURE0"))
  gl.bind_texture(gl.constant("TEXTURE_2D"), item.texture)

  let mat = model_matrix(item.x, item.y, item.w, item.h, item.rotation, vw, vh)
  let mat_f32 = js_float32_array(mat)
  gl.uniform_matrix4(pipe.u_model, false, mat_f32)
  gl.uniform1f(pipe.u_opacity, item.opacity)
  gl.uniform2f(pipe.u_texel, item.texel_x, item.texel_y)
  gl.uniform1f(pipe.u_blur, item.blur)
  gl.uniform1f(pipe.u_brightness, item.brightness)
  gl.uniform1f(pipe.u_contrast, item.contrast)
  gl.uniform1f(pipe.u_saturation, item.saturation)
  gl.uniform1f(pipe.u_gamma, item.gamma)
  gl.uniform3f(pipe.u_color, item.color_r, item.color_g, item.color_b)

  gl.draw_arrays(gl.constant("TRIANGLES"), 0, mesh.vertex_count)
}
