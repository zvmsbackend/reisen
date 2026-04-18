///|
fn fullscreen_image_command(
  path : String,
  viewport_w : Double,
  viewport_h : Double,
) -> @selene_render2d_types.DrawCommand2D? {
  if path == "" {
    return None
  }
  let image = @selene_asset.load_image(path)
  Some(
    Image({
      uv_transform: @selene_math.Transform::identity(),
      alpha_mode: Blend,
      blend_mode: Alpha,
      image,
      destination: {
        position: Vec2(0.0, 0.0),
        size: Vec2(viewport_w, viewport_h),
      },
      source: None,
      transform: @selene_math.Transform::identity(),
      repeat: @selene_math.RepeatMode::NoRepeat,
      color: { r: 255, g: 255, b: 255, a: 1.0 },
    }),
  )
}
