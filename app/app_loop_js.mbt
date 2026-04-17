///|
extern "js" fn raf_promise() -> @js_async.Promise[Double] =
  #| () => new Promise(resolve => {
  #|   requestAnimationFrame(resolve);
  #| })

///|
async fn[E : Error] run_browser_loop_impl(
  on_tick : async (Int) -> Bool raise E,
) -> Unit raise E {
  for last = 0.0 {
    let ts = @js_async.Promise::wait(raf_promise()) catch {
      @js.Error_(msg) => abort(msg.to_string())
      _ => panic()
    }
    let dt = if last == 0 {
      0
    } else {
      @cmp.maximum(0, @math.floor(ts - last).to_int())
    }
    if on_tick(dt) {
      continue ts
    } else {
      break
    }
  }
}

///|
pub async fn[E : Error] run_browser_loop_port(
  on_tick : async (Int) -> Bool raise E,
) -> Unit raise E {
  run_browser_loop_impl(on_tick)
}

///|
pub async fn[T : FromJson + ToJson] run_browser_app_loop(
  app : AppController[T],
  ui_locale_path? : String = "locales/ui.json",
  script_locale_dir? : String = "locales",
) -> Unit {
  let localization = preload_localization(
    save_namespace=app.save_ns,
    languages=app.languages,
    ui_locale_path~,
    script_locale_dir~,
  ) catch {
    LocalizationLoadFailed(message~) => {
      log_app_warn("failed to preload localization: \{message}")
      {
        locale: app.locale,
        default_locale: app.default_locale,
        ui_locales_json: "",
        script_locale_json: "",
        script_default_locale_json: "",
      }
    }
    _ =>
      {
        locale: app.locale,
        default_locale: app.default_locale,
        ui_locales_json: "",
        script_locale_json: "",
        script_default_locale_json: "",
      }
  }
  app.set_localization_payload(
    ui_locales_json=localization.ui_locales_json,
    script_locale_json=localization.script_locale_json,
    script_default_locale_json=localization.script_default_locale_json,
  )
  run_loop_with_port(
    dt => {
      app.tick(elapsed_ms=dt) catch {
        error => {
          default_app_error_handler(error.message())
          false
        }
      }
    },
    run_browser_loop_port,
  ) catch {
    _ => ()
  }
}
