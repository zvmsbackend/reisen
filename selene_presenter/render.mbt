///|
fn SelenePresenter::build_world_commands(
  self : SelenePresenter,
  snapshot : CoreRenderSnapshot,
) -> Array[@selene_render2d_types.DrawCommand2D] {
  let commands : Array[@selene_render2d_types.DrawCommand2D] = []
  let viewport_w = self.config.viewport_w
  let viewport_h = self.config.viewport_h
  let bg_rect = background_rect(viewport_w, viewport_h)
  if snapshot.background is Some(state) {
    if self.lookup_image_handle(state.id) is Some(handle) {
      commands.push(
        image_command(
          handle,
          bg_rect,
          tint_from_scalars(state.scalars),
          rotation_transform(bg_rect, state.scalars.rotation),
        ),
      )
    } else {
      commands.push(
        placeholder_rect_command(
          bg_rect,
          base_color_with_alpha(
            self.config.placeholder_background_color,
            state.scalars.opacity,
          ),
          rotation_transform(bg_rect, state.scalars.rotation),
        ),
      )
    }
  }
  let sorted_figures = snapshot.figures.iter2().to_array()
  sorted_figures.sort_by((lhs, rhs) => lhs.1.layer - rhs.1.layer)
  for entry in sorted_figures {
    let (id, placement) = entry
    let rect = figure_rect(
      placement.pos,
      viewport_w,
      viewport_h,
      placement.scalars.scale,
    )
    if self.lookup_image_handle(id) is Some(handle) {
      commands.push(
        image_command(
          handle,
          rect,
          tint_from_scalars(placement.scalars),
          rotation_transform(rect, placement.scalars.rotation),
        ),
      )
    } else {
      commands.push(
        placeholder_rect_command(
          rect,
          base_color_with_alpha(
            self.config.placeholder_figure_color,
            placement.scalars.opacity,
          ),
          rotation_transform(rect, placement.scalars.rotation),
        ),
      )
    }
  }
  commands
}

///|
fn SelenePresenter::submit_frame(
  self : SelenePresenter,
  snapshot : CoreRenderSnapshot,
) -> Unit {
  let ui_commands = match self.ui_overlay_provider {
    Some(provider) => provider()
    None => []
  }
  let frame2d : @selene_render2d_types.RenderFrame2D = {
    world_commands: self.build_world_commands(snapshot),
    ui_commands,
  }
  let frame = { ..@selene_render_pipeline.empty_render_frame(), frame2d, }
  @selene_platform_render.submit_frame(frame)
}
