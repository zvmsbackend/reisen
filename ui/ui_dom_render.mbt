///|
pub fn UiDom::render(self : UiDom, view : UiViewModel) -> Unit {
  let localized_speaker = self.localize_script_text(view.speaker)
  let localized_text = self.localize_script_text(view.text)
  let localized_intro_text = view.intro_text.map(text => {
    self.localize_script_text(text)
  })
  let localized_choices = view.choices.map(choice => {
    id: choice.id,
    text: self.localize_script_text(choice.text),
  })
  let localized_text_input = match view.text_input {
    Some(input_view) =>
      Some(UiTextInputView::{
        var_name: input_view.var_name,
        prompt: self.localize_script_text(input_view.prompt),
      })
    None => None
  }
  let localized_dialog_history : Array[DialogLogEntry] = view.dialog_history.map(entry => {
      speaker: self.localize_script_text_string(entry.speaker),
      text: self.localize_script_text_string(entry.text),
    },
  )
  let dom_figures_json = view.dom_figures.to_json().stringify()
  dom_render_dom_figures(self.root_id, dom_figures_json)
  match view.video {
    Some(video) => {
      dom_render_video(
        self.root_id,
        video.url,
        video.can_skip,
        self.media_volume,
      )
      dom_setup_typewriter_click(self.root_id)
      return
    }
    None => dom_clear_video(self.root_id)
  }
  if localized_intro_text is Some(text) {
    dom_render_intro(self.root_id, text.render())
    dom_setup_typewriter_click(self.root_id)
    return
  } else {
    dom_clear_intro(self.root_id)
  }
  if view.dialog_seq != self.last_dialog_seq && !localized_text.is_empty() {
    if view.append && view.typewriter && !self.is_skip_active() {
      let prev_len = self.typewriter_text.length()
      self.typewriter_text = localized_text
      if self.typewriter_visible < prev_len {
        self.typewriter_visible = prev_len
      }
      self.typewriter_last_update_ms = 0
    } else if view.typewriter && !self.is_skip_active() {
      self.start_typewriter(localized_text)
    } else {
      self.typewriter_text = localized_text
      self.typewriter_visible = self.typewriter_text.length()
      self.typewriter_last_update_ms = 0
    }
  }
  self.last_dialog_seq = view.dialog_seq
  dom_setup_typewriter_click(self.root_id)
  if self.dirty_speaker || self.dirty_text {
    let visible_html = if localized_text.is_empty() {
      ""
    } else if self.is_typewriter_done() {
      self.typewriter_text.render()
    } else {
      self.typewriter_text.slice(self.typewriter_visible).render()
    }
    dom_render_speaker_text(
      self.root_id,
      localized_speaker.render(),
      visible_html,
    )
    self.dirty_speaker = false
    self.dirty_text = false
  }
  dom_set_text_box_visible(self.root_id, view.text_box_visible)
  dom_set_avatar(self.root_id, view.avatar_id)
  if self.dirty_choices {
    let ids = localized_choices.map(c => c.id)
    let texts = localized_choices.map(c => c.text.render())
    dom_render_choices(self.root_id, ids, texts)
    self.dirty_choices = false
  }
  if self.dirty_action_buttons {
    dom_render_action_buttons(
      self.root_id,
      view.auto_mode,
      view.skip_mode,
      view.text_box_visible,
      view.log_visible,
      self.ui_strings.game_action_settings,
      self.ui_strings.game_action_quicksave,
      self.ui_strings.game_action_save,
      self.ui_strings.game_action_log,
      self.ui_strings.game_action_dialog,
      self.ui_strings.game_action_auto,
      self.ui_strings.game_action_skip,
      self.ui_strings.game_toggle_on_prefix,
      self.ui_strings.game_toggle_off_prefix,
    )
    self.dirty_action_buttons = false
  }
  if view.log_visible {
    dom_render_log(self.root_id, localized_dialog_history.to_json().stringify())
  } else {
    dom_clear_log(self.root_id)
  }
  if self.dirty_text_input {
    match localized_text_input {
      Some(input_view) =>
        dom_render_text_input(
          self.root_id,
          input_view.var_name,
          input_view.prompt.render(),
          self.ui_strings.game_text_input_submit,
        )
      None => dom_clear_text_input(self.root_id)
    }
    self.dirty_text_input = false
  }
}
