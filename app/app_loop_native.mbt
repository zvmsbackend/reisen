///|
pub fn[T : FromJson + ToJson] run_native_app_loop(
  app : AppController[T],
  ui_locale_path? : String = "locales/ui.json",
  script_locale_dir? : String = "locales",
  idle_render? : () -> Unit = () => (),
  config? : @selene_runtime.NativeLoopConfig = @selene_runtime.NativeLoopConfig::default(),
) -> Unit {
  let localization = preload_localization(
    save_namespace=app.save_ns,
    languages=app.languages,
    ui_locale_path~,
    script_locale_dir~,
  )
  app.set_localization_payload(
    ui_locales_json=localization.ui_locales_json,
    script_locale_json=localization.script_locale_json,
    script_default_locale_json=localization.script_default_locale_json,
  )
  let mut keep_running = true
  fn on_tick(dt) {
    keep_running = app.tick(elapsed_ms=dt) catch {
      error => {
        default_app_error_handler(error.message())
        false
      }
    }
  }
  @selene_runtime.run_native_loop_with_selene(
    _ => keep_running,
    on_render=dt => {
      if keep_running {
        idle_render()
      }
      on_tick(clamp_non_negative_ms(dt))
    },
    config~,
  )
}

///|
fn clamp_non_negative_ms(raw_delta_seconds : Double) -> Int {
  if raw_delta_seconds <= 0.0 {
    0
  } else {
    @math.floor(raw_delta_seconds * 1000.0).to_int()
  }
}
