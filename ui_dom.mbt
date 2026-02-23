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
  typewriter : Bool
  intro_text : String?
  choices : Array[UiChoiceView]
  text_input : UiTextInputView?
  auto_mode : Bool
  skip_mode : Bool
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
  skip_mode_delay_ms : Int
  mut skip_mode_last_advance_ms : Int
  mut simulated_click : Bool
  mut simulated_intro_done : Bool
  mut dirty_speaker : Bool
  mut dirty_text : Bool
  mut dirty_choices : Bool
  mut dirty_text_input : Bool
  mut dirty_action_buttons : Bool
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
    skip_mode_delay_ms: 50,
    skip_mode_last_advance_ms: 0,
    simulated_click: false,
    simulated_intro_done: false,
    dirty_speaker: true,
    dirty_text: true,
    dirty_choices: true,
    dirty_text_input: true,
    dirty_action_buttons: true,
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
  if enabled {
    self.skip_mode_last_advance_ms = 0
  }
}

///|
pub fn UiDom::toggle_skip_mode(self : UiDom) -> Unit {
  self.set_skip_mode(not(self.skip_mode))
}

///|
pub fn UiDom::should_skip_advance(self : UiDom) -> Bool {
  if not(self.skip_mode) {
    return false
  }
  if not(self.is_typewriter_done()) {
    return false
  }
  self.skip_mode_last_advance_ms >= self.skip_mode_delay_ms
}

///|
pub fn UiDom::advance_skip_mode_timer(self : UiDom, elapsed_ms~ : Int) -> Unit {
  if not(self.skip_mode) {
    return
  }
  if not(self.is_typewriter_done()) {
    return
  }
  self.skip_mode_last_advance_ms += elapsed_ms
}

///|
pub fn UiDom::mark_skip_advanced(self : UiDom) -> Unit {
  self.skip_mode_last_advance_ms = 0
}

///|
pub fn UiDom::simulate_click(self : UiDom) -> Unit {
  self.simulated_click = true
}

///|
extern "js" fn dom_render_speaker_text(
  root_id : String,
  speaker : String,
  text : String,
) -> Unit =
  #| (root_id, speaker, text) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|
  #|   let nameEl = root.querySelector('[data-reisen="speaker"]');
  #|   if (!nameEl) {
  #|     nameEl = doc.createElement('div');
  #|     nameEl.setAttribute('data-reisen', 'speaker');
  #|     root.appendChild(nameEl);
  #|   }
  #|   nameEl.textContent = speaker;
  #|
  #|   let dialog = root.querySelector('[data-reisen="dialog"]');
  #|   if (!dialog) {
  #|     dialog = doc.createElement('div');
  #|     dialog.setAttribute('data-reisen', 'dialog');
  #|     root.appendChild(dialog);
  #|   }
  #|   dialog.style.whiteSpace = 'pre-wrap';
  #|   dialog.textContent = text;
  #| }

///|
extern "js" fn dom_render_intro(root_id : String, text : String) -> Unit =
  #| (root_id, text) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   root.dataset.reisenIntroDone = '';
  #|   let intro = root.querySelector('[data-reisen="intro"]');
  #|   if (!intro) {
  #|     intro = doc.createElement('div');
  #|     intro.setAttribute('data-reisen', 'intro');
  #|     root.appendChild(intro);
  #|   }
  #|   intro.style.position = 'absolute';
  #|   intro.style.inset = '0';
  #|   intro.style.alignItems = 'flex-start';
  #|   intro.style.justifyContent = 'flex-start';
  #|   intro.style.textAlign = 'left';
  #|   intro.style.padding = '24px';
  #|   intro.style.background = 'black';
  #|   intro.style.color = 'white';
  #|   intro.style.fontFamily = "'Cormorant Garamond', 'Times New Roman', serif";
  #|   intro.style.fontSize = '72px';
  #|   intro.style.lineHeight = '1.4';
  #|   intro.style.whiteSpace = 'pre-wrap';
  #|   intro.textContent = '';
  #|   const lines = text.split('\n');
  #|   if (lines.length === 0) {
  #|     root.dataset.reisenIntroDone = '1';
  #|   }
  #|   lines.forEach((line, idx) => {
  #|     const row = doc.createElement('div');
  #|     row.style.opacity = '0';
  #|     row.style.transition = 'opacity 400ms ease';
  #|     row.style.marginBottom = '12px';
  #|     row.textContent = line;
  #|     row.dataset.reisenIntroLine = String(idx);
  #|     row.dataset.reisenIntroVisible = '0';
  #|     intro.appendChild(row);
  #|     const br = doc.createElement('br');
  #|     br.style.opacity = '0';
  #|     intro.appendChild(br);
  #|     const delay = idx * 2000;
  #|     setTimeout(() => {
  #|       row.style.opacity = '1';
  #|       br.style.opacity = '1';
  #|       row.dataset.reisenIntroVisible = '1';
  #|     }, delay);
  #|   });
  #|   setTimeout(() => root.dataset.reisenIntroDone = '1', lines.length * 2000);
  #|   const hide = (sel) => {
  #|     const el = root.querySelector(sel);
  #|     if (el) el.style.display = 'none';
  #|   };
  #|   hide('[data-reisen="speaker"]');
  #|   hide('[data-reisen="dialog"]');
  #|   hide('[data-reisen="choices"]');
  #|   hide('[data-reisen="text-input"]');
  #|   const container = root.parentElement || doc;
  #|   const canvases = container.querySelectorAll('canvas');
  #|   canvases.forEach(c => { c.style.display = 'none'; });
  #| }

///|
extern "js" fn dom_clear_intro(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   root.dataset.reisenIntroDone = '';
  #|   const intro = root.querySelector('[data-reisen="intro"]');
  #|   if (intro) intro.remove();
  #|   const show = (sel) => {
  #|     const el = root.querySelector(sel);
  #|     if (el) el.style.display = '';
  #|   };
  #|   show('[data-reisen="speaker"]');
  #|   show('[data-reisen="dialog"]');
  #|   show('[data-reisen="text-input"]');
  #|   const container = root.parentElement || doc;
  #|   const canvases = container.querySelectorAll('canvas');
  #|   canvases.forEach(c => { c.style.display = ''; });
  #| }

///|
extern "js" fn dom_take_intro_done(root_id : String) -> Bool =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return false;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return false;
  #|   if (root.dataset.reisenIntroDone === '1') {
  #|     root.dataset.reisenIntroDone = '';
  #|     return true;
  #|   }
  #|   return false;
  #| }

///|
extern "js" fn dom_reveal_intro_line(root_id : String) -> Bool =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return false;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return false;
  #|   const intro = root.querySelector('[data-reisen="intro"]');
  #|   if (!intro) return false;
  #|   const next = intro.querySelector('[data-reisen-intro-line][data-reisen-intro-visible="0"]');
  #|   if (!next) {
  #|     root.dataset.reisenIntroDone = '1';
  #|     return true;
  #|   }
  #|   next.style.opacity = '1';
  #|   next.dataset.reisenIntroVisible = '1';
  #|   return false;
  #| }

///|
extern "js" fn dom_mark_intro_done(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   root.dataset.reisenIntroDone = '1';
  #| }

///|
extern "js" fn dom_render_choices(
  root_id : String,
  choice_ids : Array[String],
  choice_texts : Array[String],
) -> Unit =
  #| (root_id, choice_ids, choice_texts) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|
  #|   let choices = root.querySelector('[data-reisen="choices"]');
  #|   if (!choices) {
  #|     choices = doc.createElement('div');
  #|     choices.setAttribute('data-reisen', 'choices');
  #|     root.appendChild(choices);
  #|   }
  #|   choices.innerHTML = '';
  #|   if (choice_ids.length === 0) {
  #|     choices.style.display = 'none';
  #|   } else {
  #|     choices.style.display = 'flex';
  #|     for (let i = 0; i < choice_ids.length; i++) {
  #|       const btn = doc.createElement('button');
  #|       const choice_id = choice_ids[i];
  #|       btn.type = 'button';
  #|       btn.textContent = choice_texts[i] ?? choice_id;
  #|       btn.setAttribute('data-choice-id', choice_id);
  #|       btn.addEventListener('click', () => {
  #|         root.dataset.reisenSelectedChoice = choice_id;
  #|       });
  #|       choices.appendChild(btn);
  #|     }
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
  #|   input.focus();
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
extern "js" fn dom_render_action_buttons(
  root_id : String,
  auto_mode : Bool,
  skip_mode : Bool,
) -> Unit =
  #| (root_id, auto_mode, skip_mode) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|
  #|   let actions = root.querySelector('[data-reisen="game-actions"]');
  #|   if (!actions) {
  #|     actions = doc.createElement('div');
  #|     actions.setAttribute('data-reisen', 'game-actions');
  #|     root.appendChild(actions);
  #|   }
  #|   actions.innerHTML = '';
  #|
  #|   const buttons = [
  #|     { id: 'settings', label: '⚙' },
  #|     { id: 'qsave', label: 'Q.Save' },
  #|     { id: 'save', label: 'Save' },
  #|     { id: 'auto', label: auto_mode ? '☑ Auto' : '☐ Auto', data: 'auto' },
  #|     { id: 'skip', label: skip_mode ? '☑ Skip' : '☐ Skip', data: 'skip' },
  #|   ];
  #|
  #|   for (const btnInfo of buttons) {
  #|     const btn = doc.createElement('button');
  #|     btn.type = 'button';
  #|     btn.textContent = btnInfo.label;
  #|     if (btnInfo.data === 'auto') {
  #|       btn.setAttribute('data-reisen-action', 'auto');
  #|       btn.classList.toggle('active', auto_mode);
  #|     } else if (btnInfo.data === 'skip') {
  #|       btn.setAttribute('data-reisen-action', 'skip');
  #|       btn.classList.toggle('active', skip_mode);
  #|     } else {
  #|       btn.setAttribute('data-reisen-action', btnInfo.id);
  #|     }
  #|     btn.addEventListener('click', () => {
  #|       root.dataset.reisenAction = btnInfo.id;
  #|     });
  #|     actions.appendChild(btn);
  #|   }
  #| }

///|
extern "js" fn dom_clear_text_input(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   const inputContainer = root.querySelector('[data-reisen="text-input"]');
  #|   if (inputContainer) {
  #|     inputContainer.remove();
  #|   }
  #| }

///|
extern "js" fn dom_clear_game_ui(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   const dialog = root.querySelector('[data-reisen="dialog"]');
  #|   if (dialog) dialog.textContent = '';
  #|   const speaker = root.querySelector('[data-reisen="speaker"]');
  #|   if (speaker) speaker.textContent = '';
  #|   const choices = root.querySelector('[data-reisen="choices"]');
  #|   if (choices) choices.innerHTML = '';
  #|   const textInput = root.querySelector('[data-reisen="text-input"]');
  #|   if (textInput) textInput.remove();
  #| }

///|
extern "js" fn dom_setup_typewriter_click(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   if (root.__reisenTypewriterBound) return;
  #|   root.__reisenTypewriterBound = true;
  #|   const shouldIgnore = (target) => {
  #|     if (!target) return false;
  #|     const tag = target.tagName;
  #|     if (tag === 'INPUT' || tag === 'TEXTAREA') return true;
  #|     if (target.isContentEditable) return true;
  #|     if (tag === 'BUTTON') return true;
  #|     if (target.closest?.('[data-reisen="choices"]')) return true;
  #|     if (target.closest?.('[data-choice-id]')) return true;
  #|     return false;
  #|   };
  #|   document.addEventListener('click', (e) => {
  #|     if (shouldIgnore(e.target)) return;
  #|     root.dataset.reisenTypewriterClick = '1';
  #|   });
  #|   doc.addEventListener('keydown', (e) => {
  #|     if (shouldIgnore(e.target)) return;
  #|     if (e.key === ' ' || e.key === 'Spacebar' || e.key === 'Enter') {
  #|       root.dataset.reisenTypewriterClick = '1';
  #|     }
  #|   });
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
fn[T] ui_view_from_director(director : Director[T], ui : UiDom) -> UiViewModel {
  let (speaker, text) = match director.dialog() {
    Some(line) => (line.speaker, line.text)
    None => ("", "")
  }
  let typewriter = match director.dialog() {
    Some(line) => line.typewriter
    None => true
  }
  let intro_text = director.intro_text()
  let choices = director
    .choices()
    .map(opt => UiChoiceView::{ id: opt.id, text: opt.text })
  let text_input = match director.text_input() {
    Some((var_name, prompt)) => Some(UiTextInputView::{ var_name, prompt })
    None => None
  }
  {
    speaker,
    text,
    typewriter,
    intro_text,
    choices,
    text_input,
    auto_mode: ui.auto_mode,
    skip_mode: ui.skip_mode,
  }
}

///|
fn UiDom::render(self : UiDom, view : UiViewModel) -> Unit {
  if view.intro_text is Some(text) {
    dom_render_intro(self.root_id, text)
    dom_setup_typewriter_click(self.root_id)
    return
  } else {
    dom_clear_intro(self.root_id)
  }
  if view.text != self.typewriter_text && view.text != "" {
    if view.typewriter {
      self.start_typewriter(view.text)
    } else {
      self.typewriter_text = view.text
      self.typewriter_visible = self.typewriter_text.length()
      self.typewriter_last_update_ms = 0
    }
  }
  dom_setup_typewriter_click(self.root_id)
  let display_text = if view.text == "" {
    ""
  } else if self.is_typewriter_done() {
    self.typewriter_text
  } else {
    self.typewriter_visible_text().to_string()
  }
  if self.dirty_speaker || self.dirty_text {
    dom_render_speaker_text(self.root_id, view.speaker, display_text)
    self.dirty_speaker = false
    self.dirty_text = false
  }
  if self.dirty_choices {
    let ids = view.choices.map(c => c.id)
    let texts = view.choices.map(c => c.text)
    dom_render_choices(self.root_id, ids, texts)
    self.dirty_choices = false
  }
  if self.dirty_action_buttons {
    dom_render_action_buttons(self.root_id, view.auto_mode, view.skip_mode)
    self.dirty_action_buttons = false
  }
  if self.dirty_text_input {
    match view.text_input {
      Some(input_view) =>
        dom_render_text_input(
          self.root_id,
          input_view.var_name,
          input_view.prompt,
        )
      None => dom_clear_text_input(self.root_id)
    }
    self.dirty_text_input = false
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
extern "js" fn dom_take_action(root_id : String) -> @js.Nullable[String] =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return null;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return null;
  #|   const action = root.dataset.reisenAction;
  #|   if (!action) return null;
  #|   delete root.dataset.reisenAction;
  #|   return action;
  #| }

///|
fn UiDom::take_action(self : UiDom) -> String? {
  dom_take_action(self.root_id).to_option()
}

///|
fn UiDom::check_typewriter_click(self : UiDom) -> Bool {
  if self.simulated_click {
    self.simulated_click = false
    return true
  }
  dom_take_typewriter_click(self.root_id)
}

///|
fn UiDom::check_intro_done(self : UiDom) -> Bool {
  if self.simulated_intro_done {
    self.simulated_intro_done = false
    return true
  }
  dom_take_intro_done(self.root_id)
}

///|
fn UiDom::reveal_intro_line(self : UiDom) -> Bool {
  dom_reveal_intro_line(self.root_id)
}

///|
pub fn UiDom::simulate_intro_done(self : UiDom) -> Unit {
  self.simulated_intro_done = true
  dom_mark_intro_done(self.root_id)
}

///|
pub fn UiDom::mark_all_dirty(self : UiDom) -> Unit {
  self.dirty_speaker = true
  self.dirty_text = true
  self.dirty_choices = true
  self.dirty_text_input = true
  self.dirty_action_buttons = true
}

///|
pub fn UiDom::mark_dirty_text(self : UiDom) -> Unit {
  self.dirty_speaker = true
  self.dirty_text = true
}

///|
pub fn UiDom::mark_dirty_choices(self : UiDom) -> Unit {
  self.dirty_choices = true
}

///|
pub fn UiDom::mark_dirty_text_input(self : UiDom) -> Unit {
  self.dirty_text_input = true
}

///|
pub fn UiDom::mark_dirty_action_buttons(self : UiDom) -> Unit {
  self.dirty_action_buttons = true
}

///|
pub fn UiDom::clear_game_ui(self : UiDom) -> Unit {
  dom_clear_game_ui(self.root_id)
}
