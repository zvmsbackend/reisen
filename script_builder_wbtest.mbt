///|
test "builder duplicate label raises" {
  let built : Result[Script[Int], ScriptBuildError] =
    try? ScriptBuilder::new()
    ..label("start")
    ..label("start")
    .build()

  assert_true(built is Err(ScriptBuildError::DuplicateLabel(name="start")))
}
