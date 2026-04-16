///|
using @core {type RuntimeEvent}

///|
pub enum AudioCommand {
  Noop
  PlayMusic(String, Bool)
  StopMusic
  PlaySfx(String)
  PlaySfxUrl(String)
  StopSfx
} derive(Debug, Eq)

///|
pub fn AudioCommand::from_event(event : RuntimeEvent) -> AudioCommand {
  match event {
    MusicPlayed(id, should_loop) => PlayMusic(id, should_loop)
    MusicStopped => StopMusic
    SfxPlayed(id, _) => PlaySfx(id)
    SfxStopped => StopSfx
    Said(voice~, ..) =>
      match voice {
        Some(url) => PlaySfxUrl(url)
        None => Noop
      }
    IntroShown(_) => Noop
    TextBoxShown | TextBoxHidden => Noop
    AvatarShown(_) | AvatarHidden => Noop
    _ => Noop
  }
}

///|
pub(open) trait AudioPort {
  set_bgm_gain(Self, Double) -> Unit
  set_sfx_gain(Self, Double) -> Unit
  has_active_sfx(Self) -> Bool
  handle_command(Self, AudioCommand) -> Unit
}

///|
pub fn &AudioPort::as_event_hook(self : &AudioPort) -> @core.EventHook {
  event => self.handle_command(AudioCommand::from_event(event))
}

///|
struct DummyAudioPort {}

///|
pub let dummy : &AudioPort = DummyAudioPort::{  }

///|
pub impl AudioPort for DummyAudioPort with set_bgm_gain(_, _) {

}

///|
pub impl AudioPort for DummyAudioPort with set_sfx_gain(_, _) {

}

///|
pub impl AudioPort for DummyAudioPort with has_active_sfx(_) {
  false
}

///|
pub impl AudioPort for DummyAudioPort with handle_command(_, _) {

}
