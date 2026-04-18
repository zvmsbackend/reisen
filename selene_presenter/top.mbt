///|
using @core {type Position}

///|
using @presenter_common {
  animation_anchor,
  animation_lerp,
  animation_sample,
  animation_scalar_source,
  animation_scalar_target,
  animation_vec2_source,
  animation_vec2_target,
}

///|
using @engine {
  type CoreRenderSnapshot,
  type RenderSyncHook,
  type RenderExtensionHook,
  type RenderExtensionView,
  type RenderExtensionUpdate,
}

///|
pub type UiOverlayProvider = () -> Array[@selene_render2d_types.DrawCommand2D]

///|
pub fn combine_ui_overlay_providers(
  primary : UiOverlayProvider?,
  secondary : UiOverlayProvider?,
) -> UiOverlayProvider? {
  match (primary, secondary) {
    (None, None) => None
    (Some(provider), None) => Some(provider)
    (None, Some(provider)) => Some(provider)
    (Some(a), Some(b)) =>
      Some(() => {
        let commands = a()
        for command in b() {
          commands.push(command)
        }
        commands
      })
  }
}

///|
pub struct SelenePresenterConfig {
  viewport_w : Double
  viewport_h : Double
  animation_step_ms : Int
  placeholder_background_color : @selene_render.Color
  placeholder_figure_color : @selene_render.Color
}

///|
pub impl Default for SelenePresenterConfig with default() {
  {
    viewport_w: 1280.0,
    viewport_h: 720.0,
    animation_step_ms: 16,
    placeholder_background_color: { r: 32, g: 36, b: 48, a: 1.0 },
    placeholder_figure_color: { r: 220, g: 228, b: 242, a: 1.0 },
  }
}

///|
priv struct ActiveAnimation {
  target : String
  prop : @core.AnimProp
  easing : @core.Easing
  duration_ms : Int
  anchor_x : Double
  anchor_y : Double
  from : Array[Double]
  to : Array[Double]
  mut elapsed_ms : Int
}

///|
priv struct EffectApplyResult {
  scalars : @core.ScalarState
  has_active_timed_effect : Bool
  active_effect_keys : Set[String]
}

///|
struct SelenePresenter {
  config : SelenePresenterConfig
  asset_store : @assets_selene.NativeAssetStore
  active_animations : Map[String, ActiveAnimation]
  effect_signatures : Map[String, String]
  effect_start_ms : Map[String, Int]
  effect_from_params : Map[String, Array[(String, Double)]]
  warned_capabilities : Set[String]
  mut ui_overlay_provider : UiOverlayProvider?
  mut has_active_timed_effects : Bool
  mut last_world_commands : Array[@selene_render2d_types.DrawCommand2D]
  mut last_submitted_epoch : String?
  mut force_submit : Bool
}

///|
pub fn SelenePresenter::new(
  asset_store? : @assets_selene.NativeAssetStore = @assets_selene.NativeAssetStore::new(),
  config? : SelenePresenterConfig = SelenePresenterConfig::default(),
) -> SelenePresenter {
  {
    config,
    asset_store,
    active_animations: {},
    effect_signatures: {},
    effect_start_ms: {},
    effect_from_params: {},
    warned_capabilities: Set::new(),
    ui_overlay_provider: None,
    has_active_timed_effects: false,
    last_world_commands: [],
    last_submitted_epoch: None,
    force_submit: true,
  }
}

///|
pub fn SelenePresenter::set_ui_overlay_provider(
  self : SelenePresenter,
  provider : UiOverlayProvider?,
) -> Unit {
  self.ui_overlay_provider = provider
  self.force_submit = true
}

///|
pub fn SelenePresenter::set_ui_overlay_providers(
  self : SelenePresenter,
  primary : UiOverlayProvider?,
  secondary : UiOverlayProvider?,
) -> Unit {
  self.set_ui_overlay_provider(combine_ui_overlay_providers(primary, secondary))
}

///|
fn SelenePresenter::lookup_image_handle(
  self : SelenePresenter,
  id : String,
) -> @selene_asset_types.ImageHandle? {
  self.asset_store.get_image_handle(id)
}

///|
pub fn SelenePresenter::submit_core_snapshot(
  self : SelenePresenter,
  snapshot : CoreRenderSnapshot,
) -> Unit {
  if !self.force_submit &&
    self.active_animations.is_empty() &&
    !self.has_active_timed_effects {
    if self.last_submitted_epoch is Some(epoch) &&
      epoch == snapshot.render_epoch {
      return
    }
  }
  self.submit_frame(snapshot)
  self.last_submitted_epoch = Some(snapshot.render_epoch)
  self.force_submit = false
}

///|
pub fn SelenePresenter::as_core_render_sync_hook(
  self : SelenePresenter,
) -> RenderSyncHook {
  (snapshot, _skip_mode) => self.submit_core_snapshot(snapshot)
}

///|
pub fn SelenePresenter::as_render_hooks(
  self : SelenePresenter,
) -> (RenderSyncHook, RenderExtensionHook) {
  (
    self.as_core_render_sync_hook(),
    (extension, skip_mode) => self.sync_render_extension(extension, skip_mode),
  )
}
