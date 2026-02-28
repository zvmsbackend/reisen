///|
/// Gallery viewer DOM integration (grid + fullscreen viewer actions).

///|
priv enum GalleryAction {
  NoAction
  Back
  Open(String)
  Close
  Prev
  Next
  Replay(String)
}

///|
struct GalleryTileView {
  id : String
  image_id : String
  thumbnail_id : String?
  title : String
  unlocked : Bool
  replay_label : String?
} derive(Show, Eq, ToJson, FromJson)

///|
priv struct GalleryMenu {
  root_id : String
  save_ns : String
  background : String
  show_locked : Bool
  mut active_id : String?
}

///|
fn GalleryMenu::new(
  root_id : String,
  save_namespace? : String = "global",
  background? : String = "",
  show_locked? : Bool = true,
) -> GalleryMenu {
  { root_id, save_ns: save_namespace, background, show_locked, active_id: None }
}

///|
fn to_gallery_tile_view(ns : String, image : GalleryImage) -> GalleryTileView {
  {
    id: image.id,
    image_id: image.image_url,
    thumbnail_id: image.thumbnail_url,
    title: image.title,
    unlocked: @gallery.is_image_unlocked_in(ns, image),
    replay_label: image.replay_label,
  }
}

///|
fn gallery_tile_views(
  ns : String,
  show_locked : Bool,
) -> Array[GalleryTileView] {
  let out : Array[GalleryTileView] = []
  for image in @gallery.registered_images() {
    let tile = to_gallery_tile_view(ns, image)
    if tile.unlocked || show_locked {
      out.push(tile)
    }
  }
  out
}

///|
fn find_tile(tiles : Array[GalleryTileView], id : String) -> GalleryTileView? {
  tiles.iter().find_first(tile => tile.id == id)
}

///|
fn next_unlocked_tile_id(
  tiles : Array[GalleryTileView],
  current_id : String?,
  step : Int,
) -> String? {
  if tiles.length() == 0 {
    return None
  }
  let unlocked : Array[GalleryTileView] = []
  for tile in tiles {
    if tile.unlocked {
      unlocked.push(tile)
    }
  }
  if unlocked.length() == 0 {
    return None
  }
  let mut current_idx = 0
  match current_id {
    Some(id) =>
      for i, tile in unlocked {
        if tile.id == id {
          current_idx = i
          break
        }
      }
    None => ()
  }
  let dir = if step < 0 { -1 } else { 1 }
  let size = unlocked.length()
  let raw = if dir < 0 { current_idx - 1 } else { current_idx + 1 }
  let wrapped = if raw < 0 { size - 1 } else if raw >= size { 0 } else { raw }
  Some(unlocked[wrapped].id)
}

///|
extern "js" fn gallery_dom_render(
  root_id : String,
  background : String,
  tiles_json : String,
  active_id : String,
) -> Unit =
  #| (root_id, background, tiles_json, active_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   let host = root.querySelector('[data-reisen="gallery-menu"]');
  #|   if (!host) {
  #|     host = doc.createElement('div');
  #|     host.dataset.reisen = 'gallery-menu';
  #|     root.appendChild(host);
  #|   }
  #|   if (background && background !== '') {
  #|     host.style.backgroundImage = `url(${background})`;
  #|     host.style.backgroundSize = 'cover';
  #|     host.style.backgroundPosition = 'center';
  #|   }
  #|   let tiles = [];
  #|   try {
  #|     const parsed = JSON.parse(tiles_json);
  #|     if (Array.isArray(parsed)) tiles = parsed;
  #|   } catch (_) {}
  #|   host.innerHTML = '';
  #|   const toolbar = doc.createElement('div');
  #|   toolbar.dataset.reisen = 'gallery-toolbar';
  #|   const backBtn = doc.createElement('button');
  #|   backBtn.type = 'button';
  #|   backBtn.textContent = 'Back';
  #|   backBtn.addEventListener('click', () => {
  #|     root.dataset.reisenGalleryActionKind = 'back';
  #|   });
  #|   toolbar.appendChild(backBtn);
  #|   host.appendChild(toolbar);
  #|   const grid = doc.createElement('div');
  #|   grid.dataset.reisen = 'gallery-grid';
  #|   const titleOf = (tile) => tile.title && tile.title !== '' ? tile.title : tile.id;
  #|   for (const tile of tiles) {
  #|     const btn = doc.createElement('button');
  #|     btn.type = 'button';
  #|     btn.dataset.reisen = 'gallery-tile';
  #|     btn.dataset.galleryId = tile.id || '';
  #|     if (!tile.unlocked) btn.dataset.locked = '1';
  #|     const label = doc.createElement('div');
  #|     label.textContent = tile.unlocked ? titleOf(tile) : 'Locked';
  #|     btn.appendChild(label);
  #|     if (tile.unlocked) {
  #|       const img = doc.createElement('img');
  #|       img.alt = titleOf(tile);
  #|       img.src = (tile.thumbnail_id && tile.thumbnail_id !== '') ? tile.thumbnail_id : tile.image_id;
  #|       btn.appendChild(img);
  #|       btn.addEventListener('click', () => {
  #|         root.dataset.reisenGalleryActionKind = 'open';
  #|         root.dataset.reisenGalleryActionPayload = tile.id || '';
  #|       });
  #|     } else {
  #|       btn.disabled = true;
  #|     }
  #|     grid.appendChild(btn);
  #|   }
  #|   host.appendChild(grid);
  #|   const active = tiles.find(tile => tile.id === active_id && tile.unlocked);
  #|   if (!active) return;
  #|   const overlay = doc.createElement('div');
  #|   overlay.dataset.reisen = 'gallery-viewer';
  #|   const image = doc.createElement('img');
  #|   image.alt = titleOf(active);
  #|   image.src = active.image_id;
  #|   overlay.appendChild(image);
  #|   const controls = doc.createElement('div');
  #|   controls.dataset.reisen = 'gallery-controls';
  #|   const mkControl = (text, kind, payload = '') => {
  #|     const btn = doc.createElement('button');
  #|     btn.type = 'button';
  #|     btn.textContent = text;
  #|     btn.addEventListener('click', () => {
  #|       root.dataset.reisenGalleryActionKind = kind;
  #|       if (payload) {
  #|         root.dataset.reisenGalleryActionPayload = payload;
  #|       } else {
  #|         delete root.dataset.reisenGalleryActionPayload;
  #|       }
  #|     });
  #|     return btn;
  #|   };
  #|   controls.appendChild(mkControl('Prev', 'prev'));
  #|   controls.appendChild(mkControl('Next', 'next'));
  #|   if (active.replay_label) {
  #|     controls.appendChild(mkControl('Replay', 'replay', active.replay_label));
  #|   }
  #|   controls.appendChild(mkControl('Close', 'close'));
  #|   overlay.appendChild(controls);
  #|   host.appendChild(overlay);
  #| }

///|
extern "js" fn gallery_action_kind(root_id : String) -> @js.Nullable[String] =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return null;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return null;
  #|   return root.dataset.reisenGalleryActionKind || null;
  #| }

///|
extern "js" fn gallery_action_payload(root_id : String) -> @js.Nullable[String] =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return null;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return null;
  #|   return root.dataset.reisenGalleryActionPayload || null;
  #| }

///|
extern "js" fn gallery_action_clear(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   delete root.dataset.reisenGalleryActionKind;
  #|   delete root.dataset.reisenGalleryActionPayload;
  #| }

///|
extern "js" fn gallery_dom_clear(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   const menu = root.querySelector('[data-reisen="gallery-menu"]');
  #|   if (menu) menu.remove();
  #|   delete root.dataset.reisenGalleryActionKind;
  #|   delete root.dataset.reisenGalleryActionPayload;
  #| }

///|
fn GalleryMenu::render(self : GalleryMenu) -> Unit {
  let tiles = gallery_tile_views(self.save_ns, self.show_locked)
  let tiles_json = tiles.to_json().stringify()
  gallery_dom_render(
    self.root_id,
    self.background,
    tiles_json,
    self.active_id.unwrap_or(""),
  )
}

///|
fn GalleryMenu::clear(self : GalleryMenu) -> Unit {
  self.active_id = None
  gallery_dom_clear(self.root_id)
}

///|
fn GalleryMenu::take_action(self : GalleryMenu) -> GalleryAction {
  let action = match gallery_action_kind(self.root_id).to_option() {
    Some("back") => GalleryAction::Back
    Some("close") => GalleryAction::Close
    Some("prev") => GalleryAction::Prev
    Some("next") => GalleryAction::Next
    Some("open") =>
      match gallery_action_payload(self.root_id).to_option() {
        Some(id) => GalleryAction::Open(id)
        None => GalleryAction::NoAction
      }
    Some("replay") =>
      match gallery_action_payload(self.root_id).to_option() {
        Some(label) => GalleryAction::Replay(label)
        None => GalleryAction::NoAction
      }
    _ => GalleryAction::NoAction
  }
  gallery_action_clear(self.root_id)
  let tiles = gallery_tile_views(self.save_ns, self.show_locked)
  match action {
    Open(id) => {
      match find_tile(tiles, id) {
        Some(tile) =>
          self.active_id = if tile.unlocked { Some(id) } else { None }
        None => self.active_id = None
      }
      action
    }
    Close => {
      self.active_id = None
      action
    }
    Prev => {
      self.active_id = next_unlocked_tile_id(tiles, self.active_id, -1)
      action
    }
    Next => {
      self.active_id = next_unlocked_tile_id(tiles, self.active_id, 1)
      action
    }
    _ => action
  }
}
