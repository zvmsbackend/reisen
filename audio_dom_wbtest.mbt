///|
test "audio command mapping from runtime event" {
  assert_eq(
    audio_command_from_event(MusicPlayed("bgm", true)),
    PlayMusic("bgm", true),
  )
  assert_eq(audio_command_from_event(MusicStopped), StopMusic)
  assert_eq(audio_command_from_event(SfxPlayed("click")), PlaySfx("click"))
  assert_eq(audio_command_from_event(Said("n", "t")), Noop)
}

///|
test "audio dom register and hook are callable" {
  let audio = AudioDom::new()
  let _bgm = audio.register_music("/bgm.ogg")
  let hook = audio.as_event_hook()

  // Avoid hard dependency on browser Audio constructor in tests.
  hook(MusicPlayed("missing", false))
  hook(SfxPlayed("missing"))
  hook(MusicStopped)
}
