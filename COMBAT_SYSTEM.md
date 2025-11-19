# Combat System Documentation

## Overview
The game features a complete turn-based combat system with melee attacks, health bars, and unit death mechanics. Units can move AND attack in the same turn, creating dynamic tactical gameplay.

## Combat Flow

### Player Turn
1. **Unit Selection**: The active player unit is automatically selected at the start of their turn
2. **Initial Attack Check**: If enemies are already in range, goes straight to attack mode
3. **Movement Phase** (if no enemies in range):
   - Green indicators show all valid movement tiles
   - Click a green tile to move your unit
   - Movement range is based on unit's `movement_range` property (default: 2 tiles)
4. **Attack Phase**:
   - After moving (or from starting position), the game enters attack mode
   - Red indicators appear on all enemies within attack range (1 tile for melee)
   - Click a red indicator to attack that enemy
   - Or click "End Turn" button to skip attacking
5. **Turn End**: After attacking or ending turn, the next unit in initiative order activates

### AI Turn
1. **Decision Making**: AI checks if it can attack from current position
2. **Attack or Move**: 
   - If enemies are in range, attack immediately
   - Otherwise, move towards nearest enemy
   - After moving, check for attack targets and attack if available
3. **Auto End Turn**: If AI cannot move or attack, automatically ends turn

## Combat Stats

### Unit Properties
- **Health**: 100 HP (default)
- **Attack Damage**: 30 base damage (±5 variance)
- **Attack Range**: 1 tile (melee)
- **Movement Range**: 2-3 tiles (varies by unit)
- **Critical Hit**: 20% chance for 1.5x damage

### Attack Mechanics
- **Damage Calculation**: Base damage + random variance (-5 to +5)
- **Critical Hits**: 20% chance, deals 1.5x damage
- **Health Reduction**: Target's health decreases by damage amount
- **Death**: Unit is removed when health reaches 0 or below

## Visual Feedback

### Health Bars
- **Position**: Displayed above each unit (at y=1.2)
- **Color**: Bright green at all times
- **Dynamic Scale**: Bar width scales with current health percentage
- **Billboard Effect**: Always faces the camera

### Unit Colors
- **Red Capsules**: Player team (Team 0)
- **Blue Capsules**: AI team (Team 1)
- **Glowing Effect**: Active unit has emission effect

### Indicators
- **Green Tiles**: Valid movement destinations
- **Red Tiles**: Valid attack targets (enemies in range)
- **Highlight**: Active unit glows

### Death Animation
- Unit sinks into ground
- Scales down to 0.1x size
- 0.5 second fade duration
- Removed from game after animation

## UI Elements

### Turn Information
- **Round Number**: Top-left corner
- **Active Unit**: Shows unit ID, team, and initiative
- **Instructions**: Context-sensitive help text

### End Turn Button
- **Visibility**: Only shown during attack phase
- **Position**: Bottom-right corner
- **Purpose**: Skip attacking and advance to next unit
- **Auto-Hide**: Disappears after use or when AI takes turn

## Technical Implementation

### Game Logic Layer (`scripts/core/`)
- **ActionType.ATTACK**: New action type for attacks
- **get_valid_attack_targets()**: Finds enemies within attack range
- **UnitDiedEvent**: Event triggered when unit health reaches 0
- **has_moved flag**: Tracks if unit has moved (allows move + attack combo)

### Presentation Layer (`scripts/systems/`)
- **Health Bar**: Dynamic 3D meshes that scale and change color
- **Attack Indicators**: Red semi-transparent tiles on enemy positions
- **Death Animation**: Tween-based sinking and scaling effect

### Controller Layer (`scripts/controllers/`)
- **PlayerMode.SELECTING_ATTACK**: New mode for attack target selection
- **_enter_attack_mode()**: Transitions from move to attack phase
- **_attack_target()**: Executes attack action
- **_end_player_turn()**: Skips attack and advances turn

## Game Balance

### Current Settings
- Movement: 2-3 tiles per turn
- Attack Range: 1 tile (melee only)
- Damage: 25-35 per hit (30 base ±5)
- Critical: 45 damage (1.5x multiplier)
- Health: 100 HP = ~3-4 hits to kill

### Turn Order
- Initiative rolls: 1-20 (random at battle start)
- Higher initiative = acts first
- Order maintained throughout entire battle

## Bug Fixes (v1.1)

### Issues Resolved
1. **Turn Flow Fixed**: `execute_action()` no longer automatically calls `_start_next_turn()`. Instead, it checks for `unit_activated` events to determine when to start the next turn. This prevents premature turn ending after player moves.

2. **Attack Mode Stability**: `_enter_attack_mode()` now accepts a `unit_id` parameter to ensure it checks the correct unit's attack options, even if the game state has changed.

3. **Health Bars Visible**: Health bars are now positioned higher (y=1.2) and use billboard rotation in `_process()` to always face the camera, making them clearly visible.

4. **AI Safety Checks**: AI now verifies units still exist before attempting attacks after moving, preventing crashes when targeting dead units.

5. **Attack Without Moving**: Player units that start their turn adjacent to enemies can attack immediately without moving first, streamlining combat.

### Technical Improvements
- Removed duplicate `_update_visual_feedback()` call from `unit_activated` event handler
- Added validation in `_enter_attack_mode()` to check `has_acted` flag
- Health bars use `_process()` for continuous camera-facing updates
- Attack target validation ensures only living units are targetable

## Future Enhancement Ideas
- Ranged weapons (attack_range > 1)
- Different weapon types with unique damage
- Armor/defense stats
- Status effects (poison, stun, etc.)
- Area of effect attacks
- Special abilities and cooldowns
- Terrain effects on movement/combat

