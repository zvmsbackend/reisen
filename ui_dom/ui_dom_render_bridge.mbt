///|
extern "js" fn dom_render_speaker_text(
  root_id : String,
  speaker : String,
  html : String,
) -> Unit =
  #| (root_id, speaker, html) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|
  #|   let nameEl = root.querySelector('[data-reisen="speaker"]');
  #|   if (!nameEl) {
  #|     nameEl = doc.createElement('div');
  #|     nameEl.dataset.reisen = 'speaker';
  #|     root.appendChild(nameEl);
  #|   }
  #|   nameEl.style.zIndex = '220';
  #|   nameEl.innerHTML = speaker;
  #|   if (!speaker || speaker.trim() === '') nameEl.style.display = 'none';
  #|
  #|   let dialog = root.querySelector('[data-reisen="dialog"]');
  #|   if (!dialog) {
  #|     dialog = doc.createElement('div');
  #|     dialog.dataset.reisen = 'dialog';
  #|     root.appendChild(dialog);
  #|   }
  #|   dialog.style.zIndex = '210';
  #|   let dialogText = dialog.querySelector('[data-reisen="dialog-text"]');
  #|   if (!dialogText) {
  #|     dialogText = doc.createElement('div');
  #|     dialogText.dataset.reisen = 'dialog-text';
  #|     dialog.appendChild(dialogText);
  #|   }
  #|   dialogText.innerHTML = html;
  #| }

///|
extern "js" fn dom_set_text_box_visible(
  root_id : String,
  visible : Bool,
) -> Unit =
  #| (root_id, visible) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   const display = visible ? '' : 'none';
  #|   const speaker = root.querySelector('[data-reisen="speaker"]');
  #|   if (speaker) {
  #|     if (!visible) {
  #|       speaker.style.display = 'none';
  #|     } else {
  #|       const hasSpeaker = String(speaker.textContent || '').trim() !== '';
  #|       speaker.style.display = hasSpeaker ? '' : 'none';
  #|     }
  #|   }
  #|   const dialog = root.querySelector('[data-reisen="dialog"]');
  #|   if (dialog) dialog.style.display = display;
  #| }

///|
extern "js" fn dom_set_avatar(root_id : String, avatar_id : String?) -> Unit =
  #| (root_id, avatar_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   const dialog = root.querySelector('[data-reisen="dialog"]');
  #|   if (!dialog) return;
  #|   let avatar = dialog.querySelector('[data-reisen="avatar"]');
  #|   if (!avatar) {
  #|     avatar = doc.createElement('img');
  #|     avatar.dataset.reisen = 'avatar';
  #|     dialog.appendChild(avatar);
  #|   }
  #|   if (!avatar_id) {
  #|     avatar.style.display = 'none';
  #|     avatar.removeAttribute('src');
  #|     dialog.removeAttribute('data-reisen-avatar');
  #|     return;
  #|   }
  #|   const url = avatar_id;
  #|   if (!url) {
  #|     avatar.style.display = 'none';
  #|     avatar.removeAttribute('src');
  #|     dialog.removeAttribute('data-reisen-avatar');
  #|     return;
  #|   }
  #|   avatar.style.display = '';
  #|   avatar.src = url;
  #|   dialog.dataset.reisenAvatar = 'on';
  #| }

///|
extern "js" fn dom_render_intro(root_id : String, text : String) -> Unit =
  #| (root_id, text) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   root.dataset.reisenIntroDone = '';
  #|   root.dataset.reisenIntroLastPage = '1';
  #|   let intro = root.querySelector('[data-reisen="intro"]');
  #|   if (!intro) {
  #|     intro = doc.createElement('div');
  #|     intro.dataset.reisen = 'intro';
  #|     root.appendChild(intro);
  #|   }
  #|   intro.textContent = '';
  #|   const lines = text.split('\n');
  #|   const style = getComputedStyle(root);
  #|   const maxLinesRaw = parseInt(style.getPropertyValue('--reisen-intro-max-lines'), 10);
  #|   const intervalRaw = parseInt(style.getPropertyValue('--reisen-intro-line-interval-ms'), 10);
  #|   const maxLines = Number.isFinite(maxLinesRaw) && maxLinesRaw > 0 ? maxLinesRaw : 6;
  #|   const lineIntervalMs = Number.isFinite(intervalRaw) && intervalRaw > 0 ? intervalRaw : 2000;
  #|   if (lines.length === 0) {
  #|     root.dataset.reisenIntroDone = '1';
  #|   }
  #|   const totalPages = Math.ceil(lines.length / maxLines);
  #|   const renderPage = (page) => {
  #|     intro.innerHTML = '';
  #|     const start = page * maxLines;
  #|     const end = Math.min(lines.length, start + maxLines);
  #|     root.dataset.reisenIntroLastPage = page === totalPages - 1 ? '1' : '0';
  #|     for (let i = start; i < end; i++) {
  #|       const row = doc.createElement('div');
  #|       row.dataset.reisen = 'intro-line';
  #|       row.textContent = lines[i];
  #|       row.dataset.reisenIntroLine = String(i);
  #|       row.dataset.reisenIntroVisible = '0';
  #|       intro.appendChild(row);
  #|       const localIndex = i - start;
  #|       setTimeout(() => {
  #|         row.dataset.reisenIntroVisible = '1';
  #|       }, localIndex * lineIntervalMs);
  #|     }
  #|   };
  #|   for (let page = 0; page < totalPages; page++) {
  #|     setTimeout(() => renderPage(page), page * maxLines * lineIntervalMs);
  #|   }
  #|   setTimeout(() => root.dataset.reisenIntroDone = '1', lines.length * lineIntervalMs);
  #|   const hide = (sel) => {
  #|     const el = root.querySelector(sel);
  #|     if (el) el.style.display = 'none';
  #|   };
  #|   hide('[data-reisen="speaker"]');
  #|   hide('[data-reisen="dialog"]');
  #|   hide('[data-reisen="avatar"]');
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
  #|   const speaker = root.querySelector('[data-reisen="speaker"]');
  #|   if (speaker) {
  #|     const hasSpeaker = String(speaker.textContent || '').trim() !== '';
  #|     speaker.style.display = hasSpeaker ? '' : 'none';
  #|   }
  #|   show('[data-reisen="dialog"]');
  #|   show('[data-reisen="avatar"]');
  #|   show('[data-reisen="text-input"]');
  #|   const container = root.parentElement || doc;
  #|   const canvases = container.querySelectorAll('canvas');
  #|   canvases.forEach(c => { c.style.display = ''; });
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
  #|     choices.dataset.reisen = 'choices';
  #|     root.appendChild(choices);
  #|   }
  #|   choices.innerHTML = '';
  #|   if (choice_ids.length === 0) {
  #|     choices.style.display = 'none';
  #|   } else {
  #|     choices.style.display = '';
  #|     for (let i = 0; i < choice_ids.length; i++) {
  #|       const btn = doc.createElement('button');
  #|       const choice_id = choice_ids[i];
  #|       btn.type = 'button';
  #|       btn.textContent = choice_texts[i] ?? choice_id;
  #|       btn.dataset.choiceId = choice_id;
  #|       btn.addEventListener('click', () => {
  #|         root.dataset.reisenSelectedChoice = choice_id;
  #|       });
  #|       choices.appendChild(btn);
  #|     }
  #|   }
  #| }

///|
extern "js" fn dom_render_video(
  root_id : String,
  url : String,
  can_skip : Bool,
  volume : Double,
) -> Unit =
  #| (root_id, url, can_skip, volume) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   const speaker = root.querySelector('[data-reisen="speaker"]');
  #|   if (speaker) {
  #|     speaker.style.display = 'none';
  #|   }
  #|   const dialog = root.querySelector('[data-reisen="dialog"]');
  #|   if (dialog) {
  #|     dialog.style.display = 'none';
  #|   }
  #|   const actions = root.querySelector('[data-reisen="game-actions"]');
  #|   if (actions) {
  #|     actions.style.display = 'none';
  #|   }
  #|   let host = root.querySelector('[data-reisen="video"]');
  #|   if (!host) {
  #|     host = doc.createElement('div');
  #|     host.dataset.reisen = 'video';
  #|     host.style.position = 'absolute';
  #|     host.style.left = '0';
  #|     host.style.top = '0';
  #|     host.style.width = '100%';
  #|     host.style.height = '100%';
  #|     host.style.display = 'flex';
  #|     host.style.alignItems = 'center';
  #|     host.style.justifyContent = 'center';
  #|     host.style.background = 'black';
  #|     host.style.zIndex = '30';
  #|     root.appendChild(host);
  #|   }
  #|   let video = host.querySelector('video[data-reisen-video="1"]');
  #|   if (!video) {
  #|     video = doc.createElement('video');
  #|     video.dataset.reisenVideo = '1';
  #|     video.style.maxWidth = '100%';
  #|     video.style.maxHeight = '100%';
  #|     video.style.width = '100%';
  #|     video.style.height = '100%';
  #|     video.style.objectFit = 'contain';
  #|     video.autoplay = true;
  #|     video.loop = false;
  #|     video.playsInline = true;
  #|     video.controls = false;
  #|     video.onended = () => {
  #|       root.dataset.reisenVideoAction = 'ended';
  #|     };
  #|     host.appendChild(video);
  #|   }
  #|   host.dataset.canSkip = can_skip ? '1' : '0';
  #|   host.onclick = () => {
  #|     if (host.dataset.canSkip === '1') {
  #|       root.dataset.reisenVideoAction = 'skip';
  #|     }
  #|   };
  #|   if (video.src !== url) {
  #|     video.src = url;
  #|   }
  #|   video.volume = Math.max(0, Math.min(1, Number(volume) || 0));
  #|   const p = video.play();
  #|   if (p && typeof p.catch === 'function') p.catch(() => {});
  #| }

///|
extern "js" fn dom_clear_video(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   const host = root.querySelector('[data-reisen="video"]');
  #|   if (host) host.remove();
  #|   const speaker = root.querySelector('[data-reisen="speaker"]');
  #|   if (speaker) {
  #|     const hasSpeaker = String(speaker.textContent || '').trim() !== '';
  #|     speaker.style.display = hasSpeaker ? '' : 'none';
  #|   }
  #|   const dialog = root.querySelector('[data-reisen="dialog"]');
  #|   if (dialog) {
  #|     dialog.style.display = '';
  #|   }
  #|   const actions = root.querySelector('[data-reisen="game-actions"]');
  #|   if (actions) {
  #|     actions.style.display = '';
  #|   }
  #|   delete root.dataset.reisenVideoAction;
  #| }

///|
extern "js" fn dom_render_text_input(
  root_id : String,
  var_name : String,
  prompt : String,
  submit_label : String,
) -> Unit =
  #| (root_id, var_name, prompt, submit_label) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|
  #|   let inputContainer = root.querySelector('[data-reisen="text-input"]');
  #|   if (!inputContainer) {
  #|     inputContainer = doc.createElement('div');
  #|     inputContainer.dataset.reisen = 'text-input';
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
  #|   input.dataset.reisenInputVar = var_name;
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
  #|   submitBtn.textContent = submit_label;
  #|   submitBtn.addEventListener('click', () => {
  #|     root.dataset.reisenSubmittedInput = input.value;
  #|   });
  #|   inputContainer.appendChild(submitBtn);
  #| }

///|
extern "js" fn dom_render_dom_figures(
  root_id : String,
  figures_json : String,
) -> Unit =
  #| (root_id, figures_json) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   let host = root.querySelector('[data-reisen="dom-figures"]');
  #|   if (!host) {
  #|     host = doc.createElement('div');
  #|     host.dataset.reisen = 'dom-figures';
  #|     host.style.position = 'absolute';
  #|     host.style.left = '0';
  #|     host.style.top = '0';
  #|     host.style.width = '100%';
  #|     host.style.height = '100%';
  #|     host.style.pointerEvents = 'none';
  #|     root.appendChild(host);
  #|   }
  #|   const mounts = root.__reisenDomFigureMounts || (root.__reisenDomFigureMounts = new Map());
  #|   const restore = (entry) => {
  #|     if (!entry || !entry.el) return;
  #|     const el = entry.el;
  #|     if (entry.onClick) {
  #|       el.removeEventListener('click', entry.onClick);
  #|     }
  #|     delete el.dataset.reisenDomInteractive;
  #|     if (entry.tabindex === null || entry.tabindex === undefined || entry.tabindex === '') {
  #|       el.removeAttribute('tabindex');
  #|     } else {
  #|       el.setAttribute('tabindex', entry.tabindex);
  #|     }
  #|     const parent = entry.parent;
  #|     const next = entry.next;
  #|     if (parent && parent.nodeType === 1) {
  #|       if (next && next.parentNode === parent) {
  #|         parent.insertBefore(el, next);
  #|       } else {
  #|         parent.appendChild(el);
  #|       }
  #|     }
  #|     if (entry.style === null || entry.style === undefined || entry.style === '') {
  #|       el.removeAttribute('style');
  #|     } else {
  #|       el.setAttribute('style', entry.style);
  #|     }
  #|   };
  #|   let figures = [];
  #|   try {
  #|     const parsed = JSON.parse(figures_json);
  #|     if (Array.isArray(parsed)) figures = parsed;
  #|   } catch (_) {}
  #|   const wanted = new Set(figures.map(f => f.id));
  #|   for (const [id, entry] of mounts.entries()) {
  #|     if (!wanted.has(id)) {
  #|       restore(entry);
  #|       mounts.delete(id);
  #|     }
  #|   }
  #|   for (const view of figures) {
  #|     if (!view || !view.id || !view.dom_id) continue;
  #|     let entry = mounts.get(view.id);
  #|     if (!entry) {
  #|       const el = doc.getElementById(view.dom_id);
  #|       if (!el) continue;
  #|       let owned = false;
  #|       for (const existing of mounts.values()) {
  #|         if (existing && existing.el === el) {
  #|           owned = true;
  #|           break;
  #|         }
  #|       }
  #|       if (owned) continue;
  #|       entry = {
  #|         el,
  #|         parent: el.parentNode,
  #|         next: el.nextSibling,
  #|         style: el.getAttribute('style'),
  #|         tabindex: el.getAttribute('tabindex'),
  #|         onClick: null,
  #|       };
  #|       entry.onClick = () => {
  #|         if (el.dataset.reisenDomInteractive !== '1') return;
  #|         if (!el.hasAttribute('tabindex')) {
  #|           el.setAttribute('tabindex', '-1');
  #|         }
  #|       };
  #|       el.addEventListener('click', entry.onClick);
  #|       mounts.set(view.id, entry);
  #|       host.appendChild(el);
  #|     } else if (entry.el.parentNode !== host) {
  #|       host.appendChild(entry.el);
  #|     }
  #|     const el = entry.el;
  #|     const interactive = !!view.interactive;
  #|     if (interactive) {
  #|       el.dataset.reisenDomInteractive = '1';
  #|     } else {
  #|       delete el.dataset.reisenDomInteractive;
  #|       if (entry.tabindex === null || entry.tabindex === undefined || entry.tabindex === '') {
  #|         el.removeAttribute('tabindex');
  #|       } else {
  #|         el.setAttribute('tabindex', entry.tabindex);
  #|       }
  #|     }
  #|     el.style.position = 'absolute';
  #|     el.style.pointerEvents = interactive ? 'auto' : 'none';
  #|     el.style.left = `${view.left_pct}%`;
  #|     el.style.top = `${view.top_pct}%`;
  #|     el.style.zIndex = String(40 + (view.layer || 0));
  #|     el.style.opacity = String(view.opacity ?? 1);
  #|     el.style.transform = `translate(${-100 * (view.anchor_x ?? 0)}%, ${-100 * (view.anchor_y ?? 0)}%) scale(${view.scale ?? 1}) rotate(${view.rotation ?? 0}deg)`;
  #|     el.style.filter = `blur(${view.blur ?? 0}px) brightness(${view.brightness ?? 1}) contrast(${view.contrast ?? 1}) saturate(${view.saturation ?? 1})`;
  #|   }
  #| }

///|
extern "js" fn dom_render_action_buttons(
  root_id : String,
  auto_mode : Bool,
  skip_mode : Bool,
  dialog_visible : Bool,
  log_visible : Bool,
  settings_label : String,
  quicksave_label : String,
  save_label : String,
  log_label : String,
  dialog_label : String,
  auto_label : String,
  skip_label : String,
  toggle_on_prefix : String,
  toggle_off_prefix : String,
) -> Unit =
  #| (root_id, auto_mode, skip_mode, dialog_visible, log_visible, settings_label, quicksave_label, save_label, log_label, dialog_label, auto_label, skip_label, toggle_on_prefix, toggle_off_prefix) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|
  #|   let actions = root.querySelector('[data-reisen="game-actions"]');
  #|   if (!actions) {
  #|     actions = doc.createElement('div');
  #|     actions.dataset.reisen = 'game-actions';
  #|     root.appendChild(actions);
  #|   }
  #|   actions.style.zIndex = '230';
  #|   actions.innerHTML = '';
  #|
  #|   const on = toggle_on_prefix || '';
  #|   const off = toggle_off_prefix || '';
  #|   const buttons = [
  #|     { id: 'settings', label: settings_label },
  #|     { id: 'qsave', label: quicksave_label },
  #|     { id: 'save', label: save_label },
  #|     { id: 'log', label: (log_visible ? on : off) + log_label, data: 'log' },
  #|     { id: 'dialog', label: (dialog_visible ? on : off) + dialog_label, data: 'dialog' },
  #|     { id: 'auto', label: (auto_mode ? on : off) + auto_label, data: 'auto' },
  #|     { id: 'skip', label: (skip_mode ? on : off) + skip_label, data: 'skip' },
  #|   ];
  #|
  #|   for (const btnInfo of buttons) {
  #|     const btn = doc.createElement('button');
  #|     btn.type = 'button';
  #|     btn.textContent = btnInfo.label;
  #|     if (btnInfo.data === 'auto') {
  #|       btn.dataset.reisenAction = 'auto';
  #|       btn.classList.toggle('active', auto_mode);
  #|     } else if (btnInfo.data === 'log') {
  #|       btn.dataset.reisenAction = 'log';
  #|       btn.classList.toggle('active', log_visible);
  #|     } else if (btnInfo.data === 'dialog') {
  #|       btn.dataset.reisenAction = 'dialog';
  #|       btn.classList.toggle('active', dialog_visible);
  #|     } else if (btnInfo.data === 'skip') {
  #|       btn.dataset.reisenAction = 'skip';
  #|       btn.classList.toggle('active', skip_mode);
  #|     } else {
  #|       btn.dataset.reisenAction = btnInfo.id;
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
extern "js" fn dom_render_log(root_id : String, history_json : String) -> Unit =
  #| (root_id, history_json) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   let panel = root.querySelector('[data-reisen="log-panel"]');
  #|   if (!panel) {
  #|     panel = doc.createElement('div');
  #|     panel.dataset.reisen = 'log-panel';
  #|     panel.style.position = 'absolute';
  #|     panel.style.left = '5%';
  #|     panel.style.top = '8%';
  #|     panel.style.width = '90%';
  #|     panel.style.height = '72%';
  #|     panel.style.overflow = 'auto';
  #|     panel.style.background = 'rgba(12,12,16,0.86)';
  #|     panel.style.border = '1px solid rgba(255,255,255,0.2)';
  #|     panel.style.borderRadius = '8px';
  #|     panel.style.padding = '12px 14px';
  #|     panel.style.color = '#f2f2f2';
  #|     panel.style.zIndex = '235';
  #|     panel.style.pointerEvents = 'auto';
  #|     root.appendChild(panel);
  #|   }
  #|   panel.innerHTML = '';
  #|   let rows = [];
  #|   try {
  #|     const parsed = JSON.parse(history_json);
  #|     if (Array.isArray(parsed)) rows = parsed;
  #|   } catch (_) {}
  #|   for (const item of rows) {
  #|     const row = doc.createElement('div');
  #|     row.style.marginBottom = '10px';
  #|     const speaker = doc.createElement('div');
  #|     speaker.style.fontWeight = '700';
  #|     speaker.style.opacity = '0.95';
  #|     speaker.textContent = item?.speaker || '';
  #|     const text = doc.createElement('div');
  #|     text.style.opacity = '0.88';
  #|     text.textContent = item?.text || '';
  #|     row.appendChild(speaker);
  #|     row.appendChild(text);
  #|     panel.appendChild(row);
  #|   }
  #|   panel.scrollTop = panel.scrollHeight;
  #| }

///|
extern "js" fn dom_clear_log(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   const panel = root.querySelector('[data-reisen="log-panel"]');
  #|   if (panel) panel.remove();
  #| }

///|
extern "js" fn dom_clear_game_ui(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   const clearDomFigures = () => {
  #|     const mounts = root.__reisenDomFigureMounts;
  #|     if (mounts && mounts.forEach) {
  #|       mounts.forEach(entry => {
  #|         if (!entry || !entry.el) return;
  #|         const el = entry.el;
  #|         if (entry.onClick) {
  #|           el.removeEventListener('click', entry.onClick);
  #|         }
  #|         delete el.dataset.reisenDomInteractive;
  #|         if (entry.tabindex === null || entry.tabindex === undefined || entry.tabindex === '') {
  #|           el.removeAttribute('tabindex');
  #|         } else {
  #|           el.setAttribute('tabindex', entry.tabindex);
  #|         }
  #|         const parent = entry.parent;
  #|         const next = entry.next;
  #|         if (parent && parent.nodeType === 1) {
  #|           if (next && next.parentNode === parent) {
  #|             parent.insertBefore(el, next);
  #|           } else {
  #|             parent.appendChild(el);
  #|           }
  #|         }
  #|         if (entry.style === null || entry.style === undefined || entry.style === '') {
  #|           el.removeAttribute('style');
  #|         } else {
  #|           el.setAttribute('style', entry.style);
  #|         }
  #|       });
  #|       mounts.clear();
  #|     }
  #|     const host = root.querySelector('[data-reisen="dom-figures"]');
  #|     if (host) host.remove();
  #|   };
  #|   const remove = (selector) => {
  #|     const node = root.querySelector(selector);
  #|     if (node) node.remove();
  #|   };
  #|   clearDomFigures();
  #|   remove('[data-reisen="speaker"]');
  #|   remove('[data-reisen="dialog"]');
  #|   remove('[data-reisen="choices"]');
  #|   remove('[data-reisen="text-input"]');
  #|   remove('[data-reisen="game-actions"]');
  #|   remove('[data-reisen="intro"]');
  #|   remove('[data-reisen="video"]');
  #|   delete root.dataset.reisenAction;
  #|   delete root.dataset.reisenSelectedChoice;
  #|   delete root.dataset.reisenSubmittedInput;
  #|   delete root.dataset.reisenTypewriterClicked;
  #|   delete root.dataset.reisenIntroDone;
  #|   delete root.dataset.reisenIntroLastPage;
  #| }
