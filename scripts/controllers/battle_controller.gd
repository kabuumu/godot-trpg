# battle_controller.gd - Bridges game logic and presentation
extends Node
class_name BattleController

var current_state

@onready var battlefield_view: Node3D = $BattlefieldView
@onready var units_container: Node3D = $Units
@onready var camera: Camera3D = $Camera3D
@onready var turn_ui = $TurnUI/Control

var unit_views: Dictionary = {}  # Maps unit_id to UnitView

# Reference to game logic classes
var GameLogic_class = load("res://scripts/core/game_logic.gd")
var GameState_class = load("res://scripts/core/gamestate.gd")

# Player input state
var selected_unit_id: int = -1
var valid_move_tiles: Array[Vector2i] = []
var is_processing_action: bool = false

func _ready():
    _initialize_battle()

func _input(event):
    # Only process input during player's turn and when not processing
    if is_processing_action or current_state == null or not is_inside_tree():
        return

    var active_unit = current_state.units.get(current_state.active_unit_id)
    if active_unit == null or active_unit.team != 0:  # Team 0 is player
        return

    # Handle mouse clicks for unit selection and movement
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _handle_mouse_click(event.position)

func _handle_mouse_click(mouse_pos: Vector2):
    print("\n=== MOUSE CLICK DEBUG ===")
    print("Mouse clicked at screen position: %v" % mouse_pos)
    var from = camera.project_ray_origin(mouse_pos)
    var to = from + camera.project_ray_normal(mouse_pos) * 1000

    var space_state = battlefield_view.get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(from, to)
    var result = space_state.intersect_ray(query)

    if result:
        print("Raycast hit at world position: %v" % result.position)
        var grid_pos = battlefield_view.world_to_grid(result.position)
        print("Converted to grid position: (%d, %d)" % [grid_pos.x, grid_pos.y])

        # Show what should be at that grid position
        var expected_world = battlefield_view.grid_to_world(grid_pos)
        print("Expected world center for grid (%d,%d): %v" % [grid_pos.x, grid_pos.y, expected_world])

        _handle_tile_click(grid_pos)
    else:
        print("Raycast hit nothing")
    print("========================\n")

func _initialize_battle():
    print("=== Initializing Battle ===")
    # Create initial 3v3 game state
    current_state = GameLogic_class.create_initial_3v3_state()
    print("Created game state with %d units" % current_state.units.size())
    print("Turn order: " + str(current_state.turn_order))
    print("Starting unit: %d (Team %d)" % [current_state.active_unit_id, current_state.active_player])

    # Spawn unit views based on state
    _spawn_unit_views()

    # Start the first turn
    _start_next_turn()

func _spawn_unit_views():
    print("=== Spawning Unit Views ===")
    # Load unit scene
    var unit_scene = preload("res://scenes/units/unit_view.tscn")

    # Create a view for each unit in the state
    for unit_id in current_state.units:
        var unit_data = current_state.units[unit_id]
        print("Creating unit %d at grid pos (%d, %d), team %d" % [unit_data.id, unit_data.position.x, unit_data.position.y, unit_data.team])

        var unit_view = unit_scene.instantiate()

        # Set properties BEFORE adding to tree so _ready() has correct values
        unit_view.unit_id = unit_data.id
        unit_view.team = unit_data.team
        unit_view.grid_position = unit_data.position

        units_container.add_child(unit_view)

        # Set position after adding to tree
        unit_view.set_grid_position(unit_data.position, battlefield_view.tile_size)

        print("  -> World position: %v" % unit_view.position)

        unit_views[unit_id] = unit_view

    print("Total units spawned: %d" % unit_views.size())

func execute_action(action) -> void:
    var result = GameLogic_class.update_gamestate(current_state, action)
    current_state = result.state

    # Play animations from events
    for event in result.events:
        await _play_event(event)

    # After all events, start next turn
    _start_next_turn()

func _play_event(event) -> void:
    match event.event_type:
        "move":
            if unit_views.has(event.unit_id):
                await unit_views[event.unit_id].animate_move(
                    event.path,
                    event.duration,
                    battlefield_view.tile_size
                )

        "attack":
            if unit_views.has(event.attacker_id) and unit_views.has(event.target_id):
                var target_pos = unit_views[event.target_id].position
                await unit_views[event.attacker_id].animate_attack(target_pos)

        "turn_start":
            print("=== Round %d Started ===" % event.turn_number)

        "unit_activated":
            print("Unit %d activated (Team %d)" % [event.unit_id, event.team])
            _update_visual_feedback()

func _start_next_turn():
    if current_state == null:
        return

    var active_unit = current_state.units.get(current_state.active_unit_id)
    if active_unit == null:
        return

    print("\n--- Turn: Unit %d (Team %d, Initiative %d) ---" % [active_unit.id, active_unit.team, active_unit.initiative])

    # Update UI
    if turn_ui:
        turn_ui.update_turn_info(
            current_state.current_turn,
            active_unit.id,
            active_unit.team,
            active_unit.initiative
        )

    # If player controlled, auto-select and show moves
    if active_unit.team == 0:  # Player team
        _auto_select_player_unit()

    _update_visual_feedback()

    # If AI controlled, execute AI move
    if active_unit.team != 0:  # Not player
        _execute_ai_turn()

func _auto_select_player_unit():
    """Automatically select the active player unit and show available moves"""
    selected_unit_id = current_state.active_unit_id
    valid_move_tiles = GameLogic_class.get_valid_moves(current_state, selected_unit_id)
    var unit = current_state.units[selected_unit_id]
    print("\n=== AUTO-SELECTED PLAYER UNIT ===")
    print("Unit %d at grid position (%d, %d)" % [selected_unit_id, unit.position.x, unit.position.y])
    print("Movement range: %d tiles" % unit.movement_range)
    print("Valid moves: %d tiles" % valid_move_tiles.size())
    if valid_move_tiles.size() > 0:
        print("Green tiles will appear showing where you can move")
    else:
        print("No valid moves available (unit is blocked)")
    print("Click a green tile to move there")
    print("=================================\n")

func _execute_ai_turn():
    is_processing_action = true
    await get_tree().create_timer(0.5).timeout  # Brief pause before AI moves

    var unit_id = current_state.active_unit_id
    var target_pos = GameLogic_class.get_ai_move(current_state, unit_id)
    var current_pos = current_state.units[unit_id].position

    if target_pos != current_pos:
        print("AI moving unit %d from (%d,%d) to (%d,%d)" % [unit_id, current_pos.x, current_pos.y, target_pos.x, target_pos.y])

        # Create move action
        var action = GameLogic_class.GameAction.new()
        action.type = GameLogic_class.ActionType.MOVE_UNIT
        action.unit_id = unit_id
        action.target_pos = target_pos
        # Create properly typed array for path
        var move_path: Array[Vector2i] = []
        move_path.append(current_pos)
        move_path.append(target_pos)
        action.path = move_path

        await execute_action(action)
    else:
        print("AI unit %d cannot move, skipping turn" % unit_id)
        var action = GameLogic_class.GameAction.new()
        action.type = GameLogic_class.ActionType.NEXT_UNIT
        await execute_action(action)

    is_processing_action = false

func _handle_tile_click(grid_pos: Vector2i):
    var active_unit = current_state.units.get(current_state.active_unit_id)
    if active_unit == null or active_unit.team != 0:
        return

    print("Tile clicked at grid (%d, %d)" % [grid_pos.x, grid_pos.y])
    print("Valid move tiles count: %d" % valid_move_tiles.size())

    # Debug: Show all valid moves
    if valid_move_tiles.size() > 0:
        print("Valid move positions:")
        for i in range(min(valid_move_tiles.size(), 10)):
            print("  - (%d, %d)" % [valid_move_tiles[i].x, valid_move_tiles[i].y])

    # Check if clicking on a valid move tile
    var is_valid = valid_move_tiles.has(grid_pos)
    print("Is clicked position in valid moves? %s" % is_valid)

    if is_valid:
        print("Clicked on valid move tile - moving unit")
        _move_selected_unit(grid_pos)
    else:
        print("Clicked on non-movable tile (not in green area)")
        # Show why it's not valid
        var closest_dist = 999999
        var closest_tile = Vector2i(-1, -1)
        for tile in valid_move_tiles:
            var dist = abs(tile.x - grid_pos.x) + abs(tile.y - grid_pos.y)
            if dist < closest_dist:
                closest_dist = dist
                closest_tile = tile
        if closest_tile != Vector2i(-1, -1):
            print("Closest valid tile is (%d, %d) at distance %d" % [closest_tile.x, closest_tile.y, closest_dist])

func _select_active_unit():
    selected_unit_id = current_state.active_unit_id
    valid_move_tiles = GameLogic_class.get_valid_moves(current_state, selected_unit_id)
    var unit = current_state.units[selected_unit_id]
    print("\n=== UNIT SELECTED ===")
    print("Selected unit %d at grid position (%d, %d)" % [selected_unit_id, unit.position.x, unit.position.y])
    print("Movement range: %d tiles" % unit.movement_range)
    print("Valid moves: %d tiles" % valid_move_tiles.size())
    for i in range(min(valid_move_tiles.size(), 10)):  # Show first 10
        var tile = valid_move_tiles[i]
        print("  - Grid (%d, %d)" % [tile.x, tile.y])
    if valid_move_tiles.size() > 10:
        print("  ... and %d more" % (valid_move_tiles.size() - 10))
    print("====================\n")
    _update_visual_feedback()

func _move_selected_unit(target_pos: Vector2i):
    if selected_unit_id < 0 or is_processing_action:
        return

    is_processing_action = true

    # Save the unit_id before clearing selection
    var moving_unit_id = selected_unit_id
    var current_pos = current_state.units[moving_unit_id].position
    print("Moving unit %d from (%d,%d) to (%d,%d)" % [moving_unit_id, current_pos.x, current_pos.y, target_pos.x, target_pos.y])

    # Create move action
    var action = GameLogic_class.GameAction.new()
    action.type = GameLogic_class.ActionType.MOVE_UNIT
    action.unit_id = moving_unit_id
    action.target_pos = target_pos
    # Create properly typed array for path
    var move_path: Array[Vector2i] = []
    move_path.append(current_pos)
    move_path.append(target_pos)
    action.path = move_path

    # Clear selection BEFORE executing action
    # (execute_action will call _start_next_turn which auto-selects next unit)
    selected_unit_id = -1
    valid_move_tiles.clear()

    await execute_action(action)

    is_processing_action = false

func _update_visual_feedback():
    # Highlight active unit
    for unit_id in unit_views:
        var unit_view = unit_views[unit_id]
        if unit_id == current_state.active_unit_id:
            unit_view.set_highlight(true)
        else:
            unit_view.set_highlight(false)

    # Show valid move tiles
    battlefield_view.clear_move_indicators()
    if selected_unit_id >= 0:
        print("Showing %d green move indicators" % valid_move_tiles.size())
        for move_pos in valid_move_tiles:
            print("  - Showing green tile at grid (%d, %d)" % [move_pos.x, move_pos.y])
            battlefield_view.show_move_indicator(move_pos)
