# Quick Test Guide

## How to Test

1. Open the project in Godot Editor
2. Press F5 or click the "Play" button
3. The game should open showing the battlefield

## What You Should See

### Visual Elements
- **Grid**: 8×6 checkerboard of grey squares
- **Blue Capsules**: 3 bright blue units in the front/bottom row
- **Red Capsules**: 3 bright red units in the back/top row
- **Labels**: Text "U0" through "U5" above each unit

### Console Output
You should see debug messages in this order:

```
=== Creating Battlefield Grid ===
Grid size: 8 x 6 tiles
Tile size: 2.0
Grid created with 48 tiles
=== Initializing Battle ===
Created game state with 6 units
=== Spawning Unit Views ===
Creating unit 0 at grid pos (1, 0), team 0
UnitView _ready() called for unit 0, team 0
  Visible: true, Model exists: true, Label exists: true
  Setting up model for unit 0
    Material: BLUE (player)
    Model mesh: [CapsuleMesh:...]
    Model material applied: [StandardMaterial3D:...]
  Label setup: U0 at (0, 2.5, 0)
  Model setup complete, position: (0, 0, 0)
  Final check - Model visible: true, in tree: true
  Set grid position (1, 0) -> world ((2, 0, 0))
  -> World position: (2, 0, 0)
[... similar messages for units 1-5 ...]
Total units spawned: 6
```

## If You Still Don't See Units

### Check Console for Errors
Look for:
- Any red error messages
- "WARNING: Model has no mesh" messages
- Any missing resource warnings

### Try These Quick Fixes

1. **Check if units exist in scene tree**:
   - While game is running, go to Remote tab in Scene dock
   - Look for "Battle" → "Units" node
   - Should see 6 UnitView child nodes
   - Click on one and check its Transform in Inspector

2. **Adjust camera for better view**:
   Edit `scenes/main/battle.tscn`, select Camera3D, and try:
   - Increase size from 20.0 to 30.0 (zoom out)
   - Change position to (7, 15, 15) (higher up)

3. **Make units even larger**:
   Edit `scripts/systems/unit_view.gd`, in `_setup_model()`:
   ```gdscript
   mesh.height = 3.0  # Even taller
   mesh.radius = 0.6  # Even wider
   ```

4. **Check if materials are working**:
   In Remote inspector, select a Model node under Units
   - Check if "Material Override" is set
   - Check if the color looks correct

### Last Resort: Simple Test Scene

If units still don't show, create a minimal test:
1. Create new 3D scene
2. Add Camera3D at (5, 5, 5) looking at origin
3. Add MeshInstance3D with CapsuleMesh
4. Set material to unshaded blue
5. If this works, the issue is with our scene setup

## Expected Behavior

The game should load instantly and show a static battlefield with units.
No interaction is implemented yet - this is just visualization.

## Next Steps After Verification

Once you can see the units:
1. Remove or reduce debug print statements
2. Add camera controls for rotation/zoom
3. Implement unit selection with mouse clicks
4. Add movement indicators and pathfinding

