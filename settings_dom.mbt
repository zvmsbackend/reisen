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
priv struct SettingsMenu {
  root_id : String
  save_ns : String
  background : String
  mut context : SettingsContext
  mut view_mode : SettingsViewMode
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
  { root_id, save_ns: save_namespace, background, context, view_mode: SettingsViewMode::Settings }
}

///|
fn SettingsMenu::set_context(self : SettingsMenu, context : SettingsContext) -> Unit {
  self.context = context
}

///|
fn SettingsMenu::set_view_mode(self : SettingsMenu, mode : SettingsViewMode) -> Unit {
  self.view_mode = mode
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
  background : String,
) -> Unit =
  #| (root_id, slots, titles, previews, mode, background) => {
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
  #|   const list = doc.createElement('div');
  #|   list.setAttribute('data-reisen', 'save-list');
  #|
  #|   const mkButton = (text, kind, slot = '') => {
  #|     const btn = doc.createElement('button');
  #|     btn.type = 'button';
  #|     btn.textContent = text;
  #|     btn.addEventListener('click', () => {
  #|       root.dataset.reisenSettingsAction = kind;
  #|       root.dataset.reisenSettingsActionSlot = slot;
  #|     });
  #|     return btn;
  #|   };
  #|
  #|   for (let i = 0; i < slots.length; i++) {
  #|     const slot = slots[i];
  #|     const title_ = titles[i] || slot;
  #|     const preview = previews[i] || '';
  #|     const text = preview ? `${title_} - ${preview}` : title_;
  #|     list.appendChild(mkButton(text, mode, slot));
  #|   }
  #|   menu.appendChild(list);
  #|
  #|   const backBtn = doc.createElement('button');
  #|   backBtn.type = 'button';
  #|   backBtn.textContent = 'Back';
  #|   backBtn.addEventListener('click', () => {
  #|     root.dataset.reisenSettingsAction = 'back';
  #|   });
  #|   backBtn.style.marginTop = '16px';
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
fn SettingsMenu::render(self : SettingsMenu) -> Unit {
  match self.view_mode {
    SettingsViewMode::SaveList | SettingsViewMode::LoadList => {
      let entries = save_slot_entries_in(self.save_ns)
      let mode_str = match self.view_mode {
        SettingsViewMode::SaveList => "save"
        SettingsViewMode::LoadList => "load"
        _ => "load"
      }
      let slots : Array[String] = []
      let titles : Array[String] = []
      let previews : Array[String] = []
      for entry in entries {
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
      }
      settings_dom_render_slots(
        self.root_id,
        slots,
        titles,
        previews,
        mode_str,
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
        SettingsViewMode::SaveList | SettingsViewMode::LoadList => {
          self.view_mode = SettingsViewMode::Settings
        }
        _ => ()
      }
      SettingsAction::Back
    }
    Some("save") => {
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
    }
    Some("load") => {
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
    }
    _ => SettingsAction::NoAction
  }
}
