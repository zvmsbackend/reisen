///|
/// Gallery image registration and persistent unlock state helpers.

///|
struct GalleryImage {
  id : String
  image_id : String
  title : String
  thumbnail_id : String?
  replay_label : String?
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
  image_id : String,
  title? : String = "",
  thumbnail_id? : String,
  replay_label? : String,
) -> GalleryImage {
  { id, image_id, title, thumbnail_id, replay_label }
}

///|
pub fn cg(
  id : String,
  image_id : String,
  title? : String = "",
  thumbnail_id? : String,
  replay_label? : String,
) -> GalleryImage {
  { id, image_id, title, thumbnail_id, replay_label }
}

///|
pub fn gallery_register_image(image : GalleryImage) -> Unit {
  if !gallery_images.contains(image.id) {
    gallery_image_order.push(image.id)
  }
  gallery_images.set(image.id, image)
}

///|
pub fn register_cg(image : GalleryImage) -> Unit {
  gallery_register_image(image)
}

///|
pub fn register_cg_image(
  id : String,
  image_id : String,
  title? : String = "",
  thumbnail_id? : String,
  replay_label? : String,
) -> GalleryImage {
  let entry : GalleryImage = { id, image_id, title, thumbnail_id, replay_label }
  register_cg(entry)
  entry
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
pub fn gallery_unlock_image(id : String) -> Unit {
  persistent_set_flag(gallery_image_unlock_key(id), true)
}

///|
pub fn unlock_cg(id : String) -> Unit {
  gallery_unlock_image(id)
}

///|
pub fn gallery_unlock_image_in(ns : String, id : String) -> Unit {
  persistent_set_flag_in(ns, gallery_image_unlock_key(id), true)
}

///|
pub fn unlock_cg_in(ns : String, id : String) -> Unit {
  gallery_unlock_image_in(ns, id)
}

///|
pub fn gallery_lock_image(id : String) -> Unit {
  persistent_delete(gallery_image_unlock_key(id))
}

///|
pub fn gallery_lock_image_in(ns : String, id : String) -> Unit {
  persistent_delete_in(ns, gallery_image_unlock_key(id))
}

///|
pub fn gallery_is_image_unlocked(id : String) -> Bool {
  persistent_get_flag(gallery_image_unlock_key(id), default=false)
}

///|
pub fn gallery_is_image_unlocked_in(ns : String, id : String) -> Bool {
  persistent_get_flag_in(ns, gallery_image_unlock_key(id), default=false)
}

///|
pub fn gallery_unlocked_images() -> Array[GalleryImage] {
  let out : Array[GalleryImage] = []
  for image in gallery_registered_images() {
    if gallery_is_image_unlocked(image.id) {
      out.push(image)
    }
  }
  out
}

///|
pub fn gallery_unlocked_images_in(ns : String) -> Array[GalleryImage] {
  let out : Array[GalleryImage] = []
  for image in gallery_registered_images() {
    if gallery_is_image_unlocked_in(ns, image.id) {
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
