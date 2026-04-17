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
}
