///|
test "figure rect presets map to expected screen anchors" {
  let (lx, ly, lw, lh) = figure_rect(Left, 1000.0, 800.0)
  assert_eq((lx, ly, lw, lh), (50.0, 80.0, 400.0, 720.0))

  let (cx, cy, cw, ch) = figure_rect(Center, 1000.0, 800.0)
  assert_eq((cx, cy, cw, ch), (300.0, 80.0, 400.0, 720.0))

  let (rx, ry, rw, rh) = figure_rect(Right, 1000.0, 800.0)
  assert_eq((rx, ry, rw, rh), (550.0, 80.0, 400.0, 720.0))
}

///|
test "figure rect custom uses normalized top-left coordinates" {
  let (x, y, w, h) = figure_rect(Custom(0.2, 0.3), 1200.0, 900.0)
  assert_eq((x, y, w, h), (240.0, 270.0, 480.0, 810.0))
}

