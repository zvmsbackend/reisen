///|
using @core {label, option}

///|
test "ui view model reflects dialog and choices from snapshot" {
  let a = label(name="a")
  let b = label(name="b")
  let snapshot = {
    ..UiSnapshot::default(),
    dialog: Some(("guide", "Pick one", true, false)),
    dialog_seq: 1,
    dialog_history: [{ speaker: "guide", text: "Pick one" }],
    choices: [option("Route A", a), option("Route B", b)],
  }
  let ui = UiDom::new("ui-root")

  let view = UiViewModel::from_snapshot(snapshot, ui)
  assert_eq(view.speaker, "guide")
  assert_eq(view.text, "Pick one")
  assert_eq(view.dialog_seq, 1)
  assert_eq(view.choices.length(), 2)
  assert_eq(view.choices[0].text, "Route A")
  assert_eq(view.dialog_history, [{ speaker: "guide", text: "Pick one" }])
}

///|
test "ui view model is empty with default snapshot" {
  let ui = UiDom::new("ui-root")
  let view = UiViewModel::from_snapshot(UiSnapshot::default(), ui)
  assert_eq(view.speaker, "")
  assert_eq(view.text, "")
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

  ignore(UiViewModel::from_snapshot(snapshot0, ui))
  ui.advance_dom_animation_timer(120)
  let view = UiViewModel::from_snapshot(snapshot0, ui)
  assert_eq(view.dom_figures.length(), 1)
  assert_eq(view.dom_figures[0].id, "promo")
  assert_eq(view.dom_figures[0].dom_id, "promo")
  assert_eq(view.dom_figures[0].layer, 2)
  assert_eq(view.dom_figures[0].opacity, 0.4)
}
