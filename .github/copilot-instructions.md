# Godot TRPG - Copilot Instructions

## Project Overview
This is an XCOM-style tactical RPG built with Godot 4.x, featuring 3D models on a 2D grid rendered in 3D space. Targets web deployment via GitHub Pages.

## Architecture & Structure

### Core Design Principles
- **Separation of Concerns**: Game logic is completely decoupled from presentation
- **Event-Driven Rendering**: UI/animations react to game events, never directly modify state
- **Immutable State Updates**: `update_gamestate()` returns new state + events, never mutates directly

### Directory Layout
```
/
├── project.godot          # Godot 4.x project configuration
├── scenes/                # .tscn scene files
│   ├── main/             # Main game scenes
│   ├── ui/               # UI components (react to events only)
│   ├── battlefield/      # 3D battlefield view with grid
│   └── units/            # 3D unit models and animations
├── scripts/              # .gd GDScript files
│   ├── core/             # Core game logic (pure logic, no nodes)
│   │   ├── gamestate.gd  # GameState class (data only)
│   │   ├── game_logic.gd # update_gamestate() implementation
│   │   └── events.gd     # Event classes for animations
│   ├── autoload/         # Singleton scripts
│   ├── controllers/      # Bridge between logic and presentation
│   └── systems/          # Rendering/animation systems
├── assets/               # Art, audio, fonts
│   ├── models/           # 3D unit models (.gltf/.glb)
│   ├── textures/         # Grid tiles, UI elements
│   └── materials/        # PBR materials for 3D
├── export/               # Build output directory
│   └── web/              # HTML5 export files
└── .github/
    └── workflows/        # CI/CD for automated builds
```

### Key Architecture Pattern

**Game Logic Layer** (`scripts/core/`):
```gdscript
# game_logic.gd - Pure logic, no Node dependencies
class_name GameLogic

static func update_gamestate(current_state: GameState, action: GameAction) -> Dictionary:
    var new_state = current_state.duplicate()
    var events = []
    
    # Apply action logic
    match action.type:
        GameAction.MOVE_UNIT:
            new_state.units[action.unit_id].position = action.target_pos
            events.append(MoveEvent.new(action.unit_id, action.path))
        GameAction.ATTACK:
            var damage = _calculate_damage(new_state, action)
            new_state.units[action.target_id].health -= damage
            events.append(AttackEvent.new(action.unit_id, action.target_id, damage))
    
    return {"state": new_state, "events": events}
```

**Presentation Layer** (`scripts/controllers/`):
```gdscript
# battle_controller.gd - Bridges logic and UI
extends Node
class_name BattleController

var current_state: GameState
@onready var battlefield_view = $BattlefieldView
@onready var animation_player = $AnimationSystem

func execute_action(action: GameAction) -> void:
    var result = GameLogic.update_gamestate(current_state, action)
    current_state = result.state
    
    # Play animations from events
    for event in result.events:
        await animation_player.play_event(event)
```

## Development Workflows

### Building for Web Export

**Export Template Setup** (one-time):
1. Open Godot Editor → Project → Export
2. Add "HTML5" export preset
3. Download export templates if prompted
4. Configure preset settings:
   - Export Path: `export/web/index.html`
   - Export Type: Regular
   - Custom HTML Shell: (optional, for custom branding)

**Command-line Export** (for CI/CD):
```bash
# Godot 4.x headless export
godot4 --headless --export-release "Web" export/web/index.html
```

### Local Testing

**Test web build locally:**
```bash
cd export/web
python -m http.server 8000
# Open http://localhost:8000 in browser
```

**Note**: Web builds require HTTP server (not `file://`) due to SharedArrayBuffer/CORS requirements.

### GitHub Pages Deployment

**Manual Testing Workflow:**
1. Build for web export (creates `export/web/` with index.html, .wasm, .pck files)
2. Push build artifacts to `gh-pages` branch:
   ```bash
   # From project root
   git checkout --orphan gh-pages
   git rm -rf .
   cp -r export/web/* .
   git add .
   git commit -m "Deploy web build"
   git push origin gh-pages --force
   git checkout main
   ```
3. Enable GitHub Pages: Settings → Pages → Source: `gh-pages` branch
4. Access at: `https://kabuumu.github.io/godot-trpg/`

**Automated CI/CD** (create `.github/workflows/deploy.yml`):
```yaml
name: Deploy to GitHub Pages
on:
  push:
    branches: [main]
jobs:
  export-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Export Godot Project
        uses: firebelley/godot-export@v5.2.1
        with:
          godot_executable_download_url: https://downloads.tuxfamily.org/godotengine/4.2.1/Godot_v4.2.1-stable_linux.x86_64.zip
          godot_export_templates_download_url: https://downloads.tuxfamily.org/godotengine/4.2.1/Godot_v4.2.1-stable_export_templates.tpz
          relative_project_path: ./
          relative_export_path: ./export/web
          export_preset_name: HTML5
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./export/web
```

## GDScript Conventions

### Naming Patterns
- **Files**: `snake_case.gd` (e.g., `player_controller.gd`)
- **Classes**: `PascalCase` (e.g., `class_name PlayerController`)
- **Variables/Functions**: `snake_case`
- **Constants/Enums**: `SCREAMING_SNAKE_CASE`
- **Signals**: `snake_case` with past tense (e.g., `signal unit_moved`)

### TRPG-Specific Patterns

**Grid System**:
- Logical grid: `Vector2i` for tile coordinates in `GameState`
- 3D rendering: Convert to `Vector3` for world positions (e.g., `Vector3(grid.x, 0, grid.y)`)
- Grid stored in logic layer, 3D meshes in presentation layer

**State Management**:
- `GameState` class: Immutable data structure (units, grid, turn info)
- Never modify state directly - always return new state from `update_gamestate()`
- Use `Resource` classes for unit stats, ability definitions

**Event System**:
```gdscript
# events.gd - Define all possible game events
class_name GameEvent

class MoveEvent extends GameEvent:
    var unit_id: int
    var path: Array[Vector2i]
    var duration: float

class AttackEvent extends GameEvent:
    var attacker_id: int
    var target_id: int
    var damage: int
    var is_critical: bool

class AbilityEvent extends GameEvent:
    var caster_id: int
    var ability_id: String
    var targets: Array[int]
```

**3D Unit Representation**:
```gdscript
# unit_view.gd - Presentation only, driven by events
extends Node3D
class_name UnitView

@export var unit_id: int
@onready var model = $Model
@onready var animation_player = $AnimationPlayer

func animate_move(path: Array[Vector2i], duration: float) -> void:
    for grid_pos in path:
        var world_pos = Vector3(grid_pos.x, 0, grid_pos.y)
        var tween = create_tween()
        tween.tween_property(self, "position", world_pos, duration)
        await tween.finished

func animate_attack(target_pos: Vector3) -> void:
    look_at(target_pos)
    animation_player.play("attack")
    await animation_player.animation_finished
```

**Turn Management**:
- Turn order calculated in `GameLogic.calculate_turn_order(state)`
- Controller handles async event playback before accepting next action

## Testing the Build

### Checklist for Web Builds
- [ ] Audio plays correctly (check browser autoplay policies)
- [ ] Touch/mouse input works
- [ ] Game scales properly on different screen sizes
- [ ] No CORS errors in browser console
- [ ] SharedArrayBuffer enabled (requires proper headers)
- [ ] Assets load correctly (check network tab)

### Common Web Export Issues
- **Black screen**: Check browser console for errors; ensure export templates match Godot version
- **Audio doesn't play**: User interaction required before audio; add click-to-start screen
- **Performance issues**: Profile with browser dev tools; consider reducing particle effects, shadows
- **Memory errors**: Reduce texture sizes, optimize asset loading

## Key Files to Create First
1. `project.godot` - Initialize Godot 4.x project
2. `scripts/core/gamestate.gd` - Core state data structure
3. `scripts/core/game_logic.gd` - Pure logic with `update_gamestate()` method
4. `scripts/core/events.gd` - Event classes for animations
5. `scripts/controllers/battle_controller.gd` - Bridge between logic and presentation
6. `scenes/battlefield/battlefield.tscn` - 3D grid view with camera
7. `scenes/units/unit_view.tscn` - 3D unit model template
8. `export/web/.gitkeep` - Placeholder for export directory

## Critical Implementation Rules
1. **Never call Node methods from `scripts/core/`** - Keep logic pure GDScript
2. **All state changes return new objects** - No in-place mutations
3. **Controllers await all events before next action** - Prevent state desync
4. **3D grid uses Godot's GridMap or custom MeshInstance3D** - Not TileMap (2D only)

## Resources
- Godot HTML5 Export Docs: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- GitHub Pages Setup: https://docs.github.com/en/pages
