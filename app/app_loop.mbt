///|
pub async fn[E : Error] run_loop_with_port(
  on_tick : async (Int) -> Bool raise E,
  loop_port : async (async (Int) -> Bool raise E) -> Unit raise E,
) -> Unit raise E {
  loop_port(on_tick)
}

///|
#cfg(target="js")
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
#cfg(target="native")
fn render_app_error_dom(message : String) -> Unit {
  @util.console_warn("[reisen:app] \{message}")
}

///|
pub fn default_app_error_handler(message : String) -> Unit {
  render_app_error_dom(message)
}
