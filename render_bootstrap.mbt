///|
/// Minimal renderer bootstrap helpers built on top of webgl.mbt.
/// This is intentionally small: shader compile/link, quad mesh, and texture upload.

///|
pub struct ShaderProgram {
  program : WebGLProgram
  a_pos : Int
  a_uv : Int
  u_tex : WebGLUniformLocation
}

///|
pub struct QuadMesh {
  vbo : WebGLBuffer
  vertex_count : Int
}

///|
pub fn compile_shader(
  gl : WebGL,
  kind : Int,
  source : String,
) -> Result[WebGLShader, String] {
  match gl.create_shader(kind) {
    None => Err("createShader returned null")
    Some(shader) => {
      gl.shader_source(shader, source)
      gl.compile_shader(shader)
      let ok = gl.get_shader_parameter(shader, gl.constant("COMPILE_STATUS"))
      if ok { Ok(shader) } else { Err(gl.get_shader_info_log(shader)) }
    }
  }
}

///|
pub fn link_program(
  gl : WebGL,
  vert : WebGLShader,
  frag : WebGLShader,
) -> Result[WebGLProgram, String] {
  match gl.create_program() {
    None => Err("createProgram returned null")
    Some(program) => {
      gl.attach_shader(program, vert)
      gl.attach_shader(program, frag)
      gl.link_program(program)
      let ok = gl.get_program_parameter(program, gl.constant("LINK_STATUS"))
      if ok { Ok(program) } else { Err(gl.get_program_info_log(program)) }
    }
  }
}

///|
pub fn create_program(
  gl : WebGL,
  vert_src : String,
  frag_src : String,
) -> Result[ShaderProgram, String] {
  let vert = compile_shader(gl, gl.constant("VERTEX_SHADER"), vert_src)
  let frag = compile_shader(gl, gl.constant("FRAGMENT_SHADER"), frag_src)
  match (vert, frag) {
    (Ok(vs), Ok(fs)) => {
      match link_program(gl, vs, fs) {
        Ok(program) => {
          let a_pos = gl.get_attrib_location(program, "a_position")
          let a_uv = gl.get_attrib_location(program, "a_uv")
          if a_pos < 0 || a_uv < 0 {
            Err("missing attributes a_position/a_uv")
          } else {
            match gl.get_uniform_location(program, "u_tex") {
              None => Err("missing uniform u_tex")
              Some(u_tex) => Ok({ program, a_pos, a_uv, u_tex })
            }
          }
        }
        Err(msg) => Err(msg)
      }
    }
    (Err(msg), _) => Err(msg)
    (_, Err(msg)) => Err(msg)
  }
}

///|
pub fn create_quad_mesh(gl : WebGL) -> Result[QuadMesh, String] {
  let vertices : Array[Double] = [
    -1.0, -1.0, 0.0, 0.0,
    1.0, -1.0, 1.0, 0.0,
    1.0, 1.0, 1.0, 1.0,
    -1.0, -1.0, 0.0, 0.0,
    1.0, 1.0, 1.0, 1.0,
    -1.0, 1.0, 0.0, 1.0,
  ]
  match gl.create_buffer() {
    None => Err("createBuffer returned null")
    Some(vbo) => {
      gl.bind_buffer(gl.constant("ARRAY_BUFFER"), vbo)
      let data = js_float32_array(vertices)
      gl.buffer_data(gl.constant("ARRAY_BUFFER"), data, gl.constant("STATIC_DRAW"))
      Ok({ vbo, vertex_count: 6 })
    }
  }
}

///|
pub fn bind_quad_attributes(gl : WebGL, program : ShaderProgram, mesh : QuadMesh) ->
  Unit {
  let stride = 4 * 4
  let offset_uv = 2 * 4
  gl.bind_buffer(gl.constant("ARRAY_BUFFER"), mesh.vbo)
  gl.enable_vertex_attrib_array(program.a_pos)
  gl.vertex_attrib_pointer(
    program.a_pos,
    2,
    gl.constant("FLOAT"),
    false,
    stride,
    0,
  )
  gl.enable_vertex_attrib_array(program.a_uv)
  gl.vertex_attrib_pointer(
    program.a_uv,
    2,
    gl.constant("FLOAT"),
    false,
    stride,
    offset_uv,
  )
}

///|
pub fn create_texture_rgba(
  gl : WebGL,
  width : Int,
  height : Int,
  pixels : Array[Int],
) -> Result[WebGLTexture, String] {
  match gl.create_texture() {
    None => Err("createTexture returned null")
    Some(tex) => {
      let target = gl.constant("TEXTURE_2D")
      gl.bind_texture(target, tex)
      gl.tex_param_i(target, gl.constant("TEXTURE_MIN_FILTER"), gl.constant("LINEAR"))
      gl.tex_param_i(target, gl.constant("TEXTURE_MAG_FILTER"), gl.constant("LINEAR"))
      gl.tex_param_i(target, gl.constant("TEXTURE_WRAP_S"), gl.constant("CLAMP_TO_EDGE"))
      gl.tex_param_i(target, gl.constant("TEXTURE_WRAP_T"), gl.constant("CLAMP_TO_EDGE"))
      let data = js_uint8_array(pixels)
      gl.tex_image_2d(
        target,
        0,
        gl.constant("RGBA"),
        width,
        height,
        0,
        gl.constant("RGBA"),
        gl.constant("UNSIGNED_BYTE"),
        data,
      )
      Ok(tex)
    }
  }
}

///|
pub fn create_solid_texture(
  gl : WebGL,
  r : Int,
  g : Int,
  b : Int,
  a : Int,
) -> Result[WebGLTexture, String] {
  create_texture_rgba(gl, 1, 1, [r, g, b, a])
}

///|
pub fn draw_textured_quad(gl : WebGL, program : ShaderProgram, mesh : QuadMesh) ->
  Unit {
  gl.use_program(program.program)
  bind_quad_attributes(gl, program, mesh)
  gl.uniform1i(program.u_tex, 0)
  gl.draw_arrays(gl.constant("TRIANGLES"), 0, mesh.vertex_count)
}
