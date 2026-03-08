///|
/// Fluent builder for authoring `Script[T]` in MoonBit DSL style.

///|
using @pixi {type Effect}

///|
struct ScriptBuilder[T] {
  instructions : Array[Instruction[T]]
}

///|
/// Convenience entrypoint for the DSL style:
/// `let s = script(builder => { ... })`.
pub fn[T] script(
  f : (ScriptBuilder[T]) -> Unit,
) -> Script[T] raise ScriptBuildError {
  let builder : ScriptBuilder[T] = ScriptBuilder::new()
  f(builder)
  builder.build()
}

///|
pub fn[T] ScriptBuilder::new() -> ScriptBuilder[T] {
  { instructions: [] }
}

///|
pub fn[T] ScriptBuilder::scene(
  self : ScriptBuilder[T],
  bg : Background,
  scalars? : ScalarState,
) -> Unit {
  match scalars {
    Some(s) =>
      self.instructions.push(ShowBackgroundState({ id: bg.id, scalars: s }))
    None => self.instructions.push(ShowBackground(bg.id))
  }
}

///|
fn[T, F : @assets.Figure] ScriptBuilder::emit_show_figure(
  self : ScriptBuilder[T],
  figure : F,
  placement : FigurePlacement,
  interactive : Bool,
) -> Unit {
  match figure.kind() {
    @assets.Pixi => self.instructions.push(ShowFigure(figure.id(), placement))
    @assets.Dom =>
      self.instructions.push(ShowDomFigure(figure.id(), placement, interactive))
  }
}

///|
pub fn[T, F : @assets.Figure] ScriptBuilder::show_figure(
  self : ScriptBuilder[T],
  figure : F,
  placement : FigurePlacement,
  interactive? : Bool = false,
) -> Unit {
  self.emit_show_figure(figure, placement, interactive)
}

///|
pub fn[T, F : @assets.Figure] ScriptBuilder::show_figure_at(
  self : ScriptBuilder[T],
  figure : F,
  pos : Position,
  layer? : Int = 0,
  scalars? : ScalarState = ScalarState::default(),
  interactive? : Bool = false,
) -> Unit {
  self.emit_show_figure(figure, { pos, layer, scalars }, interactive)
}

///|
pub fn[T, F : @assets.Figure] ScriptBuilder::hide_figure(
  self : ScriptBuilder[T],
  figure : F,
) -> Unit {
  match figure.kind() {
    @assets.Pixi => self.instructions.push(HideFigure(figure.id()))
    @assets.Dom => self.instructions.push(HideDomFigure(figure.id()))
  }
}

///|
pub fn[T] ScriptBuilder::set_figure_interactive(
  self : ScriptBuilder[T],
  figure : DomFigure,
  interactive : Bool,
) -> Unit {
  self.instructions.push(SetDomFigureInteractive(figure.id(), interactive))
}

///|
pub fn[T] ScriptBuilder::load_sexp_text(
  self : ScriptBuilder[T],
  text : String,
  parser? : SexpScriptParser[T] = SexpScriptParser::new(),
) -> Unit raise ScriptBuildError {
  parser.to_builder_with_text(text, self)
}

///|
pub fn[T] ScriptBuilder::load_sexp(
  self : ScriptBuilder[T],
  forms : ArrayView[@sexp.Sexp],
  parser? : SexpScriptParser[T] = SexpScriptParser::new(),
) -> Unit {
  parser.to_builder(forms, self)
}

///|
pub async fn[T] ScriptBuilder::load_sexp_file(
  self : ScriptBuilder[T],
  path : String,
  parser? : SexpScriptParser[T] = SexpScriptParser::new(),
) -> Unit {
  let text = @assets.load_text(path)
  parser.to_builder_with_text(text, self)
}

///|
pub fn[T] ScriptBuilder::build(
  self : ScriptBuilder[T],
) -> Script[T] raise ScriptBuildError {
  script_from_instructions(self.instructions)
}
