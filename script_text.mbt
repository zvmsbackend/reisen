///|
/// Textual script format parser for Reisen visual novel engine.
/// Line-based format: `command: arg1, arg2, ...`
/// Supports: label, jump, wait, wait_click, unlock_cg, narrate, say, scene, show, hide, music, sfx, animate, choice

///|
pub suberror ReisenTextError {} derive(Show, Eq)

///|
fn get_first_part(s : String, sep : String) -> (String, String) {
  let parts : Array[String] = []
  for p in s.split(sep) {
    parts.push(p.to_string())
  }
  if parts.length() >= 2 {
    let first = parts[0].trim().to_string()
    let rest = join_parts(parts, 1, parts.length())
    (first, rest.trim().to_string())
  } else if parts.length() == 1 {
    (parts[0].trim().to_string(), "")
  } else {
    ("", "")
  }
}

///|
fn join_parts(
  parts : Array[String],
  start : Int,
  end_exclusive : Int,
) -> String {
  parts[start:end_exclusive].join(", ")
}

///|
fn parse_typewriter_flag(raw : String) -> Bool? {
  let v = raw.trim().to_lower()
  match v {
    "true" | "1" | "yes" | "on" | "typewriter" => Some(true)
    "false" | "0" | "no" | "off" | "instant" | "instantaneous" => Some(false)
    _ => None
  }
}

///|
fn parse_can_skip_flag(raw : String) -> Bool? {
  let v = raw.trim().to_lower()
  match v {
    "true" | "1" | "yes" | "on" | "skip" | "can_skip" => Some(true)
    "false" | "0" | "no" | "off" | "noskip" | "no_skip" => Some(false)
    _ =>
      if v.has_prefix("can_skip=") {
        parse_can_skip_flag((try! raw[9:]).to_string())
      } else if v.has_prefix("skip=") {
        parse_can_skip_flag((try! raw[5:]).to_string())
      } else {
        None
      }
  }
}

///|
fn parse_voice_flag(raw : String) -> String? {
  let v = raw.trim().to_lower()
  if v.has_prefix("voice=") {
    Some((try! raw[6:]).to_string())
  } else if v.has_prefix("voice:") {
    Some((try! raw[6:]).to_string())
  } else {
    None
  }
}

///|
fn[T] flush_pending_dialog(
  builder : ScriptBuilder[T],
  pending : Ref[(Bool, String, String, Bool, Bool, String?)?],
) -> Unit {
  match pending.val {
    Some((is_intro, speaker, text, typewriter, append, voice)) =>
      if is_intro {
        builder.intro(text)
      } else {
        builder.say(
          speaker,
          text,
          typewriter~,
          append~,
          voice=match voice {
            Some(id) => id
            None => ""
          },
        )
      }
    None => ()
  }
  pending.val = None
}

///|
fn[T] reisen_text_script_to_builder(
  text : String,
  builder : ScriptBuilder[T],
) -> Unit {
  let lines : Array[String] = []
  for line in text.split("\n") {
    lines.push(line.to_string())
  }

  let mut choice_options : Array[ChoiceOption] = []
  let mut choice_speaker = ""
  let mut choice_prompt = ""
  let mut in_choice = false
  let mut last_speaker = None
  let pending_dialog : Ref[(Bool, String, String, Bool, Bool, String?)?] = Ref::new(
    None,
  )

  for raw in lines {
    let trimmed = raw.trim().to_string()
    if trimmed == "" {
      continue
    }
    if trimmed.has_prefix("|") {
      match pending_dialog.val {
        Some((is_intro, speaker, text, typewriter, append, voice)) => {
          let mut extra = (try! trimmed[1:]).to_string()
          if extra.has_prefix(" ") {
            extra = (try! extra[1:]).to_string()
          }
          pending_dialog.val = Some(
            (is_intro, speaker, text + "\n" + extra, typewriter, append, voice),
          )
        }
        None => ()
      }
      continue
    }
    if pending_dialog.val is Some(_) {
      flush_pending_dialog(builder, pending_dialog)
    }
    if trimmed.has_prefix("#") {
      continue
    }

    let (cmd, args_str) = get_first_part(trimmed, ":")

    if in_choice {
      if trimmed.has_prefix("- ") || trimmed == "-" {
        if not(choice_options.is_empty()) {
          builder.menu(choice_speaker, choice_prompt, choice_options)
          choice_options = []
          choice_speaker = ""
          choice_prompt = ""
        }
        in_choice = false
      } else {
        if not(choice_options.is_empty()) {
          builder.menu(choice_speaker, choice_prompt, choice_options)
          choice_options = []
          choice_speaker = ""
          choice_prompt = ""
        }
        in_choice = false
      }
    }

    match cmd {
      "label" =>
        if args_str != "" {
          builder.instructions.push(Label(args_str))
        }
      "jump" => if args_str != "" { builder.instructions.push(Jump(args_str)) }
      "wait" => {
        let lower = args_str.trim().to_lower()
        if lower == "click" ||
          lower == "tap" ||
          lower.has_prefix("click,") ||
          lower.has_prefix("tap,") {
          let can_skip = if lower.has_prefix("click,") ||
            lower.has_prefix("tap,") {
            let (_, tail) = get_first_part(args_str, ",")
            parse_can_skip_flag(tail).unwrap_or(true)
          } else {
            true
          }
          builder.instructions.push(WaitForClick(can_skip))
        } else {
          let ms = @strconv.parse_int(args_str) catch { _ => 0 }
          builder.instructions.push(Wait(ms))
        }
      }
      "wait_click" | "wait_for_click" =>
        builder.instructions.push(
          WaitForClick(parse_can_skip_flag(args_str).unwrap_or(true)),
        )
      "unlock_cg" | "unlock_gallery" =>
        if args_str != "" {
          builder.instructions.push(UnlockCg(args_str))
        }
      "narrate" | "narration" => {
        let parts : Array[String] = []
        for part in args_str.split(",") {
          parts.push(part.trim().to_string())
        }
        if parts.is_empty() {
          ()
        } else {
          let mut typewriter = true
          let mut voice : String? = None
          let mut end_idx = parts.length() - 1
          while end_idx >= 0 {
            let flag = parts[end_idx].trim().to_string().to_lower()
            match parse_typewriter_flag(flag) {
              Some(value) => {
                typewriter = value
                end_idx = end_idx - 1
                continue
              }
              None => ()
            }
            match parse_voice_flag(parts[end_idx]) {
              Some(id) => {
                voice = Some(id)
                end_idx = end_idx - 1
                continue
              }
              None => ()
            }
            break
          }
          let text = join_parts(parts, 0, end_idx + 1)
          pending_dialog.val = Some((false, "", text, typewriter, false, voice))
        }
      }
      "intro" =>
        if args_str != "" {
          pending_dialog.val = Some((true, "", args_str, false, false, None))
        }
      "show_textbox" | "show_text_box" => builder.instructions.push(ShowTextBox)
      "hide_textbox" | "hide_text_box" => builder.instructions.push(HideTextBox)
      "textbox" =>
        match args_str.trim().to_lower() {
          "show" | "on" => builder.instructions.push(ShowTextBox)
          "hide" | "off" => builder.instructions.push(HideTextBox)
          _ => ()
        }
      "avatar" => {
        let value = args_str.trim().to_string()
        match value.to_lower() {
          "hide" | "off" => builder.instructions.push(HideAvatar)
          _ => if value != "" { builder.instructions.push(ShowAvatar(value)) }
        }
      }
      "show_avatar" =>
        if args_str != "" {
          builder.instructions.push(ShowAvatar(args_str))
        }
      "hide_avatar" => builder.instructions.push(HideAvatar)
      "say" => {
        let parts : Array[String] = []
        for part in args_str.split(",") {
          parts.push(part.trim().to_string())
        }
        if parts.length() >= 2 {
          let speaker = parts[0]
          let mut typewriter = true
          let mut append = false
          let mut voice : String? = None
          let mut end_idx = parts.length() - 1
          while end_idx >= 1 {
            let flag = parts[end_idx].trim().to_string().to_lower()
            match parse_typewriter_flag(flag) {
              Some(value) => {
                typewriter = value
                end_idx = end_idx - 1
                continue
              }
              None => ()
            }
            if flag is ("append" | "concat" | "continue" | "+") {
              append = true
              end_idx = end_idx - 1
              continue
            }
            match parse_voice_flag(parts[end_idx]) {
              Some(id) => {
                voice = Some(id)
                end_idx = end_idx - 1
                continue
              }
              None => ()
            }
            break
          }
          let text = join_parts(parts, 1, end_idx + 1)
          match (speaker, last_speaker) {
            ("", Some(s)) =>
              pending_dialog.val = Some(
                (false, s, text, typewriter, append, voice),
              )
            ("", None) =>
              pending_dialog.val = Some(
                (false, "", text, typewriter, append, voice),
              )
            (s, _) => {
              last_speaker = Some(s)
              pending_dialog.val = Some(
                (false, s, text, typewriter, append, voice),
              )
            }
          }
        }
      }
      "scene" | "bg" | "background" =>
        if args_str != "" {
          builder.instructions.push(ShowBackground(args_str))
        }
      "show" | "figure" => {
        let (id, pos) = get_first_part(args_str, ",")
        if id != "" {
          let position : Position = match pos.trim().to_string() {
            "left" => Left
            "center" | "c" => Center
            "right" | "r" => Right
            _ => Center
          }
          builder.instructions.push(
            ShowFigure(id, {
              pos: position,
              layer: 0,
              scalars: ScalarState::default(),
            }),
          )
        }
      }
      "hide" =>
        if args_str != "" {
          builder.instructions.push(HideFigure(args_str))
        }
      "motion" | "live2d_motion" => {
        let (target, group_part) = get_first_part(args_str, ",")
        if target != "" {
          let (group, index_part) = get_first_part(group_part, ",")
          if group != "" {
            let index = if index_part.trim().to_string() == "" {
              None
            } else {
              let parsed = @strconv.parse_int(index_part.trim().to_string()) catch {
                _ => 0
              }
              Some(parsed)
            }
            builder.instructions.push(PlayLive2dMotion(target, group, index))
          }
        }
      }
      "expression" | "expr" | "live2d_expression" => {
        let (target, expr_part) = get_first_part(args_str, ",")
        if target != "" {
          let expr_id = expr_part.trim().to_string()
          let value = if expr_id == "" { None } else { Some(expr_id) }
          builder.instructions.push(SetLive2dExpression(target, value))
        }
      }
      "music" | "bgm" =>
        if args_str.trim().to_string() == "stop" {
          builder.stop_music()
        } else {
          let (track_id, loop_str) = get_first_part(args_str, ",")
          if track_id != "" {
            let should_loop = loop_str.trim().to_string() == "true" ||
              loop_str.trim().to_string() == "1"
            builder.instructions.push(PlayMusic(track_id, should_loop))
          }
        }
      "sfx" | "sound" =>
        if args_str != "" {
          let parts : Array[String] = []
          for part in args_str.split(",") {
            parts.push(part.trim().to_string())
          }
          if parts.length() >= 1 {
            let id = parts[0]
            let mut blocking = false
            for i = 1; i < parts.length(); i = i + 1 {
              let entry = parts[i]
              if entry == "" {
                continue
              }
              let (key_raw, value_raw) = get_first_part(entry, "=")
              let key = key_raw.trim().to_lower()
              let value_str = value_raw.trim().to_lower()
              if key == "blocking" || key == "block" {
                blocking = value_str == "" ||
                  value_str == "true" ||
                  value_str == "1" ||
                  value_str == "yes" ||
                  value_str == "on"
              } else if entry.to_lower() == "blocking" ||
                entry.to_lower() == "block" {
                blocking = true
              }
            }
            builder.instructions.push(PlaySfx(id, blocking))
          }
        }
      "effect" | "fx" => {
        let parts : Array[String] = []
        for part in args_str.split(",") {
          parts.push(part.trim().to_string())
        }
        if parts.length() >= 2 {
          let target = parts[0]
          let effect_id = parts[1]
          if target != "" && effect_id != "" {
            let params : Array[EffectParam] = []
            let mut phase : EffectPhase = Post
            let mut duration : Int? = None
            let mut easing : Easing = Linear
            let mut blocking = false
            for i = 2; i < parts.length(); i = i + 1 {
              let entry = parts[i]
              let (key_raw, value_raw) = get_first_part(entry, "=")
              let key = key_raw.trim().to_string()
              let value_str = value_raw.trim().to_string()
              if key == "phase" {
                let lower = value_str.to_lower()
                if lower == "pre" {
                  phase = Pre
                } else if lower == "post" {
                  phase = Post
                }
              } else if key == "duration" || key == "duration_ms" {
                let value = @strconv.parse_int(value_str) catch { _ => 0 }
                let clamped = if value < 0 { 0 } else { value }
                duration = Some(clamped)
              } else if key == "easing" {
                let lower = value_str.to_lower()
                if lower == "easein" || lower == "ease_in" {
                  easing = EaseIn
                } else if lower == "easeout" || lower == "ease_out" {
                  easing = EaseOut
                } else if lower == "easeinout" || lower == "ease_in_out" {
                  easing = EaseInOut
                } else {
                  easing = Linear
                }
              } else if key == "blocking" || key == "block" {
                let lower = value_str.to_lower()
                blocking = lower == "" ||
                  lower == "true" ||
                  lower == "1" ||
                  lower == "yes" ||
                  lower == "on"
              } else if key != "" && value_str != "" {
                let value = @strconv.parse_double(value_str) catch { _ => 0.0 }
                params.push((key, value))
              }
            }
            builder.instructions.push(
              ApplyEffect(target, {
                id: effect_id,
                params,
                phase,
                duration_ms: duration,
                easing,
                blocking,
              }),
            )
          }
        }
      }
      "animate" | "anim" => {
        let raw_parts : Array[String] = []
        for part in args_str.split(",") {
          raw_parts.push(part.trim().to_string())
        }
        let parts : Array[String] = []
        let mut blocking = false
        for entry in raw_parts {
          let lowered = entry.to_lower()
          if lowered == "blocking" || lowered == "block" {
            blocking = true
            continue
          }
          let (key_raw, value_raw) = get_first_part(entry, "=")
          let key = key_raw.trim().to_lower()
          if key == "blocking" || key == "block" {
            let value_str = value_raw.trim().to_lower()
            blocking = value_str == "" ||
              value_str == "true" ||
              value_str == "1" ||
              value_str == "yes" ||
              value_str == "on"
            continue
          }
          parts.push(entry)
        }
        if parts.length() >= 3 {
          let target = parts[0]
          let prop = parts[1]
          let duration_str = parts[2]
          if target != "" && prop != "" {
            let prop_lower = prop.to_lower()
            let duration_ms = @strconv.parse_int(duration_str) catch {
              _ => 500
            }
            let from_value = if parts.length() >= 4 {
              Some(@strconv.parse_double(parts[3]) catch { _ => 0.0 })
            } else {
              None
            }
            let to_value = if parts.length() >= 5 {
              Some(@strconv.parse_double(parts[4]) catch { _ => 0.0 })
            } else {
              None
            }
            let spec = match prop_lower {
              "opacity" | "alpha" | "fade" =>
                if parts.length() >= 5 {
                  let from = from_value.unwrap_or(0.0)
                  let to = to_value.unwrap_or(1.0)
                  anim_opacity(
                    duration_ms,
                    Some(from),
                    to,
                    easing=Linear,
                    blocking~,
                  )
                } else if parts.length() >= 4 {
                  let to = from_value.unwrap_or(1.0)
                  anim_opacity(duration_ms, None, to, easing=Linear, blocking~)
                } else {
                  anim_opacity(duration_ms, None, 1.0, easing=Linear, blocking~)
                }
              "position" | "pos" | "move" =>
                if parts.length() >= 7 {
                  let from_x = @strconv.parse_double(parts[3]) catch {
                    _ => 0.0
                  }
                  let from_y = @strconv.parse_double(parts[4]) catch {
                    _ => 0.0
                  }
                  let to_x = @strconv.parse_double(parts[5]) catch { _ => 0.0 }
                  let to_y = @strconv.parse_double(parts[6]) catch { _ => 0.0 }
                  anim_position(
                    duration_ms,
                    Some(Custom(from_x, from_y)),
                    Custom(to_x, to_y),
                    easing=Linear,
                    blocking~,
                  )
                } else if parts.length() >= 5 {
                  let to_x = @strconv.parse_double(parts[3]) catch { _ => 0.0 }
                  let to_y = @strconv.parse_double(parts[4]) catch { _ => 0.0 }
                  anim_position(
                    duration_ms,
                    None,
                    Custom(to_x, to_y),
                    easing=Linear,
                    blocking~,
                  )
                } else {
                  anim_position(
                    duration_ms,
                    None,
                    Custom(0.0, 0.0),
                    easing=Linear,
                    blocking~,
                  )
                }
              "scale" | "size" =>
                if parts.length() >= 7 {
                  let from = @strconv.parse_double(parts[3]) catch { _ => 1.0 }
                  let to = @strconv.parse_double(parts[4]) catch { _ => 1.0 }
                  let anchor_x = @strconv.parse_double(parts[5]) catch {
                    _ => 0.5
                  }
                  let anchor_y = @strconv.parse_double(parts[6]) catch {
                    _ => 0.5
                  }
                  anim_scale(
                    duration_ms,
                    Some(from),
                    to,
                    anchor=(anchor_x, anchor_y),
                    easing=Linear,
                    blocking~,
                  )
                } else if parts.length() >= 6 {
                  let to = @strconv.parse_double(parts[3]) catch { _ => 1.0 }
                  let anchor_x = @strconv.parse_double(parts[4]) catch {
                    _ => 0.5
                  }
                  let anchor_y = @strconv.parse_double(parts[5]) catch {
                    _ => 0.5
                  }
                  anim_scale(
                    duration_ms,
                    None,
                    to,
                    anchor=(anchor_x, anchor_y),
                    easing=Linear,
                    blocking~,
                  )
                } else if parts.length() >= 5 {
                  let from = from_value.unwrap_or(1.0)
                  let to = to_value.unwrap_or(1.0)
                  anim_scale(
                    duration_ms,
                    Some(from),
                    to,
                    easing=Linear,
                    blocking~,
                  )
                } else if parts.length() >= 4 {
                  let to = from_value.unwrap_or(1.0)
                  anim_scale(duration_ms, None, to, easing=Linear, blocking~)
                } else {
                  anim_scale(duration_ms, None, 1.0, easing=Linear, blocking~)
                }
              "rotation" | "rotate" =>
                if parts.length() >= 5 {
                  let from = from_value.unwrap_or(0.0)
                  let to = to_value.unwrap_or(0.0)
                  {
                    prop: Rotation,
                    duration_ms,
                    easing: Linear,
                    from: Some([from]),
                    to: Some([to]),
                    anchor: None,
                    blocking,
                  }
                } else if parts.length() >= 4 {
                  let to = from_value.unwrap_or(0.0)
                  {
                    prop: Rotation,
                    duration_ms,
                    easing: Linear,
                    from: None,
                    to: Some([to]),
                    anchor: None,
                    blocking,
                  }
                } else {
                  {
                    prop: Rotation,
                    duration_ms,
                    easing: Linear,
                    from: None,
                    to: Some([0.0]),
                    anchor: None,
                    blocking,
                  }
                }
              "blur" =>
                if parts.length() >= 5 {
                  let from = from_value.unwrap_or(0.0)
                  let to = to_value.unwrap_or(0.0)
                  {
                    prop: Blur,
                    duration_ms,
                    easing: Linear,
                    from: Some([from]),
                    to: Some([to]),
                    anchor: None,
                    blocking,
                  }
                } else if parts.length() >= 4 {
                  let to = from_value.unwrap_or(0.0)
                  {
                    prop: Blur,
                    duration_ms,
                    easing: Linear,
                    from: None,
                    to: Some([to]),
                    anchor: None,
                    blocking,
                  }
                } else {
                  {
                    prop: Blur,
                    duration_ms,
                    easing: Linear,
                    from: None,
                    to: Some([0.0]),
                    anchor: None,
                    blocking,
                  }
                }
              "brightness" =>
                if parts.length() >= 5 {
                  let from = from_value.unwrap_or(1.0)
                  let to = to_value.unwrap_or(1.0)
                  {
                    prop: Brightness,
                    duration_ms,
                    easing: Linear,
                    from: Some([from]),
                    to: Some([to]),
                    anchor: None,
                    blocking,
                  }
                } else if parts.length() >= 4 {
                  let to = from_value.unwrap_or(1.0)
                  {
                    prop: Brightness,
                    duration_ms,
                    easing: Linear,
                    from: None,
                    to: Some([to]),
                    anchor: None,
                    blocking,
                  }
                } else {
                  {
                    prop: Brightness,
                    duration_ms,
                    easing: Linear,
                    from: None,
                    to: Some([1.0]),
                    anchor: None,
                    blocking,
                  }
                }
              "contrast" =>
                if parts.length() >= 5 {
                  let from = from_value.unwrap_or(1.0)
                  let to = to_value.unwrap_or(1.0)
                  {
                    prop: Contrast,
                    duration_ms,
                    easing: Linear,
                    from: Some([from]),
                    to: Some([to]),
                    anchor: None,
                    blocking,
                  }
                } else if parts.length() >= 4 {
                  let to = from_value.unwrap_or(1.0)
                  {
                    prop: Contrast,
                    duration_ms,
                    easing: Linear,
                    from: None,
                    to: Some([to]),
                    anchor: None,
                    blocking,
                  }
                } else {
                  {
                    prop: Contrast,
                    duration_ms,
                    easing: Linear,
                    from: None,
                    to: Some([1.0]),
                    anchor: None,
                    blocking,
                  }
                }
              "saturation" | "sat" =>
                if parts.length() >= 5 {
                  let from = from_value.unwrap_or(1.0)
                  let to = to_value.unwrap_or(1.0)
                  {
                    prop: Saturation,
                    duration_ms,
                    easing: Linear,
                    from: Some([from]),
                    to: Some([to]),
                    anchor: None,
                    blocking,
                  }
                } else if parts.length() >= 4 {
                  let to = from_value.unwrap_or(1.0)
                  {
                    prop: Saturation,
                    duration_ms,
                    easing: Linear,
                    from: None,
                    to: Some([to]),
                    anchor: None,
                    blocking,
                  }
                } else {
                  {
                    prop: Saturation,
                    duration_ms,
                    easing: Linear,
                    from: None,
                    to: Some([1.0]),
                    anchor: None,
                    blocking,
                  }
                }
              "gamma" =>
                if parts.length() >= 5 {
                  let from = from_value.unwrap_or(1.0)
                  let to = to_value.unwrap_or(1.0)
                  {
                    prop: Gamma,
                    duration_ms,
                    easing: Linear,
                    from: Some([from]),
                    to: Some([to]),
                    anchor: None,
                    blocking,
                  }
                } else if parts.length() >= 4 {
                  let to = from_value.unwrap_or(1.0)
                  {
                    prop: Gamma,
                    duration_ms,
                    easing: Linear,
                    from: None,
                    to: Some([to]),
                    anchor: None,
                    blocking,
                  }
                } else {
                  {
                    prop: Gamma,
                    duration_ms,
                    easing: Linear,
                    from: None,
                    to: Some([1.0]),
                    anchor: None,
                    blocking,
                  }
                }
              "red" | "colorred" | "color_r" =>
                if parts.length() >= 5 {
                  let from = from_value.unwrap_or(1.0)
                  let to = to_value.unwrap_or(1.0)
                  {
                    prop: ColorRed,
                    duration_ms,
                    easing: Linear,
                    from: Some([from]),
                    to: Some([to]),
                    anchor: None,
                    blocking,
                  }
                } else if parts.length() >= 4 {
                  let to = from_value.unwrap_or(1.0)
                  {
                    prop: ColorRed,
                    duration_ms,
                    easing: Linear,
                    from: None,
                    to: Some([to]),
                    anchor: None,
                    blocking,
                  }
                } else {
                  {
                    prop: ColorRed,
                    duration_ms,
                    easing: Linear,
                    from: None,
                    to: Some([1.0]),
                    anchor: None,
                    blocking,
                  }
                }
              "green" | "colorgreen" | "color_g" =>
                if parts.length() >= 5 {
                  let from = from_value.unwrap_or(1.0)
                  let to = to_value.unwrap_or(1.0)
                  {
                    prop: ColorGreen,
                    duration_ms,
                    easing: Linear,
                    from: Some([from]),
                    to: Some([to]),
                    anchor: None,
                    blocking,
                  }
                } else if parts.length() >= 4 {
                  let to = from_value.unwrap_or(1.0)
                  {
                    prop: ColorGreen,
                    duration_ms,
                    easing: Linear,
                    from: None,
                    to: Some([to]),
                    anchor: None,
                    blocking,
                  }
                } else {
                  {
                    prop: ColorGreen,
                    duration_ms,
                    easing: Linear,
                    from: None,
                    to: Some([1.0]),
                    anchor: None,
                    blocking,
                  }
                }
              "blue" | "colorblue" | "color_b" =>
                if parts.length() >= 5 {
                  let from = from_value.unwrap_or(1.0)
                  let to = to_value.unwrap_or(1.0)
                  {
                    prop: ColorBlue,
                    duration_ms,
                    easing: Linear,
                    from: Some([from]),
                    to: Some([to]),
                    anchor: None,
                    blocking,
                  }
                } else if parts.length() >= 4 {
                  let to = from_value.unwrap_or(1.0)
                  {
                    prop: ColorBlue,
                    duration_ms,
                    easing: Linear,
                    from: None,
                    to: Some([to]),
                    anchor: None,
                    blocking,
                  }
                } else {
                  {
                    prop: ColorBlue,
                    duration_ms,
                    easing: Linear,
                    from: None,
                    to: Some([1.0]),
                    anchor: None,
                    blocking,
                  }
                }
              _ =>
                anim_opacity(duration_ms, None, 1.0, easing=Linear, blocking~)
            }
            if prop_lower == "opacity" ||
              prop_lower == "alpha" ||
              prop_lower == "fade" ||
              prop_lower == "position" ||
              prop_lower == "pos" ||
              prop_lower == "move" ||
              prop_lower == "scale" ||
              prop_lower == "size" ||
              prop_lower == "rotation" ||
              prop_lower == "rotate" ||
              prop_lower == "blur" ||
              prop_lower == "brightness" ||
              prop_lower == "contrast" ||
              prop_lower == "saturation" ||
              prop_lower == "sat" ||
              prop_lower == "gamma" ||
              prop_lower == "red" ||
              prop_lower == "colorred" ||
              prop_lower == "color_r" ||
              prop_lower == "green" ||
              prop_lower == "colorgreen" ||
              prop_lower == "color_g" ||
              prop_lower == "blue" ||
              prop_lower == "colorblue" ||
              prop_lower == "color_b" {
              builder.instructions.push(AnimatePixi(target, spec))
            }
          }
        }
      }
      "choice" | "choices" => {
        in_choice = true
        choice_options = []
        let (speaker, prompt) = get_first_part(args_str, ",")
        choice_speaker = speaker
        choice_prompt = prompt
      }
      "input" | "input_text" | "ask" => {
        let (var_name, prompt) = get_first_part(args_str, ",")
        if var_name != "" {
          builder.input_text(var_name, prompt)
        }
      }
      "stop_music" => builder.stop_music()
      _ => ()
    }
  }

  if pending_dialog.val is Some(_) {
    flush_pending_dialog(builder, pending_dialog)
  }
  if in_choice && not(choice_options.is_empty()) {
    builder.menu(choice_speaker, choice_prompt, choice_options)
  }
}

///|
pub fn[T] reisen_parse_text_script(
  text : String,
) -> Script[T] raise ScriptBuildError {
  let builder : ScriptBuilder[T] = ScriptBuilder::new()
  reisen_text_script_to_builder(text, builder)
  builder.build()
}
