///|
/// WebGL bindings implemented on top of moonbit-community/js-ffi/js.
///
/// These are intentionally thin wrappers around the JS WebGL API.
/// We keep them as `Value`-backed types and expose small helpers to
/// reduce repetitive JS interop code.
///
/// All blocks are split with `///|` per MoonBit conventions.

///|
#external
type Canvas

///|
#external
type WebGL

///|
#external
type WebGLProgram

///|
#external
type WebGLShader

///|
#external
type WebGLBuffer

///|
#external
type WebGLTexture

///|
#external
type WebGLUniformLocation

///|
pub extern "js" fn window_inner_width() -> Double =
  #| () => window.innerWidth

///|
pub extern "js" fn window_inner_height() -> Double =
  #| () => window.innerHeight

///|
extern "js" fn get_canvas_element(id : String) -> @js.Optional[Canvas] =
  #| (id) => document.getElementById(id)

///|
pub fn get_canvas_by_id(id : String) -> Canvas? {
  get_canvas_element(id).to_option()
}

///|
extern "js" fn Canvas::get_context_ffi(
  self : Canvas,
  context_id : String,
) -> @js.Optional[WebGL] =
  #| (canvas, context_id) => canvas.getContext(context_id)

///|
pub fn Canvas::get_webgl_context(self : Canvas) -> WebGL? {
  self.get_context_ffi("webgl").to_option()
}

///|
pub fn Canvas::get_webgl2_context(self : Canvas) -> WebGL? {
  self.get_context_ffi("webgl2").to_option()
}

///|
/// Common WebGL constants.
pub extern "js" fn WebGL::constant(self : WebGL, name : String) -> Int =
  #| (gl, name) => gl[name]

///|
/// Shader/program creation.
extern "js" fn WebGL::create_shader_ffi(
  self : WebGL,
  kind : Int,
) -> @js.Nullable[WebGLShader] =
  #| (gl, kind) => gl.createShader(kind)

///|
pub fn WebGL::create_shader(self : WebGL, kind : Int) -> WebGLShader? {
  self.create_shader_ffi(kind).to_option()
}

///|
pub extern "js" fn WebGL::shader_source(
  self : WebGL,
  shader : WebGLShader,
  src : String,
) -> Unit =
  #| (gl, shader, src) => gl.shaderSource(shader, src)

///|
pub extern "js" fn WebGL::compile_shader(
  self : WebGL,
  shader : WebGLShader,
) -> Unit =
  #| (gl, shader) => gl.compileShader(shader)

///|
pub extern "js" fn WebGL::get_shader_parameter(
  self : WebGL,
  shader : WebGLShader,
  pname : Int,
) -> Bool =
  #| (gl, shader, pname) => gl.getShaderParameter(shader, pname)

///|
pub extern "js" fn WebGL::get_shader_info_log(
  self : WebGL,
  shader : WebGLShader,
) -> String =
  #| (gl, shader) => gl.getShaderInfoLog(shader)

///|
extern "js" fn WebGL::create_program_ffi(
  self : WebGL,
) -> @js.Nullable[WebGLProgram] =
  #| (gl) => gl.createProgram()

///|
pub fn WebGL::create_program(self : WebGL) -> WebGLProgram? {
  self.create_program_ffi().to_option()
}

///|
pub extern "js" fn WebGL::attach_shader(
  self : WebGL,
  program : WebGLProgram,
  shader : WebGLShader,
) -> Unit =
  #| (gl, program, shader) => gl.attachShader(program, shader)

///|
pub extern "js" fn WebGL::link_program(
  self : WebGL,
  program : WebGLProgram,
) -> Unit =
  #| (gl, program) => gl.linkProgram(program)

///|
pub extern "js" fn WebGL::get_program_parameter(
  self : WebGL,
  program : WebGLProgram,
  pname : Int,
) -> Bool =
  #| (gl, program, pname) => gl.getProgramParameter(program, pname)

///|
pub extern "js" fn WebGL::get_program_info_log(
  self : WebGL,
  program : WebGLProgram,
) -> String =
  #| (gl, program) => gl.getProgramInfoLog(program)

///|
pub extern "js" fn WebGL::use_program(
  self : WebGL,
  program : WebGLProgram,
) -> Unit =
  #| (gl, program) => gl.useProgram(program)

///|
/// Buffers and attributes.
extern "js" fn WebGL::create_buffer_ffi(
  self : WebGL,
) -> @js.Nullable[WebGLBuffer] =
  #| (gl) => gl.createBuffer()

///|
pub fn WebGL::create_buffer(self : WebGL) -> WebGLBuffer? {
  self.create_buffer_ffi().to_option()
}

///|
pub extern "js" fn WebGL::bind_buffer(
  self : WebGL,
  target : Int,
  buf : WebGLBuffer,
) -> Unit =
  #| (gl, target, buf) => gl.bindBuffer(target, buf)

///|
pub extern "js" fn js_float32_array(data : Array[Double]) -> @js.Value =
  #| (data) => new Float32Array(data)

///|
pub extern "js" fn js_uint16_array(data : Array[Int]) -> @js.Value =
  #| (data) => new Uint16Array(data)

///|
pub extern "js" fn js_uint8_array(data : Array[Int]) -> @js.Value =
  #| (data) => new Uint8Array(data)

///|
pub extern "js" fn WebGL::buffer_data(
  self : WebGL,
  target : Int,
  data : @js.Value,
  usage : Int,
) -> Unit =
  #| (gl, target, data, usage) => gl.bufferData(target, data, usage)

///|
pub extern "js" fn WebGL::get_attrib_location(
  self : WebGL,
  program : WebGLProgram,
  name : String,
) -> Int =
  #| (gl, program, name) => gl.getAttribLocation(program, name)

///|
pub extern "js" fn WebGL::enable_vertex_attrib_array(
  self : WebGL,
  loc : Int,
) -> Unit =
  #| (gl, loc) => gl.enableVertexAttribArray(loc)

///|
pub extern "js" fn WebGL::vertex_attrib_pointer(
  self : WebGL,
  loc : Int,
  size : Int,
  kind : Int,
  normalized : Bool,
  stride : Int,
  offset : Int,
) -> Unit =
  #| (gl, loc, size, kind, normalized, stride, offset) =>
  #|   gl.vertexAttribPointer(loc, size, kind, normalized, stride, offset)

///|
/// Uniforms.
extern "js" fn WebGL::get_uniform_location_ffi(
  self : WebGL,
  program : WebGLProgram,
  name : String,
) -> @js.Nullable[WebGLUniformLocation] =
  #| (gl, program, name) => gl.getUniformLocation(program, name)

///|
pub fn WebGL::get_uniform_location(
  self : WebGL,
  program : WebGLProgram,
  name : String,
) -> WebGLUniformLocation? {
  self.get_uniform_location_ffi(program, name).to_option()
}

///|
pub extern "js" fn WebGL::uniform1f(
  self : WebGL,
  loc : WebGLUniformLocation,
  v0 : Double,
) -> Unit =
  #| (gl, loc, v0) => gl.uniform1f(loc, v0)

///|
pub extern "js" fn WebGL::uniform1i(
  self : WebGL,
  loc : WebGLUniformLocation,
  v0 : Int,
) -> Unit =
  #| (gl, loc, v0) => gl.uniform1i(loc, v0)

///|
pub extern "js" fn WebGL::uniform2f(
  self : WebGL,
  loc : WebGLUniformLocation,
  v0 : Double,
  v1 : Double,
) -> Unit =
  #| (gl, loc, v0, v1) => gl.uniform2f(loc, v0, v1)

///|
pub extern "js" fn WebGL::uniform3f(
  self : WebGL,
  loc : WebGLUniformLocation,
  v0 : Double,
  v1 : Double,
  v2 : Double,
) -> Unit =
  #| (gl, loc, v0, v1, v2) => gl.uniform3f(loc, v0, v1, v2)

///|
pub extern "js" fn WebGL::uniform4f(
  self : WebGL,
  loc : WebGLUniformLocation,
  v0 : Double,
  v1 : Double,
  v2 : Double,
  v3 : Double,
) -> Unit =
  #| (gl, loc, v0, v1, v2, v3) => gl.uniform4f(loc, v0, v1, v2, v3)

///|
pub extern "js" fn WebGL::uniform_matrix4(
  self : WebGL,
  loc : WebGLUniformLocation,
  transpose : Bool,
  data : @js.Value,
) -> Unit =
  #| (gl, loc, transpose, data) => gl.uniformMatrix4fv(loc, transpose, data)

///|
/// Textures.
extern "js" fn WebGL::create_texture_ffi(
  self : WebGL,
) -> @js.Nullable[WebGLTexture] =
  #| (gl) => gl.createTexture()

///|
pub fn WebGL::create_texture(self : WebGL) -> WebGLTexture? {
  self.create_texture_ffi().to_option()
}

///|
pub extern "js" fn WebGL::active_texture(self : WebGL, unit : Int) -> Unit =
  #| (gl, unit) => gl.activeTexture(unit)

///|
pub extern "js" fn WebGL::bind_texture(
  self : WebGL,
  target : Int,
  tex : WebGLTexture,
) -> Unit =
  #| (gl, target, tex) => gl.bindTexture(target, tex)

///|
pub extern "js" fn WebGL::tex_param_i(
  self : WebGL,
  target : Int,
  pname : Int,
  value : Int,
) -> Unit =
  #| (gl, target, pname, value) => gl.texParameteri(target, pname, value)

///|
pub extern "js" fn WebGL::tex_image_2d(
  self : WebGL,
  target : Int,
  level : Int,
  internal_format : Int,
  width : Int,
  height : Int,
  border : Int,
  format : Int,
  kind : Int,
  data : @js.Value,
) -> Unit =
  #| (gl, target, level, internal_format, width, height, border, format, kind, data) =>
  #|   gl.texImage2D(target, level, internal_format, width, height, border, format, kind, data)

///|
/// Upload texture from a JS image/canvas/video source.
pub extern "js" fn WebGL::tex_image_2d_source(
  self : WebGL,
  target : Int,
  level : Int,
  internal_format : Int,
  format : Int,
  kind : Int,
  source : @js.Value,
) -> Unit =
  #| (gl, target, level, internal_format, format, kind, source) =>
  #|   gl.texImage2D(target, level, internal_format, format, kind, source)

///|
pub extern "js" fn WebGL::generate_mipmap(self : WebGL, target : Int) -> Unit =
  #| (gl, target) => gl.generateMipmap(target)

///|
/// Frame setup and drawing.
pub extern "js" fn WebGL::viewport(
  self : WebGL,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
) -> Unit =
  #| (gl, x, y, w, h) => gl.viewport(x, y, w, h)

///|
pub extern "js" fn WebGL::clear_color(
  self : WebGL,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> Unit =
  #| (gl, r, g, b, a) => gl.clearColor(r, g, b, a)

///|
pub extern "js" fn WebGL::enable(self : WebGL, cap : Int) -> Unit =
  #| (gl, cap) => gl.enable(cap)

///|
pub extern "js" fn WebGL::blend_func(
  self : WebGL,
  sfactor : Int,
  dfactor : Int,
) -> Unit =
  #| (gl, sfactor, dfactor) => gl.blendFunc(sfactor, dfactor)

///|
pub extern "js" fn WebGL::clear(self : WebGL, mask : Int) -> Unit =
  #| (gl, mask) => gl.clear(mask)

///|
pub extern "js" fn WebGL::draw_arrays(
  self : WebGL,
  mode : Int,
  first : Int,
  count : Int,
) -> Unit =
  #| (gl, mode, first, count) => gl.drawArrays(mode, first, count)

///|
pub extern "js" fn WebGL::draw_elements(
  self : WebGL,
  mode : Int,
  count : Int,
  kind : Int,
  offset : Int,
) -> Unit =
  #| (gl, mode, count, kind, offset) => gl.drawElements(mode, count, kind, offset)
