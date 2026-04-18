///|
using @gallery {type GalleryImage}

///|
fn has_tile(
  tiles : Array[@ui_menu.GalleryTileState],
  id : String,
  unlocked : Bool,
  title : String,
) -> Bool {
  match tiles.iter().find_first(tile => tile.id == id) {
    Some(tile) => tile.unlocked == unlocked && tile.title == title
    None => false
  }
}

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
  let all_tiles = menu_all.gallery_tiles()
  assert_true(has_tile(all_tiles, unlocked.id, true, "Unlocked"))
  assert_true(has_tile(all_tiles, locked.id, false, "Locked"))

  let menu_unlocked = GalleryMenu::new(
    "app",
    save_namespace=ns,
    show_locked=false,
  )
  let unlocked_only = menu_unlocked.gallery_tiles()
  assert_true(has_tile(unlocked_only, unlocked.id, true, "Unlocked"))
  assert_true(!unlocked_only.iter().any(tile => tile.id == locked.id))

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
    script_locale_json=Some("{\"gallery.title.demo\":\"已解锁图片\"}"),
    script_default_locale_json=Some(
      "{\"gallery.title.demo\":\"Localized Title\"}",
    ),
  )
  let tiles = menu.gallery_tiles()
  let tile = tiles.iter().find_first(t => t.id == image.id)
  assert_eq(tile.map(t => t.title), Some("已解锁图片"))
}

///|
test "next unlocked tile id wraps correctly" {
  let ns = @util.gensym(prefix="wb_gallery_next")
  let a = GalleryImage::new("ia", id="a", title="A")
  let b = GalleryImage::new("ib", id="b", title="B")
  let c = GalleryImage::new("ic", id="c", title="C", replay_label="scene_c")
  @gallery.register_image(a)
  @gallery.register_image(b)
  @gallery.register_image(c)
  @gallery.lock_image_in(ns, a)
  @gallery.lock_image_in(ns, b)
  @gallery.lock_image_in(ns, c)
  @gallery.unlock_image_in(ns, a)
  @gallery.unlock_image_in(ns, c)

  let tiles = @ui_menu.gallery_tiles_from_registry(ns, true, None, None)

  assert_eq(
    @ui_menu.next_unlocked_gallery_tile_id(tiles, Some("a"), 1),
    Some("c"),
  )
  assert_eq(
    @ui_menu.next_unlocked_gallery_tile_id(tiles, Some("c"), 1),
    Some("a"),
  )
  assert_eq(
    @ui_menu.next_unlocked_gallery_tile_id(tiles, Some("a"), -1),
    Some("c"),
  )
  assert_eq(@ui_menu.next_unlocked_gallery_tile_id(tiles, None, 1), Some("c"))

  @gallery.lock_image_in(ns, a)
  @gallery.lock_image_in(ns, b)
  @gallery.lock_image_in(ns, c)
}
