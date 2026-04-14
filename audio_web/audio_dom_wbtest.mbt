///|
using @state {type DialogText}

///|
test "audio command mapping from runtime event" {
  assert_true(
    AudioCommand::from_event(MusicPlayed("bgm", true)) is PlayMusic("bgm", true),
  )
  assert_true(AudioCommand::from_event(MusicStopped) is StopMusic)
  assert_true(
    AudioCommand::from_event(SfxPlayed("click", false)) is PlaySfx("click"),
  )
  assert_true(
    AudioCommand::from_event(
      Said(
        speaker=DialogText::String("n"),
        text=DialogText::String("t"),
        typewriter=true,
        append=false,
        voice=None,
      ),
    )
    is Noop,
  )
  assert_true(
    AudioCommand::from_event(
      Said(
        speaker=DialogText::String("n"),
        text=DialogText::String("t"),
        typewriter=true,
        append=false,
        voice=Some("voice"),
      ),
    )
    is PlaySfxUrl("voice"),
  )
}

///|
test "audio dom resolver and hook are callable" {
  let audio = AudioDom::new(_ => None)
  let hook = audio.as_event_hook()

  // Avoid hard dependency on browser Audio constructor in tests.
  hook(MusicPlayed("missing", false))
  hook(SfxPlayed("missing", false))
  hook(MusicStopped)
}
