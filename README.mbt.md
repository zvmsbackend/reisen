# Reisen - Visual Novel Engine in MoonBit

A visual novel engine built in MoonBit, rendered in the browser via WebGL.

## Features

- Layered rendering (backgrounds, figures, UI)
- Audio playback (music + sound effects)
- Script-based storytelling with branching choices
- Save/load system with multiple slots
- Typewriter text effect
- Basic animations (fade, move, scale)
- Start menu, settings, and autosave

## Quick Start

### Add and Build

```bash
moon add sennenki/reisen
moon build 
```

### Run

Copy `index.html` and `stylesheet.css` from `.mooncakes/sennenki/reisen` to the project root. Fill in the HTML template, then serve the output directory with any static file server:

```bash
npx serve .
# or
python -m http.server 8080
```

Then open `index.html` in your browser.

## Project Structure

```
reisen/
├── index.html          # HTML entry point template
├── style.css           # Default stylesheet
├── app_bootstrap.mbt   # High-level game startup helpers
├── app_controller.mbt  # Start menu / settings / game flow
├── app_loop.mbt        # Browser animation frame loop
├── audio_dom.mbt       # Web Audio API integration
├── director.mbt        # Script execution coordinator
├── game_runner.mbt     # Game loop + UI sync
├── game_state.mbt      # Mutable game state (flags, variables)
├── render_bootstrap.mbt # WebGL initialization
├── render_runtime.mbt  # WebGL rendering pipeline
├── save_slots.mbt      # Browser localStorage save/load
├── script_ast.mbt      # Script instruction types
├── script_builder.mbt  # DSL for authoring scripts
├── script_runtime.mbt  # Script execution engine
├── ui_dom.mbt          # HTML UI rendering
├── webgl.mbt           # Low-level WebGL bindings
└── webgl_presenter.mbt # Render state -> WebGL
```

## Writing a Game

### 1. Define Your Game State

```mbt check
///|
pub struct MyGameData {
  player_name : String
  affection : Int
} derive(ToJson, FromJson)

///|
fn initial_state() -> GameState[MyGameData] {
  GameState::new({ player_name: "Guest", affection: 0 })
}
```

### 2. Author Your Script

```mbt check
let my_script : Script[MyGameData] = try! script(builder => {
  builder.label("start")
  builder.scene("bg_temple")
  builder.say("???", "Welcome to the temple.")
  builder.say("Miko", "Ah, a visitor! What brings you here?")
  builder.menu(
    "Miko",
    "Choose your response:",
    [
      option("1", "I'm here to pray.", "pray"),
      option("2", "Just passing through.", "pass"),
    ],
  )

  builder.label("pray")
  builder.show_figure("miko", place_center(layer=1))
  builder.say("Miko", "How reverent of you!")
  // Track affection
  builder.run_code("affection_plus", state => {
    let data = state.get_user_data()
    state.set_user_data({ ..data, affection: data.affection + 1 })
  })
  builder.jump("continue")

  builder.label("pass")
  builder.show_figure("miko", place_right(layer=1))
  builder.say("Miko", "I see. Well, feel free to look around.")
  builder.jump("continue")

  builder.label("continue")
  builder.say("Miko", "May the spirits guide you.")
  builder.play_sfx("door_close")
  builder.wait(1000)
  builder.jump("start")
})
```

### 3. Initialize Assets

```mbt check
let store : AssetStore = AssetStore::new()

// In browser: load assets asynchronously at startup
async fn load_assets() -> AssetStore {
  let store = AssetStore::new()
  store.put_image("bg_temple", load_image("/assets/bg_temple.png"))
  store.put_image("miko", load_image("/assets/miko.png"))
  store.put_bytes("door_close", load_bytes("/assets/sfx/door_close.ogg"))
  store
}
```

### 4. Start the Game

#### Simple Version (No WebGL)

```mbt check
///|
fn init {
  let runner = start_game(my_script, initial_state(), "ui-root")
  run_browser_loop(runner)
}
```

#### With WebGL Rendering

```mbt check
///|
async fn initialize() -> Unit raise {
  let store = load_assets() // your async asset loader
  let canvas = get_canvas_by_id("gl-canvas").unwrap()
  let gl = canvas.get_webgl_context().unwrap()
  let runner = start_game_webgl(
    my_script,
    initial_state(),
    "ui-root",
    gl,
    store,
    1280.0,
    720.0,
  )
  run_browser_loop(runner)
}
```

#### Full App with Menu (Recommended)

```mbt check
fn init {
  let controller = AppController::new(
    my_script,
    initial_state,
    "ui-root",
    render_sync= director => {
      // sync WebGL to director state
      ()
    },
  )
  run_browser_app_loop(controller)
}
```

## Script DSL Reference

### Narration & Dialogue

| Method | Description |
|--------|-------------|
| `narrate(text)` | Display narration text without speaker |
| `say(speaker, text)` | Display dialogue with speaker name |
| `menu(speaker, prompt, options)` | Show dialogue then choice menu |

### Flow Control

| Method | Description |
|--------|-------------|
| `label(name)` | Define a jump target |
| `jump(label)` | Unconditional jump |
| `jump_if(label, predicate)` | Conditional jump |
| `branch(then_label, else_label, predicate)` | Two-way branch |
| `wait(ms)` | Pause execution for milliseconds |

### Scene & Figures

| Method | Description |
|--------|-------------|
| `scene(background_id)` | Show background image |
| `show_figure(id, placement)` | Show character sprite |
| `show_figure_at(id, position, layer?, opacity?)` | Show with position shorthand |
| `hide_figure(id)` | Hide character sprite |

### Audio

| Method | Description |
|--------|-------------|
| `play_music(track_id, loop?)` | Play BGM (default loop=true) |
| `stop_music()` | Stop BGM |
| `play_sfx(track_id)` | Play sound effect (one-shot) |

### Animations

| Method | Description |
|--------|-------------|
| `animate(id, spec)` | Animate figure by ID |
| `animate_opacity(id, duration_ms, easing?)` | Fade in/out |
| `animate_position(id, duration_ms, easing?)` | Move |
| `animate_scale(id, duration_ms, easing?)` | Scale |

### Code Hooks

| Method | Description |
|--------|-------------|
| `run_code(id, hook)` | Execute arbitrary MoonBit code |

### Position Helpers

```mbt nocheck
place_left(layer?, opacity?)      // Left third
place_center(layer?, opacity?)    // Center
place_right(layer?, opacity?)     // Right third
place_custom(x, y, layer?, opacity?) // Custom coordinates (0-1 range)
```

### Animation Helpers

```mbt nocheck
anim_opacity(duration_ms, easing?)
anim_position(duration_ms, easing?)
anim_scale(duration_ms, easing?)
```

Easing options: `Linear`, `EaseIn`, `EaseOut`, `EaseInOut`

## Game State API

```mbt nocheck
let state = GameState::new(my_data)

// Flags (booleans)
state.set_flag("met_miko", true)
let met = state.flag("met_miko")

// Integer variables
state.set_int_var("affection", 10)
let aff = state.int_var("affection", default_value=0)

// Text variables
state.set_text_var("player_name", "Alice")
let name = state.text_var("player_name", default_value="Guest")

// Custom user data
let data = state.get_user_data()
state.set_user_data({ data with affection: data.affection + 1 })
```

## Save/Load

```mbt nocheck
// Save to slot
save_runner_to_slot(runner, "slot1", save_namespace~"mygame")

// Save with metadata
save_runner_to_slot_with_meta(
  runner,
  "slot1",
  title~"Chapter 1 Complete",
  preview~"Day 5 - Miko's Temple",
)

// Load from slot
let runner = start_game_from_slot(script, "slot1", "ui-root", save_namespace~"mygame")

// List save slots
let slots = save_slot_entries()
// Each entry: { slot: String, meta: SaveSlotMeta? }
```

## Settings

```mbt nocheck
let settings = GameSettings::{
  text_speed: 50,      // ms per character (lower = faster)
  bgm_volume: 0.7,    // 0.0 - 1.0
  sfx_volume: 0.8,    // 0.0 - 1.0
  skip_mode: false,    // skip unread text
}

// Apply settings
settings_write(settings)

// Read settings
let loaded = settings_read()
```

## Runtime Events

The engine emits `RuntimeEvent` during execution:

```mbt nocheck
///|
enum RuntimeEvent {
  Noop
  Said(String, String) // speaker, text
  ChoicePrompt(Array[ChoiceOption])
  BackgroundShown(String) // asset ID
  FigureShown(String, FigurePlacement)
  FigureHidden(String)
  MusicPlayed(String, Bool) // asset ID, loop
  MusicStopped
  SfxPlayed(String) // asset ID
  Animated(String, AnimationSpec)
  WaitStarted(Int) // ms remaining
  ScriptEnded
}
```

Use `event_hook` to react to events (e.g., play audio):

```mbt nocheck
let runner = start_game(
  script,
  state,
  "ui-root",
  event_hook=event =>
    match event {
      MusicPlayed(id, loop_) => audio.play_music(id, loop_~)
      SfxPlayed(id) => audio.play_sfx(id)
      _ => ()
    },
)
```

## HTML/CSS Integration

### HTML Structure

```html
<div id="game-container">
  <canvas id="gl-canvas"></canvas>
  <div id="ui-root"></div>
</div>
```

### CSS Classes

The engine creates these DOM elements with `data-reisen` attributes:

| Selector | Description |
|----------|-------------|
| `[data-reisen="speaker"]` | Dialogue name tag |
| `[data-reisen="dialog"]` | Dialogue text box |
| `[data-reisen="choices"]` | Choice button container |
| `[data-reisen="start-menu"]` | Start menu container |
| `[data-reisen="settings-menu"]` | Settings menu container |

## Error Handling

```mbt nocheck
match validate_script_assets(script, store) {
  Ok(_) => start_game(...)
  Err(e) => println(e) // AppBootstrapError::MissingImageAsset or MissingAudioAsset
}
```

Common errors:
- `MissingImageAsset(id~)` - Script references undefined image
- `MissingAudioAsset(id~)` - Script references undefined audio
- `MissingSaveSlot(slot~)` - Save slot not found
- `LabelNotFound(label~)` - Jump to undefined label
- `DuplicateLabel(name~)` - Duplicate label definition
