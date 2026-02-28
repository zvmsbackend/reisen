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

  let all_tiles = gallery_tile_views(ns, true)
  assert_true(all_tiles.contains(to_gallery_tile_view(ns, unlocked)))
  assert_true(all_tiles.contains(to_gallery_tile_view(ns, locked)))

  let unlocked_only = gallery_tile_views(ns, false)
  assert_true(unlocked_only.contains(to_gallery_tile_view(ns, unlocked)))
  assert_true(!unlocked_only.contains(to_gallery_tile_view(ns, locked)))

  @gallery.lock_image_in(ns, unlocked)
  @gallery.lock_image_in(ns, locked)
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
