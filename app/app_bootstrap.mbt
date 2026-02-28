///|
/// High-level bootstrap helpers that wire script runtime + UI + render sync.

///|
pub suberror AppBootstrapError {
  MissingImageAsset(id~ : String)
  MissingAudioAsset(id~ : String)
  MissingSaveSlot(slot~ : String)
}

///|
pub struct SaveSlotPayload {
  version : Int
  director_json : String
} derive(ToJson, FromJson)

///|
let save_slot_payload_version = 1

///|
fn encode_save_slot_payload(
  director_json : String,
  payload_version : Int,
) -> String {
  SaveSlotPayload::{ version: payload_version, director_json }
  .to_json()
  .stringify()
}

///|
fn decode_save_slot_payload(raw : String, payload_version : Int) -> String {
  let payload : SaveSlotPayload = @json.from_json(@json.parse(raw)) catch {
    _ => return raw
  }
  if payload.version == payload_version {
    payload.director_json
  } else {
    raw
  }
}

///|
pub fn[T] validate_script_image_assets(
  script : Script[T],
  store : AssetStore,
) -> Unit raise AppBootstrapError {
  for inst in script.instructions {
    match inst {
      ShowBackground(id) =>
        if store.get_image(id) is None && store.get_video(id) is None {
          raise AppBootstrapError::MissingImageAsset(id~)
        }
      ShowFigure(id, _) =>
        if store.get_image(id) is None && store.get_live2d_model(id) is None {
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
        if store.get_audio_url(id) is None {
          raise AppBootstrapError::MissingAudioAsset(id~)
        }
      PlaySfx(id, _) =>
        if store.get_audio_url(id) is None {
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
pub async fn[T] start_game(
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
pub async fn[T : FromJson] start_game_from_save(
  script : Script[T],
  save_json : String,
  ui_root_id : String,
  render_sync? : RenderSyncHook[T] = _ => (),
  event_hook? : EventHook = _ => (),
  settings? : GameSettings,
) -> GameRunner[T] {
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
  slot_payload_version? : Int = save_slot_payload_version,
) -> Unit {
  save_slot_write_in(
    save_namespace,
    slot,
    encode_save_slot_payload(director.save_json(), slot_payload_version),
  )
}

///|
pub fn[T : ToJson] save_runner_to_slot(
  runner : GameRunner[T],
  slot : String,
  save_namespace? : String = "global",
  slot_payload_version? : Int = save_slot_payload_version,
) -> Unit {
  save_director_to_slot(
    runner.director(),
    slot,
    save_namespace~,
    slot_payload_version~,
  )
}

///|
pub fn[T : ToJson] save_runner_to_slot_with_meta(
  runner : GameRunner[T],
  slot : String,
  title? : String = "",
  preview? : String = "",
  save_namespace? : String = "global",
  slot_payload_version? : Int = save_slot_payload_version,
) -> Unit {
  save_runner_to_slot(runner, slot, save_namespace~, slot_payload_version~)
  save_slot_write_meta_in(save_namespace, slot, save_slot_meta(title, preview))
}

///|
pub async fn[T : FromJson] start_game_from_slot(
  script : Script[T],
  slot : String,
  ui_root_id : String,
  render_sync? : RenderSyncHook[T] = _ => (),
  event_hook? : EventHook = _ => (),
  save_namespace? : String = "global",
  settings? : GameSettings,
  slot_payload_version? : Int = save_slot_payload_version,
) -> GameRunner[T] {
  match save_slot_read_in(save_namespace, slot) {
    Some(save_json) =>
      start_game_from_save(
        script,
        decode_save_slot_payload(save_json, slot_payload_version),
        ui_root_id,
        render_sync~,
        event_hook~,
        settings?,
      )
    None => raise AppBootstrapError::MissingSaveSlot(slot~)
  }
}
