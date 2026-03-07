///|
/// High-level bootstrap helpers that wire script runtime + UI + render sync.

///|
pub suberror AppBootstrapError {
  MissingImageAsset(id~ : String)
  MissingAudioAsset(id~ : String)
  MissingSaveSlot(slot~ : String)
  InvalidSavePayload(raw~ : String)
  UnsupportedSavePayloadVersion(expected~ : Int, found~ : Int)
}

///|
struct SaveSlotPayload {
  version : Int
  director_json : String
  dialog_history : Array[DialogLogEntry]
} derive(ToJson, FromJson)

///|
let save_slot_payload_version = 2

///|
fn encode_save_slot_payload(
  director_json : String,
  dialog_history : Array[DialogLogEntry],
) -> String {
  SaveSlotPayload::{
    version: save_slot_payload_version,
    director_json,
    dialog_history,
  }
  .to_json()
  .stringify()
}

///|
fn decode_save_slot_payload(
  raw : String,
) -> SaveSlotPayload raise AppBootstrapError {
  let payload : SaveSlotPayload = @json.from_json(@json.parse(raw)) catch {
    _ => raise AppBootstrapError::InvalidSavePayload(raw~)
  }
  if payload.version != save_slot_payload_version {
    raise AppBootstrapError::UnsupportedSavePayloadVersion(
      expected=save_slot_payload_version,
      found=payload.version,
    )
  }
  payload
}

///|
fn[T] validate_script_image_assets(
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
fn[T] validate_script_audio_assets(
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
fn[T] validate_script_assets(
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
  render_sync? : RenderSyncHook[T] = (_, _) => (),
  event_hook? : EventHook = _ => (),
  settings? : GameSettings,
  ui_strings? : UiStrings = UiStrings::default(),
  script_locale_json? : String = "",
  script_default_locale_json? : String = "",
  vocal_locale_dir? : String = "",
  script_locale? : String = "",
  script_default_locale? : String = "",
  gallery_ns? : String = "global",
) -> GameRunner[T] noraise {
  let runtime = Runtime::new(script, state)
  let director = Director::new(runtime, gallery_ns~)
  let ui = UiDom::new(
    ui_root_id,
    ui_strings~,
    script_locale_json~,
    script_default_locale_json~,
    vocal_locale_dir~,
    script_locale~,
    script_default_locale~,
  )
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
  render_sync? : RenderSyncHook[T] = (_, _) => (),
  event_hook? : EventHook = _ => (),
  settings? : GameSettings,
  ui_strings? : UiStrings = UiStrings::default(),
  script_locale_json? : String = "",
  script_default_locale_json? : String = "",
  vocal_locale_dir? : String = "",
  script_locale? : String = "",
  script_default_locale? : String = "",
  gallery_ns? : String = "global",
  dialog_history? : Array[DialogLogEntry] = [],
) -> GameRunner[T] {
  let director = Director::from_save_json(script, save_json, gallery_ns~)
  director.set_dialog_history(dialog_history)
  let ui = UiDom::new(
    ui_root_id,
    ui_strings~,
    script_locale_json~,
    script_default_locale_json~,
    vocal_locale_dir~,
    script_locale~,
    script_default_locale~,
  )
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
  save_store? : &SaveSlotStore = default_save_slot_storage(),
) -> Unit {
  save_store.write_slot(
    save_namespace,
    slot,
    encode_save_slot_payload(director.save_json(), director.dialog_history()),
  )
}

///|
pub fn[T : ToJson] save_runner_to_slot(
  runner : GameRunner[T],
  slot : String,
  save_namespace? : String = "global",
  save_store? : &SaveSlotStore = default_save_slot_storage(),
) -> Unit {
  save_director_to_slot(runner.director(), slot, save_namespace~, save_store~)
}

///|
pub fn[T : ToJson] save_runner_to_slot_with_meta(
  runner : GameRunner[T],
  slot : String,
  title? : String = "",
  preview? : String = "",
  save_namespace? : String = "global",
  save_store? : &SaveSlotStore = default_save_slot_storage(),
) -> Unit {
  save_runner_to_slot(runner, slot, save_namespace~, save_store~)
  save_store.write_slot_meta(
    save_namespace,
    slot,
    save_slot_meta(title, preview),
  )
}

///|
pub async fn[T : FromJson] start_game_from_slot(
  script : Script[T],
  slot : String,
  ui_root_id : String,
  render_sync? : RenderSyncHook[T] = (_, _) => (),
  event_hook? : EventHook = _ => (),
  save_namespace? : String = "global",
  save_store? : &SaveSlotStore = default_save_slot_storage(),
  settings? : GameSettings,
  ui_strings? : UiStrings = UiStrings::default(),
  script_locale_json? : String = "",
  script_default_locale_json? : String = "",
  vocal_locale_dir? : String = "",
  script_locale? : String = "",
  script_default_locale? : String = "",
  gallery_ns? : String = "global",
) -> GameRunner[T] {
  match save_store.read_slot(save_namespace, slot) {
    Some(save_json) => {
      let payload = decode_save_slot_payload(save_json)
      start_game_from_save(
        script,
        payload.director_json,
        ui_root_id,
        render_sync~,
        event_hook~,
        settings?,
        ui_strings~,
        script_locale_json~,
        script_default_locale_json~,
        vocal_locale_dir~,
        script_locale~,
        script_default_locale~,
        gallery_ns~,
        dialog_history=payload.dialog_history,
      )
    }
    None => raise AppBootstrapError::MissingSaveSlot(slot~)
  }
}
