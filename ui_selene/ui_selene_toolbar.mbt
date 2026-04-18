///|
priv struct UiToolbarButton {
  action : String
  label : String
  active : Bool
  rect : @selene_math.Rect
}

///|
fn point_in_rect(x : Double, y : Double, rect : @selene_math.Rect) -> Bool {
  let left = rect.position[X]
  let top = rect.position[Y]
  let right = left + rect.size[X]
  let bottom = top + rect.size[Y]
  x >= left && x <= right && y >= top && y <= bottom
}

///|
fn SeleneUiBackend::toolbar_buttons(
  self : SeleneUiBackend,
  view : UiViewModel,
  viewport_w : Double,
  viewport_h : Double,
) -> Array[UiToolbarButton] {
  let states : Array[(String, String, Bool)] = [
    ("settings", self.ui_strings.game_action_settings, false),
    ("qsave", self.ui_strings.game_action_quicksave, false),
    ("save", self.ui_strings.game_action_save, false),
    ("log", self.ui_strings.game_action_log, view.log_visible),
    ("dialog", self.ui_strings.game_action_dialog, view.text_box_visible),
    ("auto", self.ui_strings.game_action_auto, view.auto_mode),
    ("skip", self.ui_strings.game_action_skip, view.skip_mode),
  ]
  let count = states.length()
  if count == 0 {
    return []
  }

  let bar_left = 28.0
  let bar_right = viewport_w - 28.0
  let gap = 8.0
  let button_h = 30.0
  let bar_y = if view.text_box_visible {
    viewport_h - 66.0
  } else {
    viewport_h - 44.0
  }
  let bar_w = bar_right - bar_left
  let total_gap = gap * (count - 1).to_double()
  let button_w = (bar_w - total_gap) / count.to_double()

  let buttons : Array[UiToolbarButton] = []
  for i = 0; i < count; i = i + 1 {
    let (action, base_label, active) = states[i]
    let prefix = if active {
      self.ui_strings.game_toggle_on_prefix
    } else {
      self.ui_strings.game_toggle_off_prefix
    }
    let label = if action == "settings" || action == "qsave" || action == "save" {
      base_label
    } else {
      prefix + base_label
    }
    let x = bar_left + i.to_double() * (button_w + gap)
    buttons.push({
      action,
      label,
      active,
      rect: {
        position: @selene_math.Vec2(x, bar_y),
        size: @selene_math.Vec2(button_w, button_h),
      },
    })
  }
  buttons
}

///|
fn SeleneUiBackend::take_toolbar_action_on_click(
  self : SeleneUiBackend,
) -> Bool {
  if self.pending_action is Some(_) {
    return false
  }
  let view = match self.last_view {
    None => return false
    Some(view) => view
  }
  let mouse_pos = @selene_inputs.mouse.pos
  let mouse_x = mouse_pos.0
  let mouse_y = mouse_pos.1
  let buttons = self.toolbar_buttons(
    view,
    self.last_viewport_w,
    self.last_viewport_h,
  )
  for button in buttons {
    if point_in_rect(mouse_x, mouse_y, button.rect) {
      self.pending_action = Some(button.action)
      return true
    }
  }
  false
}
