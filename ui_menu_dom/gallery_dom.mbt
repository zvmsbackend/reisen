///|
/// Gallery viewer DOM integration (grid + fullscreen viewer actions).

///|
struct GalleryTileView {
  id : String
  image_id : String
  thumbnail_id : String?
  title : String
  unlocked : Bool
  replay_label : String?
} derive(Debug, Eq, ToJson, FromJson)

///|
struct GalleryMenu {
  root_id : String
  save_ns : String
  background : String
  mut ui_strings : UiStrings
  mut script_locale_json : String?
  mut script_default_locale_json : String?
  show_locked : Bool
  mut active_id : String?
}

///|
pub fn GalleryMenu::new(
  root_id : String,
  save_namespace? : String = "global",
  background? : String = "",
  show_locked? : Bool = true,
  ui_strings? : UiStrings = UiStrings::default(),
) -> GalleryMenu {
  {
    root_id,
    save_ns: save_namespace,
    background,
    ui_strings,
    script_locale_json: None,
    script_default_locale_json: None,
    show_locked,
    active_id: None,
  }
}

///|
pub impl @ui_menu.GalleryMenu for GalleryMenu with set_ui_strings(
  self,
  ui_strings,
) {
  self.ui_strings = ui_strings
}

///|
pub impl @ui_menu.GalleryMenu for GalleryMenu with set_script_localization(
  self,
  script_locale_json~,
  script_default_locale_json~,
) {
  self.script_locale_json = script_locale_json
  self.script_default_locale_json = script_default_locale_json
}

///|
fn to_gallery_tile_view(tile : @ui_menu.GalleryTileState) -> GalleryTileView {
  {
    id: tile.id,
    image_id: tile.image_id,
    thumbnail_id: tile.thumbnail_id,
    title: tile.title,
    unlocked: tile.unlocked,
    replay_label: tile.replay_label,
  }
}

///|
fn GalleryMenu::gallery_tiles(
  self : GalleryMenu,
) -> Array[@ui_menu.GalleryTileState] {
  @ui_menu.gallery_tiles_from_registry(
    self.save_ns,
    self.show_locked,
    self.script_locale_json,
    self.script_default_locale_json,
  )
}

///|
extern "js" fn gallery_dom_render(
  root_id : String,
  background : String,
  tiles_json : String,
  active_id : String,
  back_label : String,
  locked_label : String,
  prev_label : String,
  next_label : String,
  replay_label : String,
  close_label : String,
) -> Unit =
  #| (root_id, background, tiles_json, active_id, back_label, locked_label, prev_label, next_label, replay_label, close_label) => {
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
  #|   backBtn.textContent = back_label;
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
  #|     label.textContent = tile.unlocked ? titleOf(tile) : locked_label;
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
  #|   controls.appendChild(mkControl(prev_label, 'prev'));
  #|   controls.appendChild(mkControl(next_label, 'next'));
  #|   if (active.replay_label) {
  #|     controls.appendChild(mkControl(replay_label, 'replay', active.replay_label));
  #|   }
  #|   controls.appendChild(mkControl(close_label, 'close'));
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
pub impl @ui_menu.GalleryMenu for GalleryMenu with render(self) {
  let tiles = self.gallery_tiles()
  let dom_tiles = tiles.map(to_gallery_tile_view)
  let tiles_json = dom_tiles.to_json().stringify()
  gallery_dom_render(
    self.root_id,
    self.background,
    tiles_json,
    self.active_id.unwrap_or(""),
    self.ui_strings.gallery_back,
    self.ui_strings.gallery_locked,
    self.ui_strings.gallery_prev,
    self.ui_strings.gallery_next,
    self.ui_strings.gallery_replay,
    self.ui_strings.gallery_close,
  )
}

///|
pub impl @ui_menu.GalleryMenu for GalleryMenu with clear(self) {
  self.active_id = None
  gallery_dom_clear(self.root_id)
}

///|
pub impl @ui_menu.GalleryMenu for GalleryMenu with take_action(self) {
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
  self.active_id = @ui_menu.reduce_gallery_active_id(
    action,
    self.active_id,
    self.gallery_tiles(),
  )
  action
}
