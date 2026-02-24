///|
/// High-level bootstrap helpers that wire script runtime + UI + render sync.

///|
pub suberror AppBootstrapError {
  MissingImageAsset(id~ : String)
  MissingAudioAsset(id~ : String)
  MissingSaveSlot(slot~ : String)
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
      PlaySfx(id, _) =>
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
pub fn[T] start_game(
  script : Script[T],
  state : GameState[T],
  ui_root_id : String,
  render_sync? : RenderSyncHook[T] = _ => (),
  event_hook? : EventHook = _ => (),
  settings? : GameSettings,
) -> GameRunner[T] {
  let runtime = Runtime::new(script, state)
  let director = Director::new(runtime)
  let ui = UiDom::new(ui_root_id)
  let runner = GameRunner::new_with_hooks(director, ui, render_sync, event_hook)
  match settings {
    Some(s) => runner.apply_settings(s)
    None => ()
  }
  runner.sync_ui()
  runner
}

///|
pub fn[T : FromJson] start_game_from_save(
  script : Script[T],
  save_json : String,
  ui_root_id : String,
  render_sync? : RenderSyncHook[T] = _ => (),
  event_hook? : EventHook = _ => (),
  settings? : GameSettings,
) -> GameRunner[T] raise {
  let director = director_from_save_json(script, save_json)
  let ui = UiDom::new(ui_root_id)
  let runner = GameRunner::new_with_hooks(director, ui, render_sync, event_hook)
  match settings {
    Some(s) => runner.apply_settings(s)
    None => ()
  }
  match runner.director().take_interrupted_sfx() {
    Some(id) => event_hook(SfxPlayed(id, false))
    None => ()
  }
  runner.sync_ui()
  runner
}

///|
pub fn[T : ToJson] save_director_to_slot(
  director : Director[T],
  slot : String,
  save_namespace? : String = "global",
) -> Unit {
  save_slot_write_in(save_namespace, slot, director.save_json())
}

///|
pub fn[T : ToJson] save_runner_to_slot(
  runner : GameRunner[T],
  slot : String,
  save_namespace? : String = "global",
) -> Unit {
  save_director_to_slot(runner.director(), slot, save_namespace~)
}

///|
pub fn[T : ToJson] save_runner_to_slot_with_meta(
  runner : GameRunner[T],
  slot : String,
  title? : String = "",
  preview? : String = "",
  save_namespace? : String = "global",
) -> Unit {
  save_runner_to_slot(runner, slot, save_namespace~)
  save_slot_write_meta_in(save_namespace, slot, save_slot_meta(title, preview))
}

///|
pub fn[T : FromJson] start_game_from_slot(
  script : Script[T],
  slot : String,
  ui_root_id : String,
  render_sync? : RenderSyncHook[T] = _ => (),
  event_hook? : EventHook = _ => (),
  save_namespace? : String = "global",
  settings? : GameSettings,
) -> GameRunner[T] raise {
  match save_slot_read_in(save_namespace, slot) {
    Some(save_json) =>
      start_game_from_save(
        script,
        save_json,
        ui_root_id,
        render_sync~,
        event_hook~,
        settings?,
      )
    None => raise AppBootstrapError::MissingSaveSlot(slot~)
  }
}

///|
pub fn[T] start_game_webgl(
  script : Script[T],
  state : GameState[T],
  ui_root_id : String,
  gl : WebGL,
  store : AssetStore,
  presenter_config? : WebglPresenterConfig = webgl_presenter_default_config(),
  settings? : GameSettings,
) -> GameRunner[T] raise {
  validate_script_assets(script, store)
  let render_sync = make_webgl_render_sync_hook_with_config(
    gl, store, presenter_config,
  )
  start_game(script, state, ui_root_id, render_sync~, settings?)
}

///|
pub fn[T] start_game_webgl_with_audio(
  script : Script[T],
  state : GameState[T],
  ui_root_id : String,
  gl : WebGL,
  store : AssetStore,
  audio : AudioDom,
  presenter_config? : WebglPresenterConfig = webgl_presenter_default_config(),
  settings? : GameSettings,
) -> GameRunner[T] raise {
  validate_script_assets(script, store)
  match settings {
    Some(s) => audio.apply_settings(s)
    None => ()
  }
  let render_sync = make_webgl_render_sync_hook_with_config(
    gl, store, presenter_config,
  )
  start_game(
    script,
    state,
    ui_root_id,
    render_sync~,
    event_hook=audio.as_event_hook(),
    settings?,
  )
}
