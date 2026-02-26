# Reisen - Visual Novel Engine in MoonBit

Reisen is a visual novel engine for MoonBit targeting the browser (DOM + PixiJS canvas rendering).

## Features

- Scripted dialogue flow with labels, jumps, choices, and waits
- Runtime events for UI, audio, rendering, and tooling hooks
- Save/load slots and persistent settings in localStorage
- Start menu / settings / gallery flow via `AppController`
- Pixi presenter with animation/effect support

## Install

Clone the [template repository](https://github.com/zvmsbackend/reisen_template)

```bash
npm install
moon build --release
npm dev
```

## Quick Script Example

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
let my_script : Script[MyGameData] = try! script(builder => {
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
```

## Start a Game

```moonbit nocheck
///|
fn main {
  let runner = start_game(my_script, initial_state(), "ui-root")
  run_browser_loop(runner)
}
```

## Start With AppController

`AppController` manages transitions between start menu, gallery, settings, and in-game.

```moonbit nocheck
///|
fn main {
  let controller = AppController::new(
    my_script,
    initial_state,
    "ui-root",
    menu_background="assets/menu.jpg",
    settings_background="assets/settings.jpg",
    gallery_background="assets/gallery.jpg",
  )
  run_browser_app_loop(controller)
}
```

Gallery entry visibility is automatic: it appears when at least one gallery image is registered.

## Gallery Registration and Unlocking

```moonbit nocheck
let cg_ending = GalleryImage::new(
  "cg_ending_1",
  "assets/cg/ending_1.jpg",
  title="First Ending",
  replay_label="ending_1_replay",
)

gallery_register_image(cg_ending)
gallery_unlock_image(cg_ending)
```

You can also unlock from script:

```moonbit nocheck
let cg_scene = GalleryImage::new("cg_scene", "assets/cg/scene.jpg")
gallery_register_image(cg_scene)

let script_unlock : Script[Unit] = try! script(builder => {
  builder.unlock_cg(cg_scene)
})
```

## Asset Loading and Pixi Bootstrapping

```moonbit nocheck
///|
async fn init_pixi() -> Unit {
  let store = AssetStore::new()
  let _ = store.register_background("assets/bg/temple.jpg", id="bg_temple")
  let _ = store.register_figure("assets/fg/miko.png", id="miko")
  let audio = AudioDom::new()
  store.put_bytes("door_close", load_bytes("assets/sfx/door_close.ogg"))

  let render_sync = make_pixi_render_sync_hook_from_canvas("gl-canvas", store).unwrap()

  let controller = AppController::new(
    my_script,
    initial_state,
    "ui-root",
    event_hook=audio.as_event_hook(),
    render_sync~,
  )
  run_browser_app_loop(controller)
}
```

## Save and Load

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

## Settings

```moonbit nocheck
let settings = GameSettings::{
  text_speed: 50,
  bgm_volume: 0.7,
  sfx_volume: 0.8,
}

settings_write(settings)
let loaded = settings_read()
```

## Runtime Events

Main `RuntimeEvent` variants include:

- `Said(...)`, `ChoicePrompt(...)`, `TextInputPrompt(...)`
- `BackgroundShown(...)`, `FigureShown(...)`, `FigureHidden(...)`
- `MusicPlayed(...)`, `SfxPlayed(...)`, `SfxStopped`
- `Animated(...)`, `EffectApplied(...)`
- `WaitStarted(...)`, `WaitForClickStarted`, `ScriptEnded`

Event hook example:

```moonbit nocheck
///|
let runner = start_game(my_script, initial_state(), "ui-root", event_hook=event => {
  match event {
    MusicPlayed(id, loop_) => ignore((id, loop_))
    SfxPlayed(id, blocking) => ignore((id, blocking))
    _ => ()
  }
})
```

## Text Script Parser

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
