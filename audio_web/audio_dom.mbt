///|
/// HTML audio adapter driven by `RuntimeEvent`.

///|
using @audio_core {trait AudioPort}

///|
struct AudioDom {
  resolve_url : (String) -> String?
}

///|
pub fn AudioDom::new(resolve_url : (String) -> String?) -> AudioDom {
  { resolve_url, }
}

///|
pub fn AudioDom::new_with_store(store : &AssetStore) -> AudioDom {
  AudioDom::new(id => store.get_audio_url(id))
}

///|
pub impl AudioPort for AudioDom with set_bgm_gain(_self, gain) {
  audio_dom_set_bgm_gain(gain.clamp(min=0, max=1))
}

///|
pub impl AudioPort for AudioDom with set_sfx_gain(_self, gain) -> Unit {
  audio_dom_set_sfx_gain(gain.clamp(min=0, max=1))
}

///|
extern "js" fn audio_dom_play_music(url : String, should_loop : Bool) -> Unit =
  #| (url, should_loop) => {
  #|   const key = "__reisenBgm";
  #|   let bgm = globalThis[key];
  #|   if (!bgm) {
  #|     bgm = new Audio();
  #|     const gain = globalThis.__reisenBgmGain ?? 0.7;
  #|     if (bgm.volume !== undefined) bgm.volume = gain;
  #|     globalThis[key] = bgm;
  #|   } else {
  #|     try {
  #|       bgm.pause?.();
  #|       bgm.currentTime = 0;
  #|     } catch (_) {}
  #|   }
  #|   bgm.loop = !!should_loop;
  #|   if (bgm.src !== url) bgm.src = url;
  #|   bgm.play?.().catch?.(() => {});
  #| }

///|
extern "js" fn audio_dom_stop_music() -> Unit =
  #| () => {
  #|   const bgm = globalThis.__reisenBgm;
  #|   if (!bgm) return;
  #|   bgm.pause?.();
  #|   bgm.currentTime = 0;
  #| }

///|
extern "js" fn audio_dom_play_sfx(url : String) -> Unit =
  #| (url) => {
  #|   const sfx = new Audio(url);
  #|   const gain = globalThis.__reisenSfxGain ?? 0.8;
  #|   if (sfx.volume !== undefined) sfx.volume = gain;
  #|   const list = globalThis.__reisenSfxActive ?? (globalThis.__reisenSfxActive = []);
  #|   list.push(sfx);
  #|   const cleanup = () => {
  #|     const idx = list.indexOf(sfx);
  #|     if (idx >= 0) list.splice(idx, 1);
  #|   };
  #|   sfx.addEventListener('ended', cleanup, { once: true });
  #|   sfx.addEventListener('error', cleanup, { once: true });
  #|   sfx.play?.().catch?.(() => {});
  #| }

///|
extern "js" fn audio_dom_set_bgm_gain(gain : Double) -> Unit =
  #| (gain) => {
  #|   globalThis.__reisenBgmGain = Math.max(0, Math.min(1, gain));
  #|   const bgm = globalThis.__reisenBgm;
  #|   if (bgm && bgm.volume !== undefined) {
  #|     bgm.volume = Math.max(0, Math.min(1, gain));
  #|   }
  #| }

///|
extern "js" fn audio_dom_set_sfx_gain(gain : Double) -> Unit =
  #| (gain) => {
  #|   globalThis.__reisenSfxGain = Math.max(0, Math.min(1, gain));
  #| }

///|
extern "js" fn audio_dom_stop_sfx() -> Unit =
  #| () => {
  #|   const list = globalThis.__reisenSfxActive;
  #|   if (!list || !Array.isArray(list)) return;
  #|   list.forEach((sfx) => {
  #|     try {
  #|       sfx.pause?.();
  #|       sfx.currentTime = 0;
  #|     } catch (_) {}
  #|   });
  #|   list.length = 0;
  #| }

///|
extern "js" fn audio_dom_has_active_sfx_impl() -> Bool =
  #| () => {
  #|   const list = globalThis.__reisenSfxActive;
  #|   return !!(list && list.length);
  #| }

///|
pub impl AudioPort for AudioDom with handle_command(
  self : AudioDom,
  command : @audio_core.AudioCommand,
) -> Unit {
  match command {
    PlayMusic(id, should_loop) =>
      match (self.resolve_url)(id) {
        Some(url) => audio_dom_play_music(url, should_loop)
        None => ()
      }
    StopMusic => audio_dom_stop_music()
    PlaySfx(id) =>
      match (self.resolve_url)(id) {
        Some(url) => audio_dom_play_sfx(url)
        None => ()
      }
    PlaySfxUrl(url) => audio_dom_play_sfx(url)
    StopSfx => audio_dom_stop_sfx()
    Noop => ()
  }
}

///|
pub impl AudioPort for AudioDom with has_active_sfx(_self) {
  audio_dom_has_active_sfx_impl()
}
