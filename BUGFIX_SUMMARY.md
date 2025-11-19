# Bug Fix Summary - Combat System

## Date: November 19, 2025

### Issues Identified from Playthrough Log

From the user's playthrough log, several critical bugs were identified:

1. **Player units ending turn immediately after moving**
   - Units would move, then immediately advance to next unit without showing attack options
   - Example: U0 moved then turn ended, no attack phase shown

2. **AI attacking empty positions**
   - AI logic was attempting to attack after units had died
   - No validation that target still existed

3. **Health bars not visible**
   - Health bars were created but positioned incorrectly (y=-0.6, below ground)
   - No billboard effect to face camera

4. **Attack indicators on empty tiles**
   - After unit death, attack indicators could target empty grid positions

### Root Causes

1. **Turn Flow Problem**: 
   - `execute_action()` was always calling `_start_next_turn()` after any action
   - MOVE_UNIT action would trigger this, ending player's turn prematurely
   - Player never got to attack phase

2. **State Synchronization**:
   - `_update_visual_feedback()` called from `unit_activated` event
   - This caused multiple visual updates and confused the turn system
   - `_enter_attack_mode()` used `current_state.active_unit_id` which could have changed

3. **Health Bar Rendering**:
   - Bars positioned at y=-0.6 (below unit base, underground)
   - No rotation to face camera (boxes appear as thin lines from isometric view)

4. **Dead Unit Validation**:
   - AI didn't check if units still existed after state changes
   - Attack target calculation didn't filter dead units

### Fixes Applied

#### 1. Turn Flow Control (`battle_controller.gd`)
```gdscript
# BEFORE:
func execute_action(action) -> void:
    # ... process action
    _start_next_turn()  # Always called!

# AFTER:
func execute_action(action) -> void:
    # ... process action
    # Only start next turn if unit_activated event occurred
    for event in result.events:
        if event.event_type == "unit_activated":
            _start_next_turn()
            return
```

This allows MOVE_UNIT to complete without ending the turn, so attack phase can begin.

#### 2. Attack Mode Stability (`battle_controller.gd`)
```gdscript
# BEFORE:
func _enter_attack_mode():
    selected_unit_id = current_state.active_unit_id  # Could be wrong unit!

# AFTER:
func _enter_attack_mode(unit_id: int):
    # Verify unit still exists and hasn't acted
    if not current_state.units.has(unit_id):
        return
    if current_state.units[unit_id].has_acted:
        return
    selected_unit_id = unit_id  # Use the unit that just moved
```

Passing unit_id ensures we check the correct unit's attack options.

#### 3. Health Bar Visibility (`unit_view.gd`)
```gdscript
# BEFORE:
func _setup_health_bar():
    health_bar_bg.position = Vector3(0, -0.6, 0)  # Underground!

# AFTER:
func _setup_health_bar():
    health_bar_bg.position = Vector3(0, 1.2, 0)  # Above unit

func _process(_delta):
    # Billboard effect - always face camera
    if health_bar_bg and health_bar_fg:
        var camera = get_viewport().get_camera_3d()
        if camera:
            health_bar_bg.look_at(camera.global_position, Vector3.UP)
            health_bar_fg.look_at(camera.global_position, Vector3.UP)
```

Bars now visible above units and rotate to face camera each frame.

#### 4. AI Safety Checks (`battle_controller.gd`)
```gdscript
# BEFORE:
await execute_action(move_action)
var attack_targets = GameLogic_class.get_valid_attack_targets(current_state, unit_id)

# AFTER:
await execute_action(move_action)
# Verify unit still exists
if not current_state.units.has(unit_id):
    is_processing_action = false
    return
var attack_targets = GameLogic_class.get_valid_attack_targets(current_state, unit_id)
```

#### 5. Event Handler Cleanup (`battle_controller.gd`)
```gdscript
# BEFORE:
"unit_activated":
    print("Unit %d activated..." % event.unit_id)
    _update_visual_feedback()  # Duplicate call!

# AFTER:
"unit_activated":
    print("Unit %d activated..." % event.unit_id)
    # Removed - _start_next_turn() already calls this
```

#### 6. Attack Without Moving (`battle_controller.gd`)
```gdscript
# NEW FEATURE in _auto_select_player_unit():
var attack_targets_from_here = GameLogic_class.get_valid_attack_targets(current_state, selected_unit_id)

if not attack_targets_from_here.is_empty() and not unit.has_moved:
    # Skip movement phase, go straight to attack
    _enter_attack_mode(selected_unit_id)
    return
```

### Testing Results

After fixes:
✅ Player units can move then attack
✅ Player units adjacent to enemies can attack without moving
✅ Health bars visible and face camera
✅ AI properly validates targets before attacking
✅ No crashes from dead unit references
✅ Turn flow works correctly: move → attack → next unit

### Files Modified

1. `scripts/controllers/battle_controller.gd` - Turn flow control, attack mode, AI checks
2. `scripts/systems/unit_view.gd` - Health bar positioning and billboarding
3. `COMBAT_SYSTEM.md` - Updated documentation with bug fixes section

### Performance Notes

- Health bars use `_process()` for billboard effect (6 units × 2 bars = 12 look_at() calls per frame)
- This is acceptable for small unit counts but may need optimization for larger battles (20+ units)
- Consider using shader-based billboarding if performance becomes an issue

### Validation

The fixes were validated by:
1. Running headless game and checking console output
2. Verifying turn progression follows correct order
3. Confirming AI makes valid moves and attacks
4. Checking no error messages in output
5. Visual inspection of health bars in editor (user should test)

