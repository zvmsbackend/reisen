///|
test "gallery register keeps stable order and replacement" {
  let id_a = gensym(prefix="wb_gallery_a")
  let id_b = gensym(prefix="wb_gallery_b")
  let a = GalleryImage::new(id_a, "img_a", title="A", replay_label="scene_a")
  let b = GalleryImage::new(id_b, "img_b", title="B")
  let a2 = GalleryImage::new(id_a, "img_a_new", title="A2")

  gallery_register_image(a)
  gallery_register_image(b)
  gallery_register_image(a2)

  let registered = gallery_registered_images()
  assert_true(registered.length() >= 2)
  assert_eq(registered[registered.length() - 2].id, id_a)
  assert_eq(registered[registered.length() - 2].image_url, "img_a_new")
  assert_eq(registered[registered.length() - 2].replay_label, None)
  assert_eq(registered[registered.length() - 1], b)
}

///|
test "gallery unlock and lock roundtrip by namespace" {
  let ns = gensym(prefix="wb_gallery")
  let id = gensym(prefix="unlock_target")
  let entry = GalleryImage::new(id, "img_unlock", title="Unlockable")
  gallery_lock_image_in(ns, entry)
  assert_eq(gallery_is_image_unlocked_in(ns, entry), false)

  gallery_unlock_image_in(ns, entry)
  assert_eq(gallery_is_image_unlocked_in(ns, entry), true)

  gallery_lock_image_in(ns, entry)
  assert_eq(gallery_is_image_unlocked_in(ns, entry), false)
}

///|
test "gallery unlocked list reflects registered and unlocked" {
  let ns = gensym(prefix="wb_gallery_list")
  let image = GalleryImage::new(
    gensym(prefix="wb_gallery_list_img"),
    "img_list",
    title="List",
  )
  gallery_register_image(image)
  gallery_lock_image_in(ns, image)
  assert_true(!gallery_unlocked_images_in(ns).contains(image))

  gallery_unlock_image_in(ns, image)
  assert_true(gallery_unlocked_images_in(ns).contains(image))
}

///|
test "gallery replayable list only contains unlocked replay entries" {
  let ns = gensym(prefix="wb_gallery_replay")
  let replayable = GalleryImage::new(
    gensym(prefix="wb_gallery_replayable"),
    "img_replayable",
    replay_label="scene_replayable",
  )
  let plain = GalleryImage::new(gensym(prefix="wb_gallery_plain"), "img_plain")
  gallery_register_image(replayable)
  gallery_register_image(plain)
  gallery_lock_image_in(ns, replayable)
  gallery_lock_image_in(ns, plain)

  assert_true(gallery_replayable_images().contains(replayable))
  assert_true(!gallery_replayable_images().contains(plain))
  assert_true(!gallery_replayable_images_in(ns).contains(replayable))

  gallery_unlock_image_in(ns, replayable)
  gallery_unlock_image_in(ns, plain)
  assert_true(gallery_replayable_images_in(ns).contains(replayable))
  assert_true(!gallery_replayable_images_in(ns).contains(plain))
}

///|
test "gallery image stores replay state factory key" {
  let image = GalleryImage::new(
    gensym(prefix="wb_gallery_factory"),
    "img",
    replay_state_factory_key=ReplayStateFactoryKey("factory_key"),
  )
  assert_eq(
    image.replay_state_factory_key,
    Some(ReplayStateFactoryKey("factory_key")),
  )
}

///|
test "cg helpers register and unlock" {
  let id = gensym(prefix="wb_cg")
  let entry = GalleryImage::new(id, "img_cg", title="CG")
  gallery_register_image(entry)
  assert_eq(gallery_image_by_id(id), Some(entry))
  gallery_lock_image(entry)
  assert_eq(gallery_is_image_unlocked(entry), false)
  gallery_unlock_image(entry)
  assert_eq(gallery_is_image_unlocked(entry), true)
  gallery_lock_image(entry)
}
