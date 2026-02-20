///|
/// HTML UI bridge for dialogs and choice buttons.
/// Figures/backgrounds stay in WebGL; this module only updates DOM nodes.

///|
pub struct UiChoiceView {
  id : String
  text : String
} derive(Show, Eq)

///|
pub struct UiViewModel {
  speaker : String
  text : String
  choices : Array[UiChoiceView]
} derive(Show, Eq)

///|
pub struct UiDom {
  root_id : String
}

///|
pub fn UiDom::new(root_id : String) -> UiDom {
  { root_id, }
}

///|
extern "js" fn dom_render(
  root_id : String,
  speaker : String,
  text : String,
  choice_ids : Array[String],
  choice_texts : Array[String],
) -> Unit =
  #| (root_id, speaker, text, choice_ids, choice_texts) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|
  #|   let dialog = root.querySelector('[data-reisen="dialog"]');
  #|   if (!dialog) {
  #|     dialog = doc.createElement('div');
  #|     dialog.setAttribute('data-reisen', 'dialog');
  #|     root.appendChild(dialog);
  #|   }
  #|   let nameEl = root.querySelector('[data-reisen="speaker"]');
  #|   if (!nameEl) {
  #|     nameEl = doc.createElement('div');
  #|     nameEl.setAttribute('data-reisen', 'speaker');
  #|     root.appendChild(nameEl);
  #|   }
  #|   nameEl.textContent = speaker;
  #|   dialog.textContent = text;
  #|
  #|   let choices = root.querySelector('[data-reisen="choices"]');
  #|   if (!choices) {
  #|     choices = doc.createElement('div');
  #|     choices.setAttribute('data-reisen', 'choices');
  #|     root.appendChild(choices);
  #|   }
  #|   choices.innerHTML = '';
  #|   for (let i = 0; i < choice_ids.length; i++) {
  #|     const btn = doc.createElement('button');
  #|     btn.type = 'button';
  #|     btn.textContent = choice_texts[i] ?? choice_ids[i];
  #|     btn.setAttribute('data-choice-id', choice_ids[i]);
  #|     btn.addEventListener('click', () => {
  #|       root.dataset.reisenSelectedChoice = choice_ids[i];
  #|     });
  #|     choices.appendChild(btn);
  #|   }
  #| }

///|
extern "js" fn dom_take_selected_choice(
  root_id : String,
) -> @js.Nullable[String] =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return null;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return null;
  #|   const value = root.dataset.reisenSelectedChoice;
  #|   if (!value) return null;
  #|   delete root.dataset.reisenSelectedChoice;
  #|   return value;
  #| }

///|
pub fn[T] ui_view_from_director(director : Director[T]) -> UiViewModel {
  let (speaker, text) = match director.dialog() {
    Some(line) => (line.speaker, line.text)
    None => ("", "")
  }
  let choices = director
    .choices()
    .map(opt => UiChoiceView::{ id: opt.id, text: opt.text })
  { speaker, text, choices }
}

///|
pub fn UiDom::render(self : UiDom, view : UiViewModel) -> Unit {
  let ids = view.choices.map(c => c.id)
  let texts = view.choices.map(c => c.text)
  dom_render(self.root_id, view.speaker, view.text, ids, texts)
}

///|
pub fn UiDom::take_selected_choice(self : UiDom) -> String? {
  dom_take_selected_choice(self.root_id).to_option()
}
