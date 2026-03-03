///|
test "gallery tile views respect unlock and show_locked" {
  let ns = @util.gensym(prefix="wb_gallery_dom")
  let unlocked = GalleryImage::new("img_u", title="Unlocked")
  let locked = GalleryImage::new("img_l", title="Locked")
  @gallery.register_image(unlocked)
  @gallery.register_image(locked)
  @gallery.lock_image_in(ns, unlocked)
  @gallery.lock_image_in(ns, locked)
  @gallery.unlock_image_in(ns, unlocked)

  let menu_all = GalleryMenu::new("app", save_namespace=ns, show_locked=true)
  let all_tiles = menu_all.gallery_tile_views()
  assert_true(
    all_tiles.contains(to_gallery_tile_view(ns, unlocked, "Unlocked")),
  )
  assert_true(all_tiles.contains(to_gallery_tile_view(ns, locked, "Locked")))

  let menu_unlocked = GalleryMenu::new(
    "app",
    save_namespace=ns,
    show_locked=false,
  )
  let unlocked_only = menu_unlocked.gallery_tile_views()
  assert_true(
    unlocked_only.contains(to_gallery_tile_view(ns, unlocked, "Unlocked")),
  )
  assert_true(
    !unlocked_only.contains(to_gallery_tile_view(ns, locked, "Locked")),
  )

  @gallery.lock_image_in(ns, unlocked)
  @gallery.lock_image_in(ns, locked)
}

///|
test "gallery tile title resolves localized key" {
  let ns = @util.gensym(prefix="wb_gallery_i18n")
  let image = GalleryImage::new("img_i18n", title="@gallery.title.demo")
  @gallery.register_image(image)
  @gallery.unlock_image_in(ns, image)

  let menu = GalleryMenu::new("app", save_namespace=ns, show_locked=true)
  menu.set_script_localization(
    Some("{\"gallery.title.demo\":\"已解锁图片\"}"),
    Some("{\"gallery.title.demo\":\"Localized Title\"}"),
  )
  let tiles = menu.gallery_tile_views()
  let tile = tiles.iter().find_first(t => t.id == image.id)
  assert_eq(tile.map(t => t.title), Some("已解锁图片"))
}

///|
test "next unlocked tile id wraps correctly" {
  let tiles : Array[GalleryTileView] = [
    {
      id: "a",
      image_id: "ia",
      thumbnail_id: None,
      title: "A",
      unlocked: true,
      replay_label: None,
    },
    {
      id: "b",
      image_id: "ib",
      thumbnail_id: None,
      title: "B",
      unlocked: false,
      replay_label: None,
    },
    {
      id: "c",
      image_id: "ic",
      thumbnail_id: None,
      title: "C",
      unlocked: true,
      replay_label: Some("scene_c"),
    },
  ]

  assert_eq(next_unlocked_tile_id(tiles, Some("a"), 1), Some("c"))
  assert_eq(next_unlocked_tile_id(tiles, Some("c"), 1), Some("a"))
  assert_eq(next_unlocked_tile_id(tiles, Some("a"), -1), Some("c"))
  assert_eq(next_unlocked_tile_id(tiles, None, 1), Some("c"))
}
