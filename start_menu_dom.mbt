///|
/// Start menu DOM integration (New Game / Continue / Load Slot / Settings).

///|
priv enum StartMenuAction {
  NoAction
  NewGame
  Continue(String)
  Load
  Settings
}

///|
priv enum StartGateAction {
  NoAction
  Start
}

///|
priv enum StartLogoAction {
  NoAction
  Done
}

///|
priv struct StartMenu {
  root_id : String
  save_ns : String
  background : String
}

///|
fn StartMenu::new(
  root_id : String,
  save_namespace? : String = "global",
  background? : String = "",
) -> StartMenu {
  { root_id, save_ns: save_namespace, background }
}

///|
fn StartMenu::render_gate(self : StartMenu) -> Unit {
  start_gate_dom_render(self.root_id)
}

///|
fn StartMenu::clear_gate(self : StartMenu) -> Unit {
  start_gate_dom_clear(self.root_id)
}

///|
fn StartMenu::take_gate_action(self : StartMenu) -> StartGateAction {
  match start_gate_action_kind(self.root_id).to_option() {
    Some("start") => {
      start_gate_action_clear(self.root_id)
      StartGateAction::Start
    }
    _ => StartGateAction::NoAction
  }
}

///|
fn StartMenu::render_logo(
  self : StartMenu,
  url : String,
  duration_ms : Int,
) -> Unit {
  start_logo_dom_render(self.root_id, url, duration_ms)
}

///|
fn StartMenu::clear_logo(self : StartMenu) -> Unit {
  start_logo_dom_clear(self.root_id)
}

///|
fn StartMenu::take_logo_action(self : StartMenu) -> StartLogoAction {
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
) -> Unit =
  #| (root_id, has_continue, continue_slot, background) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|
  #|   let menu = root.querySelector('[data-reisen="start-menu"]');
  #|   if (!menu) {
  #|     menu = doc.createElement('div');
  #|     menu.setAttribute('data-reisen', 'start-menu');
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
  #|   actions.setAttribute('data-reisen', 'start-actions');
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
  #|   actions.appendChild(mkButton('New Game', 'new'));
  #|   const continueBtn = mkButton('Continue', 'continue', continue_slot);
  #|   continueBtn.disabled = !has_continue;
  #|   actions.appendChild(continueBtn);
  #|   actions.appendChild(mkButton('Load', 'load'));
  #|   actions.appendChild(mkButton('Settings', 'settings'));
  #|   menu.appendChild(actions);
  #| }

///|
extern "js" fn start_gate_dom_render(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   let gate = root.querySelector('[data-reisen="start-gate"]');
  #|   if (!gate) {
  #|     gate = doc.createElement('div');
  #|     gate.setAttribute('data-reisen', 'start-gate');
  #|     root.appendChild(gate);
  #|   }
  #|   gate.innerHTML = '';
  #|   const text = doc.createElement('div');
  #|   text.setAttribute('data-reisen', 'start-gate-text');
  #|   text.textContent = 'Click to Start';
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
  #|     logo.setAttribute('data-reisen', 'start-logo');
  #|     root.appendChild(logo);
  #|   }
  #|   const ms = typeof duration_ms === 'number' ? duration_ms : 2000;
  #|   logo.style.animation = `start-logo-fade ${ms}ms ease-in-out forwards`;
  #|   logo.innerHTML = '';
  #|   const img = doc.createElement('img');
  #|   img.setAttribute('data-reisen', 'start-logo-image');
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
fn StartMenu::render(self : StartMenu) -> Unit {
  let entries = save_slot_entries_in(self.save_ns)
  let continue_slot = choose_continue_slot(entries)
  match continue_slot {
    Some(slot) =>
      start_menu_dom_render(self.root_id, true, slot, self.background)
    None => start_menu_dom_render(self.root_id, false, "", self.background)
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
fn StartMenu::clear(self : StartMenu) -> Unit {
  start_menu_dom_clear(self.root_id)
}

///|
fn StartMenu::take_action(self : StartMenu) -> StartMenuAction {
  match start_menu_action_kind(self.root_id).to_option() {
    Some("new") => {
      start_menu_action_clear(self.root_id)
      StartMenuAction::NewGame
    }
    Some("continue") => {
      let slot = match start_menu_action_slot(self.root_id).to_option() {
        Some(slot) => slot
        None => ""
      }
      start_menu_action_clear(self.root_id)
      if slot == "" {
        StartMenuAction::NoAction
      } else {
        StartMenuAction::Continue(slot)
      }
    }
    Some("load") => {
      start_menu_action_clear(self.root_id)
      StartMenuAction::Load
    }
    Some("settings") => {
      start_menu_action_clear(self.root_id)
      StartMenuAction::Settings
    }
    _ => StartMenuAction::NoAction
  }
}
