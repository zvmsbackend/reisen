///|
/// Settings menu DOM integration (text speed, BGM volume, SFX volume, skip mode).

///|
pub enum SettingsContext {
  FromStartMenu
  FromMidgame
} derive(Show, Eq)

///|
priv enum SettingsViewMode {
  Settings
  SaveList
  LoadList
}

///|
priv enum SettingsAction {
  ViewChanged
  NoAction
  Back
  NewGame
  StartMenu
  Log
  SaveSlot(String)
  LoadSlot(String)
}

///|
priv enum SaveSlotType {
  Autosave
  Quicksave
  Normal
}

///|
priv struct SettingsMenu {
  root_id : String
  save_ns : String
  background : String
  mut context : SettingsContext
  mut view_mode : SettingsViewMode
  mut save_slot_type : SaveSlotType
  mut page : Int
}

///|
priv struct SettingsView {
  text_speed : Int
  bgm_volume : Double
  sfx_volume : Double
}

///|
fn SettingsMenu::new(
  root_id : String,
  save_namespace? : String = "global",
  background? : String = "",
  context? : SettingsContext = SettingsContext::FromStartMenu,
) -> SettingsMenu {
  {
    root_id,
    save_ns: save_namespace,
    background,
    context,
    view_mode: SettingsViewMode::Settings,
    save_slot_type: SaveSlotType::Normal,
    page: 0,
  }
}

///|
fn SettingsMenu::set_context(
  self : SettingsMenu,
  context : SettingsContext,
) -> Unit {
  self.context = context
}

///|
fn SettingsMenu::set_view_mode(
  self : SettingsMenu,
  mode : SettingsViewMode,
) -> Unit {
  self.view_mode = mode
  self.save_slot_type = SaveSlotType::Normal
  self.page = 0
}

///|
fn to_settings_view(settings : GameSettings) -> SettingsView {
  {
    text_speed: settings.text_speed,
    bgm_volume: settings.bgm_volume,
    sfx_volume: settings.sfx_volume,
  }
}

///|
extern "js" fn settings_dom_install_confirm_helper() -> Unit =
  #| () => {
  #|   if (globalThis.__reisenOpenConfirm) return;
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   globalThis.__reisenOpenConfirm = (root, message, onConfirm) => {
  #|     const existing = root.querySelector('[data-reisen="confirm-backdrop"]');
  #|     if (existing) existing.remove();
  #|     const backdrop = doc.createElement('div');
  #|     backdrop.dataset.reisen = 'confirm-backdrop';
  #|     const dialog = doc.createElement('div');
  #|     dialog.dataset.reisen = 'confirm-dialog';
  #|     const messageNode = doc.createElement('p');
  #|     messageNode.textContent = message;
  #|     const actions = doc.createElement('div');
  #|     actions.dataset.reisen = 'confirm-actions';
  #|     const cancelBtn = doc.createElement('button');
  #|     cancelBtn.type = 'button';
  #|     cancelBtn.textContent = 'Cancel';
  #|     const okBtn = doc.createElement('button');
  #|     okBtn.type = 'button';
  #|     okBtn.textContent = 'Confirm';
  #|     const close = () => backdrop.remove();
  #|     cancelBtn.addEventListener('click', close);
  #|     okBtn.addEventListener('click', () => {
  #|       close();
  #|       onConfirm();
  #|     });
  #|     backdrop.addEventListener('click', (e) => {
  #|       if (e.target === backdrop) close();
  #|     });
  #|     backdrop.addEventListener('keydown', (e) => {
  #|       if (e.key === 'Escape') close();
  #|     });
  #|     actions.appendChild(okBtn);
  #|     actions.appendChild(cancelBtn);
  #|     dialog.appendChild(messageNode);
  #|     dialog.appendChild(actions);
  #|     backdrop.appendChild(dialog);
  #|     root.appendChild(backdrop);
  #|     cancelBtn.focus();
  #|   };
  #| }

///|
extern "js" fn settings_dom_render(
  root_id : String,
  text_speed : Int,
  bgm_volume : Double,
  sfx_volume : Double,
  background : String,
  context : String,
) -> Unit =
  #| (root_id, text_speed, bgm_volume, sfx_volume, background, context) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   if (globalThis.__reisenOpenConfirm == null) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   const openConfirm = (message, onConfirm) => globalThis.__reisenOpenConfirm(root, message, onConfirm);
  #|
  #|   let menu = root.querySelector('[data-reisen="settings-menu"]');
  #|   if (!menu) {
  #|     menu = doc.createElement('div');
  #|     menu.dataset.reisen = 'settings-menu';
  #|     root.appendChild(menu);
  #|   }
  #|
  #|   if (background && background !== '') {
  #|     menu.style.backgroundImage = `url(${background})`;
  #|     menu.style.backgroundSize = 'cover';
  #|     menu.style.backgroundPosition = 'center';
  #|   }
  #|   if (context) {
  #|     menu.dataset.reisenContext = context;
  #|   }
  #|
  #|   menu.innerHTML = '';
  #|
  #|   const settingsPanel = doc.createElement('div');
  #|   settingsPanel.dataset.reisen = 'settings-panel';
  #|
  #|   const mkLabel = (text) => {
  #|     const label = doc.createElement('label');
  #|     label.textContent = text;
  #|     return label;
  #|   };
  #|
  #|   const mkSlider = (id, min, max, value, step = 1) => {
  #|     const input = doc.createElement('input');
  #|     input.type = 'range';
  #|     input.min = min;
  #|     input.max = max;
  #|     input.value = value;
  #|     input.step = step;
  #|     input.dataset.reisenSetting = id;
  #|     input.addEventListener('input', () => {
  #|       root.dataset.reisenSettingsAction = 'settings_changed';
  #|     });
  #|     return input;
  #|   };
  #|
  #|   const mkCheckbox = (id, checked) => {
  #|     const input = doc.createElement('input');
  #|     input.type = 'checkbox';
  #|     input.checked = checked;
  #|     input.dataset.reisenSetting = id;
  #|     return input;
  #|   };
  #|
  #|   const mkRow = (labelText, control) => {
  #|     const row = doc.createElement('div');
  #|     row.dataset.reisen = 'settings-row';
  #|     row.appendChild(mkLabel(labelText));
  #|     row.appendChild(control);
  #|     return row;
  #|   };
  #|
  #|   settingsPanel.appendChild(mkRow('Text Speed', mkSlider('text_speed', 10, 100, text_speed, 10)));
  #|   settingsPanel.appendChild(mkRow('BGM Volume', mkSlider('bgm_volume', 0, 100, Math.round(bgm_volume * 100), 1)));
  #|   settingsPanel.appendChild(mkRow('SFX Volume', mkSlider('sfx_volume', 0, 100, Math.round(sfx_volume * 100), 1)));
  #|
  #|   menu.appendChild(settingsPanel);
  #|
  #|   const actions = doc.createElement('div');
  #|   actions.dataset.reisen = 'settings-actions';
  #|
  #|   const mkButton = (text, kind) => {
  #|     const btn = doc.createElement('button');
  #|     btn.type = 'button';
  #|     btn.textContent = text;
  #|     btn.addEventListener('click', () => {
  #|       if (kind === 'defaults') {
  #|         const textSpeed = menu.querySelector('[data-reisen-setting="text_speed"]');
  #|         const bgmVolume = menu.querySelector('[data-reisen-setting="bgm_volume"]');
  #|         const sfxVolume = menu.querySelector('[data-reisen-setting="sfx_volume"]');
  #|         if (textSpeed) textSpeed.value = 50;
  #|         if (bgmVolume) bgmVolume.value = 70;
  #|         if (sfxVolume) sfxVolume.value = 80;
  #|         root.dataset.reisenSettingsAction = 'defaults';
  #|         return;
  #|       }
  #|       if (kind === 'start_menu' && context === 'midgame') {
  #|         openConfirm('Return to the start menu? Unsaved progress will be lost.', () => {
  #|           root.dataset.reisenSettingsAction = kind;
  #|         });
  #|         return;
  #|       }
  #|       root.dataset.reisenSettingsAction = kind;
  #|     });
  #|     return btn;
  #|   };
  #|
  #|   if (context === 'midgame') {
  #|     actions.appendChild(mkButton('Save', 'save'));
  #|     actions.appendChild(mkButton('Load', 'load'));
  #|     actions.appendChild(mkButton('Log', 'log'));
  #|     actions.appendChild(mkButton('Start Menu', 'start_menu'));
  #|   } else {
  #|     actions.appendChild(mkButton('New Game', 'new_game'));
  #|     actions.appendChild(mkButton('Load', 'load'));
  #|   }
  #|   actions.appendChild(mkButton('Defaults', 'defaults'));
  #|   actions.appendChild(mkButton('Back', 'back'));
  #|   menu.appendChild(actions);
  #| }

///|
extern "js" fn settings_action_kind(root_id : String) -> @js.Nullable[String] =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return null;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return null;
  #|   const kind = root.dataset.reisenSettingsAction;
  #|   return kind || null;
  #| }

///|
extern "js" fn settings_action_slot(root_id : String) -> @js.Nullable[String] =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return null;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return null;
  #|   const slot = root.dataset.reisenSettingsActionSlot;
  #|   return slot || null;
  #| }

///|
extern "js" fn settings_action_slot_type(
  root_id : String,
) -> @js.Nullable[String] =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return null;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return null;
  #|   const slot_type = root.dataset.reisenSettingsSlotType;
  #|   return slot_type || null;
  #| }

///|
extern "js" fn settings_action_clear(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   delete root.dataset.reisenSettingsAction;
  #|   delete root.dataset.reisenSettingsActionSlot;
  #| }

///|
extern "js" fn settings_dom_render_slots(
  root_id : String,
  slots : Array[String],
  titles : Array[String],
  previews : Array[String],
  mode : String,
  slot_type : String,
  current_page : Int,
  total_pages : Int,
  max_pages : Int,
  background : String,
) -> Unit =
  #| (root_id, slots, titles, previews, mode, slot_type, current_page, total_pages, max_pages, background) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   if (globalThis.__reisenOpenConfirm == null) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   const openConfirm = (message, onConfirm) => globalThis.__reisenOpenConfirm(root, message, onConfirm);
  #|
  #|   let menu = root.querySelector('[data-reisen="settings-menu"]');
  #|   if (!menu) {
  #|     menu = doc.createElement('div');
  #|     menu.dataset.reisen = 'settings-menu';
  #|     root.appendChild(menu);
  #|   }
  #|
  #|   if (background && background !== '') {
  #|     menu.style.backgroundImage = `url(${background})`;
  #|     menu.style.backgroundSize = 'cover';
  #|     menu.style.backgroundPosition = 'center';
  #|   }
  #|
  #|   menu.innerHTML = '';
  #|
  #|   const title = doc.createElement('h2');
  #|   title.textContent = mode === 'save' ? 'Save Game' : 'Load Game';
  #|   title.dataset.reisen = 'settings-title';
  #|   menu.appendChild(title);
  #|
  #|   // Tab buttons for slot types
  #|   const tabs = doc.createElement('div');
  #|   tabs.dataset.reisen = 'settings-tabs';
  #|   menu.dataset.reisenSlotType = slot_type;
  #|
  #|   const mkTab = (text, type) => {
  #|     const btn = doc.createElement('button');
  #|     btn.type = 'button';
  #|     btn.textContent = text;
  #|     btn.dataset.reisen = 'settings-tab';
  #|     btn.dataset.reisenSlotType = type;
  #|     btn.addEventListener('click', () => {
  #|       root.dataset.reisenSettingsAction = 'slot_type';
  #|       root.dataset.reisenSettingsSlotType = type;
  #|     });
  #|     return btn;
  #|   };
  #|
  #|   tabs.appendChild(mkTab('Auto', 'autosave'));
  #|   tabs.appendChild(mkTab('Quick', 'quicksave'));
  #|   tabs.appendChild(mkTab('Save', 'normal'));
  #|   menu.appendChild(tabs);
  #|
  #|   // Grid container
  #|   const grid = doc.createElement('div');
  #|   grid.dataset.reisen = 'settings-grid';
  #|
  #|   const mkSlotButton = (slot, title_, preview) => {
  #|     const btn = doc.createElement('button');
  #|     btn.type = 'button';
  #|     btn.dataset.reisen = 'settings-slot';
  #|     const titleSpan = doc.createElement('span');
  #|     titleSpan.textContent = title_;
  #|     titleSpan.dataset.reisen = 'settings-slot-title';
  #|     btn.appendChild(titleSpan);
  #|     if (preview) {
  #|       const previewSpan = doc.createElement('span');
  #|       previewSpan.textContent = preview.substring(0, 50) + (preview.length > 50 ? '...' : '');
  #|       previewSpan.dataset.reisen = 'settings-slot-preview';
  #|       btn.appendChild(previewSpan);
  #|     }
  #|     const deleteBtn = doc.createElement('button');
  #|     deleteBtn.type = 'button';
  #|     deleteBtn.textContent = '×';
  #|     deleteBtn.dataset.reisen = 'settings-slot-delete';
  #|     deleteBtn.addEventListener('click', (e) => {
  #|       e.stopPropagation();
  #|       openConfirm('Delete this save slot?', () => {
  #|         root.dataset.reisenSettingsAction = 'delete_slot';
  #|         root.dataset.reisenSettingsActionSlot = slot;
  #|       });
  #|     });
  #|     btn.appendChild(deleteBtn);
  #|     btn.addEventListener('click', () => {
  #|       if (mode === 'save' && title_ !== 'Empty') {
  #|         openConfirm('Overwrite this save slot?', () => {
  #|           root.dataset.reisenSettingsAction = mode;
  #|           root.dataset.reisenSettingsActionSlot = slot;
  #|         });
  #|         return;
  #|       }
  #|       root.dataset.reisenSettingsAction = mode;
  #|       root.dataset.reisenSettingsActionSlot = slot;
  #|     });
  #|     return btn;
  #|   };
  #|
  #|   for (let i = 0; i < slots.length; i++) {
  #|     grid.appendChild(mkSlotButton(slots[i], titles[i], previews[i]));
  #|   }
  #|   menu.appendChild(grid);
  #|
  #|   // Navigation buttons
  #|   if (max_pages > 1) {
  #|     const nav = doc.createElement('div');
  #|     nav.dataset.reisen = 'settings-nav';
  #|
  #|     const prevBtn = doc.createElement('button');
  #|     prevBtn.type = 'button';
  #|     prevBtn.textContent = 'Prev';
  #|     prevBtn.disabled = current_page <= 0;
  #|     prevBtn.dataset.reisen = 'settings-nav-prev';
  #|     prevBtn.addEventListener('click', () => {
  #|       root.dataset.reisenSettingsAction = 'prev_page';
  #|     });
  #|     const pageInfo = doc.createElement('span');
  #|     pageInfo.textContent = `Page ${current_page + 1}`;
  #|     pageInfo.dataset.reisen = 'settings-page-info';
  #|     const nextBtn = doc.createElement('button');
  #|     nextBtn.type = 'button';
  #|     nextBtn.textContent = 'Next';
  #|     nextBtn.disabled = current_page >= max_pages - 1;
  #|     nextBtn.dataset.reisen = 'settings-nav-next';
  #|     nextBtn.addEventListener('click', () => {
  #|       root.dataset.reisenSettingsAction = 'next_page';
  #|     });
  #|
  #|     nav.appendChild(prevBtn);
  #|     nav.appendChild(pageInfo);
  #|     nav.appendChild(nextBtn);
  #|     menu.appendChild(nav);
  #|   }
  #|
  #|   const backBtn = doc.createElement('button');
  #|   backBtn.type = 'button';
  #|   backBtn.textContent = 'Back';
  #|   backBtn.dataset.reisen = 'settings-back';
  #|   backBtn.addEventListener('click', () => {
  #|     root.dataset.reisenSettingsAction = 'back';
  #|   });
  #|   menu.appendChild(backBtn);
  #| }

///|
extern "js" fn settings_dom_read(root_id : String) -> @js.Nullable[String] =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return null;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return null;
  #|   const menu = root.querySelector('[data-reisen="settings-menu"]');
  #|   if (!menu) return null;
  #|
  #|   const textSpeed = menu.querySelector('[data-reisen-setting="text_speed"]');
  #|   const bgmVolume = menu.querySelector('[data-reisen-setting="bgm_volume"]');
  #|   const sfxVolume = menu.querySelector('[data-reisen-setting="sfx_volume"]');
  #|   const settings = {
  #|     text_speed: textSpeed ? parseInt(textSpeed.value, 10) : 50,
  #|     bgm_volume: bgmVolume ? parseInt(bgmVolume.value, 10) / 100 : 0.7,
  #|     sfx_volume: sfxVolume ? parseInt(sfxVolume.value, 10) / 100 : 0.8,
  #|   };
  #|   return JSON.stringify(settings);
  #| }

///|
fn filter_entries_by_type(
  entries : Array[SaveSlotEntry],
  slot_type : SaveSlotType,
) -> Array[SaveSlotEntry] {
  entries.filter(fn(entry) {
    let slot = entry.slot
    match slot_type {
      SaveSlotType::Autosave => slot.has_prefix("autosave")
      SaveSlotType::Quicksave => slot.has_prefix("quicksave")
      SaveSlotType::Normal =>
        not(slot.has_prefix("autosave") || slot.has_prefix("quicksave"))
    }
  })
}

///|
fn SettingsMenu::render(self : SettingsMenu) -> Unit {
  settings_dom_install_confirm_helper()
  match self.view_mode {
    SettingsViewMode::SaveList | SettingsViewMode::LoadList => {
      let mode_str = match self.view_mode {
        SettingsViewMode::SaveList => "save"
        SettingsViewMode::LoadList => "load"
        _ => "load"
      }
      let slot_type_str = match self.save_slot_type {
        SaveSlotType::Autosave => "autosave"
        SaveSlotType::Quicksave => "quicksave"
        SaveSlotType::Normal => "normal"
      }
      let entries = save_slot_entries_in(self.save_ns)
      let filtered = filter_entries_by_type(entries, self.save_slot_type)
      let total_slots = 6
      let current_page = self.page
      let start_idx = current_page * total_slots
      let slots : Array[String] = []
      let titles : Array[String] = []
      let previews : Array[String] = []
      for i in 0..<total_slots {
        let idx = start_idx + i
        if idx < filtered.length() {
          let entry = filtered[idx]
          let title = match entry.meta {
            Some(meta) => if meta.title == "" { entry.slot } else { meta.title }
            None => entry.slot
          }
          let preview = match entry.meta {
            Some(meta) => meta.preview
            None => ""
          }
          slots.push(entry.slot)
          titles.push(title)
          previews.push(preview)
        } else {
          let slot_num = start_idx + i + 1
          let slot_name = match self.save_slot_type {
            SaveSlotType::Autosave => "autosave\{slot_num}"
            SaveSlotType::Quicksave => "quicksave\{slot_num}"
            SaveSlotType::Normal => slot_num.to_string()
          }
          slots.push(slot_name)
          titles.push("Empty")
          previews.push("")
        }
      }
      let total_pages = (filtered.length() + total_slots - 1) / total_slots
      let max_pages = match self.save_slot_type {
        SaveSlotType::Normal => 100 // Arbitrary large number
        _ => 1
      }
      settings_dom_render_slots(
        self.root_id,
        slots,
        titles,
        previews,
        mode_str,
        slot_type_str,
        current_page,
        total_pages,
        max_pages,
        self.background,
      )
    }
    SettingsViewMode::Settings => {
      let settings = match settings_read_in(self.save_ns) {
        Some(s) => s
        None => game_settings_default()
      }
      let view = to_settings_view(settings)
      let context_str = match self.context {
        SettingsContext::FromStartMenu => "start_menu"
        SettingsContext::FromMidgame => "midgame"
      }
      settings_dom_render(
        self.root_id,
        view.text_speed,
        view.bgm_volume,
        view.sfx_volume,
        self.background,
        context_str,
      )
    }
  }
}

///|
extern "js" fn settings_dom_clear(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   const confirm = root.querySelector('[data-reisen="confirm-backdrop"]');
  #|   if (confirm) confirm.remove();
  #|   const menu = root.querySelector('[data-reisen="settings-menu"]');
  #|   if (menu) menu.remove();
  #|   delete root.dataset.reisenSettingsAction;
  #| }

///|
fn SettingsMenu::clear(self : SettingsMenu) -> Unit {
  settings_dom_clear(self.root_id)
}

///|
fn SettingsMenu::persist_settings(self : SettingsMenu) -> Unit {
  match settings_dom_read(self.root_id).to_option() {
    Some(raw) =>
      try {
        let settings : GameSettings = @json.from_json(@json.parse(raw))
        audio_dom_set_bgm_gain(settings.bgm_volume)
        audio_dom_set_sfx_gain(settings.sfx_volume)
        settings_write_in(self.save_ns, settings)
      } catch {
        _ => ()
      }
    None => ()
  }
}

///|
fn SettingsMenu::take_action(self : SettingsMenu) -> SettingsAction {
  match settings_action_kind(self.root_id).to_option() {
    Some("start_menu") => {
      if self.view_mode is SettingsViewMode::Settings {
        self.persist_settings()
      }
      SettingsAction::StartMenu
    }
    Some("new_game") => {
      if self.view_mode is SettingsViewMode::Settings {
        self.persist_settings()
      }
      SettingsAction::NewGame
    }
    Some("log") => {
      settings_action_clear(self.root_id)
      SettingsAction::Log
    }
    Some("back") => {
      if self.view_mode is SettingsViewMode::Settings {
        self.persist_settings()
      }
      settings_action_clear(self.root_id)
      match self.view_mode {
        SettingsViewMode::SaveList | SettingsViewMode::LoadList =>
          self.view_mode = SettingsViewMode::Settings
        _ => ()
      }
      SettingsAction::Back
    }
    Some("save") =>
      match self.view_mode {
        SettingsViewMode::SaveList | SettingsViewMode::LoadList => {
          let slot = settings_action_slot(self.root_id).to_option()
          settings_action_clear(self.root_id)
          match slot {
            Some(s) => SettingsAction::SaveSlot(s)
            None => SettingsAction::NoAction
          }
        }
        SettingsViewMode::Settings => {
          self.persist_settings()
          self.view_mode = SettingsViewMode::SaveList
          SettingsAction::ViewChanged
        }
      }
    Some("load") =>
      match self.view_mode {
        SettingsViewMode::SaveList | SettingsViewMode::LoadList => {
          let slot = settings_action_slot(self.root_id).to_option()
          settings_action_clear(self.root_id)
          match slot {
            Some(s) => SettingsAction::LoadSlot(s)
            None => SettingsAction::NoAction
          }
        }
        SettingsViewMode::Settings => {
          self.persist_settings()
          self.view_mode = SettingsViewMode::LoadList
          SettingsAction::ViewChanged
        }
      }
    Some("delete_slot") => {
      let slot = settings_action_slot(self.root_id).to_option()
      settings_action_clear(self.root_id)
      match slot {
        Some(s) => {
          save_slot_delete_in(self.save_ns, s)
          SettingsAction::ViewChanged
        }
        None => SettingsAction::NoAction
      }
    }
    Some("prev_page") => {
      settings_action_clear(self.root_id)
      match self.view_mode {
        SettingsViewMode::SaveList | SettingsViewMode::LoadList =>
          if self.page > 0 {
            self.page -= 1
            SettingsAction::ViewChanged
          } else {
            SettingsAction::NoAction
          }
        _ => SettingsAction::NoAction
      }
    }
    Some("next_page") => {
      settings_action_clear(self.root_id)
      match self.view_mode {
        SettingsViewMode::SaveList | SettingsViewMode::LoadList => {
          self.page += 1
          SettingsAction::ViewChanged
        }
        _ => SettingsAction::NoAction
      }
    }
    Some("slot_type") => {
      let slot_type_str = settings_action_slot_type(self.root_id).to_option()
      settings_action_clear(self.root_id)
      match slot_type_str {
        Some("autosave") => {
          self.save_slot_type = SaveSlotType::Autosave
          self.page = 0
          SettingsAction::ViewChanged
        }
        Some("quicksave") => {
          self.save_slot_type = SaveSlotType::Quicksave
          self.page = 0
          SettingsAction::ViewChanged
        }
        Some("normal") => {
          self.save_slot_type = SaveSlotType::Normal
          self.page = 0
          SettingsAction::ViewChanged
        }
        _ => SettingsAction::NoAction
      }
    }
    Some("settings_changed") => {
      settings_action_clear(self.root_id)
      self.persist_settings()
      SettingsAction::NoAction
    }
    Some("defaults") => {
      settings_action_clear(self.root_id)
      self.persist_settings()
      SettingsAction::NoAction
    }
    _ => SettingsAction::NoAction
  }
}
