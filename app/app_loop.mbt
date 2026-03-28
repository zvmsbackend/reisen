///|
extern "js" fn raf_promise() -> @js_async.Promise[Double] =
  #| () => new Promise(resolve => {
  #|   requestAnimationFrame(resolve);
  #| })

///|
fn max(x : Int, y : Int) -> Int {
  if x > y {
    x
  } else {
    y
  }
}

///|
async fn[E : Error] run_browser_loop_impl(
  on_tick : async (Int) -> Bool raise E,
) -> Unit raise E {
  for last = 0.0 {
    let ts = @js_async.Promise::wait(raf_promise()) catch {
      @js.Error_(msg) => abort(msg.to_string())
      _ => panic()
    }
    let dt = if last == 0 { 0 } else { max(0, @math.floor(ts - last).to_int()) }
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
pub async fn[E : Error] run_loop_with_port(
  on_tick : async (Int) -> Bool raise E,
  loop_port : async (async (Int) -> Bool raise E) -> Unit raise E,
) -> Unit raise E {
  loop_port(on_tick)
}

///|
extern "js" fn render_app_error_dom(message : String) -> Unit =
  #| (message) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) {
  #|     try {
  #|       console.error(message);
  #|     } catch (_) {}
  #|     return;
  #|   }
  #|   const id = 'reisen-abort-overlay';
  #|   let root = doc.getElementById(id);
  #|   if (!root) {
  #|     root = doc.createElement('div');
  #|     root.id = id;
  #|     root.style.position = 'fixed';
  #|     root.style.inset = '0';
  #|     root.style.zIndex = '2147483647';
  #|     root.style.background = 'rgba(8, 8, 12, 0.95)';
  #|     root.style.color = '#ffe7e7';
  #|     root.style.padding = '20px';
  #|     root.style.fontFamily = 'ui-monospace, SFMono-Regular, Menlo, monospace';
  #|     root.style.whiteSpace = 'pre-wrap';
  #|     root.style.overflow = 'auto';
  #|     root.style.boxSizing = 'border-box';
  #|     doc.body.appendChild(root);
  #|   }
  #|   root.textContent = `Program error:\n\n${String(message ?? '')}`;
  #| }

///|
pub fn default_app_error_handler(message : String) -> Unit {
  render_app_error_dom(message)
}

///|
pub async fn[T] run_browser_loop(runner : GameRunner[T]) -> Unit {
  run_loop_with_port(dt => runner.tick(elapsed_ms=dt), run_browser_loop_port)
}

///|
pub async fn[T : FromJson + ToJson] run_browser_app_loop(
  app : AppController[T],
) -> Unit raise AppControllerError {
  run_loop_with_port(dt => app.tick(elapsed_ms=dt), run_browser_loop_port)
}
