# Godot TRPG

An XCOM-style tactical RPG built with Godot 4.x, featuring 3D models on a 2D grid.

## Current Status

Basic 3v3 tactical battlefield visualization:
- 8x6 grid rendered in 3D
- 3 player units (blue) vs 3 enemy units (red)
- Orthographic camera view
- Event-driven architecture separating logic from presentation

## Quick Start

1. Open project in Godot 4.x Editor
2. Run the main scene: `scenes/main/battle.tscn`
3. See 6 units positioned on a grid battlefield

## Architecture

- **Core Logic** (`scripts/core/`) - Pure GDScript, no Node dependencies
  - `gamestate.gd` - Immutable game state
  - `game_logic.gd` - State updates via `update_gamestate()`
  - `events.gd` - Event classes for animations
  
- **Controllers** (`scripts/controllers/`) - Bridge logic and presentation
  - `battle_controller.gd` - Manages battle flow and event playback

- **Systems** (`scripts/systems/`) - Rendering and animations
  - `battlefield_view.gd` - 3D grid visualization
  - `unit_view.gd` - 3D unit representation

## Next Steps

- [ ] Add camera controls (pan, zoom, rotate)
- [ ] Implement unit selection via mouse
- [ ] Add movement system (pathfinding, range indicators)
- [ ] Implement turn-based combat
- [ ] Add UI for unit stats and actions
