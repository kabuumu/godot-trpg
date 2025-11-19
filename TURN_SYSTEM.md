# Turn-Based Initiative System

## Overview

The game now features a turn-based initiative system where units act in order based on their initiative rolls. Players control RED units (Team 0), while the AI controls BLUE units (Team 1).

## How It Works

### Initiative Order
- Each unit rolls initiative (1-20) at battle start
- Units act in order from highest to lowest initiative
- After all units have acted, a new round begins and initiative resets

### Unit Turn Flow
1. Unit's turn starts (visual highlight appears on active unit)
2. If **Player-Controlled** (RED):
   - Click on your unit to show valid movement tiles (green highlights)
   - Click on a green tile to move
   - Unit moves and turn advances to next unit
3. If **AI-Controlled** (BLUE):
   - AI automatically calculates best move towards nearest enemy
   - Unit moves after short delay
   - Turn advances to next unit

### Movement
- Each unit has a configurable `movement_range` (default 2-3 tiles)
- Movement is calculated using Manhattan distance (no diagonal)
- Units cannot move through occupied tiles
- After moving, the unit's turn ends

### Current Unit Configuration
```
Player Units (Team 0 - RED):
- Unit 0: 2 tiles movement
- Unit 1: 3 tiles movement  
- Unit 2: 2 tiles movement

AI Units (Team 1 - BLUE):
- Unit 3: 2 tiles movement
- Unit 4: 3 tiles movement
- Unit 5: 2 tiles movement
```

## Visual Feedback

- **Active Unit**: Glowing emission effect
- **Valid Moves**: Green semi-transparent tiles
- **Team Colors**:
  - RED = Player controlled
  - BLUE = AI controlled

## AI Behavior

The AI uses a simple "move towards nearest enemy" strategy:
1. Find all valid movement tiles
2. Calculate distance to nearest enemy from each tile
3. Move to the tile that minimizes distance to nearest enemy
4. If no moves available, skip turn

## Testing the System

### In Godot Editor
1. Open the project and press F5 to run
2. Click on your red unit (when it's their turn)
3. Click on a green highlighted tile to move
4. Watch as blue units automatically move towards you

### Expected Behavior
- Units alternate based on initiative order
- Player units wait for input
- AI units move automatically
- Each unit can only move on their turn
- After moving, initiative advances to next unit

## Code Structure

### Core Logic (`scripts/core/`)
- `gamestate.gd`: Tracks turn order, active unit, initiative
- `game_logic.gd`: Calculates turn order, valid moves, AI decisions
- `events.gd`: UnitActivatedEvent for turn notifications

### Controller (`scripts/controllers/`)
- `battle_controller.gd`: Handles input, triggers AI turns, manages turn flow

### View (`scripts/systems/`)
- `unit_view.gd`: Visual highlight for active unit
- `battlefield_view.gd`: Green tile indicators for valid moves

## Future Enhancements

Potential additions:
- Attack actions after movement
- Different AI strategies
- Turn time limits
- Speed-based initiative (faster units act more often)
- Action points system (move + attack in one turn)
- Special abilities with cooldowns

