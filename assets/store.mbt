///|
/// Asset loading helpers for the browser target.

///|
#external
pub type Image

///|
#external
pub type Video

#external
pub type Live2dModel

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
pub suberror AssetStoreError {
  ResourceLoadFailed(message~ : String)
}

///|
#module("/pixi-bridge.js")
fn js_load_live2d_model_promise(source : String) -> @js.Promise = "loadLive2dModel"

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
pub async fn load_live2d_model(
  source : String,
) -> Live2dModel raise AssetStoreError {
  let result = @js.Promise::wait(js_load_live2d_model_promise(source)) catch {
    _ =>
      raise AssetStoreError::ResourceLoadFailed(
        message="Failed to load Live2D model: \{source}",
      )
  }
  if !load_result_ok(result) {
    raise AssetStoreError::ResourceLoadFailed(
      message=load_result_error(
        result,
        "Failed to load Live2D model: \{source}",
      ),
    )
  }
  load_result_value(result).cast()
}

///|
pub struct AssetStore {
  images : Map[String, Image]
  videos : Map[String, Video]
  texts : Map[String, String]
  bytes : Map[String, Bytes]
  audios : Map[String, String]
  live2d_models : Map[String, Live2dModel]
}

///|
pub fn AssetStore::new() -> AssetStore {
  {
    images: Map::new(),
    videos: Map::new(),
    texts: Map::new(),
    bytes: Map::new(),
    audios: Map::new(),
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
pub fn AssetStore::put_audio_url(
  self : AssetStore,
  id : String,
  url : String,
) -> Unit {
  self.audios.set(id, url)
}

///|
pub fn AssetStore::get_audio_url(self : AssetStore, id : String) -> String? {
  self.audios.get(id)
}

///|
pub fn AssetStore::register_music(
  self : AssetStore,
  url : String,
  id? : String = @util.gensym(prefix="music"),
) -> Music {
  self.put_audio_url(id, url)
  Music::new(id)
}

///|
pub fn AssetStore::register_sfx(
  self : AssetStore,
  url : String,
  id? : String = @util.gensym(prefix="sfx"),
) -> Sfx {
  self.put_audio_url(id, url)
  Sfx::new(id)
}

///|
pub fn AssetStore::put_live2d_model(
  self : AssetStore,
  id : String,
  model : Live2dModel,
) -> Unit {
  self.live2d_models.set(id, model)
}

///|
pub fn AssetStore::get_live2d_model(
  self : AssetStore,
  id : String,
) -> Live2dModel? {
  self.live2d_models.get(id)
}

///|
pub async fn AssetStore::register_figure(
  self : AssetStore,
  url : String,
  id? : String = @util.gensym(prefix="figure"),
) -> PixiFigure {
  if self.images.get(id) is None {
    let img = load_image(url)
    self.put_image(id, img)
  }
  PixiFigure::new(id)
}

///|
pub async fn AssetStore::register_live2d_figure(
  self : AssetStore,
  model_json_url : String,
  id? : String = @util.gensym(prefix="live2d_figure"),
) -> Live2dFigure raise AssetStoreError {
  if self.live2d_models.get(id) is None {
    let model = load_live2d_model(model_json_url)
    self.put_live2d_model(id, model)
  }
  Live2dFigure::new(id)
}

///|
pub async fn AssetStore::register_background(
  self : AssetStore,
  url : String,
  id? : String = @util.gensym(prefix="background"),
) -> Background {
  if self.images.get(id) is None {
    let img = load_image(url)
    self.put_image(id, img)
  }
  Background::new(id, url)
}

///|
pub async fn AssetStore::register_background_video(
  self : AssetStore,
  url : String,
  id? : String = @util.gensym(prefix="background_video"),
) -> Background {
  if self.videos.get(id) is None {
    let video = load_video(url)
    self.put_video(id, video)
  }
  Background::new(id, url)
}
