///|
using @util {gensym}

///|
test "gallery register keeps stable order and replacement" {
  let a = GalleryImage::new(
    id="id_a",
    "img_a",
    title="A",
    replay_label="scene_a",
  )
  let b = GalleryImage::new("img_b", title="B")
  let a2 = GalleryImage::new("img_a_new", title="A2")

  register_image(a)
  register_image(b)
  register_image(a2)

  let registered = registered_images()
  assert_true(registered.length() >= 2)
  assert_eq(registered[registered.length() - 2].id, "id_a")
  assert_eq(registered[registered.length() - 2].image_url, "img_a_new")
  assert_eq(registered[registered.length() - 2].replay_label, None)
  assert_eq(registered[registered.length() - 1], b)
}

///|
test "gallery unlock and lock roundtrip by namespace" {
  let ns = gensym(prefix="wb_gallery")
  let entry = GalleryImage::new("img_unlock", title="Unlockable")
  lock_image_in(ns, entry)
  assert_eq(is_image_unlocked_in(ns, entry), false)

  unlock_image_in(ns, entry)
  assert_eq(is_image_unlocked_in(ns, entry), true)

  lock_image_in(ns, entry)
  assert_eq(is_image_unlocked_in(ns, entry), false)
}

///|
test "gallery unlocked list reflects registered and unlocked" {
  let ns = gensym(prefix="wb_gallery_list")
  let image = GalleryImage::new("img_list", title="List")
  register_image(image)
  lock_image_in(ns, image)
  assert_true(!unlocked_images_in(ns).contains(image))

  unlock_image_in(ns, image)
  assert_true(unlocked_images_in(ns).contains(image))
}

///|
test "gallery replayable list only contains unlocked replay entries" {
  let ns = gensym(prefix="wb_gallery_replay")
  let replayable = GalleryImage::new(
    "img_replayable",
    replay_label="scene_replayable",
  )
  let plain = GalleryImage::new("img_plain")
  register_image(replayable)
  register_image(plain)
  lock_image_in(ns, replayable)
  lock_image_in(ns, plain)

  assert_true(replayable_images().contains(replayable))
  assert_true(!replayable_images().contains(plain))
  assert_true(!replayable_images_in(ns).contains(replayable))

  unlock_image_in(ns, replayable)
  unlock_image_in(ns, plain)
  assert_true(replayable_images_in(ns).contains(replayable))
  assert_true(!replayable_images_in(ns).contains(plain))
}

///|
test "gallery image stores replay state factory key" {
  let image = GalleryImage::new(
    "img",
    replay_state_factory_key=ReplayStateFactoryKey::new("factory_key"),
  )
  assert_eq(
    image.replay_state_factory_key,
    Some(ReplayStateFactoryKey::new("factory_key")),
  )
}

///|
test "cg helpers register and unlock" {
  let id = gensym(prefix="wb_cg")
  let entry = GalleryImage::new(id~, "img_cg", title="CG")
  register_image(entry)
  assert_eq(image_by_id(id), Some(entry))
  lock_image(entry)
  assert_eq(is_image_unlocked(entry), false)
  unlock_image(entry)
  assert_eq(is_image_unlocked(entry), true)
  lock_image(entry)
}
