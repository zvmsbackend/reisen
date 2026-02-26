///|
/// Asset loading helpers for the browser target.
///
/// This module provides async loaders for images, text, and bytes,
/// plus a simple in-memory asset store.

///|
#external
type Image

///|
#external
type Video

///|
pub impl @js.Cast for Image with into(value) {
  Some(value.cast())
}

///|
pub impl @js.Cast for Image with from(value) {
  @js.Value::cast_from(value)
}

///|
pub impl @js.Cast for Video with into(value) {
  Some(value.cast())
}

///|
pub impl @js.Cast for Video with from(value) {
  @js.Value::cast_from(value)
}

///|
extern "js" fn load_image_promise(url : String) -> @js.Promise =
  #| (url) => new Promise((resolve, reject) => {
  #|   const img = new Image();
  #|   img.onload = () => resolve(img);
  #|   img.onerror = (e) => reject(e);
  #|   img.src = url;
  #| })

///|
extern "js" fn load_video_promise(url : String) -> @js.Promise =
  #| (url) => new Promise((resolve, reject) => {
  #|   const video = document.createElement('video');
  #|   video.preload = 'auto';
  #|   video.muted = true;
  #|   video.loop = true;
  #|   video.autoplay = true;
  #|   video.playsInline = true;
  #|   video.crossOrigin = 'anonymous';
  #|   const done = () => {
  #|     const p = video.play();
  #|     if (p && typeof p.catch === 'function') p.catch(() => {});
  #|     resolve(video);
  #|   };
  #|   video.onloadeddata = done;
  #|   video.onerror = (e) => reject(e);
  #|   video.src = url;
  #| })

///|
extern "js" fn fetch_text_promise(url : String) -> @js.Promise =
  #| (url) => fetch(url).then(r => {
  #|   if (!r.ok) { throw new Error(`HTTP ${r.status}`); }
  #|   return r.text();
  #| })

///|
extern "js" fn fetch_arraybuffer_promise(url : String) -> @js.Promise =
  #| (url) => fetch(url).then(r => {
  #|   if (!r.ok) { throw new Error(`HTTP ${r.status}`); }
  #|   return r.arrayBuffer();
  #| })

///|
extern "js" fn arraybuffer_to_u8array(buf : @js.Value) -> @js.Value =
  #| (buf) => new Uint8Array(buf)

///|
extern "js" fn u8array_to_int_array(u8 : @js.Value) -> Array[Int] =
  #| (u8) => Array.from(u8)

///|
fn int_array_to_bytes(xs : Array[Int]) -> Bytes {
  Bytes::from_array(xs.map(x => x.to_byte()))
}

///|
pub async fn load_image(url : String) -> Image {
  let v = @js.Promise::wait(load_image_promise(url))
  v.cast()
}

///|
pub async fn load_video(url : String) -> Video {
  let v = @js.Promise::wait(load_video_promise(url))
  v.cast()
}

///|
pub async fn load_text(url : String) -> String {
  let v = @js.Promise::wait(fetch_text_promise(url))
  v.cast()
}

///|
pub async fn load_bytes(url : String) -> Bytes {
  let v = @js.Promise::wait(fetch_arraybuffer_promise(url))
  let u8 = arraybuffer_to_u8array(v)
  let arr = u8array_to_int_array(u8)
  int_array_to_bytes(arr)
}

///|
struct AssetStore {
  images : Map[String, Image]
  videos : Map[String, Video]
  texts : Map[String, String]
  bytes : Map[String, Bytes]
  live2d_models : Map[String, PixiLive2dModel]
}

///|
pub fn AssetStore::new() -> AssetStore {
  {
    images: Map::new(),
    videos: Map::new(),
    texts: Map::new(),
    bytes: Map::new(),
    live2d_models: Map::new(),
  }
}

///|
pub fn AssetStore::put_image(
  self : AssetStore,
  id : String,
  img : Image,
) -> Unit {
  self.images.set(id, img)
}

///|
pub fn AssetStore::get_image(self : AssetStore, id : String) -> Image? {
  self.images.get(id)
}

///|
pub fn AssetStore::put_video(
  self : AssetStore,
  id : String,
  video : Video,
) -> Unit {
  self.videos.set(id, video)
}

///|
pub fn AssetStore::get_video(self : AssetStore, id : String) -> Video? {
  self.videos.get(id)
}

///|
pub fn AssetStore::put_text(
  self : AssetStore,
  id : String,
  text : String,
) -> Unit {
  self.texts.set(id, text)
}

///|
pub fn AssetStore::get_text(self : AssetStore, id : String) -> String? {
  self.texts.get(id)
}

///|
pub fn AssetStore::put_bytes(
  self : AssetStore,
  id : String,
  data : Bytes,
) -> Unit {
  self.bytes.set(id, data)
}

///|
pub fn AssetStore::get_bytes(self : AssetStore, id : String) -> Bytes? {
  self.bytes.get(id)
}

///|
pub fn AssetStore::put_live2d_model(
  self : AssetStore,
  id : String,
  model : PixiLive2dModel,
) -> Unit {
  self.live2d_models.set(id, model)
}

///|
pub fn AssetStore::get_live2d_model(
  self : AssetStore,
  id : String,
) -> PixiLive2dModel? {
  self.live2d_models.get(id)
}

///|
pub async fn AssetStore::register_figure(
  self : AssetStore,
  url : String,
  id? : String = gensym(prefix="figure"),
) -> PixiFigure {
  if self.images.get(id) is None {
    let img = load_image(url)
    self.put_image(id, img)
  }
  id
}

///|
pub async fn AssetStore::register_live2d_figure(
  self : AssetStore,
  model_json_url : String,
  id? : String = gensym(prefix="live2d_figure"),
) -> Live2dFigure raise PixiBindingError {
  if self.live2d_models.get(id) is None {
    let model = pixi_load_live2d_model(model_json_url)
    self.put_live2d_model(id, model)
  }
  id
}

///|
pub async fn AssetStore::register_background(
  self : AssetStore,
  url : String,
  id? : String = gensym(prefix="background"),
) -> Background {
  if self.images.get(id) is None {
    let img = load_image(url)
    self.put_image(id, img)
  }
  { id, url }
}

///|
pub async fn AssetStore::register_background_video(
  self : AssetStore,
  url : String,
  id? : String = gensym(prefix="background_video"),
) -> Background {
  if self.videos.get(id) is None {
    let video = load_video(url)
    self.put_video(id, video)
  }
  { id, url }
}
