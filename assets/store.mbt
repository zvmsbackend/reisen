///|
/// Asset loading helpers for the browser target.

///|
/// |
using @pixi {type PixiLive2dModel}

///|
using @util {load_result_error, load_result_ok, load_result_value}

///|
#external
pub type Image

///|
#external
pub type Video

///|
extern "js" fn load_image_result_promise(
  url : String,
) -> @js_async.Promise[@js.Value] =
  #| (url) => new Promise((resolve) => {
  #|   const img = new Image();
  #|   img.onload = () => resolve({ ok: true, value: img });
  #|   img.onerror = (event) => {
  #|     const target = event?.currentTarget ?? event?.target ?? img;
  #|     const src = target?.currentSrc || target?.src || url;
  #|     resolve({ ok: false, error: `Failed to load image: ${String(src ?? url)}` });
  #|   };
  #|   img.src = url;
  #| })

///|
extern "js" fn load_video_result_promise(
  url : String,
) -> @js_async.Promise[@js.Value] =
  #| (url) => new Promise((resolve) => {
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
  #|     resolve({ ok: true, value: video });
  #|   };
  #|   video.onloadeddata = done;
  #|   video.onerror = (event) => {
  #|     const target = event?.currentTarget ?? event?.target ?? video;
  #|     const src = target?.currentSrc || target?.src || url;
  #|     resolve({ ok: false, error: `Failed to load video: ${String(src ?? url)}` });
  #|   };
  #|   video.src = url;
  #| })

///|
extern "js" fn load_text_result_promise(
  url : String,
) -> @js_async.Promise[@js.Value] =
  #| (url) => fetch(url).then(r => {
  #|   if (!r.ok) {
  #|     throw new Error(`HTTP ${r.status}`);
  #|   }
  #|   return r.text();
  #| })
  #|   .then(value => ({ ok: true, value }))
  #|   .catch(error => ({ ok: false, error: String(error?.message ?? error ?? '') }))

///|
extern "js" fn load_arraybuffer_result_promise(
  url : String,
) -> @js_async.Promise[@js.Value] =
  #| (url) => fetch(url).then(r => {
  #|   if (!r.ok) {
  #|     throw new Error(`HTTP ${r.status}`);
  #|   }
  #|   return r.arrayBuffer();
  #| })
  #|   .then(value => ({ ok: true, value }))
  #|   .catch(error => ({ ok: false, error: String(error?.message ?? error ?? '') }))

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
pub async fn load_image(url : String) -> Image raise AssetStoreError {
  let result = @js_async.Promise::wait(load_image_result_promise(url)) catch {
    err =>
      raise ResourceLoadFailed(
        message=promise_error_message(err, "Failed to load image: \{url}"),
      )
  }
  if !load_result_ok(result) {
    raise ResourceLoadFailed(
      message=load_result_error(result, "Failed to load image: \{url}"),
    )
  }
  load_result_value(result).cast()
}

///|
pub async fn load_video(url : String) -> Video raise AssetStoreError {
  let result = @js_async.Promise::wait(load_video_result_promise(url)) catch {
    err =>
      raise ResourceLoadFailed(
        message=promise_error_message(err, "Failed to load video: \{url}"),
      )
  }
  if !load_result_ok(result) {
    raise ResourceLoadFailed(
      message=load_result_error(result, "Failed to load video: \{url}"),
    )
  }
  load_result_value(result).cast()
}

///|
pub async fn load_text(url : String) -> String raise AssetStoreError {
  let result = @js_async.Promise::wait(load_text_result_promise(url)) catch {
    err =>
      raise ResourceLoadFailed(
        message=promise_error_message(err, "Failed to load text: \{url}"),
      )
  }
  if !load_result_ok(result) {
    raise ResourceLoadFailed(
      message=load_result_error(result, "Failed to load text: \{url}"),
    )
  }
  load_result_value(result).cast()
}

///|
pub async fn load_bytes(url : String) -> Bytes raise AssetStoreError {
  let result = @js_async.Promise::wait(load_arraybuffer_result_promise(url)) catch {
    err =>
      raise ResourceLoadFailed(
        message=promise_error_message(err, "Failed to load bytes: \{url}"),
      )
  }
  if !load_result_ok(result) {
    raise ResourceLoadFailed(
      message=load_result_error(result, "Failed to load bytes: \{url}"),
    )
  }
  let v = load_result_value(result)
  let u8 = arraybuffer_to_u8array(v)
  let arr = u8array_to_int_array(u8)
  int_array_to_bytes(arr)
}

///|
pub suberror AssetStoreError {
  ResourceLoadFailed(message~ : String)
}

///|
pub fn AssetStoreError::message(self : AssetStoreError) -> String {
  let ResourceLoadFailed(message~) = self
  message
}

///|
extern "js" fn promise_error_message(err : Error, fallback : String) -> String =
  #| (err, fallback) => {
  #|   if (typeof err === 'string' && err.length > 0) return err;
  #|   if (err && typeof err.message === 'string' && err.message.length > 0) return err.message;
  #|   try {
  #|     const txt = String(err ?? '').trim();
  #|     return txt.length > 0 ? txt : fallback;
  #|   } catch (_) {
  #|     return fallback;
  #|   }
  #| }

///|
#module("/pixi-bridge.js")
fn js_load_live2d_model_promise(
  source : String,
) -> @js_async.Promise[@js.Value] = "loadLive2dModel"

///|
pub async fn load_live2d_model(
  source : String,
) -> PixiLive2dModel raise AssetStoreError {
  let result = @js_async.Promise::wait(js_load_live2d_model_promise(source)) catch {
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
  live2d_models : Map[String, PixiLive2dModel]
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
  id
}

///|
pub fn AssetStore::register_sfx(
  self : AssetStore,
  url : String,
  id? : String = @util.gensym(prefix="sfx"),
) -> Sfx {
  self.put_audio_url(id, url)
  id
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
  id? : String = @util.gensym(prefix="figure"),
) -> PixiFigure raise AssetStoreError {
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
  id? : String = @util.gensym(prefix="live2d_figure"),
) -> Live2dFigure raise AssetStoreError {
  if self.live2d_models.get(id) is None {
    let model = load_live2d_model(model_json_url)
    self.put_live2d_model(id, model)
  }
  id
}

///|
pub async fn AssetStore::register_background(
  self : AssetStore,
  url : String,
  id? : String = @util.gensym(prefix="background"),
) -> Background raise AssetStoreError {
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
  id? : String = @util.gensym(prefix="background_video"),
) -> Background raise AssetStoreError {
  if self.videos.get(id) is None {
    let video = load_video(url)
    self.put_video(id, video)
  }
  { id, url }
}
