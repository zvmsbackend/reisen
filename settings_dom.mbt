///|
/// Settings menu DOM integration (text speed, BGM volume, SFX volume, skip mode).

///|
priv enum SettingsAction {
  NoAction
  Back
  Saved
}

///|
priv struct SettingsMenu {
  root_id : String
  save_ns : String
  background : String
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
) -> SettingsMenu {
  { root_id, save_ns: save_namespace, background }
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
) -> Unit =
  #| (root_id, text_speed, bgm_volume, sfx_volume, background) => {
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
  #|   menu.appendChild(mkRow('Text Speed', mkSlider('text_speed', 10, 100, text_speed, 10)));
  #|   menu.appendChild(mkRow('BGM Volume', mkSlider('bgm_volume', 0, 100, Math.round(bgm_volume * 100), 1)));
  #|   menu.appendChild(mkRow('SFX Volume', mkSlider('sfx_volume', 0, 100, Math.round(sfx_volume * 100), 1)));
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
  #|   actions.appendChild(mkButton('Save', 'save'));
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
extern "js" fn settings_action_clear(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   delete root.dataset.reisenSettingsAction;
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
  let settings = match settings_read_in(self.save_ns) {
    Some(s) => s
    None => game_settings_default()
  }
  let view = to_settings_view(settings)
  settings_dom_render(
    self.root_id,
    view.text_speed,
    view.bgm_volume,
    view.sfx_volume,
    self.background,
  )
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
    Some("back") => {
      settings_action_clear(self.root_id)
      SettingsAction::Back
    }
    Some("save") => {
      let raw = settings_dom_read(self.root_id).to_option()
      settings_action_clear(self.root_id)
      match raw {
        Some(json_str) => {
          let parsed : Result[GameSettings, Error] = try? @json.from_json(
            @json.parse(json_str),
          )
          match parsed {
            Ok(settings) => {
              settings_write_in(self.save_ns, settings)
              SettingsAction::Saved
            }
            Err(_) => SettingsAction::NoAction
          }
        }
        None => SettingsAction::NoAction
      }
    }
    _ => SettingsAction::NoAction
  }
}

///|
fn SettingsMenu::current_settings(self : SettingsMenu) -> GameSettings {
  match settings_read_in(self.save_ns) {
    Some(s) => s
    None => game_settings_default()
  }
}
