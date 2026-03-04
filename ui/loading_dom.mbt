///|
struct LoadingMenu {
  root_id : String
}

///|
pub fn LoadingMenu::new(root_id : String) -> LoadingMenu {
  { root_id, }
}

///|
extern "js" fn loading_dom_render(root_id : String, text : String) -> Unit =
  #| (root_id, text) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   let host = root.querySelector('[data-reisen="loading-menu"]');
  #|   if (!host) {
  #|     host = doc.createElement('div');
  #|     host.dataset.reisen = 'loading-menu';
  #|     root.appendChild(host);
  #|   }
  #|   host.innerHTML = '';
  #|   host.style.position = 'absolute';
  #|   host.style.inset = '0';
  #|   host.style.display = 'flex';
  #|   host.style.flexDirection = 'column';
  #|   host.style.alignItems = 'center';
  #|   host.style.justifyContent = 'center';
  #|   host.style.gap = '12px';
  #|   host.style.background = 'rgba(0, 0, 0, 0.65)';
  #|   host.style.backdropFilter = 'blur(2px)';
  #|   host.style.zIndex = '500';
  #|   host.style.pointerEvents = 'auto';
  #|   const spinner = doc.createElement('div');
  #|   spinner.dataset.reisen = 'loading-spinner';
  #|   spinner.style.width = '32px';
  #|   spinner.style.height = '32px';
  #|   spinner.style.border = '3px solid rgba(255, 255, 255, 0.25)';
  #|   spinner.style.borderTopColor = 'rgba(255, 255, 255, 0.95)';
  #|   spinner.style.borderRadius = '50%';
  #|   spinner.style.animation = 'reisenSpin 0.8s linear infinite';
  #|   const label = doc.createElement('div');
  #|   label.dataset.reisen = 'loading-text';
  #|   label.textContent = text || 'Loading...';
  #|   label.style.color = '#fff';
  #|   label.style.fontSize = '18px';
  #|   label.style.letterSpacing = '0.02em';
  #|   host.appendChild(spinner);
  #|   host.appendChild(label);
  #|   if (!doc.getElementById('reisen-loading-spin-style')) {
  #|     const style = doc.createElement('style');
  #|     style.id = 'reisen-loading-spin-style';
  #|     style.textContent = '@keyframes reisenSpin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }';
  #|     doc.head?.appendChild(style);
  #|   }
  #| }

///|
extern "js" fn loading_dom_clear(root_id : String) -> Unit =
  #| (root_id) => {
  #|   const doc = globalThis.document;
  #|   if (!doc) return;
  #|   const root = doc.getElementById(root_id);
  #|   if (!root) return;
  #|   const host = root.querySelector('[data-reisen="loading-menu"]');
  #|   if (host) host.remove();
  #| }

///|
pub fn LoadingMenu::render(self : LoadingMenu, text : String) -> Unit {
  loading_dom_render(self.root_id, text)
}

///|
pub fn LoadingMenu::clear(self : LoadingMenu) -> Unit {
  loading_dom_clear(self.root_id)
}
