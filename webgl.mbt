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
pub impl @js.Cast for Canvas with into(value) {
  Some(value.cast())
}

///|
pub impl @js.Cast for Canvas with from(value) {
  @js.Value::cast_from(value)
}

///|
pub impl @js.Cast for WebGL with into(value) {
  Some(value.cast())
}

///|
pub impl @js.Cast for WebGL with from(value) {
  @js.Value::cast_from(value)
}

///|
pub impl @js.Cast for WebGLProgram with into(value) {
  Some(value.cast())
}

///|
pub impl @js.Cast for WebGLProgram with from(value) {
  @js.Value::cast_from(value)
}

///|
pub impl @js.Cast for WebGLShader with into(value) {
  Some(value.cast())
}

///|
pub impl @js.Cast for WebGLShader with from(value) {
  @js.Value::cast_from(value)
}

///|
pub impl @js.Cast for WebGLBuffer with into(value) {
  Some(value.cast())
}

///|
pub impl @js.Cast for WebGLBuffer with from(value) {
  @js.Value::cast_from(value)
}

///|
pub impl @js.Cast for WebGLTexture with into(value) {
  Some(value.cast())
}

///|
pub impl @js.Cast for WebGLTexture with from(value) {
  @js.Value::cast_from(value)
}

///|
pub impl @js.Cast for WebGLUniformLocation with into(value) {
  Some(value.cast())
}

///|
pub impl @js.Cast for WebGLUniformLocation with from(value) {
  @js.Value::cast_from(value)
}

///|
fn global_get(name : String) -> @js.Value {
  @js.globalThis.get_with_string(name)
}

///|
fn[T] v(x : T) -> @js.Value {
  @js.Value::cast_from(x)
}

///|
fn no_args() -> Array[@js.Value] {
  []
}

///|
pub fn get_canvas_by_id(id : String) -> Canvas? {
  let doc = global_get("document")
  let el : @js.Nullable[Canvas] = doc.apply_with_string("getElementById", [
    v(id),
  ])
  el.to_option()
}

///|
pub fn Canvas::get_webgl_context(self : Canvas) -> WebGL? {
  let ctx : @js.Nullable[WebGL] = v(self).apply_with_string("getContext", [
    v("webgl"),
  ])
  ctx.to_option()
}

///|
pub fn Canvas::get_webgl2_context(self : Canvas) -> WebGL? {
  let ctx : @js.Nullable[WebGL] = v(self).apply_with_string("getContext", [
    v("webgl2"),
  ])
  ctx.to_option()
}

///|
/// Common WebGL constants.
pub fn WebGL::constant(self : WebGL, name : String) -> Int {
  v(self).get_with_string(name)
}

///|
/// Shader/program creation.
pub fn WebGL::create_shader(self : WebGL, kind : Int) -> WebGLShader? {
  let shader : @js.Nullable[WebGLShader] = v(self).apply_with_string(
    "createShader",
    [v(kind)],
  )
  shader.to_option()
}

///|
pub fn WebGL::shader_source(
  self : WebGL,
  shader : WebGLShader,
  src : String,
) -> Unit {
  v(self).apply_with_string("shaderSource", [v(shader), v(src)])
}

///|
pub fn WebGL::compile_shader(self : WebGL, shader : WebGLShader) -> Unit {
  v(self).apply_with_string("compileShader", [v(shader)])
}

///|
pub fn WebGL::get_shader_parameter(
  self : WebGL,
  shader : WebGLShader,
  pname : Int,
) -> Bool {
  v(self).apply_with_string("getShaderParameter", [v(shader), v(pname)])
}

///|
pub fn WebGL::get_shader_info_log(self : WebGL, shader : WebGLShader) -> String {
  v(self).apply_with_string("getShaderInfoLog", [v(shader)])
}

///|
pub fn WebGL::create_program(self : WebGL) -> WebGLProgram? {
  let program : @js.Nullable[WebGLProgram] = v(self).apply_with_string(
    "createProgram",
    no_args(),
  )
  program.to_option()
}

///|
pub fn WebGL::attach_shader(
  self : WebGL,
  program : WebGLProgram,
  shader : WebGLShader,
) -> Unit {
  v(self).apply_with_string("attachShader", [v(program), v(shader)])
}

///|
pub fn WebGL::link_program(self : WebGL, program : WebGLProgram) -> Unit {
  v(self).apply_with_string("linkProgram", [v(program)])
}

///|
pub fn WebGL::get_program_parameter(
  self : WebGL,
  program : WebGLProgram,
  pname : Int,
) -> Bool {
  v(self).apply_with_string("getProgramParameter", [v(program), v(pname)])
}

///|
pub fn WebGL::get_program_info_log(
  self : WebGL,
  program : WebGLProgram,
) -> String {
  v(self).apply_with_string("getProgramInfoLog", [v(program)])
}

///|
pub fn WebGL::use_program(self : WebGL, program : WebGLProgram) -> Unit {
  v(self).apply_with_string("useProgram", [v(program)])
}

///|
/// Buffers and attributes.
pub fn WebGL::create_buffer(self : WebGL) -> WebGLBuffer? {
  let buf : @js.Nullable[WebGLBuffer] = v(self).apply_with_string(
    "createBuffer",
    no_args(),
  )
  buf.to_option()
}

///|
pub fn WebGL::bind_buffer(
  self : WebGL,
  target : Int,
  buf : WebGLBuffer,
) -> Unit {
  v(self).apply_with_string("bindBuffer", [v(target), v(buf)])
}

///|
pub fn js_float32_array(data : Array[Double]) -> @js.Value {
  let ctor = global_get("Float32Array")
  ctor.new([data])
}

///|
pub fn js_uint16_array(data : Array[Int]) -> @js.Value {
  let ctor = global_get("Uint16Array")
  ctor.new([data])
}

///|
pub fn js_uint8_array(data : Array[Int]) -> @js.Value {
  let ctor = global_get("Uint8Array")
  ctor.new([data])
}

///|
pub fn WebGL::buffer_data(
  self : WebGL,
  target : Int,
  data : @js.Value,
  usage : Int,
) -> Unit {
  v(self).apply_with_string("bufferData", [v(target), data, v(usage)])
}

///|
pub fn WebGL::get_attrib_location(
  self : WebGL,
  program : WebGLProgram,
  name : String,
) -> Int {
  v(self).apply_with_string("getAttribLocation", [v(program), v(name)])
}

///|
pub fn WebGL::enable_vertex_attrib_array(self : WebGL, loc : Int) -> Unit {
  v(self).apply_with_string("enableVertexAttribArray", [v(loc)])
}

///|
pub fn WebGL::vertex_attrib_pointer(
  self : WebGL,
  loc : Int,
  size : Int,
  kind : Int,
  normalized : Bool,
  stride : Int,
  offset : Int,
) -> Unit {
  v(self).apply_with_string("vertexAttribPointer", [
    v(loc),
    v(size),
    v(kind),
    v(normalized),
    v(stride),
    v(offset),
  ])
}

///|
/// Uniforms.
pub fn WebGL::get_uniform_location(
  self : WebGL,
  program : WebGLProgram,
  name : String,
) -> WebGLUniformLocation? {
  let loc : @js.Nullable[WebGLUniformLocation] = v(self).apply_with_string(
    "getUniformLocation",
    [v(program), v(name)],
  )
  loc.to_option()
}

///|
pub fn WebGL::uniform1f(
  self : WebGL,
  loc : WebGLUniformLocation,
  v0 : Double,
) -> Unit {
  v(self).apply_with_string("uniform1f", [v(loc), v(v0)])
}

///|
pub fn WebGL::uniform1i(
  self : WebGL,
  loc : WebGLUniformLocation,
  v0 : Int,
) -> Unit {
  v(self).apply_with_string("uniform1i", [v(loc), v(v0)])
}

///|
pub fn WebGL::uniform2f(
  self : WebGL,
  loc : WebGLUniformLocation,
  v0 : Double,
  v1 : Double,
) -> Unit {
  v(self).apply_with_string("uniform2f", [v(loc), v(v0), v(v1)])
}

///|
pub fn WebGL::uniform4f(
  self : WebGL,
  loc : WebGLUniformLocation,
  v0 : Double,
  v1 : Double,
  v2 : Double,
  v3 : Double,
) -> Unit {
  v(self).apply_with_string("uniform4f", [v(loc), v(v0), v(v1), v(v2), v(v3)])
}

///|
pub fn WebGL::uniform_matrix4(
  self : WebGL,
  loc : WebGLUniformLocation,
  transpose : Bool,
  data : @js.Value,
) -> Unit {
  v(self).apply_with_string("uniformMatrix4fv", [v(loc), v(transpose), data])
}

///|
/// Textures.
pub fn WebGL::create_texture(self : WebGL) -> WebGLTexture? {
  let tex : @js.Nullable[WebGLTexture] = v(self).apply_with_string(
    "createTexture",
    no_args(),
  )
  tex.to_option()
}

///|
pub fn WebGL::active_texture(self : WebGL, unit : Int) -> Unit {
  v(self).apply_with_string("activeTexture", [v(unit)])
}

///|
pub fn WebGL::bind_texture(
  self : WebGL,
  target : Int,
  tex : WebGLTexture,
) -> Unit {
  v(self).apply_with_string("bindTexture", [v(target), v(tex)])
}

///|
pub fn WebGL::tex_param_i(
  self : WebGL,
  target : Int,
  pname : Int,
  value : Int,
) -> Unit {
  v(self).apply_with_string("texParameteri", [v(target), v(pname), v(value)])
}

///|
pub fn WebGL::tex_image_2d(
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
) -> Unit {
  v(self).apply_with_string("texImage2D", [
    v(target),
    v(level),
    v(internal_format),
    v(width),
    v(height),
    v(border),
    v(format),
    v(kind),
    data,
  ])
}

///|
/// Upload texture from a JS image/canvas/video source.
pub fn WebGL::tex_image_2d_source(
  self : WebGL,
  target : Int,
  level : Int,
  internal_format : Int,
  format : Int,
  kind : Int,
  source : @js.Value,
) -> Unit {
  v(self).apply_with_string("texImage2D", [
    v(target),
    v(level),
    v(internal_format),
    v(format),
    v(kind),
    source,
  ])
}

///|
pub fn WebGL::generate_mipmap(self : WebGL, target : Int) -> Unit {
  v(self).apply_with_string("generateMipmap", [v(target)])
}

///|
/// Frame setup and drawing.
pub fn WebGL::viewport(
  self : WebGL,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
) -> Unit {
  v(self).apply_with_string("viewport", [v(x), v(y), v(w), v(h)])
}

///|
pub fn WebGL::clear_color(
  self : WebGL,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> Unit {
  v(self).apply_with_string("clearColor", [v(r), v(g), v(b), v(a)])
}

///|
pub fn WebGL::clear(self : WebGL, mask : Int) -> Unit {
  v(self).apply_with_string("clear", [v(mask)])
}

///|
pub fn WebGL::draw_arrays(
  self : WebGL,
  mode : Int,
  first : Int,
  count : Int,
) -> Unit {
  v(self).apply_with_string("drawArrays", [v(mode), v(first), v(count)])
}

///|
pub fn WebGL::draw_elements(
  self : WebGL,
  mode : Int,
  count : Int,
  kind : Int,
  offset : Int,
) -> Unit {
  v(self).apply_with_string("drawElements", [
    v(mode),
    v(count),
    v(kind),
    v(offset),
  ])
}
