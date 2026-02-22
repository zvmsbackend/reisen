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
fn[T] reisen_text_script_to_builder(
  text : String,
  builder : ScriptBuilder[T],
) -> Unit {
  let lines : Array[String] = []
  for line in text.split("\n") {
    let s = line.trim().to_string()
    if s != "" {
      lines.push(s)
    }
  }

  let mut choice_options : Array[ChoiceOption] = []
  let mut choice_speaker = ""
  let mut choice_prompt = ""
  let mut in_choice = false
  let mut last_speaker = None

  for line in lines {
    if line.has_prefix("#") {
      continue
    }

    let (cmd, args_str) = get_first_part(line, ":")

    if in_choice {
      let trimmed = line.trim()
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
      "label" => if args_str != "" { builder.label(args_str) }
      "jump" => if args_str != "" { builder.jump(args_str) }
      "wait" => {
        // Skip wait parsing for now - would need number parsing
        let _ = args_str
      }
      "narrate" | "narration" => builder.narrate(args_str)
      "say" => {
        let (speaker, text) = get_first_part(args_str, ",")
        match (speaker, last_speaker) {
          ("", Some(s)) => builder.say(s, text)
          ("", None) => builder.say("", text)
          (s, _) => {
            last_speaker = Some(s)
            builder.say(s, text)
          }
        }
      }
      "scene" | "bg" | "background" =>
        if args_str != "" {
          builder.scene(args_str)
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
          builder.show_figure_at(id, position)
        }
      }
      "hide" => if args_str != "" { builder.hide_figure(args_str) }
      "music" | "bgm" =>
        if args_str.trim().to_string() == "stop" {
          builder.stop_music()
        } else {
          let (track_id, loop_str) = get_first_part(args_str, ",")
          if track_id != "" {
            let should_loop = loop_str.trim().to_string() == "true" ||
              loop_str.trim().to_string() == "1"
            builder.play_music(track_id, should_loop)
          }
        }
      "sfx" | "sound" => if args_str != "" { builder.play_sfx(args_str) }
      "animate" | "anim" => {
        let (target, rest) = get_first_part(args_str, ",")
        let (prop, arg_str) = get_first_part(rest, ",")
        if target != "" && prop != "" {
          let prop_lower = prop.to_lower()
          let arg = (try? @strconv.parse_int(arg_str)).unwrap_or(500)
          match prop_lower {
            "opacity" | "alpha" | "fade" => builder.animate_opacity(target, arg)
            "position" | "pos" | "move" => builder.animate_position(target, arg)
            "scale" | "size" => builder.animate_scale(target, arg)
            _ => ()
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
