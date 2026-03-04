///|
/// Pixi presenter that mirrors `Director` render state.
///
/// Current migration scope:
/// - background + figure rendering
/// - layer ordering
/// - position/scale/opacity/rotation animation playback

///|
priv struct PixiPresenter {
  store : AssetStore
  config : PixiPresenterConfig
  app : PixiApplication
  stage : PixiContainer
  textures : Map[String, PixiTexture]
  texture_sizes : Map[String, (Double, Double)]
  live2d_base_sizes : Map[String, (Double, Double)]
  figure_sprites : Map[String, PixiSprite]
  figure_live2d : Map[String, PixiLive2dModel]
  mut background_sprite : PixiSprite?
  mut background_cover_sprite : PixiSprite?
  blur_filters : Map[String, PixiBlurFilter]
  color_filters : Map[String, PixiColorMatrixFilter]
  mut last_background_id : String?
  mut render_epoch : String?
  mut animation_cursor : Int
  mut live2d_motion_cursor : Int
  mut live2d_expression_cursor : Int
  mut timeline_ms : Int
  mut last_sync_ms : Int
  opacity_anims : Map[String, ScalarAnim]
  position_anims : Map[String, PositionAnim]
  scale_anims : Map[String, ScaleAnim]
  rotation_anims : Map[String, ScalarAnim]
  blur_anims : Map[String, ScalarAnim]
  brightness_anims : Map[String, ScalarAnim]
  contrast_anims : Map[String, ScalarAnim]
  saturation_anims : Map[String, ScalarAnim]
  gamma_anims : Map[String, ScalarAnim]
  color_r_anims : Map[String, ScalarAnim]
  color_g_anims : Map[String, ScalarAnim]
  color_b_anims : Map[String, ScalarAnim]
  effect_start_ms : Map[String, Int]
  effect_signatures : Map[String, String]
  effect_from_params : Map[String, Array[EffectParam]]
  mut skip_mode : Bool
}

///|
async fn PixiPresenter::new(
  canvas : PixiCanvas,
  store : AssetStore,
  config : PixiPresenterConfig,
) -> PixiPresenter {
  let app = PixiApplication::new()
  app.init_with_canvas(
    canvas,
    window_inner_width().to_int(),
    window_inner_height().to_int(),
    antialias=config.antialias,
    background_alpha=config.background_alpha,
    resolution=config.resolution,
    auto_density=config.auto_density,
  )
  let stage = app.stage()
  stage.set_sortable_children(true)
  {
    store,
    config,
    app,
    stage,
    textures: {},
    texture_sizes: {},
    live2d_base_sizes: {},
    figure_sprites: {},
    figure_live2d: {},
    background_sprite: None,
    background_cover_sprite: None,
    blur_filters: {},
    color_filters: {},
    last_background_id: None,
    render_epoch: None,
    animation_cursor: 0,
    live2d_motion_cursor: 0,
    live2d_expression_cursor: 0,
    timeline_ms: 0,
    last_sync_ms: 0,
    opacity_anims: {},
    position_anims: {},
    scale_anims: {},
    rotation_anims: {},
    blur_anims: {},
    brightness_anims: {},
    contrast_anims: {},
    saturation_anims: {},
    gamma_anims: {},
    color_r_anims: {},
    color_g_anims: {},
    color_b_anims: {},
    effect_start_ms: {},
    effect_signatures: {},
    effect_from_params: {},
    skip_mode: false,
  }
}

///|
fn PixiPresenter::update_timeline(self : PixiPresenter) -> Unit {
  let now = pixi_now_ms()
  if self.last_sync_ms <= 0 {
    self.last_sync_ms = now
    return
  }
  let dt = now - self.last_sync_ms
  self.last_sync_ms = now
  if dt > 0 {
    self.timeline_ms += dt
  }
}

///|
fn PixiPresenter::reset_render_state(self : PixiPresenter) -> Unit {
  self.animation_cursor = 0
  self.live2d_motion_cursor = 0
  self.live2d_expression_cursor = 0
  self.timeline_ms = 0
  self.last_sync_ms = 0
  self.last_background_id = None
  self.opacity_anims.clear()
  self.position_anims.clear()
  self.scale_anims.clear()
  self.rotation_anims.clear()
  self.blur_anims.clear()
  self.brightness_anims.clear()
  self.contrast_anims.clear()
  self.saturation_anims.clear()
  self.gamma_anims.clear()
  self.color_r_anims.clear()
  self.color_g_anims.clear()
  self.color_b_anims.clear()
  self.effect_start_ms.clear()
  self.effect_signatures.clear()
  self.effect_from_params.clear()
  self.blur_filters.clear()
  self.color_filters.clear()
  self.live2d_base_sizes.clear()
  match self.background_sprite {
    Some(sprite) => sprite.set_visible(false)
    None => ()
  }
  match self.background_cover_sprite {
    Some(sprite) => sprite.set_visible(false)
    None => ()
  }
  let ids : Array[String] = []
  for id in self.figure_sprites.keys() {
    ids.push(id)
  }
  for id in ids {
    match self.figure_sprites.get(id) {
      Some(sprite) => self.stage.remove_sprite(sprite)
      None => ()
    }
    self.figure_sprites.remove(id)
  }
  let live2d_ids : Array[String] = []
  for id in self.figure_live2d.keys() {
    live2d_ids.push(id)
  }
  for id in live2d_ids {
    match self.figure_live2d.get(id) {
      Some(model) => self.stage.remove_live2d(model)
      None => ()
    }
    self.figure_live2d.remove(id)
  }
}

///|
fn PixiPresenter::remove_target_animation_state(
  self : PixiPresenter,
  id : String,
) -> Unit {
  self.opacity_anims.remove(id)
  self.position_anims.remove(id)
  self.scale_anims.remove(id)
  self.rotation_anims.remove(id)
  self.blur_anims.remove(id)
  self.brightness_anims.remove(id)
  self.contrast_anims.remove(id)
  self.saturation_anims.remove(id)
  self.gamma_anims.remove(id)
  self.color_r_anims.remove(id)
  self.color_g_anims.remove(id)
  self.color_b_anims.remove(id)
  let prefix = id + "::"
  let keys : Array[String] = []
  for key in self.effect_start_ms.keys() {
    if key.has_prefix(prefix) {
      keys.push(key)
    }
  }
  for key in keys {
    self.effect_start_ms.remove(key)
    self.effect_signatures.remove(key)
    self.effect_from_params.remove(key)
  }
}

///|
fn[T] PixiPresenter::pull_new_animations(
  self : PixiPresenter,
  director : Director[T],
) -> Unit {
  let all = director.animations()
  for i, entry in all {
    if i < self.animation_cursor {
      continue
    }
    let (target, spec) = entry
    let target_map = match spec.prop {
      Position => {
        self.position_anims.set(target, {
          start_ms: self.timeline_ms,
          duration_ms: if self.skip_mode {
            0
          } else {
            spec.duration_ms
          },
          easing: spec.easing,
          from_x: anim_value(spec.from, 0),
          from_y: anim_value(spec.from, 1),
          to_x: anim_value(spec.to, 0),
          to_y: anim_value(spec.to, 1),
        })
        continue
      }
      Scale => {
        let (anchor_x, anchor_y) = anim_anchor(spec.anchor)
        self.scale_anims.set(target, {
          start_ms: self.timeline_ms,
          duration_ms: if self.skip_mode {
            0
          } else {
            spec.duration_ms
          },
          easing: spec.easing,
          from: anim_value(spec.from, 0),
          to: anim_value(spec.to, 0),
          anchor_x,
          anchor_y,
        })
        continue
      }
      Opacity => self.opacity_anims
      Rotation => self.rotation_anims
      Blur => self.blur_anims
      Brightness => self.brightness_anims
      Contrast => self.contrast_anims
      Saturation => self.saturation_anims
      Gamma => self.gamma_anims
      ColorRed => self.color_r_anims
      ColorGreen => self.color_g_anims
      ColorBlue => self.color_b_anims
    }
    target_map[target] = {
      start_ms: self.timeline_ms,
      duration_ms: if self.skip_mode {
        0
      } else {
        spec.duration_ms
      },
      easing: spec.easing,
      from: anim_value(spec.from, 0),
      to: anim_value(spec.to, 0),
    }
  }
  self.animation_cursor = all.length()
}

///|
async fn[T] PixiPresenter::pull_new_live2d_actions(
  self : PixiPresenter,
  director : Director[T],
) -> Unit noraise {
  let motions = director.live2d_motions()
  for i, entry in motions {
    if i < self.live2d_motion_cursor {
      continue
    }
    let (target, group, index) = entry
    match self.figure_live2d.get(target) {
      Some(model) => model.motion(group, index?) |> ignore
      None => ()
    }
  }
  self.live2d_motion_cursor = motions.length()

  let expressions = director.live2d_expressions()
  for i, entry in expressions {
    if i < self.live2d_expression_cursor {
      continue
    }
    let (target, id) = entry
    match self.figure_live2d.get(target) {
      Some(model) => model.set_expression(@js.Optional::from_option(id))
      None => ()
    }
  }
  self.live2d_expression_cursor = expressions.length()
}

///|
fn PixiPresenter::update_scalar_state(
  self : PixiPresenter,
  init_state : ScalarState,
  id : String,
) -> (Bool, ScalarState, ScalarAccumulator) {
  let mut changed = false
  let mut next_state = init_state
  let scalar_acc = ScalarAccumulator::from_scalar_state(init_state)
  fn apply_scalar_anim_to_state(
    anim_map : Map[String, ScalarAnim],
    get_value : (ScalarState) -> Double,
    set_value : (ScalarState, Double) -> ScalarState,
    set_acc : (Double) -> Unit,
  ) -> Unit {
    match anim_map.get(id) {
      Some(anim) => {
        let (animated, done) = apply_scalar_animation(
          get_value(next_state),
          self.timeline_ms,
          anim,
        )
        set_acc(animated)
        if done {
          anim_map.remove(id)
          match anim.to {
            Some(value) => {
              changed = true
              next_state = set_value(next_state, value)
            }
            None => ()
          }
        }
      }
      None => set_acc(get_value(next_state))
    }
  }
  apply_scalar_anim_to_state(
    self.opacity_anims,
    s => s.opacity,
    (s, v) => { ..s, opacity: v },
    v => scalar_acc.opacity = v,
  )
  apply_scalar_anim_to_state(
    self.rotation_anims,
    s => s.rotation,
    (s, v) => { ..s, rotation: v },
    v => scalar_acc.rotation = v,
  )
  apply_scalar_anim_to_state(
    self.blur_anims,
    s => s.blur,
    (s, v) => { ..s, blur: v },
    v => scalar_acc.blur = v,
  )
  apply_scalar_anim_to_state(
    self.brightness_anims,
    s => s.brightness,
    (s, v) => { ..s, brightness: v },
    v => scalar_acc.brightness = v,
  )
  apply_scalar_anim_to_state(
    self.contrast_anims,
    s => s.contrast,
    (s, v) => { ..s, contrast: v },
    v => scalar_acc.contrast = v,
  )
  apply_scalar_anim_to_state(
    self.saturation_anims,
    s => s.saturation,
    (s, v) => { ..s, saturation: v },
    v => scalar_acc.saturation = v,
  )
  apply_scalar_anim_to_state(
    self.gamma_anims,
    s => s.gamma,
    (s, v) => { ..s, gamma: v },
    v => scalar_acc.gamma = v,
  )
  apply_scalar_anim_to_state(
    self.color_r_anims,
    s => s.color_r,
    (s, v) => { ..s, color_r: v },
    v => scalar_acc.color_r = v,
  )
  apply_scalar_anim_to_state(
    self.color_g_anims,
    s => s.color_g,
    (s, v) => { ..s, color_g: v },
    v => scalar_acc.color_g = v,
  )
  apply_scalar_anim_to_state(
    self.color_b_anims,
    s => s.color_b,
    (s, v) => { ..s, color_b: v },
    v => scalar_acc.color_b = v,
  )
  (changed, next_state, scalar_acc)
}

///|
fn apply_sprite_transform(
  sprite : PixiSprite,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  rotation : Double,
  opacity : Double,
  visible : Bool,
  z_index : Int,
) -> Unit {
  sprite.set_size(w, h)
  sprite.set_position(x + w / 2.0, y + h / 2.0)
  sprite.set_rotation(rotation)
  sprite.set_alpha(opacity)
  sprite.set_visible(visible)
  sprite.set_z_index(z_index)
}

///|
fn apply_live2d_transform(
  model : PixiLive2dModel,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  rotation : Double,
  opacity : Double,
  visible : Bool,
  z_index : Int,
) -> Unit {
  model.set_position(x + w / 2.0, y + h / 2.0)
  model.set_size(w, h)
  model.set_rotation(rotation)
  model.set_alpha(opacity)
  model.set_visible(visible)
  model.set_z_index(z_index)
}

///|
fn PixiPresenter::resolve_figure_frame(
  self : PixiPresenter,
  id : String,
  placement : FigurePlacement,
  viewport_w : Double,
  viewport_h : Double,
  actual_w : Double,
  actual_h : Double,
  finished_position : Array[String],
  finished_scale : Array[String],
) -> (Double, Double, Double, Double, FigurePlacement, Bool, ScalarAccumulator) {
  let (base_x, base_y, max_w, max_h) = figure_rect(
    placement.pos,
    viewport_w,
    viewport_h,
  )
  let base_scale = placement.scalars.scale
  let base_scaled_w = actual_w * base_scale
  let base_scaled_h = actual_h * base_scale
  let (aligned_x, aligned_y) = match placement.pos {
    Center =>
      (
        (viewport_w - base_scaled_w) / 2.0,
        base_y + (max_h - base_scaled_h) / 2.0,
      )
    Left | Right =>
      (
        base_x + (max_w - base_scaled_w) / 2.0,
        base_y + (max_h - base_scaled_h) / 2.0,
      )
    Custom(x, y) =>
      custom_to_canvas_pos(
        x, y, viewport_w, viewport_h, base_scaled_w, base_scaled_h,
      )
  }

  let mut next_placement = placement
  let mut update_placement = false
  let (x1, y1) = match self.position_anims.get(id) {
    Some(anim) => {
      let (ax, ay, done) = apply_position_animation(
        aligned_x,
        aligned_y,
        self.config.position_entry_offset_ratio,
        viewport_h,
        viewport_w,
        self.timeline_ms,
        anim,
      )
      if done {
        finished_position.push(id)
        let has_custom = anim.from_x is Some(_) ||
          anim.from_y is Some(_) ||
          anim.to_x is Some(_) ||
          anim.to_y is Some(_)
        if has_custom {
          let (next_x, next_y) = canvas_to_custom_pos(
            ax, ay, viewport_w, viewport_h, base_scaled_w, base_scaled_h,
          )
          next_placement = { ..next_placement, pos: Custom(next_x, next_y) }
          update_placement = true
        }
      }
      (ax, ay)
    }
    None => (aligned_x, aligned_y)
  }

  let (x, y, w, h) = match self.scale_anims.get(id) {
    Some(anim) => {
      let (sx, sy, sw, sh, done) = apply_scale_animation(
        x1,
        y1,
        actual_w,
        actual_h,
        next_placement.scalars.scale,
        self.config.scale_entry_from,
        self.timeline_ms,
        anim,
      )
      if done {
        finished_scale.push(id)
        let anchor_changed = anim.anchor_x != 0.5 || anim.anchor_y != 0.5
        match anim.to {
          Some(value) => {
            let next_pos = if anchor_changed {
              let (next_x, next_y) = canvas_to_custom_pos(
                sx, sy, viewport_w, viewport_h, sw, sh,
              )
              Position::Custom(next_x, next_y)
            } else {
              next_placement.pos
            }
            next_placement = {
              pos: next_pos,
              layer: next_placement.layer,
              scalars: { ..next_placement.scalars, scale: value },
            }
            update_placement = true
          }
          None => ()
        }
      }
      (sx, sy, sw, sh)
    }
    None => (x1, y1, base_scaled_w, base_scaled_h)
  }

  let (changed, scalar_state, scalar_acc) = self.update_scalar_state(
    next_placement.scalars,
    id,
  )
  if changed {
    next_placement = { ..next_placement, scalars: scalar_state }
    update_placement = true
  }
  (x, y, w, h, next_placement, update_placement, scalar_acc)
}

///|
fn[T] PixiPresenter::sync_background(
  self : PixiPresenter,
  director : Director[T],
  viewport_w : Double,
  viewport_h : Double,
  active_effects : Set[String],
) -> Unit {
  match director.background_state() {
    Some(bg_state) => {
      let id = bg_state.id
      match self.last_background_id {
        Some(prev) => if prev != id { self.remove_target_animation_state(prev) }
        None => ()
      }
      self.last_background_id = Some(id)
      match self.texture_for(id) {
        Some(texture) => {
          self.refresh_video_texture_if_any(id)
          let cover_sprite = match self.background_cover_sprite {
            Some(sprite) => sprite
            None => {
              let sprite = PixiSprite::new(texture)
              sprite.set_anchor(0.5, 0.5)
              self.stage.add_sprite(sprite)
              self.background_cover_sprite = Some(sprite)
              sprite
            }
          }
          let sprite = match self.background_sprite {
            Some(sprite) => sprite
            None => {
              let sprite = PixiSprite::new(texture)
              sprite.set_anchor(0.5, 0.5)
              self.stage.add_sprite(sprite)
              self.background_sprite = Some(sprite)
              sprite
            }
          }
          cover_sprite.set_texture(texture)
          sprite.set_texture(texture)
          let (cover_x, cover_y, cover_w, cover_h) = fit_background_cover(
            id,
            viewport_w,
            viewport_h,
            self.texture_sizes,
          )
          let (base_x, base_y, base_w, base_h) = fit_background(
            id,
            viewport_w,
            viewport_h,
            self.texture_sizes,
          )
          let mut next_bg_state = bg_state
          let mut update_bg_state = false
          let mut x = base_x
          let mut y = base_y
          let mut w = base_w
          let mut h = base_h
          let base_scale = bg_state.scalars.scale
          if base_scale != 1.0 {
            let (sx, sy, sw, sh) = scale_rect_with_anchor(
              x, y, w, h, base_scale, 0.5, 0.5,
            )
            x = sx
            y = sy
            w = sw
            h = sh
          }
          match self.position_anims.get(id) {
            Some(anim) => {
              let (ax, ay, done) = apply_position_animation(
                x,
                y,
                self.config.position_entry_offset_ratio,
                viewport_h,
                viewport_w,
                self.timeline_ms,
                anim,
              )
              x = ax
              y = ay
              if done {
                self.position_anims.remove(id)
              }
            }
            None => ()
          }
          match self.scale_anims.get(id) {
            Some(anim) => {
              let (sx, sy, sw, sh, done) = apply_scale_animation(
                base_x,
                base_y,
                base_w,
                base_h,
                bg_state.scalars.scale,
                self.config.scale_entry_from,
                self.timeline_ms,
                anim,
              )
              x = sx
              y = sy
              w = sw
              h = sh
              if done {
                self.scale_anims.remove(id)
                match anim.to {
                  Some(value) => {
                    next_bg_state = {
                      id: next_bg_state.id,
                      scalars: { ..next_bg_state.scalars, scale: value },
                    }
                    update_bg_state = true
                  }
                  None => ()
                }
              }
            }
            None => ()
          }
          let (changed, next_scalars, scalar_acc) = self.update_scalar_state(
            next_bg_state.scalars,
            id,
          )
          let next_bg_state = { ..next_bg_state, scalars: next_scalars }
          update_bg_state = update_bg_state || changed
          if update_bg_state {
            director.set_background_state(next_bg_state)
          }
          apply_sprite_transform(
            cover_sprite,
            cover_x,
            cover_y,
            cover_w,
            cover_h,
            scalar_acc.rotation,
            scalar_acc.opacity,
            true,
            -1001,
          )
          let effects = director.effects(id)
          let cover_pre_skip = self.apply_effects_to_target(
            id,
            Sprite(cover_sprite),
            effects,
            active_effects,
            EffectPhase::Pre,
          )
          if cover_pre_skip {
            cover_sprite.set_visible(false)
          } else {
            self.apply_scalar_visuals_sprite(
              id + "#cover",
              cover_sprite,
              scalar_acc,
              extra_blur=2.0,
            )
            let cover_post_skip = self.apply_effects_to_target(
              id,
              Sprite(cover_sprite),
              effects,
              active_effects,
              EffectPhase::Post,
            )
            if cover_post_skip {
              cover_sprite.set_visible(false)
            }
          }
          apply_sprite_transform(
            sprite,
            x,
            y,
            w,
            h,
            scalar_acc.rotation,
            scalar_acc.opacity,
            true,
            -1000,
          )
          let base_pre_skip = self.apply_effects_to_target(
            id,
            Sprite(sprite),
            effects,
            active_effects,
            EffectPhase::Pre,
          )
          if base_pre_skip {
            sprite.set_visible(false)
          } else {
            self.apply_scalar_visuals_sprite(id, sprite, scalar_acc)
            let base_post_skip = self.apply_effects_to_target(
              id,
              Sprite(sprite),
              effects,
              active_effects,
              EffectPhase::Post,
            )
            if base_post_skip {
              sprite.set_visible(false)
            }
          }
        }
        None => {
          self.last_background_id = None
          match self.background_cover_sprite {
            Some(sprite) => sprite.set_visible(false)
            None => ()
          }
          match self.background_sprite {
            Some(sprite) => sprite.set_visible(false)
            None => ()
          }
        }
      }
    }
    None => {
      self.last_background_id = None
      match self.background_cover_sprite {
        Some(sprite) => sprite.set_visible(false)
        None => ()
      }
      match self.background_sprite {
        Some(sprite) => sprite.set_visible(false)
        None => ()
      }
    }
  }
}

///|
fn[T] PixiPresenter::sync_figures(
  self : PixiPresenter,
  director : Director[T],
  viewport_w : Double,
  viewport_h : Double,
  active_effects : Set[String],
) -> Unit {
  let figures = director.figures()
  let stale_ids : Array[String] = []
  for id in self.figure_sprites.keys() {
    if !figures.contains(id) {
      stale_ids.push(id)
    }
  }
  for id in self.figure_live2d.keys() {
    if !figures.contains(id) {
      stale_ids.push(id)
    }
  }
  for id in stale_ids {
    match self.figure_sprites.get(id) {
      Some(sprite) => self.stage.remove_sprite(sprite)
      None => ()
    }
    match self.figure_live2d.get(id) {
      Some(model) => self.stage.remove_live2d(model)
      None => ()
    }
    self.figure_sprites.remove(id)
    self.figure_live2d.remove(id)
    self.live2d_base_sizes.remove(id)
    self.remove_target_animation_state(id)
    self.blur_filters.remove(id)
    self.color_filters.remove(id)
  }

  let updated_figures : Array[(String, FigurePlacement)] = []
  let finished_position : Array[String] = []
  let finished_scale : Array[String] = []

  for id, placement in figures {
    match self.store.get_live2d_model(id) {
      Some(model_asset) => {
        let model_asset = model_asset
        match self.figure_sprites.get(id) {
          Some(sprite) => self.stage.remove_sprite(sprite)
          None => ()
        }
        self.figure_sprites.remove(id)

        let model = match self.figure_live2d.get(id) {
          Some(model) => model
          None => {
            model_asset.set_anchor(0.5, 0.5)
            model_asset.set_interactive(false)
            self.stage.add_live2d(model_asset)
            self.figure_live2d.set(id, model_asset)
            model_asset
          }
        }
        let (_, _, max_w, max_h) = figure_rect(
          placement.pos,
          viewport_w,
          viewport_h,
        )
        let (base_w, base_h) = match self.live2d_base_sizes.get(id) {
          Some(size) => size
          None => {
            let measured = (model.width(), model.height())
            let normalized = if measured.0 > 0.0 && measured.1 > 0.0 {
              measured
            } else {
              (1024.0, 1024.0)
            }
            self.live2d_base_sizes.set(id, normalized)
            normalized
          }
        }
        let (actual_w, actual_h) = fit_size_to_box(base_w, base_h, max_w, max_h)
        let (x, y, w, h, next_placement, update_placement, scalar_acc) = self.resolve_figure_frame(
          id, placement, viewport_w, viewport_h, actual_w, actual_h, finished_position,
          finished_scale,
        )

        apply_live2d_transform(
          model,
          x,
          y,
          w,
          h,
          scalar_acc.rotation,
          scalar_acc.opacity,
          true,
          placement.layer,
        )
        let effects = director.effects(id)
        let pre_skip = self.apply_effects_to_target(
          id,
          Live2d(model),
          effects,
          active_effects,
          EffectPhase::Pre,
        )
        if pre_skip {
          model.set_visible(false)
        } else {
          self.apply_scalar_visuals_sprite_live2d(id, model, scalar_acc)
          let post_skip = self.apply_effects_to_target(
            id,
            Live2d(model),
            effects,
            active_effects,
            EffectPhase::Post,
          )
          if post_skip {
            model.set_visible(false)
          }
        }
        if update_placement {
          updated_figures.push((id, next_placement))
        }
      }
      None =>
        match self.texture_for(id) {
          Some(texture) => {
            match self.figure_live2d.get(id) {
              Some(model) => self.stage.remove_live2d(model)
              None => ()
            }
            self.figure_live2d.remove(id)
            self.live2d_base_sizes.remove(id)

            self.refresh_video_texture_if_any(id)
            let sprite = match self.figure_sprites.get(id) {
              Some(sprite) => sprite
              None => {
                let sprite = PixiSprite::new(texture)
                sprite.set_anchor(0.5, 0.5)
                self.stage.add_sprite(sprite)
                self.figure_sprites.set(id, sprite)
                sprite
              }
            }
            sprite.set_texture(texture)
            let (_, _, max_w, max_h) = figure_rect(
              placement.pos,
              viewport_w,
              viewport_h,
            )
            let (actual_w, actual_h) = fit_figure(
              id,
              max_w,
              max_h,
              self.texture_sizes,
            )
            let (x, y, w, h, next_placement, update_placement, scalar_acc) = self.resolve_figure_frame(
              id, placement, viewport_w, viewport_h, actual_w, actual_h, finished_position,
              finished_scale,
            )

            apply_sprite_transform(
              sprite,
              x,
              y,
              w,
              h,
              scalar_acc.rotation,
              scalar_acc.opacity,
              true,
              placement.layer,
            )
            let effects = director.effects(id)
            let pre_skip = self.apply_effects_to_target(
              id,
              Sprite(sprite),
              effects,
              active_effects,
              EffectPhase::Pre,
            )
            if pre_skip {
              sprite.set_visible(false)
            } else {
              self.apply_scalar_visuals_sprite(id, sprite, scalar_acc)
              let post_skip = self.apply_effects_to_target(
                id,
                Sprite(sprite),
                effects,
                active_effects,
                EffectPhase::Post,
              )
              if post_skip {
                sprite.set_visible(false)
              }
            }
            if update_placement {
              updated_figures.push((id, next_placement))
            }
          }
          None => {
            match self.figure_sprites.get(id) {
              Some(sprite) => sprite.set_visible(false)
              None => ()
            }
            match self.figure_live2d.get(id) {
              Some(model) => model.set_visible(false)
              None => ()
            }
          }
        }
    }
  }

  for id in finished_position {
    if self.last_background_id != Some(id) {
      self.position_anims.remove(id)
    }
  }
  for id in finished_scale {
    if self.last_background_id != Some(id) {
      self.scale_anims.remove(id)
    }
  }
  for entry in updated_figures {
    let (id, placement) = entry
    figures.set(id, placement)
  }
}

///|
async fn[T] PixiPresenter::sync_noraise(
  self : PixiPresenter,
  director : Director[T],
  skip_mode : Bool,
) -> Unit noraise {
  self.skip_mode = skip_mode
  let epoch = director.render_epoch()
  match self.render_epoch {
    Some(prev) =>
      if prev != epoch {
        self.reset_render_state()
        self.render_epoch = Some(epoch)
      }
    None => self.render_epoch = Some(epoch)
  }

  self.update_timeline()
  self.pull_new_animations(director)
  let active_effects : Set[String] = Set::new()

  let viewport_w = window_inner_width()
  let viewport_h = window_inner_height()
  self.app.renderer_resize(viewport_w.to_int(), viewport_h.to_int())
  self.sync_background(director, viewport_w, viewport_h, active_effects)
  self.sync_figures(director, viewport_w, viewport_h, active_effects)
  self.pull_new_live2d_actions(director)
  for key in self.effect_start_ms.keys() {
    if !active_effects.contains(key) {
      self.effect_start_ms.remove(key)
      self.effect_signatures.remove(key)
      self.effect_from_params.remove(key)
    }
  }
}

///|
fn[T] PixiPresenter::as_render_sync_hook(
  self : PixiPresenter,
) -> RenderSyncHook[T] {
  (director, skip_mode) => self.sync_noraise(director, skip_mode)
}

///|
pub async fn[T] make_pixi_render_sync_hook_from_canvas(
  canvas_id : String,
  store : AssetStore,
) -> RenderSyncHook[T]? {
  make_pixi_render_sync_hook_from_canvas_with_config(
    canvas_id,
    store,
    PixiPresenterConfig::default(),
  )
}

///|
pub async fn[T] make_pixi_render_sync_hook_from_canvas_with_config(
  canvas_id : String,
  store : AssetStore,
  config : PixiPresenterConfig,
) -> RenderSyncHook[T]? {
  let canvas = get_canvas_by_id(canvas_id)
  match canvas {
    Some(c) =>
      Some(
        make_pixi_render_sync_hook_from_canvas_element_with_config(
          c, store, config,
        ),
      )
    None => None
  }
}

///|
pub async fn[T] make_pixi_render_sync_hook_from_canvas_element(
  canvas : PixiCanvas,
  store : AssetStore,
) -> RenderSyncHook[T] {
  make_pixi_render_sync_hook_from_canvas_element_with_config(
    canvas,
    store,
    PixiPresenterConfig::default(),
  )
}

///|
pub async fn[T] make_pixi_render_sync_hook_from_canvas_element_with_config(
  canvas : PixiCanvas,
  store : AssetStore,
  config : PixiPresenterConfig,
) -> RenderSyncHook[T] {
  let w = window_inner_width()
  let h = window_inner_height()
  set_canvas_element_size(canvas, w.to_int(), h.to_int())
  let presenter = PixiPresenter::new(canvas, store, config)
  presenter.as_render_sync_hook()
}
