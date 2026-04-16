///|
using @debug {assert_eq}

///|
using @core {label, option}

///|
test "ui view model reflects dialog and choices from snapshot" {
  let a = label(name="a")
  let b = label(name="b")
  let snapshot = {
    ..UiSnapshot::default(),
    dialog: Some(
      (DialogText::String("guide"), DialogText::String("Pick one"), true, false),
    ),
    dialog_seq: 1,
    dialog_history: [{ speaker: "guide", text: "Pick one" }],
    choices: [option("Route A", a), option("Route B", b)],
  }
  let ui = UiDom::new("ui-root")

  let view = ui_view_model_from_snapshot(snapshot, ui)
  assert_eq(view.speaker, DialogText::String("guide"))
  assert_eq(view.text, DialogText::String("Pick one"))
  assert_eq(view.dialog_seq, 1)
  assert_eq(view.choices.length(), 2)
  assert_eq(view.choices[0].text, DialogText::String("Route A"))
  assert_eq(view.dialog_history, [{ speaker: "guide", text: "Pick one" }])
}

///|
test "ui view model is empty with default snapshot" {
  let ui = UiDom::new("ui-root")
  let view = ui_view_model_from_snapshot(UiSnapshot::default(), ui)
  assert_eq(view.speaker, DialogText::String(""))
  assert_eq(view.text, DialogText::String(""))
  assert_eq(view.dialog_seq, 0)
  assert_eq(view.choices, [])
  assert_eq(view.dialog_history, [])
}

///|
test "ui view model includes dom figures and applies dom animation" {
  let state : @core.DomFigureState = {
    placement: @core.place_center(layer=2),
    interactive: false,
  }
  let snapshot0 = {
    ..UiSnapshot::default(),
    dom_figures: { "promo": state },
    dom_animations: [
      (
        "promo",
        {
          prop: Opacity,
          duration_ms: 120,
          easing: Linear,
          from: Some([1.0]),
          to: Some([0.4]),
          blocking: false,
          anchor: None,
        },
      ),
    ],
  }
  let ui = UiDom::new("ui-root")

  ignore(ui_view_model_from_snapshot(snapshot0, ui))
  ui.advance_dom_animation_timer(120)
  let view = ui_view_model_from_snapshot(snapshot0, ui)
  assert_eq(view.dom_figures.length(), 1)
  assert_eq(view.dom_figures[0].id, "promo")
  assert_eq(view.dom_figures[0].dom_id, "promo")
  assert_eq(view.dom_figures[0].layer, 2)
  assert_eq(view.dom_figures[0].opacity, 0.4)
}

///|
test "ui dom localizes script key with selected locale" {
  let locale_json = "{\"demo.line\":\"こんにちは\"}"
  let default_json = "{\"demo.line\":\"Hello\"}"
  let ui = UiDom::new(
    "ui-root",
    script_locale_json=locale_json,
    script_default_locale_json=default_json,
    script_locale="ja",
    script_default_locale="en",
  )
  assert_eq(
    ui.localize_script_text(DialogText::String("@demo.line")),
    DialogText::String("こんにちは"),
  )
}

///|
test "ui dom localizes script key with default locale fallback" {
  let locale_json = "{}"
  let default_json = "{\"demo.line\":\"Hello\"}"
  let ui = UiDom::new(
    "ui-root",
    script_locale_json=locale_json,
    script_default_locale_json=default_json,
    script_locale="ja",
    script_default_locale="en",
  )
  assert_eq(
    ui.localize_script_text(DialogText::String("@demo.line")),
    DialogText::String("Hello"),
  )
}

///|
test "ui dom localizes script key fallback to key" {
  let locale_json = "{}"
  let default_json = "{}"
  let ui = UiDom::new(
    "ui-root",
    script_locale_json=locale_json,
    script_default_locale_json=default_json,
    script_locale="ja",
    script_default_locale="en",
  )
  assert_eq(
    ui.localize_script_text(DialogText::String("@demo.line")),
    DialogText::String("demo.line"),
  )
}

///|
test "ui dom localizes vocal key with selected locale" {
  let ui = UiDom::new(
    "ui-root",
    vocal_locale_dir="assets/voice",
    script_locale="ja",
    script_default_locale="en",
  )
  assert_eq(
    ui.localize_vocal_url("@demo/welcome.ogg"),
    "assets/voice/ja/demo/welcome.ogg",
  )
}

///|
test "ui dom localizes vocal key with default locale when locale unset" {
  let ui = UiDom::new(
    "ui-root",
    vocal_locale_dir="assets/voice",
    script_locale="",
    script_default_locale="en",
  )
  assert_eq(
    ui.localize_vocal_url("@demo/welcome.ogg"),
    "assets/voice/en/demo/welcome.ogg",
  )
}

///|
test "ui dom localizes vocal key fallback to key" {
  let ui = UiDom::new(
    "ui-root",
    vocal_locale_dir="",
    script_locale="ja",
    script_default_locale="en",
  )
  assert_eq(ui.localize_vocal_url("@demo/welcome.ogg"), "demo/welcome.ogg")
}

///|
test "ui dom keeps literal vocal url unchanged" {
  let ui = UiDom::new("ui-root")
  assert_eq(
    ui.localize_vocal_url("assets/voice/direct.ogg"),
    "assets/voice/direct.ogg",
  )
}
