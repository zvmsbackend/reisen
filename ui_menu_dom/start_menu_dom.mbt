///|
/// Start menu DOM integration (New Game / Continue / Load Slot / Settings).

///|
struct StartMenu {
  root_id : String
  save_ns : String
  save_store : &@storage.SaveSlotStore
  background : String
  mut ui_strings : UiStrings
  mut show_credits : Bool
}

///|
pub fn StartMenu::new(
  root_id : String,
  save_namespace? : String = "global",
  save_store? : &@storage.SaveSlotStore = default_save_slot_storage(),
  background? : String = "",
  ui_strings? : UiStrings = UiStrings::default(),
  show_credits? : Bool = false,
) -> StartMenu {
  {
    root_id,
    save_ns: save_namespace,
    save_store,
    background,
    ui_strings,
    show_credits,
  }
}

///|
pub impl @ui_menu.StartMenu for StartMenu with set_ui_strings(self, ui_strings) {
  self.ui_strings = ui_strings
}

///|
pub fn StartMenu::set_show_credits(
  self : StartMenu,
  show_credits : Bool,
) -> Unit {
  self.show_credits = show_credits
}

///|
pub impl @ui_menu.StartMenu for StartMenu with render_gate(self) {
  start_gate_dom_render(self.root_id, self.ui_strings.start_gate_click_to_start)
}

///|
pub impl @ui_menu.StartMenu for StartMenu with clear_gate(self) {
  start_gate_dom_clear(self.root_id)
}

///|
pub impl @ui_menu.StartMenu for StartMenu with take_gate_action(self) {
  match start_gate_action_kind(self.root_id).to_option() {
    Some("start") => {
      start_gate_action_clear(self.root_id)
      StartGateAction::Start
    }
    _ => StartGateAction::NoAction
  }
}

///|
pub impl @ui_menu.StartMenu for StartMenu with render_logo(
  self,
  url,
  duration_ms,
) {
  start_logo_dom_render(self.root_id, url, duration_ms)
}

///|
pub impl @ui_menu.StartMenu for StartMenu with clear_logo(self) {
  start_logo_dom_clear(self.root_id)
}

///|
pub impl @ui_menu.StartMenu for StartMenu with take_logo_action(self) {
  match start_logo_action_kind(self.root_id).to_option() {
    Some("done") => {
      start_logo_action_clear(self.root_id)
      StartLogoAction::Done
    }
    _ => StartLogoAction::NoAction
  }
}

///|
pub impl @ui_menu.StartMenu for StartMenu with render_locale_picker(
  self,
  languages,
) {
  let names : Array[String] = []
  let codes : Array[String] = []
  for language in languages {
    names.push(language.0)
    codes.push(language.1)
  }
  start_locale_dom_render(
    self.root_id,
    names,
    codes,
    self.ui_strings.start_locale_title,
  )
}

///|
pub impl @ui_menu.StartMenu for StartMenu with clear_locale_picker(self) {
  start_locale_dom_clear(self.root_id)
}

///|
pub impl @ui_menu.StartMenu for StartMenu with take_locale_action(self) {
  match start_locale_action_code(self.root_id).to_option() {
    Some(code) => {
      start_locale_action_clear(self.root_id)
      Select(code)
    }
    None => NoAction
  }
}

///|
extern "js" fn start_menu_dom_render(
  root_id : String,
  has_continue : Bool,
  continue_slot : String,
  background : String,
  has_gallery : Bool,
  has_credits : Bool,
  new_game_label : String,
  continue_label : String,
  load_label : String,
  settings_label : String,
  gallery_label : String,
  credits_label : String,
) -> Unit =
  #| (root_id, has_continue, continue_slot, background, has_gallery, has_credits, new_game_label, continue_label, load_label, settings_label, gallery_label, credits_label) => {
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
  #|   if (has_credits) {
  #|     actions.appendChild(mkButton(credits_label, 'credits'));
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
extern "js" fn start_locale_dom_render(
  root_id : String,
  names : Array[String],
  codes : Array[String],
  title : String,
) -> Unit =
  #| (root_id, names, codes, title) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   let host = root.querySelector('[data-reisen="start-locale"]');
  #|   if (!host) {
  #|     host = doc.createElement('div');
  #|     host.dataset.reisen = 'start-locale';
  #|     root.appendChild(host);
  #|   }
  #|   host.innerHTML = '';
  #|   const heading = doc.createElement('h2');
  #|   heading.textContent = title;
  #|   host.appendChild(heading);
  #|   const list = doc.createElement('div');
  #|   list.dataset.reisen = 'start-locale-list';
  #|   for (let i = 0; i < names.length; i++) {
  #|     const btn = doc.createElement('button');
  #|     btn.type = 'button';
  #|     btn.textContent = names[i] || codes[i] || '';
  #|     btn.addEventListener('click', () => {
  #|       root.dataset.reisenLocaleActionCode = codes[i] || '';
  #|     });
  #|     list.appendChild(btn);
  #|   }
  #|   host.appendChild(list);
  #| }

///|
extern "js" fn start_locale_action_code(
  root_id : String,
) -> @js.Nullable[String] =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return null;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return null;
  #|   const code = root.dataset.reisenLocaleActionCode;
  #|   return code || null;
  #| }

///|
extern "js" fn start_locale_action_clear(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   delete root.dataset.reisenLocaleActionCode;
  #| }

///|
extern "js" fn start_locale_dom_clear(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   const host = root.querySelector('[data-reisen="start-locale"]');
  #|   if (host) host.remove();
  #|   delete root.dataset.reisenLocaleActionCode;
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
pub impl @ui_menu.StartMenu for StartMenu with render(self) {
  let entries = save_slot_store_entries_in(self.save_store, self.save_ns)
  let has_gallery = !@gallery.registered_images().is_empty()
  let has_credits = self.show_credits && self.ui_strings.menu_credits != ""
  let continue_slot = @ui_menu.choose_continue_slot(entries)
  match continue_slot {
    Some(slot) =>
      start_menu_dom_render(
        self.root_id,
        true,
        slot,
        self.background,
        has_gallery,
        has_credits,
        self.ui_strings.start_menu_new_game,
        self.ui_strings.start_menu_continue,
        self.ui_strings.start_menu_load,
        self.ui_strings.start_menu_settings,
        self.ui_strings.start_menu_gallery,
        self.ui_strings.menu_credits,
      )
    None =>
      start_menu_dom_render(
        self.root_id,
        false,
        "",
        self.background,
        has_gallery,
        has_credits,
        self.ui_strings.start_menu_new_game,
        self.ui_strings.start_menu_continue,
        self.ui_strings.start_menu_load,
        self.ui_strings.start_menu_settings,
        self.ui_strings.start_menu_gallery,
        self.ui_strings.menu_credits,
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
pub impl @ui_menu.StartMenu for StartMenu with clear(self) {
  start_locale_dom_clear(self.root_id)
  start_menu_dom_clear(self.root_id)
}

///|
pub impl @ui_menu.StartMenu for StartMenu with take_action(self) {
  match start_menu_action_kind(self.root_id).to_option() {
    Some("new") => {
      start_menu_action_clear(self.root_id)
      NewGame
    }
    Some("continue") => {
      let slot = start_menu_action_slot(self.root_id).to_option().unwrap_or("")
      start_menu_action_clear(self.root_id)
      match slot {
        "" => NoAction
        _ => Continue(slot)
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
    Some("credits") => {
      start_menu_action_clear(self.root_id)
      Credits
    }
    _ => NoAction
  }
}
