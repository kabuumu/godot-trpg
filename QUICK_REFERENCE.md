# Quick Reference - Turn System

## How to Test

```bash
cd /Users/robhawkes/Documents/personal/godot-trpg
godot  # Open in editor, then press F5 to run
```

## Controls

### Unit Movement
**When your RED unit's turn:**
1. Unit is **automatically selected** and highlighted
2. Green tiles appear immediately showing valid moves
3. Click a green tile to move there


**AI BLUE units move automatically**

### Camera Controls
**Movement (Arrow Keys):**
- ⬅️ **Left Arrow**: Pan left
- ➡️ **Right Arrow**: Pan right
- ⬆️ **Up Arrow**: Pan forward
- ⬇️ **Down Arrow**: Pan backward

**Rotation (WASD):**
- **W**: Tilt up
- **S**: Tilt down
- **A**: Rotate left
- **D**: Rotate right

**Zoom:**
- **Mouse Wheel**: Zoom in/out
- **Q**: Zoom in
- **E**: Zoom out

## Unit Movement Ranges

| Unit | Team | Color | Movement Range |
|------|------|-------|----------------|
| 0    | Player | RED | 2 tiles |
| 1    | Player | RED | 3 tiles |
| 2    | Player | RED | 2 tiles |
| 3    | AI | BLUE | 2 tiles |
| 4    | AI | BLUE | 3 tiles |
| 5    | AI | BLUE | 2 tiles |

## Visual Indicators

- **Glowing unit** = Current active unit
- **Green tiles** = Valid movement options
- **RED capsules** = Player controlled
- **BLUE capsules** = AI controlled

## UI Display (Top-Left)

- **Line 1:** Current round number
- **Line 2:** Active unit info (ID, team, initiative)
- **Line 3:** Instructions or AI status

## Initiative Order

Determined by random roll (1-20) at battle start.
Example: [0, 3, 4, 2, 1, 5] means Unit 0 acts first, then Unit 3, etc.

## Turn Flow

```
Round 1:
  Unit 0 (Player) → Unit 3 (AI) → Unit 4 (AI) → Unit 2 (Player) → Unit 1 (Player) → Unit 5 (AI)
Round 2:
  (Same order repeats)
```

## AI Behavior

AI units automatically move toward the nearest player unit.

## Code Locations

- **Core Logic:** `scripts/core/game_logic.gd`
- **Game State:** `scripts/core/gamestate.gd`  
- **Controller:** `scripts/controllers/battle_controller.gd`
- **UI:** `scripts/systems/turn_ui.gd`

## Customization

To change movement range, edit `game_logic.gd`:
```gdscript
# In create_initial_3v3_state()
state.units[0] = UnitData.new(0, Vector2i(1, 0), 0, 2)  # Last param = range
```

To change initiative range, edit `gamestate.gd`:
```gdscript
# In UnitData._init()
initiative = randi_range(1, 20)  # Change range here
```

## Troubleshooting

**Game shows "AI is thinking..." but nothing happens:**
- This was a bug with array initialization - now fixed!
- If it persists, check console for "AI moving" messages
- Make sure you're running the latest version of the code

**Units don't move when clicked:**
- Make sure it's that unit's turn (check UI)
- Try clicking directly on the unit capsule
- Check console for errors

**AI doesn't move:**
- Check console - may say "cannot move" if surrounded
- This is normal if all adjacent tiles are blocked

**No green tiles appear:**
- Unit may have no valid moves (all tiles occupied)
- Make sure you clicked the active unit

## Documentation Files

- `TURN_SYSTEM.md` - Feature overview
- `TESTING_TURN_SYSTEM.md` - Detailed testing guide
- `IMPLEMENTATION_SUMMARY.md` - Technical details

## Success Criteria

✅ Player can move RED units on their turn
✅ AI moves BLUE units automatically
✅ Initiative order is respected
✅ Visual feedback works
✅ UI updates correctly
✅ Rounds cycle properly

