///|
/// Start menu DOM integration (New Game / Continue / Load Slot / Settings).

///|
pub(all) enum StartMenuAction {
  NoAction
  NewGame
  Continue(String)
  Load
  Settings
  Gallery
}

///|
pub enum StartGateAction {
  NoAction
  Start
}

///|
pub enum StartLogoAction {
  NoAction
  Done
}

///|
struct StartMenu {
  root_id : String
  save_ns : String
  background : String
  ui_strings : UiStrings
}

///|
pub fn StartMenu::new(
  root_id : String,
  save_namespace? : String = "global",
  background? : String = "",
  ui_strings? : UiStrings = UiStrings::default(),
) -> StartMenu {
  { root_id, save_ns: save_namespace, background, ui_strings }
}

///|
pub fn StartMenu::render_gate(self : StartMenu) -> Unit {
  start_gate_dom_render(self.root_id, self.ui_strings.start_gate_click_to_start)
}

///|
pub fn StartMenu::clear_gate(self : StartMenu) -> Unit {
  start_gate_dom_clear(self.root_id)
}

///|
pub fn StartMenu::take_gate_action(self : StartMenu) -> StartGateAction {
  match start_gate_action_kind(self.root_id).to_option() {
    Some("start") => {
      start_gate_action_clear(self.root_id)
      StartGateAction::Start
    }
    _ => StartGateAction::NoAction
  }
}

///|
pub fn StartMenu::render_logo(
  self : StartMenu,
  url : String,
  duration_ms : Int,
) -> Unit {
  start_logo_dom_render(self.root_id, url, duration_ms)
}

///|
pub fn StartMenu::clear_logo(self : StartMenu) -> Unit {
  start_logo_dom_clear(self.root_id)
}

///|
pub fn StartMenu::take_logo_action(self : StartMenu) -> StartLogoAction {
  match start_logo_action_kind(self.root_id).to_option() {
    Some("done") => {
      start_logo_action_clear(self.root_id)
      StartLogoAction::Done
    }
    _ => StartLogoAction::NoAction
  }
}

///|
fn choose_continue_slot(entries : Array[SaveSlotEntry]) -> String? {
  let mut best_slot : String? = None
  let mut best_ts = -1.0
  for entry in entries {
    let ts = match entry.meta {
      Some(meta) => meta.updated_at_ms
      None => -1.0
    }
    if ts > best_ts || best_slot is None {
      best_slot = Some(entry.slot)
      best_ts = ts
    }
  }
  best_slot
}

///|
extern "js" fn start_menu_dom_render(
  root_id : String,
  has_continue : Bool,
  continue_slot : String,
  background : String,
  has_gallery : Bool,
  new_game_label : String,
  continue_label : String,
  load_label : String,
  settings_label : String,
  gallery_label : String,
) -> Unit =
  #| (root_id, has_continue, continue_slot, background, has_gallery, new_game_label, continue_label, load_label, settings_label, gallery_label) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|
  #|   let menu = root.querySelector('[data-reisen="start-menu"]');
  #|   if (!menu) {
  #|     menu = doc.createElement('div');
  #|     menu.dataset.reisen = 'start-menu';
  #|     root.appendChild(menu);
  #|   }
  #|
  #|   // Apply background if provided
  #|   if (background && background !== '') {
  #|     menu.style.backgroundImage = `url(${background})`;
  #|     menu.style.backgroundSize = 'cover';
  #|     menu.style.backgroundPosition = 'center';
  #|   }
  #|
  #|   menu.innerHTML = '';
  #|
  #|   const actions = doc.createElement('div');
  #|   actions.dataset.reisen = 'start-actions';
  #|
  #|   const mkButton = (text, kind, slot = '') => {
  #|     const btn = doc.createElement('button');
  #|     btn.type = 'button';
  #|     btn.textContent = text;
  #|     btn.addEventListener('click', () => {
  #|       root.dataset.reisenMenuActionKind = kind;
  #|       root.dataset.reisenMenuActionSlot = slot;
  #|     });
  #|     return btn;
  #|   };
  #|
  #|   actions.appendChild(mkButton(new_game_label, 'new'));
  #|   const continueBtn = mkButton(continue_label, 'continue', continue_slot);
  #|   continueBtn.disabled = !has_continue;
  #|   actions.appendChild(continueBtn);
  #|   actions.appendChild(mkButton(load_label, 'load'));
  #|   actions.appendChild(mkButton(settings_label, 'settings'));
  #|   if (has_gallery) {
  #|     actions.appendChild(mkButton(gallery_label, 'gallery'));
  #|   }
  #|   menu.appendChild(actions);
  #| }

///|
extern "js" fn start_gate_dom_render(
  root_id : String,
  click_to_start : String,
) -> Unit =
  #| (root_id, click_to_start) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   let gate = root.querySelector('[data-reisen="start-gate"]');
  #|   if (!gate) {
  #|     gate = doc.createElement('div');
  #|     gate.dataset.reisen = 'start-gate';
  #|     root.appendChild(gate);
  #|   }
  #|   gate.innerHTML = '';
  #|   const text = doc.createElement('div');
  #|   text.dataset.reisen = 'start-gate-text';
  #|   text.textContent = click_to_start;
  #|   gate.appendChild(text);
  #|   if (!gate.__reisenGateBound) {
  #|     gate.__reisenGateBound = true;
  #|     gate.addEventListener('click', () => {
  #|       root.dataset.reisenGateActionKind = 'start';
  #|     });
  #|   }
  #| }

///|
extern "js" fn start_gate_dom_clear(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   const gate = root.querySelector('[data-reisen="start-gate"]');
  #|   if (gate) gate.remove();
  #| }

///|
extern "js" fn start_logo_dom_render(
  root_id : String,
  url : String,
  duration_ms : Int,
) -> Unit =
  #| (root_id, url, duration_ms) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   let logo = root.querySelector('[data-reisen="start-logo"]');
  #|   if (!logo) {
  #|     logo = doc.createElement('div');
  #|     logo.dataset.reisen = 'start-logo';
  #|     root.appendChild(logo);
  #|   }
  #|   const ms = typeof duration_ms === 'number' ? duration_ms : 2000;
  #|   logo.innerHTML = '';
  #|   const img = doc.createElement('img');
  #|   img.style.setProperty('--reisen-start-logo-duration', `${ms}ms`);
  #|   img.dataset.reisen = 'start-logo-image';
  #|   img.src = url;
  #|   logo.appendChild(img);
  #|   if (!logo.__reisenLogoBound) {
  #|     logo.__reisenLogoBound = true;
  #|     logo.addEventListener('click', () => {
  #|       root.dataset.reisenLogoActionKind = 'done';
  #|     });
  #|   }
  #| }

///|
extern "js" fn start_logo_dom_clear(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   const logo = root.querySelector('[data-reisen="start-logo"]');
  #|   if (logo) logo.remove();
  #| }

///|
extern "js" fn start_logo_action_kind(root_id : String) -> @js.Nullable[String] =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return null;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return null;
  #|   const kind = root.dataset.reisenLogoActionKind;
  #|   return kind || null;
  #| }

///|
extern "js" fn start_logo_action_clear(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   delete root.dataset.reisenLogoActionKind;
  #| }

///|
extern "js" fn start_gate_action_kind(root_id : String) -> @js.Nullable[String] =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return null;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return null;
  #|   const kind = root.dataset.reisenGateActionKind;
  #|   return kind || null;
  #| }

///|
extern "js" fn start_gate_action_clear(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   delete root.dataset.reisenGateActionKind;
  #| }

///|
extern "js" fn start_menu_action_kind(root_id : String) -> @js.Nullable[String] =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return null;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return null;
  #|   const kind = root.dataset.reisenMenuActionKind;
  #|   return kind || null;
  #| }

///|
extern "js" fn start_menu_action_slot(root_id : String) -> @js.Nullable[String] =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return null;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return null;
  #|   const slot = root.dataset.reisenMenuActionSlot;
  #|   return slot || null;
  #| }

///|
extern "js" fn start_menu_action_clear(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   delete root.dataset.reisenMenuActionKind;
  #|   delete root.dataset.reisenMenuActionSlot;
  #| }

///|
pub fn StartMenu::render(self : StartMenu) -> Unit {
  let entries = save_slot_entries_in(self.save_ns)
  let has_gallery = @gallery.registered_images().length() > 0
  let continue_slot = choose_continue_slot(entries)
  match continue_slot {
    Some(slot) =>
      start_menu_dom_render(
        self.root_id,
        true,
        slot,
        self.background,
        has_gallery,
        self.ui_strings.start_menu_new_game,
        self.ui_strings.start_menu_continue,
        self.ui_strings.start_menu_load,
        self.ui_strings.start_menu_settings,
        self.ui_strings.start_menu_gallery,
      )
    None =>
      start_menu_dom_render(
        self.root_id,
        false,
        "",
        self.background,
        has_gallery,
        self.ui_strings.start_menu_new_game,
        self.ui_strings.start_menu_continue,
        self.ui_strings.start_menu_load,
        self.ui_strings.start_menu_settings,
        self.ui_strings.start_menu_gallery,
      )
  }
}

///|
extern "js" fn start_menu_dom_clear(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   const menu = root.querySelector('[data-reisen="start-menu"]');
  #|   if (menu) menu.remove();
  #|   delete root.dataset.reisenMenuActionKind;
  #|   delete root.dataset.reisenMenuActionSlot;
  #| }

///|
pub fn StartMenu::clear(self : StartMenu) -> Unit {
  start_menu_dom_clear(self.root_id)
}

///|
pub fn StartMenu::take_action(self : StartMenu) -> StartMenuAction {
  match start_menu_action_kind(self.root_id).to_option() {
    Some("new") => {
      start_menu_action_clear(self.root_id)
      NewGame
    }
    Some("continue") => {
      let slot = match start_menu_action_slot(self.root_id).to_option() {
        Some(slot) => slot
        None => ""
      }
      start_menu_action_clear(self.root_id)
      if slot == "" {
        NoAction
      } else {
        Continue(slot)
      }
    }
    Some("load") => {
      start_menu_action_clear(self.root_id)
      Load
    }
    Some("settings") => {
      start_menu_action_clear(self.root_id)
      Settings
    }
    Some("gallery") => {
      start_menu_action_clear(self.root_id)
      Gallery
    }
    _ => NoAction
  }
}
