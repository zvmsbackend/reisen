///|
pub(all) suberror AssetStoreError {
  ResourceLoadFailed(message~ : String)
}

///|
pub fn AssetStoreError::message(self : AssetStoreError) -> String {
  let ResourceLoadFailed(message~) = self
  message
}

///|
pub(open) trait AssetStore {
  has_image(Self, String) -> Bool
  has_video(Self, String) -> Bool
  has_live2d_model(Self, String) -> Bool
  get_audio_url(Self, String) -> String?
  put_audio_url(Self, String, String) -> Unit
  put_text(Self, String, String) -> Unit
  put_bytes(Self, String, Bytes) -> Unit
  put_path(Self, String, String) -> Unit
  get_path(Self, String) -> String?
  async load_image_and_cache(Self, String, String) -> Unit raise AssetStoreError
  async load_video_and_cache(Self, String, String) -> Unit raise AssetStoreError
  async load_live2d_and_cache(Self, String, String) -> Unit raise AssetStoreError
}

///|
pub async fn &AssetStore::register_figure(
  self : &AssetStore,
  url : String,
  id? : String = @util.gensym(prefix="figure"),
) -> PixiFigure raise AssetStoreError {
  self.put_path(id, url)
  self.load_image_and_cache(id, url)
  id
}

///|
pub async fn &AssetStore::register_live2d_figure(
  self : &AssetStore,
  url : String,
  id? : String = @util.gensym(prefix="live2d_figure"),
) -> Live2dFigure raise AssetStoreError {
  self.put_path(id, url)
  self.load_live2d_and_cache(id, url)
  id
}

///|
pub async fn &AssetStore::register_background(
  self : &AssetStore,
  url : String,
  id? : String = @util.gensym(prefix="background"),
) -> Background raise AssetStoreError {
  self.put_path(id, url)
  self.load_image_and_cache(id, url)
  { id, url }
}

///|
pub async fn &AssetStore::register_background_video(
  self : &AssetStore,
  url : String,
  id? : String = @util.gensym(prefix="background_video"),
) -> Background raise AssetStoreError {
  self.put_path(id, url)
  self.load_video_and_cache(id, url)
  { id, url }
}

///|
pub fn &AssetStore::register_music(
  self : &AssetStore,
  url : String,
  id? : String = @util.gensym(prefix="music"),
) -> Music {
  self.put_audio_url(id, url)
  id
}

///|
pub fn &AssetStore::register_sfx(
  self : &AssetStore,
  url : String,
  id? : String = @util.gensym(prefix="sfx"),
) -> Sfx {
  self.put_audio_url(id, url)
  id
}
