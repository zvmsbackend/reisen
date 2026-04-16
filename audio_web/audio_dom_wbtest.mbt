///|
test "audio dom resolver and hook are callable" {
  let audio : &AudioPort = AudioDom::new(_ => None)
  let hook = audio.as_event_hook()

  // Avoid hard dependency on browser Audio constructor in tests.
  hook(MusicPlayed("missing", false))
  hook(SfxPlayed("missing", false))
  hook(MusicStopped)
}
