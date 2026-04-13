///|
using @core {type EffectSpec, type EffectPhase, type Easing, type ScalarState}

///|
fn mk_effect(
  id : String,
  params : Array[(String, Double)],
  duration_ms? : Int,
  easing? : Easing = @core.Easing::Linear,
  phase? : EffectPhase = @core.EffectPhase::Post,
) -> EffectSpec {
  { id, params, phase, duration_ms, easing, blocking: false }
}

///|
test "selene effects apply supported scalar params" {
  let presenter = SelenePresenter::new()
  let base = ScalarState::default()
  let effect = mk_effect("fade", [("opacity", 0.3)])
  let result = presenter.apply_effects_to_scalars(
    "alice",
    base,
    [effect],
    false,
  )
  assert_eq(result.scalars.opacity, 0.3)
  assert_false(result.has_active_timed_effect)
  assert_true(result.active_effect_keys.contains("alice::fade"))
}

///|
test "selene effects track timed progress flag" {
  let presenter = SelenePresenter::new()
  let base = ScalarState::default()
  let effect = mk_effect("flash", [("brightness", 1.5)], duration_ms=200)
  let active = presenter.apply_effects_to_scalars("bg", base, [effect], false)
  assert_true(active.has_active_timed_effect)
  let done = presenter.apply_effects_to_scalars("bg", base, [effect], true)
  assert_false(done.has_active_timed_effect)
}

///|
test "selene effects warn once for unsupported params" {
  let presenter = SelenePresenter::new()
  let base = ScalarState::default()
  let effect = mk_effect("custom_fx", [("contrast", 1.2)])
  ignore(presenter.apply_effects_to_scalars("alice", base, [effect], false))
  ignore(presenter.apply_effects_to_scalars("alice", base, [effect], false))
  assert_true(presenter.warned_capabilities.contains("effect-param::contrast"))
  assert_true(presenter.warned_capabilities.contains("effect-id::custom_fx"))
}
