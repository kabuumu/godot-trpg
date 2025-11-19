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
enum PlayerMode { NONE, SELECTING_MOVE, SELECTING_ATTACK }
var player_mode: PlayerMode = PlayerMode.NONE
var selected_unit_id: int = -1
var valid_move_tiles: Array[Vector2i] = []
var valid_attack_targets: Array[int] = []
var is_processing_action: bool = false

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

func _ready():
    print("=== Initializing Battle ===")
    # Create initial 3v3 game state
    current_state = GameLogic_class.create_initial_3v3_state()
    print("Created game state with %d units" % current_state.units.size())
    print("Turn order: " + str(current_state.turn_order))
    print("Starting unit: %d (Team %d)" % [current_state.active_unit_id, current_state.active_player])

    # Spawn unit views based on state
    _spawn_unit_views()

    # Connect UI signals
    turn_ui.end_turn_pressed.connect(_end_player_turn)

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

        # Initialize health bar with current health
        unit_view.update_health(unit_data.health, unit_data.max_health)

        print("  -> World position: %v" % unit_view.position)

        unit_views[unit_id] = unit_view

    print("Total units spawned: %d" % unit_views.size())

func execute_action(action) -> void:
    var result = GameLogic_class.update_gamestate(current_state, action)
    current_state = result.state

    # Play animations from events
    for event in result.events:
        await _play_event(event)

    # Check if we need to start next turn (if unit_activated event was in events)
    for event in result.events:
        if event.event_type == "unit_activated":
            _start_next_turn()
            return

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

                # Update target's health bar
                var target_unit = current_state.units.get(event.target_id)
                if target_unit:
                    unit_views[event.target_id].update_health(target_unit.health, target_unit.max_health)
                    print("Unit %d took %d damage! Health: %d/%d" % [event.target_id, event.damage, target_unit.health, target_unit.max_health])

        "unit_died":
            print("Unit %d has died!" % event.unit_id)
            if unit_views.has(event.unit_id):
                await unit_views[event.unit_id].animate_death()
                unit_views.erase(event.unit_id)

        "turn_start":
            print("=== Round %d Started ===" % event.turn_number)

        "unit_activated":
            print("Unit %d activated (Team %d)" % [event.unit_id, event.team])

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
    var unit = current_state.units[selected_unit_id]

    # Check if unit can attack from current position
    var attack_targets_from_here = GameLogic_class.get_valid_attack_targets(current_state, selected_unit_id)

    if not attack_targets_from_here.is_empty() and not unit.has_moved:
        # Unit can attack without moving - go straight to attack mode
        print("\n=== UNIT CAN ATTACK FROM STARTING POSITION ===")
        print("Unit %d has %d targets in range" % [selected_unit_id, attack_targets_from_here.size()])
        _enter_attack_mode(selected_unit_id)
        return

    # Otherwise show movement options
    player_mode = PlayerMode.SELECTING_MOVE
    valid_move_tiles = GameLogic_class.get_valid_moves(current_state, selected_unit_id)
    print("\n=== AUTO-SELECTED PLAYER UNIT ===")
    print("Unit %d at grid position (%d, %d)" % [selected_unit_id, unit.position.x, unit.position.y])
    print("Movement range: %d tiles" % unit.movement_range)
    print("Valid moves: %d tiles" % valid_move_tiles.size())
    if valid_move_tiles.size() > 0:
        print("Green tiles will appear showing where you can move")
    else:
        print("No valid moves available (unit is blocked)")
    print("Click a green tile to move there, or check for attack options")
    print("=================================\n")
    _update_visual_feedback()

func _execute_ai_turn():
    is_processing_action = true
    await get_tree().create_timer(0.5).timeout  # Brief pause before AI moves

    var unit_id = current_state.active_unit_id
    var ai_action = GameLogic_class.get_ai_action(current_state, unit_id)
    var current_pos = current_state.units[unit_id].position

    match ai_action.action_type:
        "move":
            var target_pos = ai_action.move_to
            print("AI moving unit %d from (%d,%d) to (%d,%d)" % [unit_id, current_pos.x, current_pos.y, target_pos.x, target_pos.y])

            # Create move action
            var action = GameLogic_class.GameAction.new()
            action.type = GameLogic_class.ActionType.MOVE_UNIT
            action.unit_id = unit_id
            action.target_pos = target_pos
            var move_path: Array[Vector2i] = []
            move_path.append(current_pos)
            move_path.append(target_pos)
            action.path = move_path

            await execute_action(action)

            # After moving, check if can attack (verify unit still exists)
            if not current_state.units.has(unit_id):
                is_processing_action = false
                return

            await get_tree().create_timer(0.3).timeout
            var attack_targets = GameLogic_class.get_valid_attack_targets(current_state, unit_id)
            if not attack_targets.is_empty():
                print("AI attacking unit %d after move" % attack_targets[0])
                var attack_action = GameLogic_class.GameAction.new()
                attack_action.type = GameLogic_class.ActionType.ATTACK
                attack_action.unit_id = unit_id
                attack_action.target_id = attack_targets[0]
                await execute_action(attack_action)
            else:
                # No attack available, end turn
                print("AI has no attack targets, ending turn")
                var end_action = GameLogic_class.GameAction.new()
                end_action.type = GameLogic_class.ActionType.NEXT_UNIT
                await execute_action(end_action)

        "attack":
            var target_id = ai_action.attack_target
            print("AI attacking unit %d from current position" % target_id)
            var attack_action = GameLogic_class.GameAction.new()
            attack_action.type = GameLogic_class.ActionType.ATTACK
            attack_action.unit_id = unit_id
            attack_action.target_id = target_id
            await execute_action(attack_action)

        "end_turn":
            print("AI unit %d cannot move or attack, skipping turn" % unit_id)
            var action = GameLogic_class.GameAction.new()
            action.type = GameLogic_class.ActionType.NEXT_UNIT
            await execute_action(action)

    is_processing_action = false

func _handle_tile_click(grid_pos: Vector2i):
    var active_unit = current_state.units.get(current_state.active_unit_id)
    if active_unit == null or active_unit.team != 0:
        return

    print("Tile clicked at grid (%d, %d), mode: %d" % [grid_pos.x, grid_pos.y, player_mode])

    # Check if clicking on a unit (for attack)
    var clicked_unit_id = -1
    for unit_id in current_state.units:
        if current_state.units[unit_id].position == grid_pos:
            clicked_unit_id = unit_id
            break

    match player_mode:
        PlayerMode.SELECTING_MOVE:
            # Check if clicking on valid move tile
            if valid_move_tiles.has(grid_pos):
                print("Clicked on valid move tile - moving unit")
                _move_selected_unit(grid_pos)
            else:
                print("Clicked on non-movable tile")

        PlayerMode.SELECTING_ATTACK:
            # Check if clicking on valid attack target
            if clicked_unit_id >= 0 and valid_attack_targets.has(clicked_unit_id):
                print("Clicked on valid attack target - attacking unit %d" % clicked_unit_id)
                _attack_target(clicked_unit_id)
            else:
                print("Clicked on non-attackable target")

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

    # Clear move indicators
    valid_move_tiles.clear()
    battlefield_view.clear_move_indicators()

    await execute_action(action)

    # After moving, check for attack targets
    await get_tree().create_timer(0.2).timeout
    _enter_attack_mode(moving_unit_id)

    is_processing_action = false

func _enter_attack_mode(unit_id: int):
    """Enter attack selection mode - show red indicators on enemies in range"""
    # Verify unit still exists and hasn't acted yet
    if not current_state.units.has(unit_id):
        print("Unit %d no longer exists, cannot enter attack mode" % unit_id)
        return

    var unit = current_state.units[unit_id]
    if unit.has_acted:
        print("Unit %d has already acted, cannot enter attack mode" % unit_id)
        return

    player_mode = PlayerMode.SELECTING_ATTACK
    selected_unit_id = unit_id
    valid_attack_targets = GameLogic_class.get_valid_attack_targets(current_state, unit_id)

    print("\n=== ATTACK MODE ===")
    print("Valid attack targets: %d" % valid_attack_targets.size())

    if valid_attack_targets.size() > 0:
        print("Red indicators will appear on enemies you can attack")
        # Show red indicators on enemy units
        for target_id in valid_attack_targets:
            var target_pos = current_state.units[target_id].position
            battlefield_view.show_attack_indicator(target_pos)
            print("  - Can attack unit %d at (%d, %d)" % [target_id, target_pos.x, target_pos.y])
    else:
        print("No enemies in range - click End Turn button to finish")

    # Show End Turn button
    turn_ui.show_end_turn_button(true)

    print("===================\n")
    _update_visual_feedback()

func _attack_target(target_id: int):
    """Execute attack on target"""
    if selected_unit_id < 0 or is_processing_action:
        return

    is_processing_action = true

    var attacker_id = selected_unit_id
    print("Unit %d attacking unit %d" % [attacker_id, target_id])

    # Create attack action
    var action = GameLogic_class.GameAction.new()
    action.type = GameLogic_class.ActionType.ATTACK
    action.unit_id = attacker_id
    action.target_id = target_id

    # Clear attack indicators
    valid_attack_targets.clear()
    battlefield_view.clear_attack_indicators()

    # Clear selection and hide end turn button
    selected_unit_id = -1
    player_mode = PlayerMode.NONE
    turn_ui.show_end_turn_button(false)

    await execute_action(action)

    is_processing_action = false

func _end_player_turn():
    """End the current player's turn without attacking"""
    if selected_unit_id < 0 or is_processing_action:
        return

    is_processing_action = true

    print("Player ending turn for unit %d" % selected_unit_id)

    # Create end turn action
    var action = GameLogic_class.GameAction.new()
    action.type = GameLogic_class.ActionType.NEXT_UNIT

    # Clear indicators and selection
    valid_attack_targets.clear()
    battlefield_view.clear_attack_indicators()
    selected_unit_id = -1
    player_mode = PlayerMode.NONE
    turn_ui.show_end_turn_button(false)

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

    # Clear all indicators first
    battlefield_view.clear_move_indicators()
    battlefield_view.clear_attack_indicators()

    # Show appropriate indicators based on mode
    if selected_unit_id >= 0:
        match player_mode:
            PlayerMode.SELECTING_MOVE:
                print("Showing %d green move indicators" % valid_move_tiles.size())
                for move_pos in valid_move_tiles:
                    print("  - Showing green tile at grid (%d, %d)" % [move_pos.x, move_pos.y])
                    battlefield_view.show_move_indicator(move_pos)

            PlayerMode.SELECTING_ATTACK:
                print("Showing %d red attack indicators" % valid_attack_targets.size())
                for target_id in valid_attack_targets:
                    var target_pos = current_state.units[target_id].position
                    battlefield_view.show_attack_indicator(target_pos)

