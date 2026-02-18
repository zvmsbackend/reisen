///|
/// WebGL bindings implemented on top of moonbit-community/js-ffi/js.
///
/// These are intentionally thin wrappers around the JS WebGL API.
/// We keep them as `Value`-backed types and expose small helpers to
/// reduce repetitive JS interop code.
///
/// All blocks are split with `///|` per MoonBit conventions.

///|
type Js = @js.Value

///|
/// JS-backed WebGL object aliases.
type Canvas = Js
type WebGL = Js
type WebGLProgram = Js
type WebGLShader = Js
type WebGLBuffer = Js
type WebGLTexture = Js
type WebGLUniformLocation = Js

///|
fn global_get(name : String) -> Js {
  @js.globalThis.get_with_string(name)
}

///|
fn v[T : @js.Cast](x : T) -> Js {
  @js.Value::cast_from(x)
}

///|
fn no_args() -> Array[Js] {
  []
}

///|
pub fn get_canvas_by_id(id : String) -> Canvas? {
  let doc = global_get("document")
  let el : @js.Nullable[Canvas] =
    doc.apply_with_string("getElementById", [v(id)])
  el.to_option()
}

///|
pub fn get_webgl_context(canvas : Canvas) -> WebGL? {
  let ctx : @js.Nullable[WebGL] =
    canvas.apply_with_string("getContext", [v("webgl")])
  ctx.to_option()
}

///|
pub fn get_webgl2_context(canvas : Canvas) -> WebGL? {
  let ctx : @js.Nullable[WebGL] =
    canvas.apply_with_string("getContext", [v("webgl2")])
  ctx.to_option()
}

///|
/// Common WebGL constants.
pub fn gl_const(gl : WebGL, name : String) -> Int {
  gl.get_with_string(name)
}

///|
/// Shader/program creation.
pub fn gl_create_shader(gl : WebGL, kind : Int) -> WebGLShader? {
  let shader : @js.Nullable[WebGLShader] =
    gl.apply_with_string("createShader", [v(kind)])
  shader.to_option()
}

///|
pub fn gl_shader_source(gl : WebGL, shader : WebGLShader, src : String) -> Unit {
  (gl.apply_with_string("shaderSource", [shader, v(src)]))
}

///|
pub fn gl_compile_shader(gl : WebGL, shader : WebGLShader) -> Unit {
  (gl.apply_with_string("compileShader", [shader]))
}

///|
pub fn gl_get_shader_parameter(
  gl : WebGL,
  shader : WebGLShader,
  pname : Int,
) -> Bool {
  gl.apply_with_string("getShaderParameter", [shader, v(pname)])
}

///|
pub fn gl_get_shader_info_log(gl : WebGL, shader : WebGLShader) -> String {
  gl.apply_with_string("getShaderInfoLog", [shader])
}

///|
pub fn gl_create_program(gl : WebGL) -> WebGLProgram? {
  let program : @js.Nullable[WebGLProgram] =
    gl.apply_with_string("createProgram", no_args())
  program.to_option()
}

///|
pub fn gl_attach_shader(
  gl : WebGL,
  program : WebGLProgram,
  shader : WebGLShader,
) -> Unit {
  (gl.apply_with_string("attachShader", [program, shader]))
}

///|
pub fn gl_link_program(gl : WebGL, program : WebGLProgram) -> Unit {
  (gl.apply_with_string("linkProgram", [program]))
}

///|
pub fn gl_get_program_parameter(
  gl : WebGL,
  program : WebGLProgram,
  pname : Int,
) -> Bool {
  gl.apply_with_string("getProgramParameter", [program, v(pname)])
}

///|
pub fn gl_get_program_info_log(gl : WebGL, program : WebGLProgram) -> String {
  gl.apply_with_string("getProgramInfoLog", [program])
}

///|
pub fn gl_use_program(gl : WebGL, program : WebGLProgram) -> Unit {
  (gl.apply_with_string("useProgram", [program]))
}

///|
/// Buffers and attributes.
pub fn gl_create_buffer(gl : WebGL) -> WebGLBuffer? {
  let buf : @js.Nullable[WebGLBuffer] =
    gl.apply_with_string("createBuffer", no_args())
  buf.to_option()
}

///|
pub fn gl_bind_buffer(gl : WebGL, target : Int, buf : WebGLBuffer) -> Unit {
  (gl.apply_with_string("bindBuffer", [v(target), buf]))
}

///|
pub fn js_float32_array(data : Array[Double]) -> Js {
  let ctor = global_get("Float32Array")
  ctor.new([data])
}

///|
pub fn js_uint16_array(data : Array[Int]) -> Js {
  let ctor = global_get("Uint16Array")
  ctor.new([data])
}

///|
pub fn gl_buffer_data(gl : WebGL, target : Int, data : Js, usage : Int) -> Unit {
  (gl.apply_with_string("bufferData", [v(target), data, v(usage)]))
}

///|
pub fn gl_get_attrib_location(
  gl : WebGL,
  program : WebGLProgram,
  name : String,
) -> Int {
  gl.apply_with_string("getAttribLocation", [program, v(name)])
}

///|
pub fn gl_enable_vertex_attrib_array(gl : WebGL, loc : Int) -> Unit {
  (gl.apply_with_string("enableVertexAttribArray", [v(loc)]))
}

///|
pub fn gl_vertex_attrib_pointer(
  gl : WebGL,
  loc : Int,
  size : Int,
  kind : Int,
  normalized : Bool,
  stride : Int,
  offset : Int,
) -> Unit {
  (
    gl.apply_with_string(
      "vertexAttribPointer",
      [v(loc), v(size), v(kind), v(normalized), v(stride), v(offset)],
    ),
  )
}

///|
/// Uniforms.
pub fn gl_get_uniform_location(
  gl : WebGL,
  program : WebGLProgram,
  name : String,
) -> WebGLUniformLocation? {
  let loc : @js.Nullable[WebGLUniformLocation] =
    gl.apply_with_string("getUniformLocation", [program, v(name)])
  loc.to_option()
}

///|
pub fn gl_uniform1f(gl : WebGL, loc : WebGLUniformLocation, v0 : Double) -> Unit {
  (gl.apply_with_string("uniform1f", [loc, v(v0)]))
}

///|
pub fn gl_uniform2f(
  gl : WebGL,
  loc : WebGLUniformLocation,
  v0 : Double,
  v1 : Double,
) -> Unit {
  (gl.apply_with_string("uniform2f", [loc, v(v0), v(v1)]))
}

///|
pub fn gl_uniform4f(
  gl : WebGL,
  loc : WebGLUniformLocation,
  v0 : Double,
  v1 : Double,
  v2 : Double,
  v3 : Double,
) -> Unit {
  (
    gl.apply_with_string("uniform4f", [loc, v(v0), v(v1), v(v2), v(v3)]),
  )
}

///|
pub fn gl_uniform_matrix4(
  gl : WebGL,
  loc : WebGLUniformLocation,
  transpose : Bool,
  data : Js,
) -> Unit {
  (
    gl.apply_with_string("uniformMatrix4fv", [loc, v(transpose), data]),
  )
}

///|
/// Textures.
pub fn gl_create_texture(gl : WebGL) -> WebGLTexture? {
  let tex : @js.Nullable[WebGLTexture] =
    gl.apply_with_string("createTexture", no_args())
  tex.to_option()
}

///|
pub fn gl_active_texture(gl : WebGL, unit : Int) -> Unit {
  (gl.apply_with_string("activeTexture", [v(unit)]))
}

///|
pub fn gl_bind_texture(gl : WebGL, target : Int, tex : WebGLTexture) -> Unit {
  (gl.apply_with_string("bindTexture", [v(target), tex]))
}

///|
pub fn gl_tex_param_i(gl : WebGL, target : Int, pname : Int, value : Int) -> Unit {
  (gl.apply_with_string("texParameteri", [v(target), v(pname), v(value)]))
}

///|
pub fn gl_tex_image_2d(
  gl : WebGL,
  target : Int,
  level : Int,
  internal_format : Int,
  width : Int,
  height : Int,
  border : Int,
  format : Int,
  kind : Int,
  data : Js,
) -> Unit {
  (
    gl.apply_with_string(
      "texImage2D",
      [
        v(target),
        v(level),
        v(internal_format),
        v(width),
        v(height),
        v(border),
        v(format),
        v(kind),
        data,
      ],
    ),
  )
}

///|
pub fn gl_generate_mipmap(gl : WebGL, target : Int) -> Unit {
  (gl.apply_with_string("generateMipmap", [v(target)]))
}

///|
/// Frame setup and drawing.
pub fn gl_viewport(gl : WebGL, x : Int, y : Int, w : Int, h : Int) -> Unit {
  (gl.apply_with_string("viewport", [v(x), v(y), v(w), v(h)]))
}

///|
pub fn gl_clear_color(gl : WebGL, r : Double, g : Double, b : Double, a : Double) ->
  Unit {
  (gl.apply_with_string("clearColor", [v(r), v(g), v(b), v(a)]))
}

///|
pub fn gl_clear(gl : WebGL, mask : Int) -> Unit {
  (gl.apply_with_string("clear", [v(mask)]))
}

///|
pub fn gl_draw_arrays(gl : WebGL, mode : Int, first : Int, count : Int) -> Unit {
  (gl.apply_with_string("drawArrays", [v(mode), v(first), v(count)]))
}

///|
pub fn gl_draw_elements(
  gl : WebGL,
  mode : Int,
  count : Int,
  kind : Int,
  offset : Int,
) -> Unit {
  (
    gl.apply_with_string("drawElements", [v(mode), v(count), v(kind), v(offset)]),
  )
}
