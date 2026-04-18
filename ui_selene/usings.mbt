///|
using @ui_game {
  type UiStrings,
  type UiViewModel,
  type UiChoiceView,
  type UiTextInputView,
  type UiVideoView,
  type UiPort,
  trait UiBackend,
  trait UiPlatformHooks,
  trait UiPortFactory,
}

///|
using @state {type DialogText}

///|
using @core {type UiSnapshot, type DialogLogEntry}

///|
using @core {type Easing, animation_progress}
