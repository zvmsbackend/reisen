///|
pub struct WebAssetStore {
  asset_paths : Map[String, String]
  images : Map[String, Image]
  videos : Map[String, Video]
  live2d_models : Map[String, @pixi.PixiLive2dModel]
  texts : Map[String, String]
  bytes : Map[String, Bytes]
  audios : Map[String, String]
}

///|
pub fn WebAssetStore::new() -> WebAssetStore {
  {
    asset_paths: Map::new(),
    images: Map::new(),
    videos: Map::new(),
    live2d_models: Map::new(),
    texts: Map::new(),
    bytes: Map::new(),
    audios: Map::new(),
  }
}

///|
pub fn WebAssetStore::put_image(
  self : WebAssetStore,
  id : String,
  img : Image,
) -> Unit {
  self.images.set(id, img)
}

///|
pub fn WebAssetStore::get_image(self : WebAssetStore, id : String) -> Image? {
  self.images.get(id)
}

///|
pub fn WebAssetStore::put_video(
  self : WebAssetStore,
  id : String,
  video : Video,
) -> Unit {
  self.videos.set(id, video)
}

///|
pub fn WebAssetStore::get_video(self : WebAssetStore, id : String) -> Video? {
  self.videos.get(id)
}

///|
pub fn WebAssetStore::put_live2d_model(
  self : WebAssetStore,
  id : String,
  model : @pixi.PixiLive2dModel,
) -> Unit {
  self.live2d_models.set(id, model)
}

///|
pub fn WebAssetStore::get_live2d_model(
  self : WebAssetStore,
  id : String,
) -> @pixi.PixiLive2dModel? {
  self.live2d_models.get(id)
}

///|
pub async fn WebAssetStore::register_figure(
  self : WebAssetStore,
  url : String,
  id? : String = @util.gensym(prefix="figure"),
) -> @assets.PixiFigure raise @assets.AssetStoreError {
  self.put_path(id, url)
  self.load_image_and_cache(id, url)
  id
}

///|
pub async fn WebAssetStore::register_live2d_figure(
  self : WebAssetStore,
  url : String,
  id? : String = @util.gensym(prefix="live2d_figure"),
) -> @assets.Live2dFigure raise @assets.AssetStoreError {
  self.put_path(id, url)
  self.load_live2d_and_cache(id, url)
  id
}

///|
pub async fn WebAssetStore::register_background(
  self : WebAssetStore,
  url : String,
  id? : String = @util.gensym(prefix="background"),
) -> @assets.Background raise @assets.AssetStoreError {
  self.put_path(id, url)
  self.load_image_and_cache(id, url)
  { id, url }
}

///|
pub async fn WebAssetStore::register_background_video(
  self : WebAssetStore,
  url : String,
  id? : String = @util.gensym(prefix="background_video"),
) -> @assets.Background raise @assets.AssetStoreError {
  self.put_path(id, url)
  self.load_video_and_cache(id, url)
  { id, url }
}

///|
pub fn WebAssetStore::register_music(
  self : WebAssetStore,
  url : String,
  id? : String = @util.gensym(prefix="music"),
) -> @assets.Music {
  self.put_audio_url(id, url)
  id
}

///|
pub fn WebAssetStore::register_sfx(
  self : WebAssetStore,
  url : String,
  id? : String = @util.gensym(prefix="sfx"),
) -> @assets.Sfx {
  self.put_audio_url(id, url)
  id
}

///|
pub impl @assets.AssetStore for WebAssetStore with has_image(self, id) {
  self.images.contains(id)
}

///|
pub impl @assets.AssetStore for WebAssetStore with has_video(self, id) {
  self.videos.contains(id)
}

///|
pub impl @assets.AssetStore for WebAssetStore with has_live2d_model(self, id) {
  self.live2d_models.contains(id)
}

///|
pub impl @assets.AssetStore for WebAssetStore with get_audio_url(self, id) {
  self.audios.get(id)
}

///|
pub impl @assets.AssetStore for WebAssetStore with put_audio_url(self, id, url) {
  self.audios.set(id, url)
}

///|
pub impl @assets.AssetStore for WebAssetStore with put_text(self, id, text) {
  self.texts.set(id, text)
}

///|
pub impl @assets.AssetStore for WebAssetStore with put_bytes(self, id, data) {
  self.bytes.set(id, data)
}

///|
pub impl @assets.AssetStore for WebAssetStore with put_path(self, id, path) {
  self.asset_paths.set(id, path)
}

///|
pub impl @assets.AssetStore for WebAssetStore with get_path(self, id) {
  self.asset_paths.get(id)
}

///|
pub async fn WebAssetStore::load_image_and_cache(
  self : WebAssetStore,
  id : String,
  url : String,
) -> Unit raise @assets.AssetStoreError {
  if self.images.get(id) is None {
    let img = load_image(url)
    self.images.set(id, img)
  }
}

///|
pub async fn WebAssetStore::load_video_and_cache(
  self : WebAssetStore,
  id : String,
  url : String,
) -> Unit raise @assets.AssetStoreError {
  if self.videos.get(id) is None {
    let video = load_video(url)
    self.videos.set(id, video)
  }
}

///|
pub async fn WebAssetStore::load_live2d_and_cache(
  self : WebAssetStore,
  id : String,
  url : String,
) -> Unit raise @assets.AssetStoreError {
  if self.live2d_models.get(id) is None {
    let model = load_live2d_model(url)
    self.live2d_models.set(id, model)
  }
}
