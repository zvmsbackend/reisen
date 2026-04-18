///|
fn base_color_with_alpha(
  c : @selene_render.Color,
  alpha : Double,
) -> @selene_render.Color {
  { r: c.r, g: c.g, b: c.b, a: alpha }
}

///|
fn background_rect(
  viewport_w : Double,
  viewport_h : Double,
) -> @selene_math.Rect {
  {
    position: @selene_math.Vec2(0.0, 0.0),
    size: @selene_math.Vec2(viewport_w, viewport_h),
  }
}

///|
fn figure_rect(
  position : Position,
  viewport_w : Double,
  viewport_h : Double,
  scale : Double,
) -> @selene_math.Rect {
  let width = viewport_w * 0.32 * scale
  let height = viewport_h * 0.78 * scale
  let y = viewport_h - height
  let x = match position {
    Left => viewport_w * 0.18 - width / 2.0
    Center => viewport_w * 0.5 - width / 2.0
    Right => viewport_w * 0.82 - width / 2.0
    Custom(cx, cy) => {
      let px = viewport_w * cx - width / 2.0
      let py = viewport_h * cy - height / 2.0
      ignore(py)
      px
    }
  }
  let y = match position {
    Custom(_, cy) => viewport_h * cy - height / 2.0
    _ => y
  }
  { position: @selene_math.Vec2(x, y), size: @selene_math.Vec2(width, height) }
}

///|
fn image_command(
  handle : @selene_asset_types.ImageHandle,
  destination : @selene_math.Rect,
  color : @selene_render.Color,
  transform : @selene_math.Transform,
) -> @selene_render2d_types.DrawCommand2D {
  Image({
    uv_transform: @selene_math.Transform::identity(),
    alpha_mode: Blend,
    blend_mode: Alpha,
    image: handle,
    destination,
    source: None,
    transform,
    repeat: @selene_math.RepeatMode::NoRepeat,
    color,
  })
}

///|
fn placeholder_rect_command(
  rect : @selene_math.Rect,
  color : @selene_render.Color,
  transform : @selene_math.Transform,
) -> @selene_render2d_types.DrawCommand2D {
  Rect({
    rect,
    transform,
    alpha_mode: Blend,
    blend_mode: Alpha,
    fill_color: color,
    stroke_color: None,
  })
}

///|
fn to_color_component(value : Double) -> UInt {
  let v = value.clamp(min=0.0, max=1.0)
  (v * 255.0).to_int().reinterpret_as_uint()
}

///|
fn tint_from_scalars(scalars : @core.ScalarState) -> @selene_render.Color {
  {
    r: to_color_component(scalars.color_r * scalars.brightness),
    g: to_color_component(scalars.color_g * scalars.brightness),
    b: to_color_component(scalars.color_b * scalars.brightness),
    a: scalars.opacity.clamp(min=0.0, max=1.0),
  }
}

///|
fn rotation_transform(
  rect : @selene_math.Rect,
  rotation_deg : Double,
) -> @selene_math.Transform {
  if rotation_deg.abs() <= 0.000001 {
    return @selene_math.Transform::identity()
  }
  let center_x = rect.position[@selene_math.X] + rect.size[@selene_math.X] / 2.0
  let center_y = rect.position[@selene_math.Y] + rect.size[@selene_math.Y] / 2.0
  @selene_math.Transform::identity()
  .append_translation(-center_x, -center_y)
  .append_rotation_deg(rotation_deg)
  .append_translation(center_x, center_y)
}
