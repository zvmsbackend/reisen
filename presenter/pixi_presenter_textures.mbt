///|
fn PixiPresenter::texture_for(
  self : PixiPresenter,
  id : String,
) -> PixiTexture? {
  match self.textures.get(id) {
    Some(texture) => Some(texture)
    None => {
      let maybe_texture = match self.store.get_image(id) {
        Some(image) => Some(PixiTexture::new(@js.Value::cast_from(image)))
        None =>
          match self.store.get_video(id) {
            Some(video) => Some(PixiTexture::new(@js.Value::cast_from(video)))
            None => None
          }
      }
      match maybe_texture {
        Some(texture) => {
          let w = texture.width()
          let h = texture.height()
          self.textures.set(id, texture)
          self.texture_sizes.set(id, (w, h))
          Some(texture)
        }
        None => None
      }
    }
  }
}

///|
fn PixiPresenter::refresh_video_texture_if_any(
  self : PixiPresenter,
  id : String,
) -> Unit {
  match self.store.get_video(id) {
    Some(_) =>
      match self.textures.get(id) {
        Some(texture) => texture.update()
        None => ()
      }
    None => ()
  }
}
