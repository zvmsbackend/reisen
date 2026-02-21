///|
/// HTML UI bridge for dialogs and choice buttons.
/// Figures/backgrounds stay in WebGL; this module only updates DOM nodes.

///|
struct UiChoiceView {
  id : String
  text : String
} derive(Show, Eq)

///|
struct UiTextInputView {
  var_name : String
  prompt : String
} derive(Show, Eq)

///|
struct UiViewModel {
  speaker : String
  text : String
  choices : Array[UiChoiceView]
  text_input : UiTextInputView?
} derive(Show, Eq)

///|
struct UiDom {
  root_id : String
  mut text_speed : Int
  mut typewriter_text : String
  mut typewriter_visible : Int
  mut typewriter_last_update_ms : Int
  mut auto_mode : Bool
  auto_mode_delay_ms : Int
  mut auto_mode_last_advance_ms : Int
  mut skip_mode : Bool
}

///|
fn UiDom::new(root_id : String) -> UiDom {
  {
    root_id,
    text_speed: 50,
    typewriter_text: "",
    typewriter_visible: 0,
    typewriter_last_update_ms: 0,
    auto_mode: false,
    auto_mode_delay_ms: 2000,
    auto_mode_last_advance_ms: 0,
    skip_mode: false,
  }
}

///|
pub fn UiDom::set_text_speed(self : UiDom, speed : Int) -> Unit {
  let clamped = if speed < 10 { 10 } else if speed > 100 { 100 } else { speed }
  self.text_speed = clamped
}

///|
pub fn UiDom::text_speed_ms_per_char(self : UiDom) -> Int {
  let speed = self.text_speed
  if speed <= 0 {
    100
  } else {
    2000 / speed
  }
}

///|
pub fn UiDom::start_typewriter(self : UiDom, text : String) -> Unit {
  self.typewriter_text = text
  self.typewriter_visible = 0
  self.typewriter_last_update_ms = 0
}

///|
pub fn UiDom::is_typewriter_done(self : UiDom) -> Bool {
  self.typewriter_visible >= self.typewriter_text.length()
}

///|
pub fn UiDom::typewriter_visible_text(self : UiDom) -> StringView {
  self.typewriter_text[:self.typewriter_visible] catch {
    _ => self.typewriter_text
  }
}

///|
pub fn UiDom::advance_typewriter(self : UiDom, elapsed_ms~ : Int) -> Bool {
  if self.is_typewriter_done() {
    return true
  }
  self.typewriter_last_update_ms += elapsed_ms
  let ms_per_char = self.text_speed_ms_per_char()
  if self.typewriter_last_update_ms >= ms_per_char {
    let chars_to_add = self.typewriter_last_update_ms / ms_per_char
    self.typewriter_last_update_ms = self.typewriter_last_update_ms %
      ms_per_char
    self.typewriter_visible += chars_to_add
    if self.typewriter_visible > self.typewriter_text.length() {
      self.typewriter_visible = self.typewriter_text.length()
    }
  }
  self.is_typewriter_done()
}

///|
pub fn UiDom::complete_typewriter(self : UiDom) -> Unit {
  self.typewriter_visible = self.typewriter_text.length()
}

///|
pub fn UiDom::set_auto_mode(self : UiDom, enabled : Bool) -> Unit {
  self.auto_mode = enabled
  if enabled {
    self.auto_mode_last_advance_ms = 0
  }
}

///|
pub fn UiDom::toggle_auto_mode(self : UiDom) -> Unit {
  self.set_auto_mode(not(self.auto_mode))
}

///|
pub fn UiDom::should_auto_advance(self : UiDom) -> Bool {
  if not(self.auto_mode) {
    return false
  }
  if not(self.is_typewriter_done()) {
    return false
  }
  self.auto_mode_last_advance_ms >= self.auto_mode_delay_ms
}

///|
pub fn UiDom::mark_auto_advanced(self : UiDom) -> Unit {
  self.auto_mode_last_advance_ms = 0
}

///|
pub fn UiDom::advance_auto_mode_timer(self : UiDom, elapsed_ms~ : Int) -> Unit {
  if not(self.auto_mode) {
    return
  }
  if not(self.is_typewriter_done()) {
    return
  }
  self.auto_mode_last_advance_ms += elapsed_ms
}

///|
pub fn UiDom::set_skip_mode(self : UiDom, enabled : Bool) -> Unit {
  self.skip_mode = enabled
}

///|
pub fn UiDom::toggle_skip_mode(self : UiDom) -> Unit {
  if self.skip_mode {
    self.skip_mode = false
  } else {
    self.skip_mode = true
  }
}

///|
pub fn UiDom::should_skip_advance(self : UiDom) -> Bool {
  self.skip_mode
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
extern "js" fn dom_render_text_input(
  root_id : String,
  var_name : String,
  prompt : String,
) -> Unit =
  #| (root_id, var_name, prompt) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|
  #|   let inputContainer = root.querySelector('[data-reisen="text-input"]');
  #|   if (!inputContainer) {
  #|     inputContainer = doc.createElement('div');
  #|     inputContainer.setAttribute('data-reisen', 'text-input');
  #|     root.appendChild(inputContainer);
  #|   }
  #|   inputContainer.innerHTML = '';
  #|
  #|   const label = doc.createElement('label');
  #|   label.textContent = prompt;
  #|   inputContainer.appendChild(label);
  #|
  #|   const input = doc.createElement('input');
  #|   input.type = 'text';
  #|   input.setAttribute('data-reisen-input-var', var_name);
  #|   input.addEventListener('keydown', (e) => {
  #|     if (e.key === 'Enter') {
  #|       root.dataset.reisenSubmittedInput = input.value;
  #|     }
  #|   });
  #|   inputContainer.appendChild(input);
  #|
  #|   const submitBtn = doc.createElement('button');
  #|   submitBtn.type = 'button';
  #|   submitBtn.textContent = 'Submit';
  #|   submitBtn.addEventListener('click', () => {
  #|     root.dataset.reisenSubmittedInput = input.value;
  #|   });
  #|   inputContainer.appendChild(submitBtn);
  #| }

///|
extern "js" fn dom_take_submitted_text_input(
  root_id : String,
) -> @js.Nullable[String] =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return null;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return null;
  #|   const value = root.dataset.reisenSubmittedInput;
  #|   if (!value) return null;
  #|   delete root.dataset.reisenSubmittedInput;
  #|   return value;
  #| }

///|
extern "js" fn dom_setup_typewriter_click(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   let dialog = root.querySelector('[data-reisen="dialog"]');
  #|   if (!dialog) {
  #|     dialog = doc.createElement('div');
  #|     dialog.setAttribute('data-reisen', 'dialog');
  #|     root.appendChild(dialog);
  #|   }
  #|   const clickHandler = (e) => {
  #|     root.dataset.reisenTypewriterClick = '1';
  #|   };
  #|   dialog.removeEventListener('click', clickHandler);
  #|   dialog.addEventListener('click', clickHandler);
  #| }

///|
extern "js" fn dom_take_typewriter_click(root_id : String) -> Bool =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return false;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return false;
  #|   const clicked = root.dataset.reisenTypewriterClick === '1';
  #|   if (clicked) delete root.dataset.reisenTypewriterClick;
  #|   return clicked;
  #| }

///|
fn[T] ui_view_from_director(director : Director[T]) -> UiViewModel {
  let (speaker, text) = match director.dialog() {
    Some(line) => (line.speaker, line.text)
    None => ("", "")
  }
  let choices = director
    .choices()
    .map(opt => UiChoiceView::{ id: opt.id, text: opt.text })
  let text_input = match director.text_input() {
    Some((var_name, prompt)) => Some(UiTextInputView::{ var_name, prompt })
    None => None
  }
  { speaker, text, choices, text_input }
}

///|
fn UiDom::render(self : UiDom, view : UiViewModel) -> Unit {
  if view.text != self.typewriter_text && view.text != "" {
    self.start_typewriter(view.text)
  }
  dom_setup_typewriter_click(self.root_id)
  let display_text = if view.text == "" {
    ""
  } else if self.is_typewriter_done() {
    self.typewriter_text
  } else {
    self.typewriter_visible_text().to_string()
  }
  let ids = view.choices.map(c => c.id)
  let texts = view.choices.map(c => c.text)
  dom_render(self.root_id, view.speaker, display_text, ids, texts)
  match view.text_input {
    Some(input_view) =>
      dom_render_text_input(
        self.root_id,
        input_view.var_name,
        input_view.prompt,
      )
    None => ()
  }
}

///|
fn UiDom::take_selected_choice(self : UiDom) -> String? {
  dom_take_selected_choice(self.root_id).to_option()
}

///|
fn UiDom::take_submitted_text_input(self : UiDom) -> String? {
  dom_take_submitted_text_input(self.root_id).to_option()
}

///|
fn UiDom::check_typewriter_click(self : UiDom) -> Bool {
  dom_take_typewriter_click(self.root_id)
}
