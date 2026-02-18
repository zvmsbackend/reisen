# Visual Novel Engine Architecture (MoonBit + WebGL)

This document outlines the architecture for a simple visual novel engine built in MoonBit, rendered in the browser via WebGL. The goals are:
- Minimal, clear core
- Deterministic script execution
- Layered rendering (BG, figures, UI)
- Audio playback (music + sfx)
- Simple animations (fade, move, scale)
- Choices + branching

## Scope and Features
- Start menu (New Game, Continue, Settings)
- Scene backgrounds
- Characters/figures (sprites)
- Dialogue box + name tag
- Choice menus
- Music and sound effects
- Basic animations (fade in/out, move, scale)

## High-Level Architecture
The engine is split into 4 primary subsystems:
- Script & State
- Renderer
- Audio
- UI

These are orchestrated by a single Runtime loop.

## Runtime Loop
1. Poll input (mouse/touch/keys)
2. Update active animations and transitions
3. Advance script if waiting conditions are satisfied
4. Build render list (layers)
5. Render to WebGL
6. Update audio (music/sfx state)

## Script & State
### Script Model
Scripts are compiled into a list of instructions (bytecode-style):
- ShowBackground(id)
- ShowFigure(id, position, layer)
- HideFigure(id)
- PlayMusic(track, loop)
- PlaySfx(track)
- Say(name, text)
- Choice(options)
- Jump(label)
- Label(name)
- Wait(duration)

Note: Example DSL code will be added once the engine APIs are finalized to avoid stale or syntactically incorrect samples.

### State
The runtime state is a single struct:
- current_label
- ip (instruction pointer)
- call_stack (for future extension)
- visible_layers (BG, figures, UI)
- current_dialog (speaker, text)
- choice_state (options + selection)
- animation_state (active tweens)

State changes happen only through instruction execution and animation updates.

## Renderer (WebGL)
### Render Layers
Renderables are sorted by layer:
1. Background
2. Figures (sprite layers)
3. UI (dialog box, menus)

### Renderables
Each renderable has:
- texture handle
- position
- scale
- opacity
- z-order

### Pipeline
- WebGL uses a simple 2D quad shader
- Each renderable is a quad with UVs
- Uniforms for transform + opacity

## Audio
Uses Web Audio API with:
- One looping music channel
- Multiple one-shot SFX

State:
- current_music_id
- music_gain
- sfx_gain

## UI
UI is built from simple screen primitives:
- Dialogue box
- Name tag
- Choice menu
- Buttons (start menu)

UI components are rendered as textures or colored quads, with text rendered to canvas and uploaded to WebGL textures.

## Animations
Simple tween system:
- Linear or ease-in/out
- Target properties: opacity, position, scale

Animations are stored in an active list and updated every frame by delta time.

## Data & Assets
- All assets defined in a manifest (json or moon file)
- Scripts reference assets by id
- Assets loaded at startup or lazily on first use

## Extension Points (Future)
- Save/load support
- More animation types
- Custom script functions
- Text effects (typewriter, shake)
