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
struct UiDomFigureView {
  id : String
  dom_id : String
  interactive : Bool
  left_pct : Double
  top_pct : Double
  anchor_x : Double
  anchor_y : Double
  layer : Int
  opacity : Double
  scale : Double
  rotation : Double
  blur : Double
  brightness : Double
  contrast : Double
  saturation : Double
  gamma : Double
  color_r : Double
  color_g : Double
  color_b : Double
} derive(Show, Eq, ToJson, FromJson)

///|
struct UiViewModel {
  speaker : String
  text : String
  typewriter : Bool
  intro_text : String?
  append : Bool
  text_box_visible : Bool
  avatar_id : String?
  choices : Array[UiChoiceView]
  text_input : UiTextInputView?
  dom_figures : Array[UiDomFigureView]
  auto_mode : Bool
  skip_mode : Bool
} derive(Show, Eq)

///|
struct UiDom {
  root_id : String
  mut dom_animation_cursor : Int
  mut dom_timeline_ms : Int
  dom_position_anims : Map[String, DomPositionAnim]
  dom_opacity_anims : Map[String, DomScalarAnim]
  dom_scale_anims : Map[String, DomScalarAnim]
  dom_rotation_anims : Map[String, DomScalarAnim]
  dom_blur_anims : Map[String, DomScalarAnim]
  dom_brightness_anims : Map[String, DomScalarAnim]
  dom_contrast_anims : Map[String, DomScalarAnim]
  dom_saturation_anims : Map[String, DomScalarAnim]
  dom_gamma_anims : Map[String, DomScalarAnim]
  dom_color_r_anims : Map[String, DomScalarAnim]
  dom_color_g_anims : Map[String, DomScalarAnim]
  dom_color_b_anims : Map[String, DomScalarAnim]
  mut text_speed : Int
  mut typewriter_raw_text : String
  mut typewriter_text : String
  mut typewriter_visible : Int
  mut typewriter_last_update_ms : Int
  mut auto_mode : Bool
  auto_mode_delay_ms : Int
  mut auto_mode_last_advance_ms : Int
  mut skip_mode : Bool
  mut skip_hold : Bool
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
    dom_animation_cursor: 0,
    dom_timeline_ms: 0,
    dom_position_anims: {},
    dom_opacity_anims: {},
    dom_scale_anims: {},
    dom_rotation_anims: {},
    dom_blur_anims: {},
    dom_brightness_anims: {},
    dom_contrast_anims: {},
    dom_saturation_anims: {},
    dom_gamma_anims: {},
    dom_color_r_anims: {},
    dom_color_g_anims: {},
    dom_color_b_anims: {},
    text_speed: 50,
    typewriter_raw_text: "",
    typewriter_text: "",
    typewriter_visible: 0,
    typewriter_last_update_ms: 0,
    auto_mode: false,
    auto_mode_delay_ms: 2000,
    auto_mode_last_advance_ms: 0,
    skip_mode: false,
    skip_hold: false,
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
priv struct DomScalarAnim {
  start_ms : Int
  duration_ms : Int
  easing : Easing
  from : Double
  to : Double
}

///|
priv struct DomPositionAnim {
  start_ms : Int
  duration_ms : Int
  easing : Easing
  from_x : Double
  from_y : Double
  to_x : Double
  to_y : Double
}

///|
fn dom_ease(p : Double, easing : Easing) -> Double {
  let t = if p < 0.0 { 0.0 } else if p > 1.0 { 1.0 } else { p }
  match easing {
    Linear => t
    EaseIn => t * t
    EaseOut => 1.0 - (1.0 - t) * (1.0 - t)
    EaseInOut =>
      if t < 0.5 {
        2.0 * t * t
      } else {
        1.0 - (-2.0 * t + 2.0) * (-2.0 * t + 2.0) / 2.0
      }
  }
}

///|
fn dom_anim_progress(
  now_ms : Int,
  start_ms : Int,
  duration_ms : Int,
  easing : Easing,
) -> (Double, Bool) {
  let duration = if duration_ms <= 0 { 0 } else { duration_ms }
  if duration == 0 {
    return (1.0, true)
  }
  let elapsed = now_ms - start_ms
  if elapsed <= 0 {
    return (0.0, false)
  }
  if elapsed >= duration {
    return (1.0, true)
  }
  let raw = elapsed.to_double() / duration.to_double()
  (dom_ease(raw, easing), false)
}

///|
fn scalar_at(now_ms : Int, anim : DomScalarAnim) -> (Double, Bool) {
  let (p, done) = dom_anim_progress(
    now_ms,
    anim.start_ms,
    anim.duration_ms,
    anim.easing,
  )
  (anim.from + (anim.to - anim.from) * p, done)
}

///|
fn pos_at(now_ms : Int, anim : DomPositionAnim) -> (Double, Double, Bool) {
  let (p, done) = dom_anim_progress(
    now_ms,
    anim.start_ms,
    anim.duration_ms,
    anim.easing,
  )
  (
    anim.from_x + (anim.to_x - anim.from_x) * p,
    anim.from_y + (anim.to_y - anim.from_y) * p,
    done,
  )
}

///|
fn dom_pos_tuple(pos : Position) -> (Double, Double) {
  match pos {
    Left => (0.18, 0.5)
    Center => (0.5, 0.5)
    Right => (0.82, 0.5)
    Custom(x, y) => (x, y)
  }
}

///|
fn[T] UiDom::pull_new_dom_animations(
  self : UiDom,
  director : Director[T],
) -> Unit {
  let all = director.dom_animations()
  if self.dom_animation_cursor > all.length() {
    self.dom_animation_cursor = 0
  }
  for i, entry in all {
    if i < self.dom_animation_cursor {
      continue
    }
    let (target, spec) = entry
    let dom_figures = director.dom_figures()
    match spec.prop {
      Position => {
        let (cur_x, cur_y) = match dom_figures.get(target) {
          Some(state) => dom_pos_tuple(state.placement.pos)
          None => (0.5, 0.5)
        }
        let from_x = anim_value(spec.from, 0).unwrap_or(cur_x)
        let from_y = anim_value(spec.from, 1).unwrap_or(cur_y)
        let to_x = anim_value(spec.to, 0).unwrap_or(from_x)
        let to_y = anim_value(spec.to, 1).unwrap_or(from_y)
        self.dom_position_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from_x,
          from_y,
          to_x,
          to_y,
        })
      }
      Opacity => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(state.placement.scalars.opacity)
          None => anim_value(spec.from, 0).unwrap_or(1.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_opacity_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from,
          to,
        })
      }
      Scale => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(state.placement.scalars.scale)
          None => anim_value(spec.from, 0).unwrap_or(1.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_scale_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from,
          to,
        })
      }
      Rotation => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(state.placement.scalars.rotation)
          None => anim_value(spec.from, 0).unwrap_or(0.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_rotation_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from,
          to,
        })
      }
      Blur => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(state.placement.scalars.blur)
          None => anim_value(spec.from, 0).unwrap_or(0.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_blur_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from,
          to,
        })
      }
      Brightness => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(
              state.placement.scalars.brightness,
            )
          None => anim_value(spec.from, 0).unwrap_or(1.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_brightness_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from,
          to,
        })
      }
      Contrast => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(state.placement.scalars.contrast)
          None => anim_value(spec.from, 0).unwrap_or(1.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_contrast_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from,
          to,
        })
      }
      Saturation => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(
              state.placement.scalars.saturation,
            )
          None => anim_value(spec.from, 0).unwrap_or(1.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_saturation_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from,
          to,
        })
      }
      Gamma => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(state.placement.scalars.gamma)
          None => anim_value(spec.from, 0).unwrap_or(1.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_gamma_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from,
          to,
        })
      }
      ColorRed => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(state.placement.scalars.color_r)
          None => anim_value(spec.from, 0).unwrap_or(1.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_color_r_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from,
          to,
        })
      }
      ColorGreen => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(state.placement.scalars.color_g)
          None => anim_value(spec.from, 0).unwrap_or(1.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_color_g_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from,
          to,
        })
      }
      ColorBlue => {
        let from = match dom_figures.get(target) {
          Some(state) =>
            anim_value(spec.from, 0).unwrap_or(state.placement.scalars.color_b)
          None => anim_value(spec.from, 0).unwrap_or(1.0)
        }
        let to = anim_value(spec.to, 0).unwrap_or(from)
        self.dom_color_b_anims.set(target, {
          start_ms: self.dom_timeline_ms,
          duration_ms: spec.duration_ms,
          easing: spec.easing,
          from,
          to,
        })
      }
    }
  }
  self.dom_animation_cursor = all.length()
}

///|
pub fn UiDom::advance_dom_animation_timer(
  self : UiDom,
  elapsed_ms : Int,
) -> Unit {
  if elapsed_ms > 0 {
    self.dom_timeline_ms += elapsed_ms
  }
}

///|
pub fn UiDom::has_active_dom_animations(self : UiDom) -> Bool {
  self.dom_position_anims.length() > 0 ||
  self.dom_opacity_anims.length() > 0 ||
  self.dom_scale_anims.length() > 0 ||
  self.dom_rotation_anims.length() > 0 ||
  self.dom_blur_anims.length() > 0 ||
  self.dom_brightness_anims.length() > 0 ||
  self.dom_contrast_anims.length() > 0 ||
  self.dom_saturation_anims.length() > 0 ||
  self.dom_gamma_anims.length() > 0 ||
  self.dom_color_r_anims.length() > 0 ||
  self.dom_color_g_anims.length() > 0 ||
  self.dom_color_b_anims.length() > 0
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
  self.typewriter_raw_text = text
  self.typewriter_text = dom_strip_text_markup(text)
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
pub fn UiDom::set_skip_hold(self : UiDom, enabled : Bool) -> Unit {
  self.skip_hold = enabled
  if enabled {
    self.skip_mode_last_advance_ms = 0
  }
}

///|
pub fn UiDom::is_skip_active(self : UiDom) -> Bool {
  self.skip_mode || self.skip_hold
}

///|
pub fn UiDom::toggle_skip_mode(self : UiDom) -> Unit {
  self.set_skip_mode(not(self.skip_mode))
}

///|
pub fn UiDom::should_skip_advance(self : UiDom) -> Bool {
  if not(self.is_skip_active()) {
    return false
  }
  if not(self.is_typewriter_done()) {
    return false
  }
  self.skip_mode_last_advance_ms >= self.skip_mode_delay_ms
}

///|
pub fn UiDom::advance_skip_mode_timer(self : UiDom, elapsed_ms~ : Int) -> Unit {
  if not(self.is_skip_active()) {
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
  visible_count : Int,
) -> Unit =
  #| (root_id, speaker, text, visible_count) => {
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
  #|   nameEl.textContent = speaker;
  #|
  #|   let dialog = root.querySelector('[data-reisen="dialog"]');
  #|   if (!dialog) {
  #|     dialog = doc.createElement('div');
  #|     dialog.dataset.reisen = 'dialog';
  #|     root.appendChild(dialog);
  #|   }
  #|   let dialogText = dialog.querySelector('[data-reisen="dialog-text"]');
  #|   if (!dialogText) {
  #|     dialogText = doc.createElement('div');
  #|     dialogText.dataset.reisen = 'dialog-text';
  #|     dialog.appendChild(dialogText);
  #|   }
  #|   dialogText.innerHTML = '';
  #|   if (visible_count <= 0) return;
  #|   const rubyPattern = /\[([^\]]+)\]\(([^)]+)\)/g;
  #|   const stylePattern = /\[([^\]]+)\]\{([^}]+)\}/g;
  #|   let lastIndex = 0;
  #|   let remaining = visible_count;
  #|   let match;
  #|   const nextMatch = (pattern) => {
  #|     const m = pattern.exec(text);
  #|     return m ? { match: m, index: m.index } : null;
  #|   };
  #|   const appendPlain = (chunk) => {
  #|     if (!chunk) return;
  #|     const visible = chunk.slice(0, remaining);
  #|     if (visible) {
  #|       dialogText.appendChild(doc.createTextNode(visible));
  #|       remaining -= visible.length;
  #|     }
  #|   };
  #|   while (remaining > 0) {
  #|     const rubyNext = nextMatch(rubyPattern);
  #|     const styleNext = nextMatch(stylePattern);
  #|     let next = rubyNext;
  #|     let kind = 'ruby';
  #|     if (!next || (styleNext && styleNext.index < next.index)) {
  #|       next = styleNext;
  #|       kind = 'style';
  #|     }
  #|     if (!next) break;
  #|     match = next.match;
  #|     if (match.index > lastIndex) {
  #|       appendPlain(text.slice(lastIndex, match.index));
  #|     }
  #|     if (remaining <= 0) break;
  #|     const base = kind === 'ruby' ? match[1] : match[1];
  #|     if (remaining >= base.length) {
  #|       if (kind === 'ruby') {
  #|         const ruby = doc.createElement('ruby');
  #|         ruby.appendChild(doc.createTextNode(base));
  #|         const rt = doc.createElement('rt');
  #|         rt.textContent = match[2];
  #|         ruby.appendChild(rt);
  #|         dialogText.appendChild(ruby);
  #|       } else {
  #|         const span = doc.createElement('span');
  #|         span.textContent = base;
  #|         span.setAttribute('style', match[2]);
  #|         dialogText.appendChild(span);
  #|       }
  #|       remaining -= base.length;
  #|     } else {
  #|       appendPlain(base);
  #|       break;
  #|     }
  #|     lastIndex = match.index + match[0].length;
  #|   }
  #|   if (remaining > 0 && lastIndex < text.length) {
  #|     appendPlain(text.slice(lastIndex));
  #|   }
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
  #|   if (speaker) speaker.style.display = display;
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
extern "js" fn dom_strip_text_markup(text : String) -> String =
  #| (text) => text
  #|   .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '$1')
  #|   .replace(/\[([^\]]+)\]\{([^}]+)\}/g, '$1')

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
  #|   show('[data-reisen="speaker"]');
  #|   show('[data-reisen="dialog"]');
  #|   show('[data-reisen="avatar"]');
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
  #|         if (typeof el.focus === 'function') {
  #|           el.focus();
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
  #|     el.style.zIndex = String(100 + (view.layer || 0));
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
  #|     actions.dataset.reisen = 'game-actions';
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
  #|       btn.dataset.reisenAction = 'auto';
  #|       btn.classList.toggle('active', auto_mode);
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
  #|   delete root.dataset.reisenAction;
  #|   delete root.dataset.reisenSelectedChoice;
  #|   delete root.dataset.reisenSubmittedInput;
  #|   delete root.dataset.reisenTypewriterClicked;
  #|   delete root.dataset.reisenIntroDone;
  #|   delete root.dataset.reisenIntroLastPage;
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
  #|     if (target.closest?.('[data-reisen-dom-interactive="1"]')) return true;
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
fn[T] UiDom::apply_active_dom_animations(
  self : UiDom,
  director : Director[T],
) -> Unit {
  let dom_figures = director.dom_figures()
  let finished_position : Array[String] = []
  let finished_opacity : Array[String] = []
  let finished_scale : Array[String] = []
  let finished_rotation : Array[String] = []
  let finished_blur : Array[String] = []
  let finished_brightness : Array[String] = []
  let finished_contrast : Array[String] = []
  let finished_saturation : Array[String] = []
  let finished_gamma : Array[String] = []
  let finished_color_r : Array[String] = []
  let finished_color_g : Array[String] = []
  let finished_color_b : Array[String] = []

  for id, state in dom_figures {
    let mut next = state.placement
    match self.dom_position_anims.get(id) {
      Some(anim) => {
        let (x, y, done) = pos_at(self.dom_timeline_ms, anim)
        next = { ..next, pos: Custom(x, y) }
        if done {
          finished_position.push(id)
        }
      }
      None => ()
    }

    match self.dom_opacity_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, opacity: value } }
        if done {
          finished_opacity.push(id)
        }
      }
      None => ()
    }
    match self.dom_scale_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, scale: value } }
        if done {
          finished_scale.push(id)
        }
      }
      None => ()
    }
    match self.dom_rotation_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, rotation: value } }
        if done {
          finished_rotation.push(id)
        }
      }
      None => ()
    }
    match self.dom_blur_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, blur: value } }
        if done {
          finished_blur.push(id)
        }
      }
      None => ()
    }
    match self.dom_brightness_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, brightness: value } }
        if done {
          finished_brightness.push(id)
        }
      }
      None => ()
    }
    match self.dom_contrast_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, contrast: value } }
        if done {
          finished_contrast.push(id)
        }
      }
      None => ()
    }
    match self.dom_saturation_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, saturation: value } }
        if done {
          finished_saturation.push(id)
        }
      }
      None => ()
    }
    match self.dom_gamma_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, gamma: value } }
        if done {
          finished_gamma.push(id)
        }
      }
      None => ()
    }
    match self.dom_color_r_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, color_r: value } }
        if done {
          finished_color_r.push(id)
        }
      }
      None => ()
    }
    match self.dom_color_g_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, color_g: value } }
        if done {
          finished_color_g.push(id)
        }
      }
      None => ()
    }
    match self.dom_color_b_anims.get(id) {
      Some(anim) => {
        let (value, done) = scalar_at(self.dom_timeline_ms, anim)
        next = { ..next, scalars: { ..next.scalars, color_b: value } }
        if done {
          finished_color_b.push(id)
        }
      }
      None => ()
    }
    dom_figures.set(id, { placement: next, interactive: state.interactive })
  }

  for id in finished_position {
    self.dom_position_anims.remove(id)
  }
  for id in finished_opacity {
    self.dom_opacity_anims.remove(id)
  }
  for id in finished_scale {
    self.dom_scale_anims.remove(id)
  }
  for id in finished_rotation {
    self.dom_rotation_anims.remove(id)
  }
  for id in finished_blur {
    self.dom_blur_anims.remove(id)
  }
  for id in finished_brightness {
    self.dom_brightness_anims.remove(id)
  }
  for id in finished_contrast {
    self.dom_contrast_anims.remove(id)
  }
  for id in finished_saturation {
    self.dom_saturation_anims.remove(id)
  }
  for id in finished_gamma {
    self.dom_gamma_anims.remove(id)
  }
  for id in finished_color_r {
    self.dom_color_r_anims.remove(id)
  }
  for id in finished_color_g {
    self.dom_color_g_anims.remove(id)
  }
  for id in finished_color_b {
    self.dom_color_b_anims.remove(id)
  }
}

///|
fn[T] ui_view_from_director(director : Director[T], ui : UiDom) -> UiViewModel {
  ui.pull_new_dom_animations(director)
  ui.apply_active_dom_animations(director)
  let dom_figures : Array[UiDomFigureView] = []
  for id, state in director.dom_figures() {
    let placement = state.placement
    let (left_pct, top_pct, anchor_x, anchor_y) = match placement.pos {
      Left => (18.0, 50.0, 0.5, 0.5)
      Center => (50.0, 50.0, 0.5, 0.5)
      Right => (82.0, 50.0, 0.5, 0.5)
      Custom(x, y) => (x * 100.0, y * 100.0, 0.5, 0.5)
    }
    dom_figures.push({
      id,
      dom_id: id,
      interactive: state.interactive,
      left_pct,
      top_pct,
      anchor_x,
      anchor_y,
      layer: placement.layer,
      opacity: placement.scalars.opacity,
      scale: placement.scalars.scale,
      rotation: placement.scalars.rotation,
      blur: placement.scalars.blur,
      brightness: placement.scalars.brightness,
      contrast: placement.scalars.contrast,
      saturation: placement.scalars.saturation,
      gamma: placement.scalars.gamma,
      color_r: placement.scalars.color_r,
      color_g: placement.scalars.color_g,
      color_b: placement.scalars.color_b,
    })
  }
  let (speaker, text) = match director.dialog() {
    Some(line) => (line.speaker, line.text)
    None => ("", "")
  }
  let typewriter = match director.dialog() {
    Some(line) => line.typewriter
    None => true
  }
  let append = match director.dialog() {
    Some(line) => line.append
    None => false
  }
  let intro_text = director.intro_text()
  let text_box_visible = director.text_box_visible()
  let avatar_id = director.avatar_id()
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
    append,
    text_box_visible,
    avatar_id,
    choices,
    text_input,
    dom_figures,
    auto_mode: ui.auto_mode,
    skip_mode: ui.skip_mode,
  }
}

///|
fn UiDom::render(self : UiDom, view : UiViewModel) -> Unit {
  let dom_figures_json = view.dom_figures.to_json().stringify()
  dom_render_dom_figures(self.root_id, dom_figures_json)
  if view.intro_text is Some(text) {
    dom_render_intro(self.root_id, text)
    dom_setup_typewriter_click(self.root_id)
    return
  } else {
    dom_clear_intro(self.root_id)
  }
  if view.text != self.typewriter_raw_text && view.text != "" {
    if view.append &&
      view.typewriter &&
      view.text.has_prefix(self.typewriter_raw_text) {
      let prev_len = self.typewriter_text.length()
      self.typewriter_raw_text = view.text
      self.typewriter_text = dom_strip_text_markup(view.text)
      if self.typewriter_visible < prev_len {
        self.typewriter_visible = prev_len
      }
      self.typewriter_last_update_ms = 0
    } else if view.typewriter {
      self.start_typewriter(view.text)
    } else {
      self.typewriter_raw_text = view.text
      self.typewriter_text = dom_strip_text_markup(view.text)
      self.typewriter_visible = self.typewriter_text.length()
      self.typewriter_last_update_ms = 0
    }
  }
  dom_setup_typewriter_click(self.root_id)
  let visible_count = if view.text == "" {
    0
  } else if self.is_typewriter_done() {
    self.typewriter_text.length()
  } else {
    self.typewriter_visible
  }
  if self.dirty_speaker || self.dirty_text {
    dom_render_speaker_text(
      self.root_id,
      view.speaker,
      self.typewriter_raw_text,
      visible_count,
    )
    self.dirty_speaker = false
    self.dirty_text = false
  }
  dom_set_text_box_visible(self.root_id, view.text_box_visible)
  dom_set_avatar(self.root_id, view.avatar_id)
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
  self.dom_animation_cursor = 0
  self.dom_timeline_ms = 0
  self.dom_position_anims.clear()
  self.dom_opacity_anims.clear()
  self.dom_scale_anims.clear()
  self.dom_rotation_anims.clear()
  self.dom_blur_anims.clear()
  self.dom_brightness_anims.clear()
  self.dom_contrast_anims.clear()
  self.dom_saturation_anims.clear()
  self.dom_gamma_anims.clear()
  self.dom_color_r_anims.clear()
  self.dom_color_g_anims.clear()
  self.dom_color_b_anims.clear()
  dom_clear_game_ui(self.root_id)
}
