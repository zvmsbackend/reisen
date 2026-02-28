///|
/// Gallery image registration and persistent unlock state helpers.
pub struct ReplayStateFactories[T](Map[String, () -> @state.GameState[T]])

///|
pub fn[T] ReplayStateFactories::new() -> ReplayStateFactories[T] {
  Map::new()
}

///|
pub struct ReplayStateFactoryKey(String) derive(Show, Eq, ToJson, FromJson)

///|
pub fn ReplayStateFactoryKey::new(key : String) -> ReplayStateFactoryKey {
  ReplayStateFactoryKey(key)
}

///|
pub fn[T] ReplayStateFactories::register(
  self : ReplayStateFactories[T],
  factory : () -> @state.GameState[T],
  key? : String = @util.gensym(prefix="replay_factory"),
) -> ReplayStateFactoryKey {
  self.0.set(key, factory)
  ReplayStateFactoryKey::new(key)
}

///|
pub fn[T] ReplayStateFactories::get(
  self : ReplayStateFactories[T],
  key : ReplayStateFactoryKey,
) -> (() -> @state.GameState[T])? {
  self.0.get(key.0)
}

///|
pub struct GalleryImage {
  id : String
  image_url : String
  title : String
  thumbnail_url : String?
  replay_label : String?
  replay_state_factory_key : ReplayStateFactoryKey?
} derive(Show, Eq, ToJson, FromJson)

///|
let gallery_images : Map[String, GalleryImage] = {}

///|
let gallery_image_order : Array[String] = []

///|
fn gallery_image_unlock_key(id : String) -> String {
  "gallery.image." + id
}

///|
pub fn GalleryImage::new(
  id : String,
  image_url : String,
  title? : String = "",
  thumbnail_url? : String,
  replay_label? : String,
  replay_state_factory_key? : ReplayStateFactoryKey,
) -> GalleryImage {
  {
    id,
    image_url,
    title,
    thumbnail_url,
    replay_label,
    replay_state_factory_key,
  }
}

///|
pub fn GalleryImage::id(self : GalleryImage) -> String {
  self.id
}

///|
pub fn register_image(image : GalleryImage) -> Unit {
  if !gallery_images.contains(image.id) {
    gallery_image_order.push(image.id)
  }
  gallery_images.set(image.id, image)
}

///|
pub fn image_by_id(id : String) -> GalleryImage? {
  gallery_images.get(id)
}

///|
pub fn registered_images() -> Array[GalleryImage] {
  let out : Array[GalleryImage] = []
  for id in gallery_image_order {
    match gallery_images.get(id) {
      Some(image) => out.push(image)
      None => ()
    }
  }
  out
}

///|
pub fn unlock_image(image : GalleryImage) -> Unit {
  @storage.persistent_set_flag(gallery_image_unlock_key(image.id), true)
}

///|
pub fn unlock_image_by_id(id : String) -> Unit {
  @storage.persistent_set_flag(gallery_image_unlock_key(id), true)
}

///|
pub fn unlock_image_in(ns : String, image : GalleryImage) -> Unit {
  @storage.persistent_set_flag_in(ns, gallery_image_unlock_key(image.id), true)
}

///|
pub fn lock_image(image : GalleryImage) -> Unit {
  @storage.persistent_delete(gallery_image_unlock_key(image.id))
}

///|
pub fn lock_image_in(ns : String, image : GalleryImage) -> Unit {
  @storage.persistent_delete_in(ns, gallery_image_unlock_key(image.id))
}

///|
pub fn is_image_unlocked(image : GalleryImage) -> Bool {
  @storage.persistent_get_flag(
    gallery_image_unlock_key(image.id),
    default=false,
  )
}

///|
pub fn is_image_unlocked_in(ns : String, image : GalleryImage) -> Bool {
  @storage.persistent_get_flag_in(
    ns,
    gallery_image_unlock_key(image.id),
    default=false,
  )
}

///|
pub fn unlocked_images() -> Array[GalleryImage] {
  let out : Array[GalleryImage] = []
  for image in registered_images() {
    if is_image_unlocked(image) {
      out.push(image)
    }
  }
  out
}

///|
pub fn unlocked_images_in(ns : String) -> Array[GalleryImage] {
  let out : Array[GalleryImage] = []
  for image in registered_images() {
    if is_image_unlocked_in(ns, image) {
      out.push(image)
    }
  }
  out
}

///|
pub fn replayable_images() -> Array[GalleryImage] {
  let out : Array[GalleryImage] = []
  for image in registered_images() {
    if image.replay_label is Some(_) {
      out.push(image)
    }
  }
  out
}

///|
pub fn replayable_images_in(ns : String) -> Array[GalleryImage] {
  let out : Array[GalleryImage] = []
  for image in unlocked_images_in(ns) {
    if image.replay_label is Some(_) {
      out.push(image)
    }
  }
  out
}
