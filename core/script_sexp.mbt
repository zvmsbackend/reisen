///|
/// S-expression script parser for Reisen.

///|
pub suberror ReisenSexpError derive(Show, Eq)

///|
pub type SexpHostFunction[T] = (@state.GameState[T], ArrayView[@js.Value]) -> @js.Value

///|
pub struct SexpScriptParser[T] {
  host_functions : Map[String, SexpHostFunction[T]]
}

///|
pub fn[T] SexpScriptParser::new() -> SexpScriptParser[T] {
  let parser = { host_functions: {} }
  register_default_functions(parser)
  parser
}

///|
pub fn[T] SexpScriptParser::register_function(
  self : SexpScriptParser[T],
  name : String,
  f : SexpHostFunction[T],
) -> Unit {
  self.host_functions[name] = f
}

///|
extern "js" fn js_undefined() -> @js.Value = "() => undefined"

///|
extern "js" fn js_strict_eq(lhs : @js.Value, rhs : @js.Value) -> Bool =
  #| (lhs, rhs) => lhs === rhs

///|
fn js_value_as_string(value : @js.Value) -> String? {
  @js.Cast::into(value)
}

///|
fn js_value_as_int(value : @js.Value) -> Int? {
  @js.Cast::into(value)
}

///|
fn js_value_as_double(value : @js.Value) -> Double? {
  @js.Cast::into(value)
}

///|
fn js_value_as_bool(value : @js.Value) -> Bool? {
  @js.Cast::into(value)
}

///|
fn js_to_string(value : @js.Value) -> String {
  match js_value_as_string(value) {
    Some(s) => s
    None =>
      match js_value_as_int(value) {
        Some(i) => i.to_string()
        None =>
          match js_value_as_double(value) {
            Some(d) => d.to_string()
            None =>
              match js_value_as_bool(value) {
                Some(b) => if b { "true" } else { "false" }
                None => ""
              }
          }
      }
  }
}

///|
fn js_to_int(value : @js.Value) -> Int {
  match js_value_as_int(value) {
    Some(i) => i
    None =>
      match js_value_as_double(value) {
        Some(d) => d.to_int()
        None =>
          match js_value_as_bool(value) {
            Some(b) => if b { 1 } else { 0 }
            None =>
              match js_value_as_string(value) {
                Some(s) => @strconv.parse_int(s) catch { _ => 0 }
                None => 0
              }
          }
      }
  }
}

///|
fn js_to_double(value : @js.Value) -> Double {
  match js_value_as_double(value) {
    Some(d) => d
    None =>
      match js_value_as_int(value) {
        Some(i) => i.to_double()
        None =>
          match js_value_as_bool(value) {
            Some(b) => if b { 1.0 } else { 0.0 }
            None =>
              match js_value_as_string(value) {
                Some(s) => @strconv.parse_double(s) catch { _ => 0.0 }
                None => 0.0
              }
          }
      }
  }
}

///|
fn js_to_bool(value : @js.Value) -> Bool {
  match js_value_as_bool(value) {
    Some(b) => b
    None =>
      match js_value_as_int(value) {
        Some(i) => i != 0
        None =>
          match js_value_as_double(value) {
            Some(d) => d != 0.0
            None =>
              match js_value_as_string(value) {
                Some(s) => {
                  let lowered = s.trim().to_lower()
                  !(lowered == "" || lowered == "false" || lowered == "0")
                }
                None => false
              }
          }
      }
  }
}

///|
fn[T] std_eq(_ : @state.GameState[T], args : ArrayView[@js.Value]) -> @js.Value {
  match args {
    [lhs, rhs] => @js.Cast::from(js_strict_eq(lhs, rhs))
    _ => js_undefined()
  }
}

///|
fn[T] std_neq(
  _ : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  match args {
    [lhs, rhs] => @js.Cast::from(!js_strict_eq(lhs, rhs))
    _ => js_undefined()
  }
}

///|
fn[T] std_not(
  _ : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  match args {
    [v] => @js.Cast::from(!js_to_bool(v))
    _ => js_undefined()
  }
}

///|
fn[T] std_and(
  _ : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  let mut all_true = true
  for arg in args {
    if !js_to_bool(arg) {
      all_true = false
    }
  }
  @js.Cast::from(all_true)
}

///|
fn[T] std_or(_ : @state.GameState[T], args : ArrayView[@js.Value]) -> @js.Value {
  let mut any_true = false
  for arg in args {
    if js_to_bool(arg) {
      any_true = true
    }
  }
  @js.Cast::from(any_true)
}

///|
fn[T] std_gt(_ : @state.GameState[T], args : ArrayView[@js.Value]) -> @js.Value {
  match args {
    [lhs, rhs] => @js.Cast::from(js_to_double(lhs) > js_to_double(rhs))
    _ => js_undefined()
  }
}

///|
fn[T] std_gte(
  _ : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  match args {
    [lhs, rhs] => @js.Cast::from(js_to_double(lhs) >= js_to_double(rhs))
    _ => js_undefined()
  }
}

///|
fn[T] std_lt(_ : @state.GameState[T], args : ArrayView[@js.Value]) -> @js.Value {
  match args {
    [lhs, rhs] => @js.Cast::from(js_to_double(lhs) < js_to_double(rhs))
    _ => js_undefined()
  }
}

///|
fn[T] std_lte(
  _ : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  match args {
    [lhs, rhs] => @js.Cast::from(js_to_double(lhs) <= js_to_double(rhs))
    _ => js_undefined()
  }
}

///|
fn[T] std_add(
  _ : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  let mut sum = 0.0
  for arg in args {
    sum = sum + js_to_double(arg)
  }
  @js.Cast::from(sum)
}

///|
fn[T] std_sub(
  _ : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  match args {
    [] => js_undefined()
    [x] => @js.Cast::from(-js_to_double(x))
    [head, .. rest] => {
      let mut out = js_to_double(head)
      for v in rest {
        out = out - js_to_double(v)
      }
      @js.Cast::from(out)
    }
  }
}

///|
fn[T] std_mul(
  _ : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  if args.length() == 0 {
    return js_undefined()
  }
  let mut out = 1.0
  for arg in args {
    out = out * js_to_double(arg)
  }
  @js.Cast::from(out)
}

///|
fn[T] std_div(
  _ : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  match args {
    [lhs, rhs] => {
      let divisor = js_to_double(rhs)
      if divisor == 0.0 {
        js_undefined()
      } else {
        @js.Cast::from(js_to_double(lhs) / divisor)
      }
    }
    _ => js_undefined()
  }
}

///|
fn[T] std_mod(
  _ : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  match args {
    [lhs, rhs] => {
      let divisor = js_to_int(rhs)
      if divisor == 0 {
        js_undefined()
      } else {
        @js.Cast::from(js_to_int(lhs) % divisor)
      }
    }
    _ => js_undefined()
  }
}

///|
fn[T] std_concat(
  _ : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  let mut out = ""
  for arg in args {
    out = out + js_to_string(arg)
  }
  @js.Cast::from(out)
}

///|
fn[T] std_int_var(
  state : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  match args {
    [name] => @js.Cast::from(state.int_var(js_to_string(name)))
    [name, default_value] =>
      @js.Cast::from(
        state.int_var(
          js_to_string(name),
          default_value=js_to_int(default_value),
        ),
      )
    _ => js_undefined()
  }
}

///|
fn[T] std_flag(
  state : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  match args {
    [name] => @js.Cast::from(state.flag(js_to_string(name)))
    _ => js_undefined()
  }
}

///|
fn[T] std_text_var(
  state : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  match args {
    [name] => @js.Cast::from(state.text_var(js_to_string(name)))
    [name, default_value] =>
      @js.Cast::from(
        state.text_var(
          js_to_string(name),
          default_value=js_to_string(default_value),
        ),
      )
    _ => js_undefined()
  }
}

///|
fn[T] std_set_int(
  state : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  match args {
    [name, value] => {
      state.set_int_var(js_to_string(name), js_to_int(value))
      @js.Cast::from(true)
    }
    _ => js_undefined()
  }
}

///|
fn[T] std_set_flag(
  state : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  match args {
    [name, value] => {
      state.set_flag(js_to_string(name), js_to_bool(value))
      @js.Cast::from(true)
    }
    _ => js_undefined()
  }
}

///|
fn[T] std_set_text(
  state : @state.GameState[T],
  args : ArrayView[@js.Value],
) -> @js.Value {
  match args {
    [name, value] => {
      state.set_text_var(js_to_string(name), js_to_string(value))
      @js.Cast::from(true)
    }
    _ => js_undefined()
  }
}

///|
fn[T] register_default_functions(parser : SexpScriptParser[T]) -> Unit {
  parser.register_function("=", std_eq)
  parser.register_function("!=", std_neq)
  parser.register_function("not", std_not)
  parser.register_function("and", std_and)
  parser.register_function("or", std_or)
  parser.register_function(">", std_gt)
  parser.register_function(">=", std_gte)
  parser.register_function("<", std_lt)
  parser.register_function("<=", std_lte)
  parser.register_function("+", std_add)
  parser.register_function("-", std_sub)
  parser.register_function("*", std_mul)
  parser.register_function("/", std_div)
  parser.register_function("%", std_mod)
  parser.register_function("concat", std_concat)
  parser.register_function("int-var", std_int_var)
  parser.register_function("flag", std_flag)
  parser.register_function("text-var", std_text_var)
  parser.register_function("set-int", std_set_int)
  parser.register_function("set-flag", std_set_flag)
  parser.register_function("set-text", std_set_text)
}

///|
fn sexp_as_string(value : @sexp.Sexp) -> String? {
  match value {
    @sexp.String(s) => Some(s)
    @sexp.Symbol(sym) => Some(sym.to_string())
    _ => None
  }
}

///|
fn sexp_as_int(value : @sexp.Sexp) -> Int? {
  match value {
    @sexp.Int(i) => Some(i)
    _ => None
  }
}

///|
fn sexp_as_double(value : @sexp.Sexp) -> Double? {
  match value {
    @sexp.Double(d) => Some(d)
    @sexp.Int(i) => Some(i.to_double())
    _ => None
  }
}

///|
fn sexp_as_bool(value : @sexp.Sexp) -> Bool? {
  match value {
    @sexp.Bool(b) => Some(b)
    _ => None
  }
}

///|
fn[T] sexp_to_js_value(
  value : @sexp.Sexp,
  state : @state.GameState[T],
  host_functions : Map[String, SexpHostFunction[T]],
  payload? : @js.Value,
) -> @js.Value {
  match value {
    @sexp.Int(i) => @js.Cast::from(i)
    @sexp.Double(d) => @js.Cast::from(d)
    @sexp.Bool(b) => @js.Cast::from(b)
    @sexp.String(s) => @js.Cast::from(s)
    @sexp.Char(c) => @js.Cast::from(c.to_string())
    @sexp.Symbol(sym) =>
      if sym == @sexp.Symbol::new("payload") && payload is Some(payload) {
        payload
      } else {
        @js.Value::cast_from(sym.to_string())
      }
    @sexp.List(xs) =>
      match xs {
        [@sexp.Symbol(fn_name), .. args] => {
          let name = fn_name.to_string()
          match host_functions.get(name) {
            Some(f) => {
              let evaluated : Array[@js.Value] = []
              for arg in args {
                evaluated.push(
                  sexp_to_js_value(arg, state, host_functions, payload?),
                )
              }
              f(state, evaluated)
            }
            None => js_undefined()
          }
        }
        _ => js_undefined()
      }
  }
}

///|
fn js_value_to_bool(value : @js.Value) -> Bool {
  @js.Cast::into(value).unwrap_or(false)
}

///|
fn js_value_to_string(value : @js.Value) -> String? {
  @js.Cast::into(value)
}

///|
fn parse_position(value : @sexp.Sexp) -> Position {
  match value {
    @sexp.List([@sexp.Symbol(tag), .. rest]) =>
      if tag == @sexp.Symbol::new("left") {
        Left
      } else if tag == @sexp.Symbol::new("center") {
        Center
      } else if tag == @sexp.Symbol::new("right") {
        Right
      } else if tag == @sexp.Symbol::new("custom") {
        match rest {
          [x, y] =>
            Custom(
              sexp_as_double(x).unwrap_or(0.0),
              sexp_as_double(y).unwrap_or(0.0),
            )
          _ => Center
        }
      } else {
        Center
      }
    _ => Center
  }
}

///|
fn parse_choice_options(items : Array[@sexp.Sexp]) -> Array[ChoiceOption] {
  let out : Array[ChoiceOption] = []
  for item in items {
    match item {
      @sexp.List([text, jump, .. rest]) => {
        let txt = sexp_as_string(text).unwrap_or("")
        let tgt = sexp_as_string(jump).unwrap_or("")
        let mut id = ""
        match rest {
          [@sexp.Symbol(k), v] if k == @sexp.Symbol::new(":id") =>
            id = sexp_as_string(v).unwrap_or("")
          _ => ()
        }
        if txt != "" && tgt != "" {
          out.push(
            option(txt, label(name=tgt), id=if id == "" { txt } else { id }),
          )
        }
      }
      _ => ()
    }
  }
  out
}

///|
fn[T] lower_form(
  form : @sexp.Sexp,
  builder : ScriptBuilder[T],
  host_functions : Map[String, SexpHostFunction[T]],
) -> Unit {
  match form {
    @sexp.List([@sexp.Symbol(head), .. args]) => {
      let cmd = head.to_string()
      match cmd {
        "label" =>
          match args {
            [name] => {
              let s = sexp_as_string(name).unwrap_or("")
              if s != "" {
                builder.label(label(name=s))
              }
            }
            _ => ()
          }
        "jump" =>
          match args {
            [name] => {
              let s = sexp_as_string(name).unwrap_or("")
              if s != "" {
                builder.jump(label(name=s))
              }
            }
            _ => ()
          }
        "jump-if" =>
          match args {
            [target, predicate] => {
              let label_name = sexp_as_string(target).unwrap_or("")
              if label_name != "" {
                builder.jump_if(label(name=label_name), state => {
                  let value = sexp_to_js_value(predicate, state, host_functions)
                  js_value_to_bool(value)
                })
              }
            }
            _ => ()
          }
        "jump-by" =>
          match args {
            [selector] =>
              builder.jump_by(state => {
                let value = sexp_to_js_value(selector, state, host_functions)
                let target = js_value_to_string(value).unwrap_or("")
                label(name=target)
              })
            _ => ()
          }
        "run-code" =>
          match args {
            [expr] =>
              builder.run_code(state => {
                ignore(sexp_to_js_value(expr, state, host_functions))
              })
            _ => ()
          }
        "wait-custom-event" =>
          match args {
            [name, predicate] => {
              let event_name = sexp_as_string(name).unwrap_or("")
              if event_name != "" {
                builder.wait_custom_event(event_name, (state, payload_text) => {
                  let payload = @js.Cast::from(payload_text)
                  let value = sexp_to_js_value(
                    predicate,
                    state,
                    host_functions,
                    payload~,
                  )
                  js_value_to_bool(value)
                })
              }
            }
            _ => ()
          }
        "wait-custom-event-jump" =>
          match args {
            [name, selector] => {
              let event_name = sexp_as_string(name).unwrap_or("")
              if event_name != "" {
                builder.wait_custom_event_jump(event_name, (state, payload_text) => {
                  let payload = @js.Cast::from(payload_text)
                  let value = sexp_to_js_value(
                    selector,
                    state,
                    host_functions,
                    payload~,
                  )
                  let target = js_value_to_string(value).unwrap_or("")
                  label(name=target)
                })
              }
            }
            _ => ()
          }
        "wait" =>
          match args {
            [ms] => builder.wait(sexp_as_int(ms).unwrap_or(0))
            _ => ()
          }
        "wait-click" =>
          match args {
            [flag] =>
              builder.wait_click(can_skip=sexp_as_bool(flag).unwrap_or(true))
            _ => builder.wait_click()
          }
        "unlock-cg" =>
          match args {
            [id] => {
              let cg_id = sexp_as_string(id).unwrap_or("")
              if cg_id != "" {
                builder.instructions.push(UnlockCg(cg_id))
              }
            }
            _ => ()
          }
        "intro" =>
          match args {
            [text] => builder.intro(sexp_as_string(text).unwrap_or(""))
            _ => ()
          }
        "show-text-box" => builder.show_text_box()
        "hide-text-box" => builder.hide_text_box()
        "show-avatar" =>
          match args {
            [url] => builder.show_avatar(sexp_as_string(url).unwrap_or(""))
            _ => ()
          }
        "hide-avatar" => builder.hide_avatar()
        "say" =>
          match args {
            [speaker, text, .. rest] => {
              let sp = sexp_as_string(speaker).unwrap_or("")
              let tx = sexp_as_string(text).unwrap_or("")
              let mut typewriter = true
              let mut append = false
              let mut voice = ""
              let mut i = 0
              while i + 1 < rest.length() {
                match rest[i] {
                  @sexp.Symbol(k) if k == @sexp.Symbol::new(":typewriter") =>
                    typewriter = sexp_as_bool(rest[i + 1]).unwrap_or(typewriter)
                  @sexp.Symbol(k) if k == @sexp.Symbol::new(":append") =>
                    append = sexp_as_bool(rest[i + 1]).unwrap_or(append)
                  @sexp.Symbol(k) if k == @sexp.Symbol::new(":voice") =>
                    voice = sexp_as_string(rest[i + 1]).unwrap_or(voice)
                  _ => ()
                }
                i = i + 2
              }
              builder.say(sp, tx, typewriter~, append~, voice~)
            }
            _ => ()
          }
        "narrate" =>
          match args {
            [text] => builder.narrate(sexp_as_string(text).unwrap_or(""))
            _ => ()
          }
        "scene" =>
          match args {
            [bg_id] => {
              let id = sexp_as_string(bg_id).unwrap_or("")
              if id != "" {
                builder.instructions.push(ShowBackground(id))
              }
            }
            _ => ()
          }
        "show-figure" =>
          match args {
            [id, pos] => {
              let target = sexp_as_string(id).unwrap_or("")
              if target != "" {
                builder.instructions.push(
                  ShowFigure(target, {
                    pos: parse_position(pos),
                    layer: 0,
                    scalars: ScalarState::default(),
                  }),
                )
              }
            }
            _ => ()
          }
        "hide-figure" =>
          match args {
            [id] => {
              let target = sexp_as_string(id).unwrap_or("")
              if target != "" {
                builder.instructions.push(HideFigure(target))
              }
            }
            _ => ()
          }
        "play-live2d-motion" =>
          match args {
            [target, group] => {
              let id = sexp_as_string(target).unwrap_or("")
              let motion = sexp_as_string(group).unwrap_or("")
              if id != "" && motion != "" {
                builder.instructions.push(PlayLive2dMotion(id, motion, None))
              }
            }
            [target, group, index] => {
              let id = sexp_as_string(target).unwrap_or("")
              let motion = sexp_as_string(group).unwrap_or("")
              if id != "" && motion != "" {
                builder.instructions.push(
                  PlayLive2dMotion(
                    id,
                    motion,
                    Some(sexp_as_int(index).unwrap_or(0)),
                  ),
                )
              }
            }
            _ => ()
          }
        "set-live2d-expression" =>
          match args {
            [target] => {
              let id = sexp_as_string(target).unwrap_or("")
              if id != "" {
                builder.instructions.push(SetLive2dExpression(id, None))
              }
            }
            [target, expr] => {
              let id = sexp_as_string(target).unwrap_or("")
              if id != "" {
                builder.instructions.push(
                  SetLive2dExpression(
                    id,
                    Some(sexp_as_string(expr).unwrap_or("")),
                  ),
                )
              }
            }
            _ => ()
          }
        "play-music" =>
          match args {
            [id] => {
              let track = sexp_as_string(id).unwrap_or("")
              if track != "" {
                builder.instructions.push(PlayMusic(track, false))
              }
            }
            [id, loop_flag] => {
              let track = sexp_as_string(id).unwrap_or("")
              if track != "" {
                builder.instructions.push(
                  PlayMusic(track, sexp_as_bool(loop_flag).unwrap_or(false)),
                )
              }
            }
            _ => ()
          }
        "stop-music" => builder.stop_music()
        "play-sfx" =>
          match args {
            [id] => {
              let sfx_id = sexp_as_string(id).unwrap_or("")
              if sfx_id != "" {
                builder.instructions.push(PlaySfx(sfx_id, false))
              }
            }
            [id, blocking] => {
              let sfx_id = sexp_as_string(id).unwrap_or("")
              if sfx_id != "" {
                builder.instructions.push(
                  PlaySfx(sfx_id, sexp_as_bool(blocking).unwrap_or(false)),
                )
              }
            }
            _ => ()
          }
        "play-video" =>
          match args {
            [url] => {
              let video_url = sexp_as_string(url).unwrap_or("")
              if video_url != "" {
                builder.play_video(video_url)
              }
            }
            [url, can_skip] => {
              let video_url = sexp_as_string(url).unwrap_or("")
              if video_url != "" {
                builder.play_video(
                  video_url,
                  can_skip=sexp_as_bool(can_skip).unwrap_or(false),
                )
              }
            }
            _ => ()
          }
        "effect" =>
          match args {
            [target, effect_id, .. rest] => {
              let t = sexp_as_string(target).unwrap_or("")
              let e = sexp_as_string(effect_id).unwrap_or("")
              if t != "" && e != "" {
                let params : Array[EffectParam] = []
                for item in rest {
                  match item {
                    @sexp.List([k, v]) => {
                      let key = sexp_as_string(k).unwrap_or("")
                      let value = sexp_as_double(v).unwrap_or(0.0)
                      if key != "" {
                        params.push((key, value))
                      }
                    }
                    _ => ()
                  }
                }
                builder.instructions.push(
                  ApplyEffect(t, {
                    id: e,
                    params,
                    phase: Post,
                    duration_ms: None,
                    easing: Linear,
                    blocking: false,
                  }),
                )
              }
            }
            _ => ()
          }
        "animate" =>
          match args {
            [target, prop, duration, from, to] => {
              let t = sexp_as_string(target).unwrap_or("")
              let p = sexp_as_string(prop).unwrap_or("").to_lower()
              let dur = sexp_as_int(duration).unwrap_or(0)
              let from_value = sexp_as_double(from).unwrap_or(0.0)
              let to_value = sexp_as_double(to).unwrap_or(0.0)
              if t != "" {
                let spec = if p == "opacity" {
                  anim_opacity(dur, Some(from_value), to_value)
                } else {
                  anim_opacity(dur, None, to_value)
                }
                builder.instructions.push(AnimatePixi(t, spec))
              }
            }
            _ => ()
          }
        "choice" => {
          let options = parse_choice_options(args.to_array())
          if !options.is_empty() {
            builder.choice(options)
          }
        }
        "menu" =>
          match args {
            [speaker, prompt, .. items] => {
              let sp = sexp_as_string(speaker).unwrap_or("")
              let pr = sexp_as_string(prompt).unwrap_or("")
              let options = parse_choice_options(items.to_array())
              if !options.is_empty() {
                builder.menu(sp, pr, options)
              }
            }
            _ => ()
          }
        "input-text" =>
          match args {
            [var_name, prompt] => {
              let vn = sexp_as_string(var_name).unwrap_or("")
              if vn != "" {
                builder.input_text(vn, sexp_as_string(prompt).unwrap_or(""))
              }
            }
            _ => ()
          }
        _ => ()
      }
    }
    _ => ()
  }
}

///|
fn[T] SexpScriptParser::to_builder(
  parser : SexpScriptParser[T],
  text : String,
  builder : ScriptBuilder[T],
) -> Unit {
  let forms = @sexp.parse_many(text) catch { _ => return }
  for form in forms {
    lower_form(form, builder, parser.host_functions)
  }
}

///|
pub fn[T] reisen_sexp_script_to_builder(
  text : String,
  builder : ScriptBuilder[T],
) -> Unit {
  SexpScriptParser::new().to_builder(text, builder)
}

///|
pub fn[T] reisen_parse_sexp_script(
  text : String,
) -> Script[T] raise ScriptBuildError {
  let builder : ScriptBuilder[T] = ScriptBuilder::new()
  reisen_sexp_script_to_builder(text, builder)
  builder.build()
}

///|
pub fn[T] reisen_parse_sexp_script_with_parser(
  text : String,
  parser : SexpScriptParser[T],
) -> Script[T] raise ScriptBuildError {
  let builder : ScriptBuilder[T] = ScriptBuilder::new()
  parser.to_builder(text, builder)
  builder.build()
}
