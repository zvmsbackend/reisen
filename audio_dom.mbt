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
pub fn AudioDom::register(self : AudioDom, id : String, url : String) -> Unit {
  self.urls[id] = url
}

///|
pub fn AudioDom::register_many(
  self : AudioDom,
  entries : Array[(String, String)],
) -> Unit {
  for id_url in entries {
    let (id, url) = id_url
    self.urls[id] = url
  }
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
  #|   sfx.play?.().catch?.(() => {});
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
