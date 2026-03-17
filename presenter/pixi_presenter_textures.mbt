///|
fn PixiPresenter::texture_for(
  self : PixiPresenter,
  id : String,
) -> PixiTexture? {
  match self.textures.get(id) {
    Some(texture) => Some(texture)
    None => {
      let maybe_texture = match self.store.get_image(id) {
        Some(image) => image |> @js.Value::cast_from |> PixiTexture::new |> Some
        None =>
          self.store
          .get_video(id)
          .bind(video => {
            video |> @js.Value::cast_from |> PixiTexture::new |> Some
          })
      }
      maybe_texture.bind(texture => {
        let w = texture.width()
        let h = texture.height()
        self.textures.set(id, texture)
        self.texture_sizes.set(id, (w, h))
        Some(texture)
      })
    }
  }
}

///|
fn PixiPresenter::refresh_video_texture_if_any(
  self : PixiPresenter,
  id : String,
) -> Unit {
  guard self.store.get_video(id) is Some(_) else { return }
  if self.textures.get(id) is Some(texture) {
    texture.update()
  }
}
