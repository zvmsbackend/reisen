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
  Saved
  NewGame
  Load
  StartMenu
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
  mut save_page : Int
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
    save_page: 0,
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
  self.save_page = 0
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
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|
  #|   let menu = root.querySelector('[data-reisen="settings-menu"]');
  #|   if (!menu) {
  #|     menu = doc.createElement('div');
  #|     menu.setAttribute('data-reisen', 'settings-menu');
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
  #|   const settingsPanel = doc.createElement('div');
  #|   settingsPanel.style.background = 'var(--bg-secondary, rgba(0, 0, 0, 0.85))';
  #|   settingsPanel.style.padding = '20px 24px';
  #|   settingsPanel.style.borderRadius = '12px';
  #|   settingsPanel.style.boxShadow = '0 4px 24px rgba(0, 0, 0, 0.3)';
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
  #|     input.setAttribute('data-reisen-setting', id);
  #|     return input;
  #|   };
  #|
  #|   const mkCheckbox = (id, checked) => {
  #|     const input = doc.createElement('input');
  #|     input.type = 'checkbox';
  #|     input.checked = checked;
  #|     input.setAttribute('data-reisen-setting', id);
  #|     return input;
  #|   };
  #|
  #|   const mkRow = (labelText, control) => {
  #|     const row = doc.createElement('div');
  #|     row.style.display = 'flex';
  #|     row.style.alignItems = 'center';
  #|     row.style.gap = '8px';
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
  #|   actions.setAttribute('data-reisen', 'settings-actions');
  #|   actions.style.marginTop = '16px';
  #|
  #|   const mkButton = (text, kind) => {
  #|     const btn = doc.createElement('button');
  #|     btn.type = 'button';
  #|     btn.textContent = text;
  #|     btn.addEventListener('click', () => {
  #|       root.dataset.reisenSettingsAction = kind;
  #|     });
  #|     return btn;
  #|   };
  #|
  #|   if (context === 'midgame') {
  #|     actions.appendChild(mkButton('Save', 'save'));
  #|     actions.appendChild(mkButton('Load', 'load'));
  #|     actions.appendChild(mkButton('Start Menu', 'start_menu'));
  #|   } else {
  #|     actions.appendChild(mkButton('New Game', 'new_game'));
  #|     actions.appendChild(mkButton('Load', 'load'));
  #|   }
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
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|
  #|   let menu = root.querySelector('[data-reisen="settings-menu"]');
  #|   if (!menu) {
  #|     menu = doc.createElement('div');
  #|     menu.setAttribute('data-reisen', 'settings-menu');
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
  #|   title.style.color = 'var(--text-primary, #fff)';
  #|   title.style.marginBottom = '16px';
  #|   menu.appendChild(title);
  #|
  #|   // Tab buttons for slot types
  #|   const tabs = doc.createElement('div');
  #|   tabs.style.display = 'flex';
  #|   tabs.style.gap = '8px';
  #|   tabs.style.marginBottom = '16px';
  #|
  #|   const mkTab = (text, type) => {
  #|     const btn = doc.createElement('button');
  #|     btn.type = 'button';
  #|     btn.textContent = text;
  #|     btn.style.padding = '8px 16px';
  #|     btn.style.background = slot_type === type ? 'var(--button-hover, rgba(255,255,255,0.2))' : 'transparent';
  #|     btn.style.color = 'var(--text-primary, #fff)';
  #|     btn.style.border = '1px solid var(--border-color, rgba(255,255,255,0.3))';
  #|     btn.style.borderRadius = '4px';
  #|     btn.style.cursor = 'pointer';
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
  #|   grid.style.display = 'grid';
  #|   grid.style.gridTemplateColumns = 'repeat(2, 1fr)';
  #|   grid.style.gap = '16px';
  #|   grid.style.background = 'var(--bg-secondary, rgba(0,0,0,0.85))';
  #|   grid.style.padding = '16px';
  #|   grid.style.borderRadius = '8px';
  #|   grid.style.boxShadow = '0 4px 24px rgba(0, 0, 0, 0.3)';
  #|   grid.style.maxHeight = '500px';
  #|   grid.style.overflowY = 'auto';
  #|   grid.style.width = 'min(90vw, 800px)';
  #|   grid.style.boxSizing = 'border-box';
  #|   grid.style.gridTemplateRows = 'repeat(3, min(120px, 20vh))';

  #|
  #|   const mkSlotButton = (slot, title_, preview) => {
  #|     const btn = doc.createElement('button');
  #|     btn.type = 'button';
  #|     btn.style.padding = '16px';
  #|     btn.style.textAlign = 'left';
  #|     btn.style.background = 'transparent';
  #|     btn.style.color = 'var(--text-primary, #fff)';
  #|     btn.style.border = '1px solid var(--border-color, rgba(255,255,255,0.2))';
  #|     btn.style.borderRadius = '4px';
  #|     btn.style.cursor = 'pointer';
  #|     btn.style.display = 'flex';
  #|     btn.style.flexDirection = 'column';
  #|     btn.style.gap = '8px';
  #|     btn.style.justifyContent = 'space-between';
  #|     btn.style.height = '100%';
  #|     btn.style.boxSizing = 'border-box';
  #|
  #|     const titleSpan = doc.createElement('span');
  #|     titleSpan.textContent = title_;
  #|     titleSpan.style.fontWeight = 'bold';
  #|     btn.appendChild(titleSpan);
  #|
  #|     if (preview) {
  #|       const previewSpan = doc.createElement('span');
  #|       previewSpan.textContent = preview.substring(0, 50) + (preview.length > 50 ? '...' : '');
  #|       previewSpan.style.fontSize = '12px';
  #|       previewSpan.style.color = 'var(--text-secondary, rgba(255,255,255,0.7))';
  #|       btn.appendChild(previewSpan);
  #|     }
  #|
  #|     btn.addEventListener('click', () => {
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
  #|     nav.style.display = 'flex';
  #|     nav.style.justifyContent = 'space-between';
  #|     nav.style.marginTop = '16px';
  #|
  #|     const prevBtn = doc.createElement('button');
  #|     prevBtn.type = 'button';
  #|     prevBtn.textContent = 'Prev';
  #|     prevBtn.disabled = current_page <= 0;
  #|     prevBtn.style.padding = '8px 16px';
  #|     prevBtn.style.background = 'var(--bg-secondary, rgba(255,255,255,0.1))';
  #|     prevBtn.style.color = 'var(--text-primary, #fff)';
  #|     prevBtn.style.border = '1px solid var(--border-color, rgba(255,255,255,0.3))';
  #|     prevBtn.style.borderRadius = '4px';
  #|     prevBtn.style.cursor = 'pointer';
  #|     prevBtn.addEventListener('click', () => {
  #|       root.dataset.reisenSettingsAction = 'prev_page';
  #|     });

  #|     const pageInfo = doc.createElement('span');
  #|     pageInfo.textContent = `Page ${current_page + 1}`;
  #|     pageInfo.style.color = 'var(--text-primary, #fff)';
  #|     pageInfo.style.alignSelf = 'center';

  #|     const nextBtn = doc.createElement('button');
  #|     nextBtn.type = 'button';
  #|     nextBtn.textContent = 'Next';
  #|     nextBtn.disabled = current_page >= max_pages - 1;
  #|     nextBtn.style.padding = '8px 16px';
  #|     nextBtn.style.background = 'var(--bg-secondary, rgba(255,255,255,0.1))';
  #|     nextBtn.style.color = 'var(--text-primary, #fff)';
  #|     nextBtn.style.border = '1px solid var(--border-color, rgba(255,255,255,0.3))';
  #|     nextBtn.style.borderRadius = '4px';
  #|     nextBtn.style.cursor = 'pointer';
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
  #|   backBtn.style.marginTop = '16px';
  #|   backBtn.style.padding = '10px 24px';
  #|   backBtn.style.background = 'transparent';
  #|   backBtn.style.color = 'var(--text-primary, #fff)';
  #|   backBtn.style.border = '1px solid var(--border-color, rgba(255,255,255,0.3))';
  #|   backBtn.style.borderRadius = '4px';
  #|   backBtn.style.cursor = 'pointer';
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
      SaveSlotType::Autosave => slot.starts_with("autosave")
      SaveSlotType::Quicksave => slot.starts_with("quicksave")
      SaveSlotType::Normal =>
        not(slot.starts_with("autosave") || slot.starts_with("quicksave"))
    }
  })
}

///|
fn SettingsMenu::render(self : SettingsMenu) -> Unit {
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
      let start_idx = self.save_page * total_slots
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
        self.save_page,
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
  #|   const menu = root.querySelector('[data-reisen="settings-menu"]');
  #|   if (menu) menu.remove();
  #|   delete root.dataset.reisenSettingsAction;
  #| }

///|
fn SettingsMenu::clear(self : SettingsMenu) -> Unit {
  settings_dom_clear(self.root_id)
}

///|
fn SettingsMenu::take_action(self : SettingsMenu) -> SettingsAction {
  match settings_action_kind(self.root_id).to_option() {
    Some("start_menu") => SettingsAction::StartMenu
    Some("new_game") => SettingsAction::NewGame
    Some("back") => {
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
          self.view_mode = SettingsViewMode::LoadList
          SettingsAction::ViewChanged
        }
      }
    _ => SettingsAction::NoAction
  }
}
