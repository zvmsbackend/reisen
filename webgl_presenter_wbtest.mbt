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

///|
test "opacity animation interpolates and completes" {
  let anim : OpacityAnim = { start_ms: 100, duration_ms: 200, easing: Linear }
  let (o1, done1) = apply_opacity_animation(0.8, 100, anim)
  assert_eq((o1, done1), (0.0, false))

  let (o2, done2) = apply_opacity_animation(0.8, 200, anim)
  assert_true(o2 > 0.39 && o2 < 0.41)
  assert_true(!done2)

  let (o3, done3) = apply_opacity_animation(0.8, 301, anim)
  assert_eq((o3, done3), (0.8, true))
}

///|
test "position animation moves upward to target y" {
  let anim : PositionAnim = { start_ms: 0, duration_ms: 100, easing: Linear }
  let (_, y0, done0) = apply_position_animation(
    100.0, 200.0, 0.04, 1000.0, 0, anim,
  )
  assert_eq((y0, done0), (240.0, false))

  let (_, y1, done1) = apply_position_animation(
    100.0, 200.0, 0.04, 1000.0, 50, anim,
  )
  assert_eq((y1, done1), (220.0, false))

  let (_, y2, done2) = apply_position_animation(
    100.0, 200.0, 0.04, 1000.0, 100, anim,
  )
  assert_eq((y2, done2), (200.0, true))
}

///|
test "scale animation grows around center" {
  let anim : ScaleAnim = { start_ms: 0, duration_ms: 100, easing: Linear }
  let (x0, y0, w0, h0, done0) = apply_scale_animation(
    100.0, 200.0, 300.0, 400.0, 0.0, 0, anim,
  )
  assert_eq((x0, y0, w0, h0, done0), (250.0, 400.0, 0.0, 0.0, false))

  let (x1, y1, w1, h1, done1) = apply_scale_animation(
    100.0, 200.0, 300.0, 400.0, 0.0, 50, anim,
  )
  assert_eq((x1, y1, w1, h1, done1), (175.0, 300.0, 150.0, 200.0, false))

  let (x2, y2, w2, h2, done2) = apply_scale_animation(
    100.0, 200.0, 300.0, 400.0, 0.0, 100, anim,
  )
  assert_eq((x2, y2, w2, h2, done2), (100.0, 200.0, 300.0, 400.0, true))
}

///|
test "presenter config defaults are stable" {
  assert_eq(webgl_presenter_default_config(), {
    position_entry_offset_ratio: 0.04,
    scale_entry_from: 0.0,
  })
}
