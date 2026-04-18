///|
fn dialog_text_or_intro(view : UiViewModel) -> String {
  let dialog = view.text.raw_text()
  if dialog != "" {
    return dialog
  }
  match view.intro_text {
    Some(text) => text.raw_text()
    None => ""
  }
}

///|
priv struct OverlayBodyLine {
  text : String
  is_choice : Bool
}

///|
fn SeleneUiBackend::body_lines(view : UiViewModel) -> Array[OverlayBodyLine] {
  let lines : Array[OverlayBodyLine] = []
  let body = dialog_text_or_intro(view)
  if body != "" {
    lines.push({ text: body, is_choice: false })
  }
  if !view.choices.is_empty() {
    for i = 0; i < view.choices.length(); i = i + 1 {
      let choice = view.choices[i]
      lines.push({
        text: "\{i + 1}. \{choice.text.raw_text()}",
        is_choice: true,
      })
      if i >= 2 {
        break
      }
    }
  }
  if view.text_input is Some(input) {
    lines.push({ text: "Input: \{input.prompt.raw_text()}", is_choice: false })
  }
  if view.video is Some(video) {
    let skip_hint = if video.can_skip { " (skip available)" } else { "" }
    lines.push({ text: "Video: \{video.url}\{skip_hint}", is_choice: false })
  }
  lines
}

///|
fn measure_text_width(
  style : @selene_render2d_types.TextStyle2D,
  text : String,
) -> Double {
  @selene_platform_render.measure_text(style, text)[X]
}

///|
fn wrap_text_manual(
  raw : String,
  style : @selene_render2d_types.TextStyle2D,
  max_width : Double,
) -> Array[String] {
  if max_width <= 0.0 {
    return [""]
  }
  let wrapped : Array[String] = []
  let mut line_builder = StringBuilder::new()
  for c in raw {
    if c == '\n' {
      wrapped.push(line_builder.to_string())
      line_builder = StringBuilder::new()
    } else {
      let candidate_builder = StringBuilder::new()
      candidate_builder.write_string(line_builder.to_string())
      candidate_builder.write_char(c)
      let candidate = candidate_builder.to_string()
      if line_builder.to_string() != "" &&
        measure_text_width(style, candidate) > max_width {
        wrapped.push(line_builder.to_string())
        line_builder = StringBuilder::new()
        line_builder.write_char(c)
      } else {
        line_builder.write_char(c)
      }
    }
  }
  let tail = line_builder.to_string()
  if tail != "" || wrapped.is_empty() {
    wrapped.push(tail)
  }
  wrapped
}

///|
fn wrap_overlay_lines(
  lines : Array[OverlayBodyLine],
  style : @selene_render2d_types.TextStyle2D,
  max_width : Double,
) -> Array[OverlayBodyLine] {
  let wrapped : Array[OverlayBodyLine] = []
  for line in lines {
    for segment in wrap_text_manual(line.text, style, max_width) {
      wrapped.push({ text: segment, is_choice: line.is_choice })
    }
  }
  wrapped
}

///|
pub fn SeleneUiBackend::ui_overlay_commands(
  self : SeleneUiBackend,
  viewport_w? : Double = 1280.0,
  viewport_h? : Double = 720.0,
) -> Array[@selene_render2d_types.DrawCommand2D] {
  self.last_viewport_w = viewport_w
  self.last_viewport_h = viewport_h
  match self.last_view {
    None => []
    Some(view) => {
      let panel_alpha = self.panel_alpha.clamp(min=0.0, max=1.0)
      let choice_alpha = self.choices_alpha.clamp(min=0.0, max=1.0)
      let speaker_text_style = self.overlay_text_theme.speaker
      let body_text_style = self.overlay_text_theme.body
      let speaker = view.speaker.raw_text()
      let toolbar_buttons = self.toolbar_buttons(view, viewport_w, viewport_h)
      let panel_rect : @selene_math.Rect = {
        position: @selene_math.Vec2(28.0, viewport_h - 236.0),
        size: @selene_math.Vec2(viewport_w - 56.0, 208.0),
      }
      let text_width = viewport_w - 96.0
      let speaker_draw_style : @selene_render2d_types.TextStyle2D = {
        font: speaker_text_style.font,
        family: speaker_text_style.family,
        size: speaker_text_style.size,
        color: {
          r: speaker_text_style.color_r,
          g: speaker_text_style.color_g,
          b: speaker_text_style.color_b,
          a: speaker_text_style.color_a * panel_alpha,
        },
        align: Left,
        baseline: Top,
      }
      let body_draw_style : @selene_render2d_types.TextStyle2D = {
        font: body_text_style.font,
        family: body_text_style.family,
        size: body_text_style.size,
        color: {
          r: body_text_style.color_r,
          g: body_text_style.color_g,
          b: body_text_style.color_b,
          a: body_text_style.color_a,
        },
        align: Left,
        baseline: Top,
      }
      let speaker_lines = wrap_text_manual(
        speaker, speaker_draw_style, text_width,
      )
      let lines = wrap_overlay_lines(
        SeleneUiBackend::body_lines(view),
        body_draw_style,
        text_width,
      )
      let has_dialog_lines = !((speaker == "" || speaker_lines.is_empty()) &&
        lines.is_empty())
      let commands : Array[@selene_render2d_types.DrawCommand2D] = []
      if view.text_box_visible && has_dialog_lines {
        commands.push(
          Rect({
            alpha_mode: Blend,
            blend_mode: Alpha,
            rect: panel_rect,
            transform: @selene_math.Transform::identity(),
            fill_color: { r: 10, g: 14, b: 20, a: 0.82 * panel_alpha },
            stroke_color: Some({ r: 214, g: 224, b: 238, a: 0.92 * panel_alpha }),
          }),
        )
        let mut y = viewport_h - 214.0
        if speaker != "" {
          for line in speaker_lines {
            commands.push(
              Text({
                blend_mode: Alpha,
                text: line,
                position: @selene_math.Vec2(48.0, y),
                transform: @selene_math.Transform::identity(),
                style: speaker_draw_style,
              }),
            )
            y += 34.0
          }
          y += 4.0
        }
        for line in lines {
          let line_alpha = if line.is_choice {
            panel_alpha * choice_alpha
          } else {
            panel_alpha
          }
          commands.push(
            Text({
              blend_mode: Alpha,
              text: line.text,
              position: @selene_math.Vec2(48.0, y),
              transform: @selene_math.Transform::identity(),
              style: {
                ..body_draw_style,
                color: {
                  r: body_text_style.color_r,
                  g: body_text_style.color_g,
                  b: body_text_style.color_b,
                  a: body_text_style.color_a * line_alpha,
                },
              },
            }),
          )
          y += 30.0
        }
      }

      let toolbar_style : @selene_render2d_types.TextStyle2D = {
        font: body_text_style.font,
        family: body_text_style.family,
        size: 19.0,
        color: {
          r: body_text_style.color_r,
          g: body_text_style.color_g,
          b: body_text_style.color_b,
          a: body_text_style.color_a,
        },
        align: Center,
        baseline: Center,
      }
      for button in toolbar_buttons {
        commands.push(
          Rect({
            alpha_mode: Blend,
            blend_mode: Alpha,
            rect: button.rect,
            transform: @selene_math.Transform::identity(),
            fill_color: if button.active {
              { r: 88, g: 126, b: 176, a: 0.9 }
            } else {
              { r: 43, g: 56, b: 76, a: 0.8 }
            },
            stroke_color: Some({ r: 214, g: 224, b: 238, a: 0.88 }),
          }),
        )
        let center_x = button.rect.position[X] + button.rect.size[X] * 0.5
        let center_y = button.rect.position[Y] + button.rect.size[Y] * 0.5
        commands.push(
          Text({
            blend_mode: Alpha,
            text: button.label,
            position: @selene_math.Vec2(center_x, center_y),
            transform: @selene_math.Transform::identity(),
            style: toolbar_style,
          }),
        )
      }
      commands
    }
  }
}

///|
pub fn SeleneUiBackend::ui_overlay_provider(
  self : SeleneUiBackend,
  viewport_w? : Double = 1280.0,
  viewport_h? : Double = 720.0,
) -> () -> Array[@selene_render2d_types.DrawCommand2D] {
  () => self.ui_overlay_commands(viewport_w~, viewport_h~)
}
