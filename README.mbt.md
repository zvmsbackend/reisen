# Reisen - Visual Novel Engine in MoonBit

Reisen is a browser-focused visual novel engine for MoonBit.
Current module layout is subpackage-first (`core`, `assets`, `engine`, `app`, `presenter`, etc.), and the examples below follow the current APIs.

## Install

Clone the [template repository](https://github.com/zvmsbackend/reisen_template)

```bash
npm install
moon build --release
npm run dev
```

## Subpackages

- `sennenki/reisen/core`: script AST, builder DSL, runtime, text parser
- `sennenki/reisen/state`: `GameState`
- `sennenki/reisen/assets`: asset types + `AssetStore`
- `sennenki/reisen/gallery`: gallery registry + unlock/replay metadata
- `sennenki/reisen/engine`: `Director`, `GameRunner`
- `sennenki/reisen/presenter`: Pixi render-sync hook builders
- `sennenki/reisen/app`: bootstrap helpers, app loop, `AppController`
- `sennenki/reisen/ui`, `sennenki/reisen/pixi`, `sennenki/reisen/storage`, `sennenki/reisen/util`: supporting packages

## Quick Script Example (`core` + `state`)

```moonbit nocheck
///|
pub struct MyGameData {
  player_name : String
  affection : Int
} derive(ToJson, FromJson)

///|
fn initial_state() -> GameState[MyGameData] {
  GameState::new({ player_name: "Guest", affection: 0 })
}

///|
let start : Label = label()

///|
let pray : Label = label()

///|
let pass : Label = label()

///|
let continue_ : Label = label()

///|
let my_script_factory : ScriptFactory[MyGameData] = () => {
  try! script(builder => {
    builder
    ..label(start)
    ..say("Miko", "Welcome.")
    ..menu("Miko", "Choose:", [
      option("Pray", pray, id="pray"),
      option("Pass", pass, id="pass"),
    ])
    ..label(pray)
    ..run_code(state => {
      let d = state.get_user_data()
      state.set_user_data({ ..d, affection: d.affection + 1 })
    })
    ..jump(continue_)
    ..label(pass)
    ..jump(continue_)
    ..label(continue_)
    ..wait_click()
    .jump(start)
  })
}
```

## Asset Loading + Presenter Hook (`assets` + `presenter`)

```moonbit nocheck
///|
async fn prepare_assets() -> AssetStore {
  let store = AssetStore::new()
  let _ = store.register_background("assets/bg/temple.jpg", id="bg_temple")
  let _ = store.register_figure("assets/fg/miko.png", id="miko")
  let _ = store.register_music("assets/bgm/theme.ogg", id="bgm_theme")
  store
}

///|
async fn prepare_render_sync(store : AssetStore) -> RenderSyncHook[MyGameData]? {
  let config = try! PixiPresenterConfig::new(
    background_alpha=0.0,
    resolution=1.0,
    position_entry_offset_ratio=0.04,
    scale_entry_from=0.0,
  )
  make_pixi_render_sync_hook_from_canvas_with_config("gl-canvas", store, config)
}
```

## Start With AppController (`app`)

`AppController` handles start menu, settings, gallery, and in-game transitions.

```moonbit nocheck
///|
async fn main {
  let store = prepare_assets()
  validate_script_assets(my_script, store)

  let render_sync = prepare_render_sync(store).unwrap()

  let controller = AppController::new(
    my_script_factory,
    initial_state,
    "ui-root",
    store,
    menu_background="bg_temple",
    settings_background="bg_temple",
    gallery_background="bg_temple",
    render_sync~,
  )
  run_browser_app_loop(controller)
}
```

## Gallery Registration and Unlocking (`gallery`)

```moonbit nocheck
let cg_ending = GalleryImage::new(
  "assets/cg/ending_1.jpg",
  id="cg_ending_1",
  title="First Ending",
  replay_label="ending_1_replay",
)

register_image(cg_ending)
unlock_image(cg_ending)
```

You can also unlock from script:

```moonbit nocheck
let script_unlock : Script[Unit] = try! script(builder => {
  builder.unlock_cg(cg_ending)
})
```

## Save and Load (`app`)

```moonbit nocheck
save_runner_to_slot(runner, "slot1", save_namespace="mygame")

save_runner_to_slot_with_meta(
  runner,
  "slot1",
  title="Chapter 1",
  preview="Temple Entrance",
  save_namespace="mygame",
)

let restored = start_game_from_slot(
  my_script,
  "slot1",
  "ui-root",
  save_namespace="mygame",
)
```

## Runtime Events (`core`)

Main `RuntimeEvent` variants include:

- `Said(...)`, `ChoicePrompt(...)`, `TextInputPrompt(...)`
- `BackgroundShown(...)`, `FigureShown(...)`, `FigureHidden(...)`
- `MusicPlayed(...)`, `SfxPlayed(...)`, `SfxStopped`
- `AnimatedPixi(...)`, `AnimatedDom(...)`, `EffectApplied(...)`
- `WaitStarted(...)`, `WaitForClickStarted`, `ScriptEnded`

Event hook example:

```moonbit nocheck
let runner = start_game(my_script, initial_state(), "ui-root", event_hook=event => {
  match event {
    MusicPlayed(id, loop_) => ignore((id, loop_))
    SfxPlayed(id, blocking) => ignore((id, blocking))
    _ => ()
  }
})
```

## Text Script Parser (`core`)

```moonbit nocheck
///|
let text =
  #|label: start
  #|say: Narrator, Hello
  #|wait: click
  #|jump: start

///|
let parsed : Script[Unit] = try! reisen_parse_text_script(text)
```

Append text script into a builder:

```moonbit nocheck
///|
let combined : Script[Unit] = try! script(builder => {
  builder.load_text("label: start\nsay: Narrator, Hello")
})
```

Supported text commands include `label`, `jump`, `wait`, `wait_click`, `unlock_cg`, `say`, `narrate`, `scene`, `show`, `hide`, `music`, `sfx`, `animate`, `effect`, `choice`, and `input`.
