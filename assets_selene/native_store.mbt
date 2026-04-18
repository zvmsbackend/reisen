///|
pub struct NativeAssetStore {
  asset_paths : Map[String, String]
  image_handles : Map[String, @selene_asset_types.ImageHandle]
  texts : Map[String, String]
  bytes : Map[String, Bytes]
  audios : Map[String, String]
}

///|
pub fn NativeAssetStore::new() -> NativeAssetStore {
  { asset_paths: {}, image_handles: {}, texts: {}, bytes: {}, audios: {} }
}

///|
fn resolve_image_path(path : String) -> String {
  if @x_fs.path_exists(path) {
    return path
  }
  let public_path = "public/\{path}"
  if @x_fs.path_exists(public_path) {
    return public_path
  }
  path
}

///|
fn NativeAssetStore::load_image_handle(
  self : NativeAssetStore,
  id : String,
  path : String,
) -> @selene_asset_types.ImageHandle {
  match self.image_handles.get(id) {
    Some(handle) => handle
    None => {
      let resolved_path = resolve_image_path(path)
      self.asset_paths.set(id, resolved_path)
      let handle = @selene_asset.load_image(resolved_path)
      self.image_handles.set(id, handle)
      handle
    }
  }
}

///|
pub fn NativeAssetStore::get_image_handle(
  self : NativeAssetStore,
  id : String,
) -> @selene_asset_types.ImageHandle? {
  match self.image_handles.get(id) {
    Some(handle) => Some(handle)
    None =>
      match self.asset_paths.get(id) {
        Some(path) => {
          let handle = self.load_image_handle(id, path)
          Some(handle)
        }
        None => None
      }
  }
}

///|
pub fn NativeAssetStore::register_figure(
  self : NativeAssetStore,
  path : String,
  id? : String = @util.gensym(prefix="figure"),
) -> @assets.PixiFigure {
  self.put_path(id, path)
  ignore(self.load_image_handle(id, path))
  id
}

///|
pub fn NativeAssetStore::register_background(
  self : NativeAssetStore,
  path : String,
  id? : String = @util.gensym(prefix="background"),
) -> @assets.Background {
  self.put_path(id, path)
  ignore(self.load_image_handle(id, path))
  { id, url: path }
}

///|
pub fn NativeAssetStore::register_music(
  self : NativeAssetStore,
  path : String,
  id? : String = @util.gensym(prefix="music"),
) -> @assets.Music {
  self.put_audio_url(id, path)
  id
}

///|
pub fn NativeAssetStore::register_sfx(
  self : NativeAssetStore,
  path : String,
  id? : String = @util.gensym(prefix="sfx"),
) -> @assets.Sfx {
  self.put_audio_url(id, path)
  id
}

///|
pub impl @assets.AssetStore for NativeAssetStore with has_image(self, id) {
  self.image_handles.contains(id)
}

///|
pub impl @assets.AssetStore for NativeAssetStore with has_video(_self, _id) {
  false
}

///|
pub impl @assets.AssetStore for NativeAssetStore with has_live2d_model(
  _self,
  _id,
) {
  false
}

///|
pub impl @assets.AssetStore for NativeAssetStore with get_audio_url(self, id) {
  self.audios.get(id)
}

///|
pub impl @assets.AssetStore for NativeAssetStore with put_audio_url(
  self,
  id,
  path,
) {
  self.audios.set(id, path)
}

///|
pub impl @assets.AssetStore for NativeAssetStore with put_text(self, id, text) {
  self.texts.set(id, text)
}

///|
pub impl @assets.AssetStore for NativeAssetStore with put_bytes(self, id, data) {
  self.bytes.set(id, data)
}

///|
pub impl @assets.AssetStore for NativeAssetStore with put_path(self, id, path) {
  self.asset_paths.set(id, path)
}

///|
pub impl @assets.AssetStore for NativeAssetStore with get_path(self, id) {
  self.asset_paths.get(id)
}
