///|
/// Minimal renderer bootstrap helpers built on top of webgl.mbt.
/// This is intentionally small: shader compile/link, quad mesh, and texture upload.

///|
suberror RenderError {
  NullObject(op~ : String)
  ShaderCompile(log~ : String)
  ProgramLink(log~ : String)
  MissingAttribute(name~ : String)
  MissingUniform(name~ : String)
  MissingImage(id~ : String)
}

///|
priv struct ShaderProgram {
  program : WebGLProgram
  a_pos : Int
  a_uv : Int
  u_tex : WebGLUniformLocation
}

///|
priv struct QuadMesh {
  vbo : WebGLBuffer
  vertex_count : Int
}

///|
fn compile_shader(
  gl : WebGL,
  kind : Int,
  source : String,
) -> WebGLShader raise RenderError {
  match gl.create_shader(kind) {
    None => raise RenderError::NullObject(op="createShader")
    Some(shader) => {
      gl.shader_source(shader, source)
      gl.compile_shader(shader)
      let ok = gl.get_shader_parameter(shader, gl.constant("COMPILE_STATUS"))
      if ok {
        shader
      } else {
        raise RenderError::ShaderCompile(log=gl.get_shader_info_log(shader))
      }
    }
  }
}

///|
fn link_program(
  gl : WebGL,
  vert : WebGLShader,
  frag : WebGLShader,
) -> WebGLProgram raise RenderError {
  match gl.create_program() {
    None => raise RenderError::NullObject(op="createProgram")
    Some(program) => {
      gl.attach_shader(program, vert)
      gl.attach_shader(program, frag)
      gl.link_program(program)
      let ok = gl.get_program_parameter(program, gl.constant("LINK_STATUS"))
      if ok {
        program
      } else {
        raise RenderError::ProgramLink(log=gl.get_program_info_log(program))
      }
    }
  }
}

///|
fn create_program(
  gl : WebGL,
  vert_src : String,
  frag_src : String,
) -> ShaderProgram raise RenderError {
  let vert = compile_shader(gl, gl.constant("VERTEX_SHADER"), vert_src)
  let frag = compile_shader(gl, gl.constant("FRAGMENT_SHADER"), frag_src)
  let program = link_program(gl, vert, frag)
  let a_pos = gl.get_attrib_location(program, "a_position")
  if a_pos < 0 {
    raise RenderError::MissingAttribute(name="a_position")
  }
  let a_uv = gl.get_attrib_location(program, "a_uv")
  if a_uv < 0 {
    raise RenderError::MissingAttribute(name="a_uv")
  }
  match gl.get_uniform_location(program, "u_tex") {
    None => raise RenderError::MissingUniform(name="u_tex")
    Some(u_tex) => { program, a_pos, a_uv, u_tex }
  }
}

///|
fn create_quad_mesh(gl : WebGL) -> QuadMesh raise RenderError {
  let vertices : Array[Double] = [
    -1.0, -1.0, 0.0, 0.0, 1.0, -1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, -1.0, -1.0, 0.0,
    0.0, 1.0, 1.0, 1.0, 1.0, -1.0, 1.0, 0.0, 1.0,
  ]
  match gl.create_buffer() {
    None => raise RenderError::NullObject(op="createBuffer")
    Some(vbo) => {
      gl.bind_buffer(gl.constant("ARRAY_BUFFER"), vbo)
      let data = js_float32_array(vertices)
      gl.buffer_data(
        gl.constant("ARRAY_BUFFER"),
        data,
        gl.constant("STATIC_DRAW"),
      )
      { vbo, vertex_count: 6 }
    }
  }
}

///|
fn bind_quad_attributes(
  gl : WebGL,
  program : ShaderProgram,
  mesh : QuadMesh,
) -> Unit {
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
fn create_texture_rgba(
  gl : WebGL,
  width : Int,
  height : Int,
  pixels : Array[Int],
) -> WebGLTexture raise RenderError {
  match gl.create_texture() {
    None => raise RenderError::NullObject(op="createTexture")
    Some(tex) => {
      let target = gl.constant("TEXTURE_2D")
      gl.bind_texture(target, tex)
      gl.tex_param_i(
        target,
        gl.constant("TEXTURE_MIN_FILTER"),
        gl.constant("LINEAR"),
      )
      gl.tex_param_i(
        target,
        gl.constant("TEXTURE_MAG_FILTER"),
        gl.constant("LINEAR"),
      )
      gl.tex_param_i(
        target,
        gl.constant("TEXTURE_WRAP_S"),
        gl.constant("CLAMP_TO_EDGE"),
      )
      gl.tex_param_i(
        target,
        gl.constant("TEXTURE_WRAP_T"),
        gl.constant("CLAMP_TO_EDGE"),
      )
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
      tex
    }
  }
}

///|
/// Create a texture directly from a loaded browser image asset.
fn create_texture_from_image(
  gl : WebGL,
  image : Image,
  mipmap? : Bool = false,
) -> WebGLTexture raise RenderError {
  match gl.create_texture() {
    None => raise RenderError::NullObject(op="createTexture")
    Some(tex) => {
      let target = gl.constant("TEXTURE_2D")
      gl.bind_texture(target, tex)
      gl.tex_param_i(
        target,
        gl.constant("TEXTURE_MIN_FILTER"),
        gl.constant("LINEAR"),
      )
      gl.tex_param_i(
        target,
        gl.constant("TEXTURE_MAG_FILTER"),
        gl.constant("LINEAR"),
      )
      gl.tex_param_i(
        target,
        gl.constant("TEXTURE_WRAP_S"),
        gl.constant("CLAMP_TO_EDGE"),
      )
      gl.tex_param_i(
        target,
        gl.constant("TEXTURE_WRAP_T"),
        gl.constant("CLAMP_TO_EDGE"),
      )
      gl.tex_image_2d_source(
        target,
        0,
        gl.constant("RGBA"),
        gl.constant("RGBA"),
        gl.constant("UNSIGNED_BYTE"),
        @js.Value::cast_from(image),
      )
      if mipmap {
        gl.generate_mipmap(target)
      }
      tex
    }
  }
}

///|
/// Resolve an image from `AssetStore` and create a texture from it.
fn create_texture_from_store(
  gl : WebGL,
  store : AssetStore,
  image_id : String,
  mipmap? : Bool = false,
) -> WebGLTexture raise RenderError {
  match store.get_image(image_id) {
    None => raise RenderError::MissingImage(id=image_id)
    Some(image) => create_texture_from_image(gl, image, mipmap~)
  }
}

///|
fn create_solid_texture(
  gl : WebGL,
  r : Int,
  g : Int,
  b : Int,
  a : Int,
) -> WebGLTexture raise RenderError {
  create_texture_rgba(gl, 1, 1, [r, g, b, a])
}

///|
fn draw_textured_quad(
  gl : WebGL,
  program : ShaderProgram,
  mesh : QuadMesh,
) -> Unit {
  gl.use_program(program.program)
  bind_quad_attributes(gl, program, mesh)
  gl.uniform1i(program.u_tex, 0)
  gl.draw_arrays(gl.constant("TRIANGLES"), 0, mesh.vertex_count)
}
