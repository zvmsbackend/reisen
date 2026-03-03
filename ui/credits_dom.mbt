///|
pub enum CreditsAction {
  NoAction
  Back
}

///|
struct CreditsMenu {
  root_id : String
  background : String
  mut ui_strings : UiStrings
}

///|
pub fn CreditsMenu::new(
  root_id : String,
  background? : String = "",
  ui_strings? : UiStrings = UiStrings::default(),
) -> CreditsMenu {
  { root_id, background, ui_strings }
}

///|
pub fn CreditsMenu::set_ui_strings(
  self : CreditsMenu,
  ui_strings : UiStrings,
) -> Unit {
  self.ui_strings = ui_strings
}

///|
extern "js" fn credits_dom_render(
  root_id : String,
  background : String,
  credits_html : String,
  back_label : String,
) -> Unit =
  #| (root_id, background, credits_html, back_label) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   let host = root.querySelector('[data-reisen="credits-menu"]');
  #|   if (!host) {
  #|     host = doc.createElement('div');
  #|     host.dataset.reisen = 'credits-menu';
  #|     root.appendChild(host);
  #|   }
  #|   if (background && background !== '') {
  #|     host.style.backgroundImage = `url(${background})`;
  #|     host.style.backgroundSize = 'cover';
  #|     host.style.backgroundPosition = 'center';
  #|   } else {
  #|     host.style.backgroundImage = '';
  #|     host.style.backgroundSize = '';
  #|     host.style.backgroundPosition = '';
  #|   }
  #|   host.innerHTML = '';
  #|   const content = doc.createElement('div');
  #|   content.dataset.reisen = 'credits-content';
  #|   content.innerHTML = credits_html || '';
  #|   host.appendChild(content);
  #|   const actions = doc.createElement('div');
  #|   actions.dataset.reisen = 'credits-actions';
  #|   const back = doc.createElement('button');
  #|   back.type = 'button';
  #|   back.textContent = back_label;
  #|   back.addEventListener('click', () => {
  #|     root.dataset.reisenCreditsAction = 'back';
  #|   });
  #|   actions.appendChild(back);
  #|   host.appendChild(actions);
  #| }

///|
extern "js" fn credits_action_kind(root_id : String) -> @js.Nullable[String] =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return null;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return null;
  #|   const action = root.dataset.reisenCreditsAction;
  #|   return action || null;
  #| }

///|
extern "js" fn credits_action_clear(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   delete root.dataset.reisenCreditsAction;
  #| }

///|
extern "js" fn credits_dom_clear(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   const host = root.querySelector('[data-reisen="credits-menu"]');
  #|   if (host) host.remove();
  #|   delete root.dataset.reisenCreditsAction;
  #| }

///|
pub fn CreditsMenu::render(self : CreditsMenu, credits_html : String) -> Unit {
  credits_dom_render(
    self.root_id,
    self.background,
    credits_html,
    self.ui_strings.settings_back,
  )
}

///|
pub fn CreditsMenu::take_action(self : CreditsMenu) -> CreditsAction {
  match credits_action_kind(self.root_id).to_option() {
    Some("back") => {
      credits_action_clear(self.root_id)
      CreditsAction::Back
    }
    _ => CreditsAction::NoAction
  }
}

///|
pub fn CreditsMenu::clear(self : CreditsMenu) -> Unit {
  credits_dom_clear(self.root_id)
}
