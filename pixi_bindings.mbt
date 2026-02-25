///|
/// PixiJS bindings for the MoonBit JS backend.
///
/// These bindings intentionally stay thin and renderer-focused so they can be
/// consumed by a Pixi-backed presenter without coupling script/runtime layers.

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
type PixiTicker

///|
#external
type PixiFilter

///|
#module("pixi.js")
fn pixi_application_class() -> @js.Value = "Application"

///|
#module("pixi.js")
fn pixi_container_class() -> @js.Value = "Container"

///|
#module("pixi.js")
fn pixi_texture_class() -> @js.Value = "Texture"

///|
#module("pixi.js")
fn pixi_sprite_class() -> @js.Value = "Sprite"

///|
#module("pixi.js")
fn pixi_filter_class() -> @js.Value = "Filter"

///|
#module("pixi.js")
fn pixi_assets_namespace() -> @js.Value = "Assets"

///|
extern "js" fn js_new_0(ctor : @js.Value) -> @js.Value =
  #| (ctor) => new ctor()

///|
extern "js" fn js_texture_from_ffi(
  texture_class : @js.Value,
  source : @js.Value,
) -> PixiTexture =
  #| (Texture, source) => Texture.from(source)

///|
extern "js" fn js_sprite_from_texture_ffi(
  sprite_class : @js.Value,
  texture : PixiTexture,
) -> PixiSprite =
  #| (Sprite, texture) => new Sprite(texture)

///|
extern "js" fn js_assets_load_promise(
  assets_ns : @js.Value,
  source : String,
) -> @js.Promise =
  #| (Assets, source) => Assets.load(source)

///|
extern "js" fn js_new_filter_ffi(
  filter_class : @js.Value,
  vertex_src : String,
  fragment_src : String,
) -> PixiFilter =
  #| (Filter, vertex_src, fragment_src) => {
  #|   try {
  #|     return new Filter({ vertex: vertex_src, fragment: fragment_src });
  #|   } catch (_) {
  #|     return new Filter(vertex_src, fragment_src);
  #|   }
  #| }

///|
pub fn pixi_new_application() -> PixiApplication {
  js_new_0(pixi_application_class()).cast()
}

///|
pub fn pixi_new_container() -> PixiContainer {
  js_new_0(pixi_container_class()).cast()
}

///|
pub fn pixi_texture_from(source : @js.Value) -> PixiTexture {
  js_texture_from_ffi(pixi_texture_class(), source)
}

///|
pub fn pixi_new_sprite(texture : PixiTexture) -> PixiSprite {
  js_sprite_from_texture_ffi(pixi_sprite_class(), texture)
}

///|
pub async fn pixi_assets_load_texture(source : String) -> PixiTexture {
  let v = @js.Promise::wait(
    js_assets_load_promise(pixi_assets_namespace(), source),
  )
  v.cast()
}

///|
pub fn pixi_new_filter(
  vertex_src : String,
  fragment_src : String,
) -> PixiFilter {
  js_new_filter_ffi(pixi_filter_class(), vertex_src, fragment_src)
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
extern "js" fn PixiApplication::canvas(self : PixiApplication) -> @js.Value =
  #| (app) => app.canvas ?? app.view

///|
extern "js" fn PixiApplication::renderer_resize(
  self : PixiApplication,
  width : Int,
  height : Int,
) -> Unit =
  #| (app, width, height) => app.renderer.resize(width, height)

///|
extern "js" fn PixiApplication::ticker(self : PixiApplication) -> PixiTicker =
  #| (app) => app.ticker

///|
extern "js" fn PixiApplication::destroy(self : PixiApplication) -> Unit =
  #| (app) => app.destroy(true)

///|
extern "js" fn PixiContainer::add_container(
  self : PixiContainer,
  child : PixiContainer,
) -> Unit =
  #| (self, child) => { self.addChild(child); }

///|
extern "js" fn PixiContainer::add_sprite(
  self : PixiContainer,
  child : PixiSprite,
) -> Unit =
  #| (self, child) => { self.addChild(child); }

///|
extern "js" fn PixiContainer::remove_container(
  self : PixiContainer,
  child : PixiContainer,
) -> Unit =
  #| (self, child) => { self.removeChild(child); }

///|
extern "js" fn PixiContainer::remove_sprite(
  self : PixiContainer,
  child : PixiSprite,
) -> Unit =
  #| (self, child) => { self.removeChild(child); }

///|
extern "js" fn PixiContainer::remove_children(self : PixiContainer) -> Unit =
  #| (self) => { self.removeChildren(); }

///|
extern "js" fn PixiContainer::set_position(
  self : PixiContainer,
  x : Double,
  y : Double,
) -> Unit =
  #| (self, x, y) => { self.position.set(x, y); }

///|
extern "js" fn PixiContainer::set_scale(
  self : PixiContainer,
  x : Double,
  y : Double,
) -> Unit =
  #| (self, x, y) => { self.scale.set(x, y); }

///|
extern "js" fn PixiContainer::set_alpha(
  self : PixiContainer,
  alpha : Double,
) -> Unit =
  #| (self, alpha) => { self.alpha = alpha; }

///|
extern "js" fn PixiContainer::set_visible(
  self : PixiContainer,
  visible : Bool,
) -> Unit =
  #| (self, visible) => { self.visible = visible; }

///|
extern "js" fn PixiContainer::set_z_index(
  self : PixiContainer,
  z_index : Int,
) -> Unit =
  #| (self, z_index) => { self.zIndex = z_index; }

///|
extern "js" fn PixiContainer::set_sortable_children(
  self : PixiContainer,
  sortable : Bool,
) -> Unit =
  #| (self, sortable) => { self.sortableChildren = sortable; }

///|
extern "js" fn PixiContainer::set_filters(
  self : PixiContainer,
  filters : Array[PixiFilter],
) -> Unit =
  #| (self, filters) => { self.filters = filters.length > 0 ? filters : null; }

///|
extern "js" fn PixiSprite::set_texture(
  self : PixiSprite,
  texture : PixiTexture,
) -> Unit =
  #| (self, texture) => { self.texture = texture; }

///|
extern "js" fn PixiSprite::set_anchor(
  self : PixiSprite,
  x : Double,
  y : Double,
) -> Unit =
  #| (self, x, y) => { self.anchor.set(x, y); }

///|
extern "js" fn PixiSprite::set_position(
  self : PixiSprite,
  x : Double,
  y : Double,
) -> Unit =
  #| (self, x, y) => { self.position.set(x, y); }

///|
extern "js" fn PixiSprite::set_scale(
  self : PixiSprite,
  x : Double,
  y : Double,
) -> Unit =
  #| (self, x, y) => { self.scale.set(x, y); }

///|
extern "js" fn PixiSprite::set_alpha(self : PixiSprite, alpha : Double) -> Unit =
  #| (self, alpha) => { self.alpha = alpha; }

///|
extern "js" fn PixiSprite::set_visible(
  self : PixiSprite,
  visible : Bool,
) -> Unit =
  #| (self, visible) => { self.visible = visible; }

///|
extern "js" fn PixiSprite::set_tint(self : PixiSprite, tint_rgb : Int) -> Unit =
  #| (self, tint_rgb) => { self.tint = tint_rgb; }

///|
extern "js" fn PixiSprite::set_blend_mode(
  self : PixiSprite,
  blend_mode : Int,
) -> Unit =
  #| (self, blend_mode) => { self.blendMode = blend_mode; }

///|
extern "js" fn PixiSprite::set_z_index(
  self : PixiSprite,
  z_index : Int,
) -> Unit =
  #| (self, z_index) => { self.zIndex = z_index; }

///|
extern "js" fn PixiTexture::destroy(self : PixiTexture) -> Unit =
  #| (self) => { self.destroy(true); }

///|
extern "js" fn PixiTicker::add(
  self : PixiTicker,
  on_tick : (Double) -> Unit,
) -> Unit =
  #| (ticker, on_tick) => {
  #|   ticker.add((tick) => {
  #|     const dt = tick && typeof tick === 'object' && 'deltaMS' in tick
  #|       ? tick.deltaMS
  #|       : Number(tick) || 0;
  #|     on_tick(dt);
  #|   });
  #| }

///|
extern "js" fn PixiTicker::start(self : PixiTicker) -> Unit =
  #| (ticker) => ticker.start()

///|
extern "js" fn PixiTicker::stop(self : PixiTicker) -> Unit =
  #| (ticker) => ticker.stop()

///|
extern "js" fn PixiFilter::set_uniform_float(
  self : PixiFilter,
  key : String,
  value : Double,
) -> Unit =
  #| (self, key, value) => {
  #|   if (!self.resources) return;
  #|   const uniforms = self.resources.uniforms?.uniforms ?? self.resources.uniforms;
  #|   if (uniforms && key in uniforms) {
  #|     uniforms[key] = value;
  #|   }
  #| }

///|
extern "js" fn PixiFilter::set_uniform_vec2(
  self : PixiFilter,
  key : String,
  x : Double,
  y : Double,
) -> Unit =
  #| (self, key, x, y) => {
  #|   if (!self.resources) return;
  #|   const uniforms = self.resources.uniforms?.uniforms ?? self.resources.uniforms;
  #|   if (uniforms && key in uniforms) {
  #|     uniforms[key] = [x, y];
  #|   }
  #| }
