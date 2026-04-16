///|
/// Selene native audio adapter driven by `RuntimeEvent` through `AudioPort`.

///|
using @audio_core {trait AudioPort}

///|
struct SeleneAudio {
  resolve_url : (String) -> String?
  mut bgm_gain : Double
  mut sfx_gain : Double
  mut bgm_instance : @selene_platform_audio.AudioInstance?
  mut active_sfx : Array[@selene_platform_audio.AudioInstance]
}

///|
fn clamp_gain(gain : Double) -> Double {
  gain.clamp(min=0.0, max=1.0)
}

///|
pub fn SeleneAudio::new(resolve_url : (String) -> String?) -> SeleneAudio {
  {
    resolve_url,
    bgm_gain: 0.7,
    sfx_gain: 0.8,
    bgm_instance: None,
    active_sfx: [],
  }
}

///|
pub fn SeleneAudio::new_with_store(store : &AssetStore) -> SeleneAudio {
  SeleneAudio::new(id => store.get_audio_url(id))
}

///|
fn SeleneAudio::cleanup_finished_sfx(self : SeleneAudio) -> Unit {
  let alive : Array[@selene_platform_audio.AudioInstance] = []
  for instance in self.active_sfx {
    if !@selene_platform_audio.is_finished(instance~) {
      alive.push(instance)
    }
  }
  self.active_sfx = alive
}

///|
fn SeleneAudio::stop_music(self : SeleneAudio) -> Unit {
  match self.bgm_instance {
    Some(instance) => @selene_platform_audio.stop(instance~)
    None => ()
  }
  self.bgm_instance = None
}

///|
fn SeleneAudio::play_music_url(
  self : SeleneAudio,
  url : String,
  should_loop : Bool,
) -> Unit {
  self.stop_music()
  let instance = @selene_platform_audio.play_audio(
    audio_path=url,
    volume=self.bgm_gain,
    speed=1.0,
    loop_=should_loop,
    paused=false,
  )
  self.bgm_instance = Some(instance)
}

///|
fn SeleneAudio::play_sfx_url(self : SeleneAudio, url : String) -> Unit {
  self.cleanup_finished_sfx()
  let instance = @selene_platform_audio.play_audio(
    audio_path=url,
    volume=self.sfx_gain,
    speed=1.0,
    loop_=false,
    paused=false,
  )
  self.active_sfx.push(instance)
}

///|
fn SeleneAudio::stop_all_sfx(self : SeleneAudio) -> Unit {
  for instance in self.active_sfx {
    @selene_platform_audio.stop(instance~)
  }
  self.active_sfx = []
}

///|
pub impl AudioPort for SeleneAudio with set_bgm_gain(self, gain) {
  self.bgm_gain = clamp_gain(gain)
  match self.bgm_instance {
    Some(instance) => @selene_platform_audio.set_volume(
      instance~,
      volume=self.bgm_gain,
    )
    None => ()
  }
}

///|
pub impl AudioPort for SeleneAudio with set_sfx_gain(self, gain) {
  self.sfx_gain = clamp_gain(gain)
  self.cleanup_finished_sfx()
  for instance in self.active_sfx {
    @selene_platform_audio.set_volume(instance~, volume=self.sfx_gain)
  }
}

///|
pub impl AudioPort for SeleneAudio with has_active_sfx(self) {
  self.cleanup_finished_sfx()
  !self.active_sfx.is_empty()
}

///|
pub impl AudioPort for SeleneAudio with handle_command(
  self : SeleneAudio,
  command : @audio_core.AudioCommand,
) -> Unit {
  self.cleanup_finished_sfx()
  match command {
    PlayMusic(id, should_loop) =>
      match (self.resolve_url)(id) {
        Some(url) => self.play_music_url(url, should_loop)
        None => ()
      }
    StopMusic => self.stop_music()
    PlaySfx(id) =>
      match (self.resolve_url)(id) {
        Some(url) => self.play_sfx_url(url)
        None => ()
      }
    PlaySfxUrl(url) => self.play_sfx_url(url)
    StopSfx => self.stop_all_sfx()
    Noop => ()
  }
}
