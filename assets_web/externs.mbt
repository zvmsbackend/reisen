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
pub async fn load_image(url : String) -> Image raise @assets.AssetStoreError {
  let result = (url |> load_image_result_promise |> @js_async.Promise::wait) catch {
    err =>
      raise @assets.AssetStoreError::ResourceLoadFailed(
        message=@util.promise_error_message(err, "Failed to load image: \{url}"),
      )
  }
  if !@util.load_result_ok(result) {
    raise @assets.AssetStoreError::ResourceLoadFailed(
      message=@util.load_result_error(result, "Failed to load image: \{url}"),
    )
  }
  @util.load_result_value(result).cast()
}

///|
pub async fn load_video(url : String) -> Video raise @assets.AssetStoreError {
  let result = (url |> load_video_result_promise |> @js_async.Promise::wait) catch {
    err =>
      raise @assets.AssetStoreError::ResourceLoadFailed(
        message=@util.promise_error_message(err, "Failed to load video: \{url}"),
      )
  }
  if !@util.load_result_ok(result) {
    raise @assets.AssetStoreError::ResourceLoadFailed(
      message=@util.load_result_error(result, "Failed to load video: \{url}"),
    )
  }
  @util.load_result_value(result).cast()
}

///|
pub async fn load_bytes(url : String) -> Bytes raise @assets.AssetStoreError {
  let result = (url
  |> load_arraybuffer_result_promise
  |> @js_async.Promise::wait) catch {
    err =>
      raise @assets.AssetStoreError::ResourceLoadFailed(
        message=@util.promise_error_message(err, "Failed to load bytes: \{url}"),
      )
  }
  if !@util.load_result_ok(result) {
    raise @assets.AssetStoreError::ResourceLoadFailed(
      message=@util.load_result_error(result, "Failed to load bytes: \{url}"),
    )
  }
  let v = @util.load_result_value(result)
  let u8 = arraybuffer_to_u8array(v)
  let arr = u8array_to_int_array(u8)
  int_array_to_bytes(arr)
}

///|
#module("/pixi-bridge.js")
fn js_load_live2d_model_promise(
  source : String,
) -> @js_async.Promise[@js.Value] = "loadLive2dModel"

///|
pub async fn load_live2d_model(
  source : String,
) -> @pixi.PixiLive2dModel raise @assets.AssetStoreError {
  let result = (source
  |> js_load_live2d_model_promise
  |> @js_async.Promise::wait) catch {
    _ =>
      raise @assets.AssetStoreError::ResourceLoadFailed(
        message="Failed to load Live2D model: \{source}",
      )
  }
  if !@util.load_result_ok(result) {
    raise @assets.AssetStoreError::ResourceLoadFailed(
      message=@util.load_result_error(
        result,
        "Failed to load Live2D model: \{source}",
      ),
    )
  }
  @util.load_result_value(result).cast()
}
