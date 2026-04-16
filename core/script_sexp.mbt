///|
/// S-expression script parser for Reisen.

///|
pub suberror ReisenSexpError derive(Debug, Eq)

///|
pub(all) enum SexpValue {
  Bool(Bool)
  Int(Int)
  Double(Double)
  String(String)
  Undefined
} derive(Debug)

///|
pub type SexpHostFunction[T] = (@state.GameState[T], ArrayView[SexpValue]) -> SexpValue

///|
struct SexpScriptParser[T] {
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
pub impl Eq for SexpValue with equal(lhs, rhs) {
  match (lhs, rhs) {
    (Bool(a), Bool(b)) => a == b
    (Int(a), Int(b)) => a == b
    (Double(a), Double(b)) => a == b
    (String(a), String(b)) => a == b
    (Int(a), Double(b)) => a.to_double() == b
    (Double(a), Int(b)) => a == b.to_double()
    _ => false
  }
}

///|
pub impl Show for SexpValue with output(value, logger) {
  logger.write_string(
    match value {
      String(s) => s
      Int(i) => i.to_string()
      Double(d) => d.to_string()
      Bool(b) => if b { "true" } else { "false" }
      Undefined => ""
    },
  )
}

///|
pub fn SexpValue::to_int(value : SexpValue) -> Int {
  match value {
    Int(i) => i
    Double(d) => d.to_int()
    Bool(b) => if b { 1 } else { 0 }
    String(s) => @string.parse_int(s) catch { _ => 0 }
    Undefined => 0
  }
}

///|
pub fn SexpValue::to_double(value : SexpValue) -> Double {
  match value {
    Double(d) => d
    Int(i) => i.to_double()
    Bool(b) => if b { 1.0 } else { 0.0 }
    String(s) => @string.parse_double(s) catch { _ => 0.0 }
    Undefined => 0.0
  }
}

///|
pub fn SexpValue::to_bool(value : SexpValue) -> Bool {
  match value {
    Bool(b) => b
    Int(i) => i != 0
    Double(d) => d != 0.0
    String(s) => {
      let lowered = s.trim().to_lower()
      !(lowered == "" || lowered == "false" || lowered == "0")
    }
    Undefined => false
  }
}

///|
fn[T] std_eq(_ : @state.GameState[T], args : ArrayView[SexpValue]) -> SexpValue {
  match args {
    [lhs, rhs] => Bool(lhs == rhs)
    _ => Undefined
  }
}

///|
fn[T] std_neq(
  _ : @state.GameState[T],
  args : ArrayView[SexpValue],
) -> SexpValue {
  match args {
    [lhs, rhs] => Bool(lhs != rhs)
    _ => Undefined
  }
}

///|
fn[T] std_not(
  _ : @state.GameState[T],
  args : ArrayView[SexpValue],
) -> SexpValue {
  match args {
    [v] => Bool(!v.to_bool())
    _ => Undefined
  }
}

///|
fn[T] std_and(
  _ : @state.GameState[T],
  args : ArrayView[SexpValue],
) -> SexpValue {
  Bool(args.all(SexpValue::to_bool))
}

///|
fn[T] std_or(_ : @state.GameState[T], args : ArrayView[SexpValue]) -> SexpValue {
  Bool(args.any(SexpValue::to_bool))
}

///|
fn[T] std_gt(_ : @state.GameState[T], args : ArrayView[SexpValue]) -> SexpValue {
  match args {
    [lhs, rhs] => Bool(lhs.to_double() > rhs.to_double())
    _ => Undefined
  }
}

///|
fn[T] std_gte(
  _ : @state.GameState[T],
  args : ArrayView[SexpValue],
) -> SexpValue {
  match args {
    [lhs, rhs] => Bool(lhs.to_double() >= rhs.to_double())
    _ => Undefined
  }
}

///|
fn[T] std_lt(_ : @state.GameState[T], args : ArrayView[SexpValue]) -> SexpValue {
  match args {
    [lhs, rhs] => Bool(lhs.to_double() < rhs.to_double())
    _ => Undefined
  }
}

///|
fn[T] std_lte(
  _ : @state.GameState[T],
  args : ArrayView[SexpValue],
) -> SexpValue {
  match args {
    [lhs, rhs] => Bool(lhs.to_double() <= rhs.to_double())
    _ => Undefined
  }
}

///|
fn[T] std_add(
  _ : @state.GameState[T],
  args : ArrayView[SexpValue],
) -> SexpValue {
  Double(args.fold(init=0.0, (acc, arg) => acc + arg.to_double()))
}

///|
fn[T] std_sub(
  _ : @state.GameState[T],
  args : ArrayView[SexpValue],
) -> SexpValue {
  match args {
    [] => Undefined
    [x] => Double(-x.to_double())
    [head, .. rest] =>
      for v in rest; out = head.to_double() {
        continue out - v.to_double()
      } nobreak {
        Double(out)
      }
  }
}

///|
fn[T] std_mul(
  _ : @state.GameState[T],
  args : ArrayView[SexpValue],
) -> SexpValue {
  if args.is_empty() {
    return Undefined
  }
  let mut out = 1.0
  for arg in args {
    out = out * arg.to_double()
  }
  Double(out)
}

///|
fn[T] std_div(
  _ : @state.GameState[T],
  args : ArrayView[SexpValue],
) -> SexpValue {
  match args {
    [lhs, rhs] => {
      let divisor = rhs.to_double()
      if divisor == 0.0 {
        Undefined
      } else {
        Double(lhs.to_double() / divisor)
      }
    }
    _ => Undefined
  }
}

///|
fn[T] std_mod(
  _ : @state.GameState[T],
  args : ArrayView[SexpValue],
) -> SexpValue {
  match args {
    [lhs, rhs] => {
      let divisor = rhs.to_int()
      if divisor == 0 {
        Undefined
      } else {
        Int(lhs.to_int() % divisor)
      }
    }
    _ => Undefined
  }
}

///|
fn[T] std_concat(
  _ : @state.GameState[T],
  args : ArrayView[SexpValue],
) -> SexpValue {
  String(args.iter().map(Show::to_string).join(""))
}

///|
fn[T] std_int_var(
  state : @state.GameState[T],
  args : ArrayView[SexpValue],
) -> SexpValue {
  match args {
    [name] => Int(state.int_var(name.to_string()))
    [name, default_value] =>
      Int(state.int_var(name.to_string(), default_value=default_value.to_int()))
    _ => Undefined
  }
}

///|
fn[T] std_flag(
  state : @state.GameState[T],
  args : ArrayView[SexpValue],
) -> SexpValue {
  match args {
    [name] => Bool(state.flag(name.to_string()))
    _ => Undefined
  }
}

///|
fn[T] std_text_var(
  state : @state.GameState[T],
  args : ArrayView[SexpValue],
) -> SexpValue {
  match args {
    [name] => String(state.text_var(name.to_string()))
    [name, default_value] =>
      String(
        state.text_var(
          name.to_string(),
          default_value=default_value.to_string(),
        ),
      )
    _ => Undefined
  }
}

///|
fn[T] std_set_int(
  state : @state.GameState[T],
  args : ArrayView[SexpValue],
) -> SexpValue {
  match args {
    [name, value] => {
      state.set_int_var(name.to_string(), value.to_int())
      Bool(true)
    }
    _ => Undefined
  }
}

///|
fn[T] std_set_flag(
  state : @state.GameState[T],
  args : ArrayView[SexpValue],
) -> SexpValue {
  match args {
    [name, value] => {
      state.set_flag(name.to_string(), value.to_bool())
      Bool(true)
    }
    _ => Undefined
  }
}

///|
fn[T] std_set_text(
  state : @state.GameState[T],
  args : ArrayView[SexpValue],
) -> SexpValue {
  match args {
    [name, value] => {
      state.set_text_var(name.to_string(), value.to_string())
      Bool(true)
    }
    _ => Undefined
  }
}

///|
fn[T] register_default_functions(parser : SexpScriptParser[T]) -> Unit {
  parser
  ..register_function("=", std_eq)
  ..register_function("!=", std_neq)
  ..register_function("not", std_not)
  ..register_function("and", std_and)
  ..register_function("or", std_or)
  ..register_function(">", std_gt)
  ..register_function(">=", std_gte)
  ..register_function("<", std_lt)
  ..register_function("<=", std_lte)
  ..register_function("+", std_add)
  ..register_function("-", std_sub)
  ..register_function("*", std_mul)
  ..register_function("/", std_div)
  ..register_function("%", std_mod)
  ..register_function("concat", std_concat)
  ..register_function("int-var", std_int_var)
  ..register_function("flag", std_flag)
  ..register_function("text-var", std_text_var)
  ..register_function("set-int", std_set_int)
  ..register_function("set-flag", std_set_flag)
  .register_function("set-text", std_set_text)
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
fn[T] sexp_to_value(
  value : @sexp.Sexp,
  state : @state.GameState[T],
  host_functions : Map[String, SexpHostFunction[T]],
  payload? : SexpValue,
) -> SexpValue {
  match value {
    @sexp.Int(i) => SexpValue::Int(i)
    @sexp.Double(d) => SexpValue::Double(d)
    @sexp.Bool(b) => SexpValue::Bool(b)
    @sexp.String(s) => SexpValue::String(s)
    @sexp.Char(c) => SexpValue::String(c.to_string())
    @sexp.Symbol(sym) =>
      if sym == @sexp.Symbol::new("payload") && payload is Some(payload) {
        payload
      } else {
        SexpValue::String(sym.to_string())
      }
    @sexp.List(xs) =>
      match xs {
        [@sexp.Symbol(fn_name), .. args] => {
          let name = fn_name.to_string()
          match host_functions.get(name) {
            Some(f) => {
              let evaluated = args.map(arg => {
                sexp_to_value(arg, state, host_functions, payload?)
              })
              f(state, evaluated)
            }
            None => Undefined
          }
        }
        _ => Undefined
      }
  }
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
fn is_keyword_token(value : @sexp.Sexp) -> Bool {
  value is @sexp.Symbol(sym) && sym.to_string().has_prefix(":")
}

///|
fn parse_easing(value : @sexp.Sexp) -> Easing? {
  match sexp_as_string(value).unwrap_or("").to_lower() {
    "linear" => Some(Linear)
    "ease-in" | "easein" => Some(EaseIn)
    "ease-out" | "easeout" => Some(EaseOut)
    "ease-in-out" | "easeinout" => Some(EaseInOut)
    _ => None
  }
}

///|
fn parse_anchor(value : @sexp.Sexp) -> (Double, Double)? {
  match value {
    @sexp.List([x, y]) =>
      Some((sexp_as_double(x).unwrap_or(0.5), sexp_as_double(y).unwrap_or(0.5)))
    _ => None
  }
}

///|
fn parse_render_kind(value : @sexp.Sexp) -> RenderableKind {
  match sexp_as_string(value).unwrap_or("").to_lower() {
    "dom" => @assets.Dom
    _ => @assets.Pixi
  }
}

///|
fn parse_render_kind_option(
  parts : ArrayView[@sexp.Sexp],
  start : Int,
) -> RenderableKind {
  let mut kind : RenderableKind = Pixi
  let mut i = start
  while i + 1 < parts.length() {
    match parts[i] {
      @sexp.Symbol(k) if k == @sexp.Symbol::new(":kind") =>
        kind = parse_render_kind(parts[i + 1])
      _ => ()
    }
    i = i + 1
  }
  kind
}

///|
fn parse_anim_options(
  parts : ArrayView[@sexp.Sexp],
  start : Int,
) -> (Easing, Bool, (Double, Double)?) {
  let mut easing = Linear
  let mut blocking = false
  let mut anchor : (Double, Double)? = None
  let mut i = start
  while i + 1 < parts.length() {
    match parts[i] {
      @sexp.Symbol(k) if k == @sexp.Symbol::new(":easing") =>
        easing = parse_easing(parts[i + 1]).unwrap_or(easing)
      @sexp.Symbol(k) if k == @sexp.Symbol::new(":blocking") =>
        blocking = sexp_as_bool(parts[i + 1]).unwrap_or(blocking)
      @sexp.Symbol(k) if k == @sexp.Symbol::new(":anchor") =>
        match parse_anchor(parts[i + 1]) {
          Some(parsed) => anchor = Some(parsed)
          None => ()
        }
      _ => ()
    }
    i = i + 2
  }
  (easing, blocking, anchor)
}

///|
fn build_scalar_anim(
  prop : String,
  duration_ms : Int,
  from : Double?,
  to : Double,
  easing : Easing,
  blocking : Bool,
  anchor : (Double, Double)?,
) -> AnimationSpec? {
  fn with_from(
    from : Double?,
    mk : (Double) -> AnimationSpec,
    mk_no_from : () -> AnimationSpec,
  ) -> AnimationSpec {
    match from {
      Some(v) => mk(v)
      None => mk_no_from()
    }
  }
  match prop {
    "opacity" =>
      Some(
        with_from(
          from,
          v => anim_opacity(duration_ms, from=v, to, easing~, blocking~),
          () => anim_opacity(duration_ms, to, easing~, blocking~),
        ),
      )
    "scale" =>
      Some(
        with_from(
          from,
          v => {
            anim_scale(
              duration_ms,
              from=v,
              to,
              anchor=anchor.unwrap_or((0.5, 0.5)),
              easing~,
              blocking~,
            )
          },
          () => {
            anim_scale(
              duration_ms,
              to,
              anchor=anchor.unwrap_or((0.5, 0.5)),
              easing~,
              blocking~,
            )
          },
        ),
      )
    "rotation" =>
      Some(
        with_from(
          from,
          v => anim_rotation(duration_ms, from=v, to, easing~, blocking~),
          () => anim_rotation(duration_ms, to, easing~, blocking~),
        ),
      )
    "blur" =>
      Some(
        with_from(
          from,
          v => anim_blur(duration_ms, from=v, to, easing~, blocking~),
          () => anim_blur(duration_ms, to, easing~, blocking~),
        ),
      )
    "brightness" =>
      Some(
        with_from(
          from,
          v => anim_brightness(duration_ms, from=v, to, easing~, blocking~),
          () => anim_brightness(duration_ms, to, easing~, blocking~),
        ),
      )
    "contrast" =>
      Some(
        with_from(
          from,
          v => anim_contrast(duration_ms, from=v, to, easing~, blocking~),
          () => anim_contrast(duration_ms, to, easing~, blocking~),
        ),
      )
    "saturation" =>
      Some(
        with_from(
          from,
          v => anim_saturation(duration_ms, from=v, to, easing~, blocking~),
          () => anim_saturation(duration_ms, to, easing~, blocking~),
        ),
      )
    "gamma" =>
      Some(
        with_from(
          from,
          v => anim_gamma(duration_ms, from=v, to, easing~, blocking~),
          () => anim_gamma(duration_ms, to, easing~, blocking~),
        ),
      )
    "color-red" =>
      Some(
        with_from(
          from,
          v => anim_color_red(duration_ms, from=v, to, easing~, blocking~),
          () => anim_color_red(duration_ms, to, easing~, blocking~),
        ),
      )
    "color-green" =>
      Some(
        with_from(
          from,
          v => anim_color_green(duration_ms, from=v, to, easing~, blocking~),
          () => anim_color_green(duration_ms, to, easing~, blocking~),
        ),
      )
    "color-blue" =>
      Some(
        with_from(
          from,
          v => anim_color_blue(duration_ms, from=v, to, easing~, blocking~),
          () => anim_color_blue(duration_ms, to, easing~, blocking~),
        ),
      )
    _ => None
  }
}

///|
fn parse_anim_spec(
  prop : String,
  duration_ms : Int,
  parts : ArrayView[@sexp.Sexp],
  value_start : Int,
) -> AnimationSpec? {
  if prop == "position" {
    if parts.length() <= value_start {
      return None
    }
    let mut from : Position? = None
    let mut to_index = value_start
    let mut option_start = value_start + 1
    if parts.length() > value_start + 1 &&
      !is_keyword_token(parts[value_start + 1]) {
      from = parts[value_start] |> parse_position |> Some
      to_index = value_start + 1
      option_start = value_start + 2
    }
    if is_keyword_token(parts[to_index]) {
      return None
    }
    let (easing, blocking, _) = parse_anim_options(parts, option_start)
    return Some(
      anim_position(
        duration_ms,
        parse_position(parts[to_index]),
        from?,
        easing~,
        blocking~,
      ),
    )
  }
  if parts.length() <= value_start {
    return None
  }
  let mut from : Double? = None
  let mut to_index = value_start
  let mut option_start = value_start + 1
  if parts.length() > value_start + 1 &&
    !is_keyword_token(parts[value_start + 1]) {
    from = Some(sexp_as_double(parts[value_start]).unwrap_or(0.0))
    to_index = value_start + 1
    option_start = value_start + 2
  }
  if is_keyword_token(parts[to_index]) {
    return None
  }
  let (easing, blocking, anchor) = parse_anim_options(parts, option_start)
  build_scalar_anim(
    prop,
    duration_ms,
    from,
    sexp_as_double(parts[to_index]).unwrap_or(0.0),
    easing,
    blocking,
    anchor,
  )
}

///|
fn parse_group_animation_step(item : @sexp.Sexp) -> GroupStep? {
  match item {
    @sexp.List([prop, duration, .. rest]) => {
      let parts = [prop, duration, ..rest]
      let p = sexp_as_string(prop).unwrap_or("").to_lower()
      let dur = sexp_as_int(duration).unwrap_or(0)
      parse_anim_spec(p, dur, parts, 2).map(spec => GroupStep::Animate(spec))
    }
    _ => None
  }
}

///|
fn parse_effect_phase(value : @sexp.Sexp) -> EffectPhase {
  match sexp_as_string(value).unwrap_or("").to_lower() {
    "pre" => Pre
    _ => Post
  }
}

///|
fn parse_effect_spec(
  effect_id : String,
  raw_items : ArrayView[@sexp.Sexp],
) -> EffectSpec? {
  if effect_id == "" {
    return None
  }
  let params : Array[EffectParam] = []
  let mut phase = Post
  let mut duration_ms : Int? = None
  let mut easing = Linear
  let mut blocking = false
  let mut i = 0
  while i < raw_items.length() {
    match raw_items[i] {
      @sexp.List([k, v]) => {
        let key = sexp_as_string(k).unwrap_or("")
        if key != "" {
          params.push((key, sexp_as_double(v).unwrap_or(0.0)))
        }
        i = i + 1
      }
      @sexp.Symbol(k) if i + 1 < raw_items.length() =>
        if k == @sexp.Symbol::new(":phase") {
          phase = parse_effect_phase(raw_items[i + 1])
          i = i + 2
        } else if k == @sexp.Symbol::new(":duration") {
          duration_ms = Some(sexp_as_int(raw_items[i + 1]).unwrap_or(0))
          i = i + 2
        } else if k == @sexp.Symbol::new(":easing") {
          easing = parse_easing(raw_items[i + 1]).unwrap_or(easing)
          i = i + 2
        } else if k == @sexp.Symbol::new(":blocking") {
          blocking = sexp_as_bool(raw_items[i + 1]).unwrap_or(blocking)
          i = i + 2
        } else {
          i = i + 1
        }
      _ => i = i + 1
    }
  }
  Some({ id: effect_id, params, phase, duration_ms, easing, blocking })
}

///|
fn parse_mixed_group_effect_step(item : @sexp.Sexp) -> GroupStep? {
  match item {
    @sexp.List([@sexp.Symbol(tag), effect_id, .. rest]) => {
      if tag != @sexp.Symbol::new("effect") {
        return None
      }
      let id = sexp_as_string(effect_id).unwrap_or("")
      parse_effect_spec(id, rest).map(spec => GroupStep::Effect(spec))
    }
    _ => None
  }
}

///|
fn parse_mixed_group_step(item : @sexp.Sexp) -> GroupStep? {
  match parse_mixed_group_effect_step(item) {
    Some(step) => Some(step)
    None => parse_group_animation_step(item)
  }
}

///|
fn parse_scalar_key(key : String) -> String {
  key.to_lower()
}

///|
fn parse_show_figure_options(
  rest : ArrayView[@sexp.Sexp],
) -> (Int, ScalarState, Bool, RenderableKind) {
  let mut layer = 0
  let mut interactive = false
  let mut kind : RenderableKind = Pixi
  let mut scalars = ScalarState::default()
  let mut i = 0
  while i + 1 < rest.length() {
    match rest[i] {
      @sexp.Symbol(k) => {
        let key = parse_scalar_key(k.to_string())
        if key == ":layer" {
          layer = sexp_as_int(rest[i + 1]).unwrap_or(layer)
        } else if key == ":interactive" {
          interactive = sexp_as_bool(rest[i + 1]).unwrap_or(interactive)
        } else if key == ":kind" {
          kind = parse_render_kind(rest[i + 1])
        } else if key == ":opacity" {
          scalars = {
            ..scalars,
            opacity: sexp_as_double(rest[i + 1]).unwrap_or(scalars.opacity),
          }
        } else if key == ":scale" {
          scalars = {
            ..scalars,
            scale: sexp_as_double(rest[i + 1]).unwrap_or(scalars.scale),
          }
        } else if key == ":rotation" {
          scalars = {
            ..scalars,
            rotation: sexp_as_double(rest[i + 1]).unwrap_or(scalars.rotation),
          }
        } else if key == ":blur" {
          scalars = {
            ..scalars,
            blur: sexp_as_double(rest[i + 1]).unwrap_or(scalars.blur),
          }
        } else if key == ":brightness" {
          scalars = {
            ..scalars,
            brightness: sexp_as_double(rest[i + 1]).unwrap_or(
              scalars.brightness,
            ),
          }
        } else if key == ":contrast" {
          scalars = {
            ..scalars,
            contrast: sexp_as_double(rest[i + 1]).unwrap_or(scalars.contrast),
          }
        } else if key == ":saturation" {
          scalars = {
            ..scalars,
            saturation: sexp_as_double(rest[i + 1]).unwrap_or(
              scalars.saturation,
            ),
          }
        } else if key == ":gamma" {
          scalars = {
            ..scalars,
            gamma: sexp_as_double(rest[i + 1]).unwrap_or(scalars.gamma),
          }
        } else if key == ":color-r" || key == ":color-red" {
          scalars = {
            ..scalars,
            color_r: sexp_as_double(rest[i + 1]).unwrap_or(scalars.color_r),
          }
        } else if key == ":color-g" || key == ":color-green" {
          scalars = {
            ..scalars,
            color_g: sexp_as_double(rest[i + 1]).unwrap_or(scalars.color_g),
          }
        } else if key == ":color-b" || key == ":color-blue" {
          scalars = {
            ..scalars,
            color_b: sexp_as_double(rest[i + 1]).unwrap_or(scalars.color_b),
          }
        }
      }
      _ => ()
    }
    i = i + 2
  }
  (layer, scalars, interactive, kind)
}

///|
fn parse_choice_options(items : ArrayView[@sexp.Sexp]) -> Array[ChoiceOption] {
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
            option(
              txt,
              label(name=tgt),
              id=match id {
                "" => txt
                _ => id
              },
            ),
          )
        }
      }
      _ => ()
    }
  }
  out
}

///|
fn[T] lower_scene_figure_command(
  cmd : String,
  args : ArrayView[@sexp.Sexp],
  builder : ScriptBuilder[T],
) -> Unit {
  match cmd {
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
        [id, pos, .. rest] => {
          let target = sexp_as_string(id).unwrap_or("")
          if target != "" {
            let (layer, scalars, interactive, kind) = parse_show_figure_options(
              rest,
            )
            let placement = { pos: parse_position(pos), layer, scalars }
            if kind is @assets.Dom {
              builder.instructions.push(
                ShowDomFigure(target, placement, interactive),
              )
            } else {
              builder.instructions.push(ShowFigure(target, placement))
            }
          }
        }
        _ => ()
      }
    "set-figure-interactive" =>
      match args {
        [id, interactive] => {
          let target = sexp_as_string(id).unwrap_or("")
          if target != "" {
            builder.instructions.push(
              SetDomFigureInteractive(
                target,
                sexp_as_bool(interactive).unwrap_or(false),
              ),
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
    _ => ()
  }
}

///|
fn[T] lower_group_command(
  args : ArrayView[@sexp.Sexp],
  parse_step : (@sexp.Sexp) -> GroupStep?,
  builder : ScriptBuilder[T],
) -> Unit {
  match args {
    [target, .. step_items] => {
      let t = sexp_as_string(target).unwrap_or("")
      if t != "" {
        let mut kind : RenderableKind = Pixi
        let steps : Array[GroupStep] = []
        for item in step_items {
          if !(item is @sexp.Symbol(k) && k == @sexp.Symbol::new(":kind")) {
            match parse_step(item) {
              Some(step) => steps.push(step)
              None => ()
            }
          }
        }
        let mut i = 0
        while i + 1 < step_items.length() {
          match step_items[i] {
            @sexp.Symbol(k) if k == @sexp.Symbol::new(":kind") =>
              kind = parse_render_kind(step_items[i + 1])
            _ => ()
          }
          i = i + 2
        }
        if !steps.is_empty() {
          builder.instructions.push(AnimateGroup(t, steps, kind))
        }
      }
    }
    _ => ()
  }
}

///|
fn[T] lower_effect_animation_command(
  cmd : String,
  args : ArrayView[@sexp.Sexp],
  builder : ScriptBuilder[T],
) -> Unit {
  match cmd {
    "effect" =>
      match args {
        [target, effect_id, .. rest] => {
          let t = sexp_as_string(target).unwrap_or("")
          let e = sexp_as_string(effect_id).unwrap_or("")
          if t != "" {
            match parse_effect_spec(e, rest) {
              Some(spec) => builder.instructions.push(ApplyEffect(t, spec))
              None => ()
            }
          }
        }
        _ => ()
      }
    "animate" =>
      match args {
        [target, prop, duration, ..] => {
          let t = sexp_as_string(target).unwrap_or("")
          let p = sexp_as_string(prop).unwrap_or("").to_lower()
          let dur = sexp_as_int(duration).unwrap_or(0)
          if t != "" {
            let kind = parse_render_kind_option(args, 3)
            match parse_anim_spec(p, dur, args, 3) {
              Some(spec) => builder.instructions.push(Animate(t, spec, kind))
              None => ()
            }
          }
        }
        _ => ()
      }
    "animate-group" =>
      lower_group_command(args, parse_group_animation_step, builder)
    "mixed-group" => lower_group_command(args, parse_mixed_group_step, builder)
    _ => ()
  }
}

///|
fn[T] lower_flow_command(
  cmd : String,
  args : ArrayView[@sexp.Sexp],
  builder : ScriptBuilder[T],
  host_functions : Map[String, SexpHostFunction[T]],
) -> Unit {
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
              let value = sexp_to_value(predicate, state, host_functions)
              value.to_bool()
            })
          }
        }
        _ => ()
      }
    "branch" =>
      match args {
        [then_target, else_target, predicate] => {
          let then_name = sexp_as_string(then_target).unwrap_or("")
          let else_name = sexp_as_string(else_target).unwrap_or("")
          if then_name != "" && else_name != "" {
            builder.branch(label(name=then_name), label(name=else_name), state => {
              let value = sexp_to_value(predicate, state, host_functions)
              value.to_bool()
            })
          }
        }
        _ => ()
      }
    "jump-by" =>
      match args {
        [selector] =>
          builder.jump_by(state => {
            let value = sexp_to_value(selector, state, host_functions)
            let target = match value {
              String(s) => s
              _ => ""
            }
            label(name=target)
          })
        _ => ()
      }
    "run-code" =>
      match args {
        [expr] =>
          builder.run_code(state => {
            ignore(sexp_to_value(expr, state, host_functions))
          })
        _ => ()
      }
    "wait-custom-event" =>
      match args {
        [name, predicate] => {
          let event_name = sexp_as_string(name).unwrap_or("")
          if event_name != "" {
            builder.wait_custom_event(event_name, (state, payload_text) => {
              let payload = SexpValue::String(payload_text)
              let value = sexp_to_value(
                predicate,
                state,
                host_functions,
                payload~,
              )
              value.to_bool()
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
              let payload = SexpValue::String(payload_text)
              let value = sexp_to_value(
                selector,
                state,
                host_functions,
                payload~,
              )
              let target = match value {
                String(s) => s
                _ => ""
              }
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
    _ => ()
  }
}

///|
fn[T] lower_dialog_command(
  cmd : String,
  args : ArrayView[@sexp.Sexp],
  builder : ScriptBuilder[T],
) -> Unit {
  match cmd {
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
    "say-many" =>
      match args {
        [speaker, @sexp.List(text_items), .. rest] => {
          let sp = sexp_as_string(speaker).unwrap_or("")
          let texts = text_items.filter_map(sexp_as_string)
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
          if !texts.is_empty() {
            builder.say_many(sp, texts, typewriter~, append~, voice~)
          }
        }
        _ => ()
      }
    "narrate" =>
      match args {
        [text] => builder.narrate(sexp_as_string(text).unwrap_or(""))
        _ => ()
      }
    _ => ()
  }
}

///|
fn[T] lower_media_command(
  cmd : String,
  args : ArrayView[@sexp.Sexp],
  builder : ScriptBuilder[T],
) -> Unit {
  match cmd {
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
              SetLive2dExpression(id, Some(sexp_as_string(expr).unwrap_or(""))),
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
    _ => ()
  }
}

///|
fn[T] lower_ui_command(
  cmd : String,
  args : ArrayView[@sexp.Sexp],
  builder : ScriptBuilder[T],
) -> Unit {
  match cmd {
    "show-text-box" => builder.show_text_box()
    "hide-text-box" => builder.hide_text_box()
    "show-avatar" =>
      match args {
        [url] => builder.show_avatar(sexp_as_string(url).unwrap_or(""))
        _ => ()
      }
    "hide-avatar" => builder.hide_avatar()
    _ => ()
  }
}

///|
fn[T] lower_choice_input_command(
  cmd : String,
  args : ArrayView[@sexp.Sexp],
  builder : ScriptBuilder[T],
) -> Unit {
  match cmd {
    "choice" => {
      let options = parse_choice_options(args)
      if !options.is_empty() {
        builder.choice(options)
      }
    }
    "menu" =>
      match args {
        [speaker, prompt, .. items] => {
          let sp = sexp_as_string(speaker).unwrap_or("")
          let pr = sexp_as_string(prompt).unwrap_or("")
          let options = parse_choice_options(items)
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
        "label"
        | "jump"
        | "jump-if"
        | "branch"
        | "jump-by"
        | "run-code"
        | "wait-custom-event"
        | "wait-custom-event-jump"
        | "wait"
        | "wait-click"
        | "unlock-cg"
        | "intro" => lower_flow_command(cmd, args, builder, host_functions)
        "show-text-box" | "hide-text-box" | "show-avatar" | "hide-avatar" =>
          lower_ui_command(cmd, args, builder)
        "say" | "say-many" | "narrate" =>
          lower_dialog_command(cmd, args, builder)
        "scene" | "show-figure" | "set-figure-interactive" | "hide-figure" =>
          lower_scene_figure_command(cmd, args, builder)
        "play-live2d-motion"
        | "set-live2d-expression"
        | "play-music"
        | "stop-music"
        | "play-sfx"
        | "play-video" => lower_media_command(cmd, args, builder)
        "effect" | "animate" | "animate-group" | "mixed-group" =>
          lower_effect_animation_command(cmd, args, builder)
        "choice" | "menu" | "input-text" =>
          lower_choice_input_command(cmd, args, builder)
        _ => ()
      }
    }
    _ => ()
  }
}

///|
pub fn[T] SexpScriptParser::to_builder(
  parser : SexpScriptParser[T],
  forms : ArrayView[@sexp.Sexp],
  builder : ScriptBuilder[T],
) -> Unit {
  for form in forms {
    lower_form(form, builder, parser.host_functions)
  }
}

///|
pub fn[T] SexpScriptParser::to_builder_with_text(
  parser : SexpScriptParser[T],
  text : String,
  builder : ScriptBuilder[T],
) -> Unit raise ScriptBuildError {
  let forms = @sexp.parse_many(text) catch {
    err => raise SexpParseError(message=err.to_string())
  }
  parser.to_builder(forms, builder)
}

///|
pub fn[T] reisen_parse_sexp_script(
  text : String,
  parser? : SexpScriptParser[T] = SexpScriptParser::new(),
) -> Script[T] raise ScriptBuildError {
  let builder : ScriptBuilder[T] = ScriptBuilder::new()
  parser.to_builder_with_text(text, builder)
  builder.build()
}
