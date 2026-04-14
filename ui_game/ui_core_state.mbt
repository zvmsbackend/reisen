///|
priv struct UiCoreState {
  mut text_speed : Int
  mut typewriter_text : DialogText
  mut last_dialog_seq : Int
  mut typewriter_visible : Int
  mut typewriter_last_update_ms : Int
  mut last_intro_seq : Int
  mut auto_mode : Bool
  auto_mode_delay_ms : Int
  wait_click_auto_skip_delay_ms : Int
  mut auto_mode_last_advance_ms : Int
  mut skip_mode : Bool
  mut skip_hold : Bool
  skip_mode_delay_ms : Int
  mut skip_mode_last_advance_ms : Int
  mut simulated_click : Bool
  mut log_visible : Bool
  mut dirty_speaker : Bool
  mut dirty_text : Bool
  mut dirty_choices : Bool
  mut dirty_text_input : Bool
  mut dirty_action_buttons : Bool
}

///|
fn UiCoreState::new() -> UiCoreState {
  {
    text_speed: 50,
    typewriter_text: DialogText::empty(),
    last_dialog_seq: -1,
    typewriter_visible: 0,
    typewriter_last_update_ms: 0,
    last_intro_seq: -1,
    auto_mode: false,
    auto_mode_delay_ms: 2000,
    wait_click_auto_skip_delay_ms: 160,
    auto_mode_last_advance_ms: 0,
    skip_mode: false,
    skip_hold: false,
    skip_mode_delay_ms: 50,
    skip_mode_last_advance_ms: 0,
    simulated_click: false,
    log_visible: false,
    dirty_speaker: true,
    dirty_text: true,
    dirty_choices: true,
    dirty_text_input: true,
    dirty_action_buttons: true,
  }
}

///|
fn UiCoreState::is_skip_active(self : UiCoreState) -> Bool {
  self.skip_mode || self.skip_hold
}

///|
fn UiCoreState::text_speed_ms_per_char(self : UiCoreState) -> Int {
  if self.text_speed <= 0 {
    100
  } else {
    2000 / self.text_speed
  }
}

///|
fn UiCoreState::is_typewriter_done(self : UiCoreState) -> Bool {
  self.typewriter_visible >= self.typewriter_text.length()
}

///|
fn UiCoreState::sync_from_snapshot(
  self : UiCoreState,
  snapshot : UiSnapshot,
) -> Unit {
  if snapshot.intro_text is Some(_) {
    if snapshot.dialog_seq != self.last_intro_seq {
      self.last_intro_seq = snapshot.dialog_seq
    }
  } else {
    self.last_intro_seq = -1
  }

  defer {
    self.last_dialog_seq = snapshot.dialog_seq
  }
  guard snapshot.dialog is Some((_, text, typewriter, append)) else {
    self.typewriter_text = DialogText::empty()
    self.typewriter_visible = 0
    self.typewriter_last_update_ms = 0
  }
  if snapshot.dialog_seq == self.last_dialog_seq {
    return
  }
  if append && typewriter && !self.is_skip_active() {
    let prev_len = self.typewriter_text.length()
    self.typewriter_text = text
    if self.typewriter_visible < prev_len {
      self.typewriter_visible = prev_len
    }
    if self.typewriter_visible > self.typewriter_text.length() {
      self.typewriter_visible = self.typewriter_text.length()
    }
    self.typewriter_last_update_ms = 0
  } else if typewriter && !self.is_skip_active() {
    self.typewriter_text = text
    self.typewriter_visible = 0
    self.typewriter_last_update_ms = 0
  } else {
    self.typewriter_text = text
    self.typewriter_visible = self.typewriter_text.length()
    self.typewriter_last_update_ms = 0
  }
}

///|
fn UiCoreState::mark_all_dirty(self : UiCoreState) -> Unit {
  self.dirty_speaker = true
  self.dirty_text = true
  self.dirty_choices = true
  self.dirty_text_input = true
  self.dirty_action_buttons = true
}

///|
fn UiCoreState::clear_render_dirty_after_frame(self : UiCoreState) -> Unit {
  self.dirty_speaker = false
  self.dirty_text = false
  self.dirty_choices = false
  self.dirty_text_input = false
  self.dirty_action_buttons = false
}

///|
fn UiCoreState::visible_text(self : UiCoreState) -> DialogText {
  self.typewriter_text.slice(self.typewriter_visible)
}
