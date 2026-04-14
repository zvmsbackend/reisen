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
  #|     if (root.dataset.reisenIntroLastPage === '1') {
  #|       root.dataset.reisenIntroDone = '1';
  #|       return true;
  #|     }
  #|     return false;
  #|   }
  #|   next.dataset.reisenIntroVisible = '1';
  #|   const remaining = intro.querySelector('[data-reisen-intro-line][data-reisen-intro-visible="0"]');
  #|   if (!remaining && root.dataset.reisenIntroLastPage === '1') {
  #|     root.dataset.reisenIntroDone = '1';
  #|     return true;
  #|   }
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
extern "js" fn dom_take_video_action(root_id : String) -> @js.Nullable[String] =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return null;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return null;
  #|   const action = root.dataset.reisenVideoAction;
  #|   if (!action) return null;
  #|   delete root.dataset.reisenVideoAction;
  #|   return action;
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
  #|   if (root.__reisenTypewriterBound) return;
  #|   root.__reisenTypewriterBound = true;
  #|   const shouldIgnore = (target) => {
  #|     if (!target) return false;
  #|     const tag = target.tagName;
  #|     if (tag === 'INPUT' || tag === 'TEXTAREA') return true;
  #|     if (target.isContentEditable) return true;
  #|     if (tag === 'BUTTON') return true;
  #|     if (target.closest?.('[data-reisen="choices"]')) return true;
  #|     if (target.closest?.('[data-reisen="log-panel"]')) return true;
  #|     if (target.closest?.('[data-reisen-dom-interactive="1"]')) return true;
  #|     if (target.closest?.('[data-reisen="video"]')) return true;
  #|     if (target.closest?.('[data-choice-id]')) return true;
  #|     return false;
  #|   };
  #|   doc.addEventListener('click', (e) => {
  #|     if (shouldIgnore(e.target)) return;
  #|     root.dataset.reisenTypewriterClick = '1';
  #|   });
  #|   doc.addEventListener('keydown', (e) => {
  #|     if (shouldIgnore(e.target)) return;
  #|     if (e.key === 'Control') {
  #|       root.dataset.reisenAction = 'skip_hold_on';
  #|       return;
  #|     }
  #|     if (e.key === ' ' || e.key === 'Spacebar' || e.key === 'Enter') {
  #|       root.dataset.reisenTypewriterClick = '1';
  #|     }
  #|   });
  #|   doc.addEventListener('keyup', (e) => {
  #|     if (shouldIgnore(e.target)) return;
  #|     if (e.key === 'Control') {
  #|       root.dataset.reisenAction = 'skip_hold_off';
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
