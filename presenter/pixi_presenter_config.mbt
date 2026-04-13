///|
pub struct PixiPresenterConfig {
  antialias : Bool
  background_alpha : Double
  resolution : Double
  auto_density : Bool
  position_entry_offset_ratio : Double
  scale_entry_from : Double
} derive(Debug, Eq)

///|
pub suberror PixiPresenterConfigError {
  BackgroundAlphaOutOfRange(value~ : Double)
  InvalidResolution(value~ : Double)
  NegativePositionEntryOffsetRatio(value~ : Double)
  NegativeScaleEntryFrom(value~ : Double)
}

///|
pub fn PixiPresenterConfig::new(
  antialias? : Bool = true,
  background_alpha? : Double = 0.0,
  resolution? : Double = 1.0,
  auto_density? : Bool = true,
  position_entry_offset_ratio? : Double = 0.04,
  scale_entry_from? : Double = 0.0,
) -> PixiPresenterConfig raise PixiPresenterConfigError {
  if background_alpha < 0.0 || background_alpha > 1.0 {
    raise PixiPresenterConfigError::BackgroundAlphaOutOfRange(
      value=background_alpha,
    )
  }
  if resolution <= 0.0 {
    raise PixiPresenterConfigError::InvalidResolution(value=resolution)
  }
  if position_entry_offset_ratio < 0.0 {
    raise PixiPresenterConfigError::NegativePositionEntryOffsetRatio(
      value=position_entry_offset_ratio,
    )
  }
  if scale_entry_from < 0.0 {
    raise PixiPresenterConfigError::NegativeScaleEntryFrom(
      value=scale_entry_from,
    )
  }
  {
    antialias,
    background_alpha,
    resolution,
    auto_density,
    position_entry_offset_ratio,
    scale_entry_from,
  }
}

///|
pub impl Default for PixiPresenterConfig with default() {
  try! PixiPresenterConfig::new()
}
