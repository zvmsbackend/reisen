///|
/// Textual script format parser for Reisen visual novel engine.
/// Line-based format: `command: arg1, arg2, ...`
/// Supports: label, jump, wait, narrate, say, scene, show, hide, music, sfx, animate, choice

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
    let mut rest = ""
    for i in 1..<parts.length() {
      if i > 1 {
        rest = rest + sep
      }
      rest = rest + parts[i]
    }
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
  let mut out = ""
  for i in start..<end_exclusive {
    if i > start {
      out = out + ", "
    }
    out = out + parts[i]
  }
  out
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
fn[T] flush_pending_dialog(
  builder : ScriptBuilder[T],
  pending : Ref[(String, String, Bool)?],
) -> Unit {
  match pending.val {
    Some((speaker, text, typewriter)) => builder.say(speaker, text, typewriter~)
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
  let pending_dialog : Ref[(String, String, Bool)?] = Ref::new(None)

  for raw in lines {
    let trimmed = raw.trim().to_string()
    if trimmed == "" {
      continue
    }
    if trimmed.has_prefix("|") {
      match pending_dialog.val {
        Some((speaker, text, typewriter)) => {
          let mut extra = (try! trimmed[1:]).to_string()
          if extra.has_prefix(" ") {
            extra = (try! extra[1:]).to_string()
          }
          pending_dialog.val = Some((speaker, text + "\n" + extra, typewriter))
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
        let ms = (try? @strconv.parse_int(args_str)).unwrap_or(0)
        builder.instructions.push(Wait(ms))
      }
      "narrate" | "narration" => {
        let parts : Array[String] = []
        for part in args_str.split(",") {
          parts.push(part.trim().to_string())
        }
        if parts.is_empty() {
          ()
        } else {
          let maybe_flag = parse_typewriter_flag(parts[parts.length() - 1])
          let (text, typewriter) = match maybe_flag {
            Some(flag) if parts.length() > 1 =>
              (join_parts(parts, 0, parts.length() - 1), flag)
            _ => (join_parts(parts, 0, parts.length()), true)
          }
          pending_dialog.val = Some(("", text, typewriter))
        }
      }
      "say" => {
        let parts : Array[String] = []
        for part in args_str.split(",") {
          parts.push(part.trim().to_string())
        }
        if parts.length() >= 2 {
          let speaker = parts[0]
          let maybe_flag = parse_typewriter_flag(parts[parts.length() - 1])
          let (text, typewriter) = match maybe_flag {
            Some(flag) if parts.length() > 2 =>
              (join_parts(parts, 1, parts.length() - 1), flag)
            _ => (join_parts(parts, 1, parts.length()), true)
          }
          match (speaker, last_speaker) {
            ("", Some(s)) => pending_dialog.val = Some((s, text, typewriter))
            ("", None) => pending_dialog.val = Some(("", text, typewriter))
            (s, _) => {
              last_speaker = Some(s)
              pending_dialog.val = Some((s, text, typewriter))
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
          let position = match pos.trim().to_string() {
            "left" => Left
            "center" | "c" => Center
            "right" | "r" => Right
            _ => Center
          }
          builder.instructions.push(
            ShowFigure(id, { pos: position, layer: 0, opacity: 1.0, scale: 1.0 }),
          )
        }
      }
      "hide" =>
        if args_str != "" {
          builder.instructions.push(HideFigure(args_str))
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
          builder.instructions.push(PlaySfx(args_str))
        }
      "animate" | "anim" => {
        let parts : Array[String] = []
        for part in args_str.split(",") {
          parts.push(part.trim().to_string())
        }
        if parts.length() >= 3 {
          let target = parts[0]
          let prop = parts[1]
          let duration_str = parts[2]
          if target != "" && prop != "" {
            let prop_lower = prop.to_lower()
            let duration_ms = (try? @strconv.parse_int(duration_str)).unwrap_or(
              500,
            )
            let from_value = if parts.length() >= 4 {
              Some((try? @strconv.parse_double(parts[3])).unwrap_or(0.0))
            } else {
              None
            }
            let to_value = if parts.length() >= 5 {
              Some((try? @strconv.parse_double(parts[4])).unwrap_or(0.0))
            } else {
              None
            }
            let spec = match prop_lower {
              "opacity" | "alpha" | "fade" =>
                match (from_value, to_value) {
                  (Some(from), Some(to)) =>
                    anim_opacity_range(duration_ms, from, to, easing=Linear)
                  _ => anim_opacity(duration_ms, easing=Linear)
                }
              "position" | "pos" | "move" =>
                if parts.length() >= 7 {
                  let from_x = (try? @strconv.parse_double(parts[3])).unwrap_or(
                    0.0,
                  )
                  let from_y = (try? @strconv.parse_double(parts[4])).unwrap_or(
                    0.0,
                  )
                  let to_x = (try? @strconv.parse_double(parts[5])).unwrap_or(
                    0.0,
                  )
                  let to_y = (try? @strconv.parse_double(parts[6])).unwrap_or(
                    0.0,
                  )
                  anim_position_range(
                    duration_ms,
                    from_x,
                    from_y,
                    to_x,
                    to_y,
                    easing=Linear,
                  )
                } else {
                  anim_position(duration_ms, easing=Linear)
                }
              "scale" | "size" =>
                match (from_value, to_value) {
                  (Some(from), Some(to)) =>
                    anim_scale_range(duration_ms, from, to, easing=Linear)
                  _ => anim_scale(duration_ms, easing=Linear)
                }
              _ => anim_opacity(duration_ms, easing=Linear)
            }
            if prop_lower == "opacity" ||
              prop_lower == "alpha" ||
              prop_lower == "fade" ||
              prop_lower == "position" ||
              prop_lower == "pos" ||
              prop_lower == "move" ||
              prop_lower == "scale" ||
              prop_lower == "size" {
              builder.instructions.push(Animate(target, spec))
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
