///|
extern "js" fn raf_promise() -> @js.Promise =
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
async fn run_browser_loop_impl(on_tick : async (Int) -> Bool) -> Unit {
  for last = 0.0 {
    let ts = @js.Promise::wait(raf_promise()).cast()
    let dt = if last == 0 { 0 } else { max(0, @math.floor(ts - last).to_int()) }
    if on_tick(dt) {
      continue ts
    } else {
      break
    }
  }
}

///|
let abort_hook_installed : Ref[Bool] = Ref::new(false)

///|
extern "js" fn render_abort_dom(message : String) -> Unit =
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
  #|   root.textContent = `Program aborted:\n\n${String(message ?? '')}`;
  #| }

///|
fn install_abort_hook_once() -> Unit {
  if abort_hook_installed.val {
    return
  }
  abort_hook_installed.val = true
  @lib.add_hook(message => render_abort_dom(message))
}

///|
pub async fn[T] run_browser_loop(runner : GameRunner[T]) -> Unit {
  install_abort_hook_once()
  run_browser_loop_impl(dt => runner.tick(elapsed_ms=dt))
}

///|
pub async fn[T : FromJson + ToJson] run_browser_app_loop(
  app : AppController[T],
) -> Unit {
  install_abort_hook_once()
  run_browser_loop_impl(dt => app.tick(elapsed_ms=dt))
}
