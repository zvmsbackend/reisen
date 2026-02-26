///|
/// PixiJS bindings for the MoonBit JS backend.
///
/// These bindings intentionally stay thin and renderer-focused so they can be
/// consumed by a Pixi-backed presenter without coupling script/runtime layers.

///|
#external
type PixiCanvas

///|
#external
type PixiApplication

///|
#external
type PixiContainer

///|
#external
type PixiSprite

///|
#external
type PixiTexture

///|
#external
type PixiFilter

///|
#external
type PixiBlurFilter

///|
#external
type PixiColorMatrixFilter

///|
#external
type PixiLive2dModel

///|
pub extern "js" fn window_inner_width() -> Double =
  #| () => window.innerWidth

///|
pub extern "js" fn window_inner_height() -> Double =
  #| () => window.innerHeight

///|
extern "js" fn get_canvas_element(id : String) -> @js.Optional[PixiCanvas] =
  #| (id) => document.getElementById(id)

///|
pub fn get_canvas_by_id(id : String) -> PixiCanvas? {
  get_canvas_element(id).to_option()
}

///|
#module("/pixi-bridge.js")
pub fn pixi_new_application() -> PixiApplication = "newApplication"

///|
#module("/pixi-bridge.js")
pub fn pixi_new_container() -> PixiContainer = "newContainer"

///|
#module("/pixi-bridge.js")
pub fn pixi_texture_from(source : @js.Value) -> PixiTexture = "textureFrom"

///|
#module("/pixi-bridge.js")
pub fn pixi_new_sprite(texture : PixiTexture) -> PixiSprite = "spriteFrom"

///|
#module("/pixi-bridge.js")
pub fn pixi_new_filter(
  vertex_src : String,
  fragment_src : String,
) -> PixiFilter = "newFilter"

///|
#module("/pixi-bridge.js")
pub fn pixi_new_blur_filter() -> PixiBlurFilter = "newBlurFilter"

///|
#module("/pixi-bridge.js")
pub fn pixi_new_color_matrix_filter() -> PixiColorMatrixFilter = "newColorMatrixFilter"

///|
#module("/pixi-bridge.js")
fn js_load_live2d_model_promise(source : String) -> @js.Promise = "loadLive2dModel"

///|
pub suberror PixiBindingError {
  ResourceLoadFailed(message~ : String)
}

///|
extern "js" fn load_result_ok(result : @js.Value) -> Bool =
  #| (result) => !!(result && result.ok === true)

///|
extern "js" fn load_result_value(result : @js.Value) -> @js.Value =
  #| (result) => result?.value

///|
extern "js" fn load_result_error(
  result : @js.Value,
  fallback : String,
) -> String =
  #| (result, fallback) => {
  #|   const message = result && typeof result.error === 'string' ? result.error : '';
  #|   return message || fallback;
  #| }

///|
pub async fn pixi_load_live2d_model(
  source : String,
) -> PixiLive2dModel raise PixiBindingError {
  let result = @js.Promise::wait(js_load_live2d_model_promise(source)) catch {
    _ =>
      raise PixiBindingError::ResourceLoadFailed(
        message="Failed to load Live2D model: \{source}",
      )
  }
  if !load_result_ok(result) {
    raise PixiBindingError::ResourceLoadFailed(
      message=load_result_error(
        result,
        "Failed to load Live2D model: \{source}",
      ),
    )
  }
  load_result_value(result).cast()
}

///|
#module("/pixi-bridge.js")
fn js_assets_load_promise(source : String) -> @js.Promise = "loadTexturePromise"

///|
pub async fn pixi_assets_load_texture(
  source : String,
) -> PixiTexture raise PixiBindingError {
  let result = @js.Promise::wait(js_assets_load_promise(source)) catch {
    _ =>
      raise PixiBindingError::ResourceLoadFailed(
        message="Failed to load Pixi texture: \{source}",
      )
  }
  if !load_result_ok(result) {
    raise PixiBindingError::ResourceLoadFailed(
      message=load_result_error(
        result,
        "Failed to load Pixi texture: \{source}",
      ),
    )
  }
  load_result_value(result).cast()
}

///|
extern "js" fn PixiApplication::init_with_canvas_promise(
  self : PixiApplication,
  canvas : @js.Value,
  width : Int,
  height : Int,
  antialias : Bool,
  background_alpha : Double,
  resolution : Double,
  auto_density : Bool,
) -> @js.Promise =
  #| (app, canvas, width, height, antialias, background_alpha, resolution, auto_density) =>
  #|   app.init({
  #|     canvas,
  #|     width,
  #|     height,
  #|     antialias,
  #|     backgroundAlpha: background_alpha,
  #|     resolution,
  #|     autoDensity: auto_density,
  #|   })

///|
pub async fn PixiApplication::init_with_canvas(
  self : PixiApplication,
  canvas : @js.Value,
  width : Int,
  height : Int,
  antialias? : Bool = true,
  background_alpha? : Double = 0.0,
  resolution? : Double = 1.0,
  auto_density? : Bool = true,
) -> Unit {
  @js.Promise::wait(
    self.init_with_canvas_promise(
      canvas, width, height, antialias, background_alpha, resolution, auto_density,
    ),
  )
  |> ignore
}

///|
extern "js" fn PixiApplication::stage(self : PixiApplication) -> PixiContainer =
  #| (app) => app.stage

///|
extern "js" fn PixiApplication::renderer_resize(
  self : PixiApplication,
  width : Int,
  height : Int,
) -> Unit =
  #| (app, width, height) => app.renderer.resize(width, height)

///|
extern "js" fn PixiContainer::add_sprite(
  self : PixiContainer,
  child : PixiSprite,
) -> Unit =
  #| (self, child) => { self.addChild(child); }

///|
extern "js" fn PixiContainer::remove_sprite(
  self : PixiContainer,
  child : PixiSprite,
) -> Unit =
  #| (self, child) => { self.removeChild(child); }

///|
extern "js" fn PixiContainer::add_live2d(
  self : PixiContainer,
  child : PixiLive2dModel,
) -> Unit =
  #| (self, child) => { self.addChild(child); }

///|
extern "js" fn PixiContainer::remove_live2d(
  self : PixiContainer,
  child : PixiLive2dModel,
) -> Unit =
  #| (self, child) => { self.removeChild(child); }

///|
extern "js" fn PixiContainer::set_sortable_children(
  self : PixiContainer,
  sortable : Bool,
) -> Unit =
  #| (self, sortable) => { self.sortableChildren = sortable; }

///|
extern "js" fn PixiSprite::set_texture(
  self : PixiSprite,
  texture : PixiTexture,
) -> Unit =
  #| (self, texture) => { self.texture = texture; }

///|
pub extern "js" fn PixiSprite::set_filters(
  self : PixiSprite,
  filters : Array[@js.Value],
) -> Unit =
  #| (self, filters) => { self.filters = filters.length > 0 ? filters : null; }

///|
extern "js" fn PixiSprite::set_anchor(
  self : PixiSprite,
  x : Double,
  y : Double,
) -> Unit =
  #| (self, x, y) => { self.anchor.set(x, y); }

///|
pub extern "js" fn PixiSprite::set_position(
  self : PixiSprite,
  x : Double,
  y : Double,
) -> Unit =
  #| (self, x, y) => { self.position.set(x, y); }

///|
pub extern "js" fn PixiSprite::set_scale(
  self : PixiSprite,
  x : Double,
  y : Double,
) -> Unit =
  #| (self, x, y) => { self.scale.set(x, y); }

///|
extern "js" fn PixiSprite::set_size(
  self : PixiSprite,
  width : Double,
  height : Double,
) -> Unit =
  #| (self, width, height) => {
  #|   self.width = width;
  #|   self.height = height;
  #| }

///|
pub extern "js" fn PixiSprite::set_rotation(
  self : PixiSprite,
  radians : Double,
) -> Unit =
  #| (self, radians) => { self.rotation = radians; }

///|
pub extern "js" fn PixiSprite::set_alpha(
  self : PixiSprite,
  alpha : Double,
) -> Unit =
  #| (self, alpha) => { self.alpha = alpha; }

///|
extern "js" fn PixiSprite::set_visible(
  self : PixiSprite,
  visible : Bool,
) -> Unit =
  #| (self, visible) => { self.visible = visible; }

///|
pub extern "js" fn PixiSprite::set_tint(
  self : PixiSprite,
  tint_rgb : Int,
) -> Unit =
  #| (self, tint_rgb) => { self.tint = tint_rgb; }

///|
extern "js" fn PixiSprite::set_z_index(
  self : PixiSprite,
  z_index : Int,
) -> Unit =
  #| (self, z_index) => { self.zIndex = z_index; }

///|
pub extern "js" fn PixiLive2dModel::set_anchor(
  self : PixiLive2dModel,
  x : Double,
  y : Double,
) -> Unit =
  #| (self, x, y) => {
  #|   if (self.anchor && self.anchor.set) {
  #|     self.anchor.set(x, y);
  #|   }
  #| }

///|
pub extern "js" fn PixiLive2dModel::set_position(
  self : PixiLive2dModel,
  x : Double,
  y : Double,
) -> Unit =
  #| (self, x, y) => {
  #|   if (self.position && self.position.set) {
  #|     self.position.set(x, y);
  #|   } else {
  #|     self.x = x;
  #|     self.y = y;
  #|   }
  #| }

///|
pub extern "js" fn PixiLive2dModel::set_scale(
  self : PixiLive2dModel,
  x : Double,
  y : Double,
) -> Unit =
  #| (self, x, y) => {
  #|   if (self.scale && self.scale.set) {
  #|     self.scale.set(x, y);
  #|   }
  #| }

///|
pub extern "js" fn PixiLive2dModel::width(self : PixiLive2dModel) -> Double =
  #| (self) => Number(self.width) || 0

///|
pub extern "js" fn PixiLive2dModel::height(self : PixiLive2dModel) -> Double =
  #| (self) => Number(self.height) || 0

///|
pub extern "js" fn PixiLive2dModel::set_size(
  self : PixiLive2dModel,
  width : Double,
  height : Double,
) -> Unit =
  #| (self, width, height) => {
  #|   self.width = width;
  #|   self.height = height;
  #| }

///|
pub extern "js" fn PixiLive2dModel::set_rotation(
  self : PixiLive2dModel,
  radians : Double,
) -> Unit =
  #| (self, radians) => { self.rotation = radians; }

///|
pub extern "js" fn PixiLive2dModel::set_alpha(
  self : PixiLive2dModel,
  alpha : Double,
) -> Unit =
  #| (self, alpha) => { self.alpha = alpha; }

///|
pub extern "js" fn PixiLive2dModel::set_visible(
  self : PixiLive2dModel,
  visible : Bool,
) -> Unit =
  #| (self, visible) => { self.visible = visible; }

///|
pub extern "js" fn PixiLive2dModel::set_filters(
  self : PixiLive2dModel,
  filters : Array[@js.Value],
) -> Unit =
  #| (self, filters) => { self.filters = filters.length > 0 ? filters : null; }

///|
pub extern "js" fn PixiLive2dModel::set_interactive(
  self : PixiLive2dModel,
  interactive : Bool,
) -> Unit =
  #| (self, interactive) => {
  #|   self.autoInteract = interactive;
  #| }

///|
pub extern "js" fn PixiLive2dModel::set_z_index(
  self : PixiLive2dModel,
  z_index : Int,
) -> Unit =
  #| (self, z_index) => { self.zIndex = z_index; }

///|
pub extern "js" fn PixiLive2dModel::focus(
  self : PixiLive2dModel,
  x : Double,
  y : Double,
  instant? : Bool = false,
) -> Unit =
  #| (self, x, y, instant) => {
  #|   if (typeof self.focus === 'function') {
  #|     self.focus(x, y, instant);
  #|   }
  #| }

///|
pub extern "js" fn PixiLive2dModel::destroy(self : PixiLive2dModel) -> Unit =
  #| (self) => {
  #|   if (typeof self.destroy === 'function') {
  #|     self.destroy({ children: true, texture: false, baseTexture: false });
  #|   }
  #| }

///|
#module("/pixi-bridge.js")
fn js_live2d_motion_promise(
  model : PixiLive2dModel,
  group : String,
  index? : Int,
) -> @js.Promise = "live2dMotion"

///|
pub async fn PixiLive2dModel::motion(
  self : PixiLive2dModel,
  group : String,
  index? : Int,
) -> Bool {
  let v = @js.Promise::wait(js_live2d_motion_promise(self, group, index?))
  v.cast()
}

///|
pub extern "js" fn PixiLive2dModel::start_motion(
  self : PixiLive2dModel,
  group : String,
  index : @js.Optional[Int],
) -> Unit =
  #| (self, group, index) => {
  #|   if (typeof self.motion === 'function') {
  #|     Promise.resolve(self.motion(group, index, 3)).catch((e) => {});
  #|   }
  #| }

///|
#module("/pixi-bridge.js")
fn js_live2d_expression_promise(
  model : PixiLive2dModel,
  id? : String,
) -> @js.Promise = "live2dExpression"

///|
pub async fn PixiLive2dModel::expression(
  self : PixiLive2dModel,
  id? : String,
) -> Bool {
  let v = @js.Promise::wait(js_live2d_expression_promise(self, id?))
  v.cast()
}

///|
pub extern "js" fn PixiLive2dModel::set_expression(
  self : PixiLive2dModel,
  id : @js.Optional[String],
) -> Unit =
  #| (self, id) => {
  #|   if (typeof self.expression === 'function') {
  #|     Promise.resolve(self.expression(id)).catch(() => {});
  #|   }
  #| }

///|
extern "js" fn PixiTexture::width(self : PixiTexture) -> Double =
  #| (self) => {
  #|   const w = self.width ?? self.orig?.width ?? 0;
  #|   return Number(w) || 0;
  #| }

///|
extern "js" fn PixiTexture::height(self : PixiTexture) -> Double =
  #| (self) => {
  #|   const h = self.height ?? self.orig?.height ?? 0;
  #|   return Number(h) || 0;
  #| }

///|
extern "js" fn PixiTexture::update(self : PixiTexture) -> Unit =
  #| (self) => {
  #|   if (self.update) self.update();
  #| }

///|
extern "js" fn PixiBlurFilter::set_strength(
  self : PixiBlurFilter,
  value : Double,
) -> Unit =
  #| (self, value) => {
  #|   const v = Math.max(0, Number(value) || 0);
  #|   self.blur = v;
  #|   self.blurX = v;
  #|   self.blurY = v;
  #| }

///|
extern "js" fn PixiColorMatrixFilter::apply_adjustments(
  self : PixiColorMatrixFilter,
  brightness : Double,
  contrast : Double,
  saturation : Double,
  gamma : Double,
  color_r : Double,
  color_g : Double,
  color_b : Double,
) -> Unit =
  #| (self, brightness, contrast, saturation, gamma, color_r, color_g, color_b) => {
  #|   if (self.reset) self.reset();
  #|   if (self.brightness) self.brightness(brightness, false);
  #|   if (self.contrast) self.contrast(contrast, false);
  #|   if (self.saturate) self.saturate(saturation, false);
  #|   if (self.matrix) {
  #|     const safeGamma = gamma > 0 ? gamma : 1;
  #|     const g = 1 / safeGamma;
  #|     self.matrix[0] *= g;
  #|     self.matrix[6] *= g;
  #|     self.matrix[12] *= g;
  #|     self.matrix[0] *= color_r;
  #|     self.matrix[6] *= color_g;
  #|     self.matrix[12] *= color_b;
  #|   }
  #| }
