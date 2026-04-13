///|
pub(all) enum DialogText {
  String(String)
  Concat(Array[DialogText])
  Interpolation(String)
  Enhanced(DialogText, style~ : String)
  Ruby(String, ruby~ : String)
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn DialogText::empty() -> DialogText {
  String("")
}

///|
pub fn DialogText::new(text : String) -> DialogText {
  let parts : Array[DialogText] = []
  let buf = StringBuilder::new()
  let chars = text.to_array()
  let len = chars.length()
  let mut i = 0

  fn flush_buf() {
    let s = buf.to_string()
    if !s.is_empty() {
      parts.push(String(s))
      buf.reset()
    }
  }

  fn read_until(start : Int, stop : Char) -> (String, Int)? {
    let inner = StringBuilder::new()
    let mut j = start
    while j < len && chars[j] != stop {
      inner.write_char(chars[j])
      j += 1
    }
    if j < len {
      Some((inner.to_string(), j))
    } else {
      None
    }
  }

  while i < len {
    let c = chars[i]
    match c {
      '[' =>
        // Try to parse [base](ruby) or [base]{style}
        match read_until(i + 1, ']') {
          None => {
            buf.write_char('[')
            i += 1
          }
          Some((base_text, close_bracket)) => {
            let after = close_bracket + 1
            if after < len && chars[after] == '(' {
              match read_until(after + 1, ')') {
                Some((ruby_text, close_paren)) => {
                  flush_buf()
                  parts.push(Ruby(base_text, ruby=ruby_text))
                  i = close_paren + 1
                }
                None => {
                  buf.write_char('[')
                  i += 1
                }
              }
            } else if after < len && chars[after] == '{' {
              match read_until(after + 1, '}') {
                Some((style_text, close_brace)) => {
                  flush_buf()
                  parts.push(
                    Enhanced(DialogText::new(base_text), style=style_text),
                  )
                  i = close_brace + 1
                }
                None => {
                  buf.write_char('[')
                  i += 1
                }
              }
            } else {
              buf.write_char('[')
              i += 1
            }
          }
        }
      '{' =>
        // Try to parse {varname} interpolation
        match read_until(i + 1, '}') {
          Some((var_name, close_brace)) => {
            flush_buf()
            parts.push(Interpolation(var_name))
            i = close_brace + 1
          }
          None => {
            buf.write_char(c)
            i += 1
          }
        }
      _ => {
        buf.write_char(c)
        i += 1
      }
    }
  }
  flush_buf()
  match parts.length() {
    0 => String("")
    1 => parts[0]
    _ => Concat(parts)
  }
}

///|
pub fn DialogText::raw_text(self : DialogText) -> String {
  let result = StringBuilder::new()
  fn walk(text) {
    match text {
      String(s) => result.write_string(s)
      Concat(parts) => parts.each(walk)
      Interpolation(var_name) => result.write_string("{\{var_name}}")
      Enhanced(base, ..) => walk(base)
      Ruby(base, ..) => result.write_string(base)
    }
  }
  walk(self)
  result.to_string()
}

///|
pub fn DialogText::length(self : DialogText) -> Int {
  match self {
    String(s) => s.length()
    Concat(parts) => parts.fold(init=0, (acc, part) => acc + part.length())
    Interpolation(_) => 0
    Enhanced(base, ..) => base.length()
    Ruby(base, ..) => base.length()
  }
}

///|
pub fn DialogText::is_empty(self : DialogText) -> Bool {
  match self {
    String(s) => s.is_empty()
    Concat(parts) => parts.all(part => part.is_empty())
    Interpolation(_) => false
    Enhanced(base, ..) => base.is_empty()
    Ruby(base, ..) => base.is_empty()
  }
}

///|
pub fn DialogText::render(self : DialogText) -> String {
  let result = StringBuilder::new()
  fn walk(text : DialogText, parent_style : String) {
    match text {
      String(s) => result.write_string(escape_html(s))
      Concat(parts) => parts.each(part => walk(part, parent_style))
      Interpolation(var_name) => result.write_string("{\{var_name}}")
      Enhanced(base, style~) => {
        let combined = if parent_style.is_empty() {
          style
        } else {
          "\{style}; \{parent_style}"
        }
        result
        ..write_string("<span style=\"")
        ..write_string(combined)
        .write_string("\">")
        walk(base, combined)
        result.write_string("</span>")
      }
      Ruby(base, ruby~) =>
        result
        ..write_string("<ruby>")
        ..write_string(escape_html(base))
        ..write_string("<rp>(</rp><rt>")
        ..write_string(escape_html(ruby))
        ..write_string("</rt><rp>)</rp>")
        .write_string("</ruby>")
    }
  }
  walk(self, "")
  result.to_string()
}

///|
pub fn DialogText::slice(self : DialogText, end : Int) -> DialogText {
  let mut remaining = end
  fn slice_string(s : String) {
    if remaining > s.length() {
      remaining -= s.length()
      s
    } else {
      let result = s[:remaining].to_string()
      remaining = 0
      result
    }
  }
  fn walk(text : DialogText) -> DialogText {
    guard remaining > 0 else { return String("") }
    match text {
      String(s) => s |> slice_string |> String
      Concat(parts) => {
        let result_parts = []
        for part in parts {
          if remaining <= 0 {
            break
          }
          result_parts.push(walk(part))
        }
        Concat(result_parts)
      }
      Interpolation(_) => self
      Enhanced(base, style~) => Enhanced(walk(base), style~)
      Ruby(base, ruby~) => Ruby(slice_string(base), ruby~)
    }
  }
  walk(self)
}

///|
pub impl Add for DialogText with add(self, other) {
  match (self, other) {
    (String(s1), String(s2)) => String(s1 + s2)
    (Concat(parts1), Concat(parts2)) => Concat(parts1 + parts2)
    (Concat(parts), other) => Concat(parts + [other])
    (other, Concat(parts)) => Concat([other] + parts)
    (self, other) => Concat([self, other])
  }
}
