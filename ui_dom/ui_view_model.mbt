///|
pub fn ui_view_model_from_snapshot(
  snapshot : UiSnapshot,
  ui : UiDom,
) -> UiViewModel {
  ui.pull_new_dom_animations(snapshot)
  let dom_figure_states = snapshot.dom_figures.copy()
  ui.apply_active_dom_animations(dom_figure_states)
  let dom_figures : Array[UiDomFigureView] = []
  for id, state in dom_figure_states {
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
  let (speaker, text) = match snapshot.dialog {
    Some((speaker, text, _, _)) => (speaker, text)
    None => (DialogText::empty(), DialogText::empty())
  }
  let typewriter = match snapshot.dialog {
    Some((_, _, typewriter, _)) => typewriter
    None => true
  }
  let append = match snapshot.dialog {
    Some((_, _, _, append)) => append
    None => false
  }
  let intro_text = snapshot.intro_text
  let video = match snapshot.video {
    Some((url, can_skip)) => Some(UiVideoView::{ url, can_skip })
    None => None
  }
  let text_box_visible = snapshot.text_box_visible
  let avatar_id = snapshot.avatar_id
  let choices = snapshot.choices.map(opt => UiChoiceView::{
    id: opt.id,
    text: opt.text,
  })
  let text_input = snapshot.text_input.map(entry => UiTextInputView::{
    var_name: entry.0,
    prompt: entry.1,
  })
  {
    speaker,
    text,
    dialog_seq: snapshot.dialog_seq,
    typewriter,
    intro_text,
    video,
    append,
    text_box_visible,
    avatar_id,
    choices,
    text_input,
    dialog_history: snapshot.dialog_history,
    dom_figures,
    auto_mode: ui.auto_mode,
    skip_mode: ui.is_skip_active(),
    log_visible: ui.log_visible,
    dirty_speaker: true,
    dirty_text: true,
    dirty_choices: true,
    dirty_text_input: true,
    dirty_action_buttons: true,
  }
}
