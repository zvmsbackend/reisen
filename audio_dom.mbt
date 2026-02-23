///|
/// HTML audio adapter driven by `RuntimeEvent`.

///|
enum AudioCommand {
  Noop
  PlayMusic(String, Bool)
  StopMusic
  PlaySfx(String)
} derive(Show, Eq)

///|
fn audio_command_from_event(event : RuntimeEvent) -> AudioCommand {
  match event {
    MusicPlayed(id, should_loop) => AudioCommand::PlayMusic(id, should_loop)
    MusicStopped => AudioCommand::StopMusic
    SfxPlayed(id) => AudioCommand::PlaySfx(id)
    Said(_, _, _) => AudioCommand::Noop
    IntroShown(_) => AudioCommand::Noop
    _ => AudioCommand::Noop
  }
}

///|
struct AudioDom {
  urls : Map[String, String]
}

///|
pub fn AudioDom::new() -> AudioDom {
  { urls: {} }
}

///|
pub fn AudioDom::register_music(
  self : AudioDom,
  url : String,
  id? : String = gensym(prefix="music"),
) -> Music {
  self.urls[id] = url
  { id, }
}

///|
pub fn AudioDom::register_sfx(
  self : AudioDom,
  url : String,
  id? : String = gensym(prefix="sfx"),
) -> Sfx {
  self.urls[id] = url
  { id, }
}

///|
pub fn AudioDom::set_bgm_gain(_self : AudioDom, gain : Double) -> Unit {
  let clamped = if gain < 0.0 { 0.0 } else if gain > 1.0 { 1.0 } else { gain }
  audio_dom_set_bgm_gain(clamped)
}

///|
pub fn AudioDom::set_sfx_gain(_self : AudioDom, gain : Double) -> Unit {
  let clamped = if gain < 0.0 { 0.0 } else if gain > 1.0 { 1.0 } else { gain }
  audio_dom_set_sfx_gain(clamped)
}

///|
pub fn AudioDom::apply_settings(
  self : AudioDom,
  settings : GameSettings,
) -> Unit {
  self.set_bgm_gain(settings.bgm_volume)
  self.set_sfx_gain(settings.sfx_volume)
}

///|
extern "js" fn audio_dom_play_music(url : String, should_loop : Bool) -> Unit =
  #| (url, should_loop) => {
  #|   const key = "__reisenBgm";
  #|   let bgm = globalThis[key];
  #|   if (!bgm) {
  #|     bgm = new Audio();
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
  #|   sfx.play?.().catch?.(() => {});
  #| }

///|
extern "js" fn audio_dom_set_bgm_gain(gain : Double) -> Unit =
  #| (gain) => {
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
pub fn AudioDom::handle_event(self : AudioDom, event : RuntimeEvent) -> Unit {
  match audio_command_from_event(event) {
    AudioCommand::PlayMusic(id, should_loop) =>
      match self.urls.get(id) {
        Some(url) => audio_dom_play_music(url, should_loop)
        None => ()
      }
    AudioCommand::StopMusic => audio_dom_stop_music()
    AudioCommand::PlaySfx(id) =>
      match self.urls.get(id) {
        Some(url) => audio_dom_play_sfx(url)
        None => ()
      }
    AudioCommand::Noop => ()
  }
}

///|
pub fn AudioDom::as_event_hook(self : AudioDom) -> EventHook {
  event => self.handle_event(event)
}
