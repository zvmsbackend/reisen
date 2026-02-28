///|
test "pixi presenter config constructor accepts valid values" {
  let cfg = try! PixiPresenterConfig::new(
    antialias=false,
    background_alpha=0.5,
    resolution=2.0,
    auto_density=false,
    position_entry_offset_ratio=0.1,
    scale_entry_from=0.25,
  )
  assert_eq(cfg.antialias, false)
  assert_eq(cfg.background_alpha, 0.5)
  assert_eq(cfg.resolution, 2.0)
  assert_eq(cfg.auto_density, false)
  assert_eq(cfg.position_entry_offset_ratio, 0.1)
  assert_eq(cfg.scale_entry_from, 0.25)
}

///|
test "pixi presenter config constructor validates background alpha" {
  let bad_low : Result[PixiPresenterConfig, Error] = try? PixiPresenterConfig::new(
    background_alpha=-0.01,
  )
  assert_true(
    bad_low
    is Err(PixiPresenterConfigError::BackgroundAlphaOutOfRange(value=-0.01)),
  )

  let bad_high : Result[PixiPresenterConfig, Error] = try? PixiPresenterConfig::new(
    background_alpha=1.01,
  )
  assert_true(
    bad_high
    is Err(PixiPresenterConfigError::BackgroundAlphaOutOfRange(value=1.01)),
  )
}

///|
test "pixi presenter config constructor validates resolution and entry values" {
  let bad_resolution : Result[PixiPresenterConfig, Error] = try? PixiPresenterConfig::new(
    resolution=0.0,
  )
  assert_true(
    bad_resolution
    is Err(PixiPresenterConfigError::InvalidResolution(value=0.0)),
  )

  let bad_offset : Result[PixiPresenterConfig, Error] = try? PixiPresenterConfig::new(
    position_entry_offset_ratio=-0.1,
  )
  assert_true(
    bad_offset
    is Err(
      PixiPresenterConfigError::NegativePositionEntryOffsetRatio(value=-0.1)
    ),
  )

  let bad_scale : Result[PixiPresenterConfig, Error] = try? PixiPresenterConfig::new(
    scale_entry_from=-0.2,
  )
  assert_true(
    bad_scale
    is Err(PixiPresenterConfigError::NegativeScaleEntryFrom(value=-0.2)),
  )
}
