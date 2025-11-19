# Godot TRPG

An XCOM-style tactical RPG built with Godot 4.x, featuring 3D models on a 2D grid.

## Current Status

Basic 3v3 tactical battlefield visualization:
- 8x6 grid rendered in 3D with checkerboard pattern
- 3 player units (bright blue capsules) vs 3 enemy units (bright red capsules)
- Orthographic camera with isometric view
- Event-driven architecture separating logic from presentation
- Comprehensive debug output for troubleshooting

### Recent Fixes
- Fixed circular reference in GameState class
- Improved unit visibility with unshaded bright colors
- Increased character size for better visibility
- Fixed property initialization timing
- Added extensive debug logging

## Quick Start

1. Open project in Godot 4.x Editor
2. Run the main scene: `scenes/main/battle.tscn` (Press F5)
3. You should see:
   - Grey/white checkerboard grid (8x6 tiles)
   - 3 blue capsules on the bottom row (player units)
   - 3 red capsules on the top row (enemy units)
   - Labels (U0-U5) above each unit
4. Check console for debug output if something looks wrong

## Troubleshooting

If you only see the grid but no characters:
1. Check the console output for debug messages
2. Look for any error messages or warnings
3. Verify units are being created (should see "=== Spawning Unit Views ===")
4. See `DEBUG.md` and `FIXES.md` for detailed troubleshooting steps

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

## Project Structure

See `.github/copilot-instructions.md` for detailed architecture documentation and development guidelines.

