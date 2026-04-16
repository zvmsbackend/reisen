///|
pub fn[T] run_native_loop(
  runner : GameRunner[T],
  config? : @selene_runtime.NativeLoopConfig = @selene_runtime.NativeLoopConfig::default(),
) -> Unit {
  @selene_runtime.run_native_loop_with_selene(
    dt => runner.tick(elapsed_ms=dt),
    config~,
  )
}

///|
pub fn[T : FromJson + ToJson] run_native_app_loop(
  app : AppController[T],
  ui_locale_path? : String = "locales/ui.json",
  script_locale_dir? : String = "locales",
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
  @selene_runtime.run_native_loop_with_selene(
    dt => {
      app.tick(elapsed_ms=dt) catch {
        error => {
          default_app_error_handler(error.message())
          false
        }
      }
    },
    config~,
  )
}
