///|
/// High-level bootstrap helpers that wire script runtime + UI + render sync.

///|
pub suberror AppBootstrapError {
  MissingImageAsset(id~ : String)
  MissingAudioAsset(id~ : String)
}

///|
pub fn[T] validate_script_image_assets(
  script : Script[T],
  store : AssetStore,
) -> Unit raise AppBootstrapError {
  for inst in script.instructions {
    match inst {
      ShowBackground(id) =>
        if store.get_image(id) is None {
          raise AppBootstrapError::MissingImageAsset(id~)
        }
      ShowFigure(id, _) =>
        if store.get_image(id) is None {
          raise AppBootstrapError::MissingImageAsset(id~)
        }
      _ => ()
    }
  }
}

///|
pub fn[T] validate_script_audio_assets(
  script : Script[T],
  store : AssetStore,
) -> Unit raise AppBootstrapError {
  for inst in script.instructions {
    match inst {
      PlayMusic(id, _) =>
        if store.get_bytes(id) is None {
          raise AppBootstrapError::MissingAudioAsset(id~)
        }
      PlaySfx(id) =>
        if store.get_bytes(id) is None {
          raise AppBootstrapError::MissingAudioAsset(id~)
        }
      _ => ()
    }
  }
}

///|
pub fn[T] validate_script_assets(
  script : Script[T],
  store : AssetStore,
) -> Unit raise AppBootstrapError {
  validate_script_image_assets(script, store)
  validate_script_audio_assets(script, store)
}

///|
pub fn[T] start_game_with_render_sync(
  script : Script[T],
  state : GameState[T],
  ui_root_id : String,
  render_sync : RenderSyncHook[T],
) -> GameRunner[T] {
  let runtime = Runtime::new(script, state)
  let director = Director::new(runtime)
  let runner = GameRunner::new_with_render_sync(
    director,
    UiDom::new(ui_root_id),
    render_sync,
  )
  runner.sync_ui()
  runner
}

///|
pub fn[T] start_game_webgl(
  script : Script[T],
  state : GameState[T],
  ui_root_id : String,
  gl : WebGL,
  store : AssetStore,
  viewport_w : Double,
  viewport_h : Double,
) -> GameRunner[T] raise {
  validate_script_assets(script, store)
  let render_sync = make_webgl_render_sync_hook(
    gl, store, viewport_w, viewport_h,
  )
  start_game_with_render_sync(script, state, ui_root_id, render_sync)
}
