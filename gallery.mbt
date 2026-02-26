///|
/// Gallery image registration and persistent unlock state helpers.
struct ReplayStateFactories[T](Map[String, () -> GameState[T]])

///|
pub fn[T] ReplayStateFactories::new() -> ReplayStateFactories[T] {
  Map::new()
}

///|
pub fn[T] ReplayStateFactories::register(
  self : ReplayStateFactories[T],
  factory : () -> GameState[T],
  key? : String = gensym(prefix="replay_factory"),
) -> ReplayStateFactoryKey {
  self.0.set(key, factory)
  key
}

///|
pub fn[T] ReplayStateFactories::get(
  self : ReplayStateFactories[T],
  key : ReplayStateFactoryKey,
) -> (() -> GameState[T])? {
  self.0.get(key.0)
}

///|
struct ReplayStateFactoryKey(String) derive(Show, Eq, ToJson, FromJson)

///|
struct GalleryImage {
  id : String
  image_url : String
  title : String
  thumbnail_url : String?
  replay_label : String?
  replay_state_factory_key : ReplayStateFactoryKey?
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn Background::as_gallery_image(
  self : Background,
  title : String,
  thumbnail? : Background,
  replay_label? : Label,
  replay_state_factory_key? : ReplayStateFactoryKey,
  id? : String = gensym(prefix="cg"),
) -> GalleryImage {
  {
    id,
    image_url: self.url,
    title,
    thumbnail_url: thumbnail.map(b => b.url),
    replay_label: replay_label.map(l => l.0),
    replay_state_factory_key,
  }
}

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
pub fn gallery_register_image(image : GalleryImage) -> Unit {
  if !gallery_images.contains(image.id) {
    gallery_image_order.push(image.id)
  }
  gallery_images.set(image.id, image)
}

///|
pub fn gallery_image_by_id(id : String) -> GalleryImage? {
  gallery_images.get(id)
}

///|
pub fn gallery_registered_images() -> Array[GalleryImage] {
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
pub fn gallery_unlock_image(image : GalleryImage) -> Unit {
  persistent_set_flag(gallery_image_unlock_key(image.id), true)
}

///|
fn gallery_unlock_image_by_id(id : String) -> Unit {
  persistent_set_flag(gallery_image_unlock_key(id), true)
}

///|
pub fn gallery_unlock_image_in(ns : String, image : GalleryImage) -> Unit {
  persistent_set_flag_in(ns, gallery_image_unlock_key(image.id), true)
}

///|
pub fn gallery_lock_image(image : GalleryImage) -> Unit {
  persistent_delete(gallery_image_unlock_key(image.id))
}

///|
pub fn gallery_lock_image_in(ns : String, image : GalleryImage) -> Unit {
  persistent_delete_in(ns, gallery_image_unlock_key(image.id))
}

///|
pub fn gallery_is_image_unlocked(image : GalleryImage) -> Bool {
  persistent_get_flag(gallery_image_unlock_key(image.id), default=false)
}

///|
pub fn gallery_is_image_unlocked_in(ns : String, image : GalleryImage) -> Bool {
  persistent_get_flag_in(ns, gallery_image_unlock_key(image.id), default=false)
}

///|
pub fn gallery_unlocked_images() -> Array[GalleryImage] {
  let out : Array[GalleryImage] = []
  for image in gallery_registered_images() {
    if gallery_is_image_unlocked(image) {
      out.push(image)
    }
  }
  out
}

///|
pub fn gallery_unlocked_images_in(ns : String) -> Array[GalleryImage] {
  let out : Array[GalleryImage] = []
  for image in gallery_registered_images() {
    if gallery_is_image_unlocked_in(ns, image) {
      out.push(image)
    }
  }
  out
}

///|
pub fn gallery_replayable_images() -> Array[GalleryImage] {
  let out : Array[GalleryImage] = []
  for image in gallery_registered_images() {
    if image.replay_label is Some(_) {
      out.push(image)
    }
  }
  out
}

///|
pub fn gallery_replayable_images_in(ns : String) -> Array[GalleryImage] {
  let out : Array[GalleryImage] = []
  for image in gallery_unlocked_images_in(ns) {
    if image.replay_label is Some(_) {
      out.push(image)
    }
  }
  out
}
