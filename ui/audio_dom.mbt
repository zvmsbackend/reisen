///|
/// HTML audio adapter driven by `RuntimeEvent`.

///|
enum AudioCommand {
  Noop
  PlayMusic(String, Bool)
  StopMusic
  PlaySfx(String)
  PlaySfxUrl(String)
  StopSfx
} derive(Show, Eq)

///|
fn AudioCommand::from_event(event : RuntimeEvent) -> AudioCommand {
  match event {
    MusicPlayed(id, should_loop) => AudioCommand::PlayMusic(id, should_loop)
    MusicStopped => AudioCommand::StopMusic
    SfxPlayed(id, _) => AudioCommand::PlaySfx(id)
    SfxStopped => AudioCommand::StopSfx
    Said(voice~, ..) =>
      match voice {
        Some(url) => AudioCommand::PlaySfxUrl(url)
        None => AudioCommand::Noop
      }
    IntroShown(_) => AudioCommand::Noop
    TextBoxShown | TextBoxHidden => AudioCommand::Noop
    AvatarShown(_) | AvatarHidden => AudioCommand::Noop
    _ => AudioCommand::Noop
  }
}

///|
struct AudioDom {
  resolve_url : (String) -> String?
}

///|
pub fn AudioDom::new(resolve_url : (String) -> String?) -> AudioDom {
  { resolve_url, }
}

///|
pub fn AudioDom::new_with_store(store : AssetStore) -> AudioDom {
  AudioDom::new(id => store.get_audio_url(id))
}

///|
pub fn AudioDom::set_bgm_gain(gain : Double) -> Unit {
  let clamped = if gain < 0.0 { 0.0 } else if gain > 1.0 { 1.0 } else { gain }
  audio_dom_set_bgm_gain(clamped)
}

///|
pub fn AudioDom::set_sfx_gain(gain : Double) -> Unit {
  let clamped = if gain < 0.0 { 0.0 } else if gain > 1.0 { 1.0 } else { gain }
  audio_dom_set_sfx_gain(clamped)
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
pub fn AudioDom::handle_event(self : AudioDom, event : RuntimeEvent) -> Unit {
  match AudioCommand::from_event(event) {
    AudioCommand::PlayMusic(id, should_loop) =>
      match (self.resolve_url)(id) {
        Some(url) => audio_dom_play_music(url, should_loop)
        None => ()
      }
    AudioCommand::StopMusic => audio_dom_stop_music()
    AudioCommand::PlaySfx(id) =>
      match (self.resolve_url)(id) {
        Some(url) => audio_dom_play_sfx(url)
        None => ()
      }
    AudioCommand::PlaySfxUrl(url) => audio_dom_play_sfx(url)
    AudioCommand::StopSfx => audio_dom_stop_sfx()
    AudioCommand::Noop => ()
  }
}

///|
pub fn AudioDom::has_active_sfx() -> Bool {
  audio_dom_has_active_sfx_impl()
}

///|
pub fn AudioDom::as_event_hook(self : AudioDom) -> @core.EventHook {
  event => self.handle_event(event)
}
