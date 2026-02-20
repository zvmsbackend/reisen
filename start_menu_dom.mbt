///|
/// Start menu DOM integration (New Game / Continue / Load Slot).

///|
priv enum StartMenuAction {
  NoAction
  NewGame
  Continue(String)
  LoadSlot(String)
}

///|
priv struct StartMenu {
  root_id : String
  save_ns : String
}

///|
priv struct SlotView {
  slot : String
  title : String
  preview : String
  updated_at_ms : Double
}

///|
fn StartMenu::new(
  root_id : String,
  save_namespace? : String = "global",
) -> StartMenu {
  { root_id, save_ns: save_namespace }
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
fn to_slot_view(entry : SaveSlotEntry) -> SlotView {
  match entry.meta {
    Some(meta) => {
      let title = if meta.title == "" { entry.slot } else { meta.title }
      {
        slot: entry.slot,
        title,
        preview: meta.preview,
        updated_at_ms: meta.updated_at_ms,
      }
    }
    None =>
      { slot: entry.slot, title: entry.slot, preview: "", updated_at_ms: -1.0 }
  }
}

///|
fn sorted_slot_views(entries : Array[SaveSlotEntry]) -> Array[SlotView] {
  let views = entries.map(to_slot_view)
  views.sort_by_key(view => -view.updated_at_ms)
  views
}

///|
extern "js" fn start_menu_dom_render(
  root_id : String,
  slots : Array[String],
  titles : Array[String],
  previews : Array[String],
  has_continue : Bool,
  continue_slot : String,
) -> Unit =
  #| (root_id, slots, titles, previews, has_continue, continue_slot) => {
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
  #|   menu.appendChild(actions);
  #|
  #|   const list = doc.createElement('div');
  #|   list.setAttribute('data-reisen', 'save-list');
  #|   for (let i = 0; i < slots.length; i++) {
  #|     const slot = slots[i];
  #|     const title = titles[i] || slot;
  #|     const preview = previews[i] || '';
  #|     const text = preview ? `${title} - ${preview}` : title;
  #|     list.appendChild(mkButton(text, 'load', slot));
  #|   }
  #|   menu.appendChild(list);
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
  let views = sorted_slot_views(entries)
  let slots = views.map(view => view.slot)
  let titles = views.map(view => view.title)
  let previews = views.map(view => view.preview)
  let continue_slot = choose_continue_slot(entries)
  match continue_slot {
    Some(slot) =>
      start_menu_dom_render(self.root_id, slots, titles, previews, true, slot)
    None =>
      start_menu_dom_render(self.root_id, slots, titles, previews, false, "")
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
      let slot = match start_menu_action_slot(self.root_id).to_option() {
        Some(slot) => slot
        None => ""
      }
      start_menu_action_clear(self.root_id)
      if slot == "" {
        StartMenuAction::NoAction
      } else {
        StartMenuAction::LoadSlot(slot)
      }
    }
    _ => StartMenuAction::NoAction
  }
}
