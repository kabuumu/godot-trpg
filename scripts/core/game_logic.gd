# game_logic.gd - Pure game logic, no Node dependencies
class_name GameLogic

# Load dependencies
const GameState_class = preload("res://scripts/core/gamestate.gd")
const GameEvent_class = preload("res://scripts/core/events.gd")

# Action types
enum ActionType {
    MOVE_UNIT,
    ATTACK,
    END_TURN,
    NEXT_UNIT  # Move to next unit in initiative order
}

class GameAction:
    var type: ActionType
    var unit_id: int = -1
    var target_pos: Vector2i = Vector2i.ZERO
    var target_id: int = -1
    var path: Array[Vector2i] = []

    func _init():
        pass

# Main state update function - returns new state + events
static func update_gamestate(current_state, action) -> Dictionary:
    var new_state = current_state.duplicate()
    var events = []

    const GameEvent_class = preload("res://scripts/core/events.gd")

    match action.type:
        ActionType.MOVE_UNIT:
            if new_state.units.has(action.unit_id):
                var unit = new_state.units[action.unit_id]
                # Validate movement is within range
                var distance = abs(action.target_pos.x - unit.position.x) + abs(action.target_pos.y - unit.position.y)
                if distance <= unit.movement_range:
                    unit.position = action.target_pos
                    unit.has_moved = true  # Mark as moved, but not acted (can still attack)
                    events.append(GameEvent_class.MoveEvent.new(action.unit_id, action.path))

        ActionType.ATTACK:
            if new_state.units.has(action.unit_id) and new_state.units.has(action.target_id):
                var attacker = new_state.units[action.unit_id]
                var target = new_state.units[action.target_id]

                # Calculate damage
                var damage = attacker.attack_damage + randi_range(-5, 5)  # Add variance
                var is_crit = randf() < 0.2  # 20% crit chance
                if is_crit:
                    damage = int(damage * 1.5)

                target.health -= damage
                attacker.has_acted = true

                events.append(GameEvent_class.AttackEvent.new(action.unit_id, action.target_id, damage, is_crit))

                # Check if target died
                if target.health <= 0:
                    events.append(GameEvent_class.UnitDiedEvent.new(action.target_id))
                    new_state.units.erase(action.target_id)
                    # Remove from turn order
                    var idx = new_state.turn_order.find(action.target_id)
                    if idx >= 0:
                        new_state.turn_order.remove_at(idx)
                        # Adjust current_unit_index if needed
                        if idx < new_state.current_unit_index:
                            new_state.current_unit_index -= 1

                # After unit acts, move to next in initiative
                var next_result = _advance_to_next_unit(new_state)
                new_state = next_result.state
                events.append_array(next_result.events)

        ActionType.NEXT_UNIT:
            # Mark current unit as acted if they haven't already
            if new_state.units.has(new_state.active_unit_id):
                new_state.units[new_state.active_unit_id].has_acted = true
            var next_result = _advance_to_next_unit(new_state)
            new_state = next_result.state
            events.append_array(next_result.events)

        ActionType.END_TURN:
            new_state.current_turn += 1
            new_state.active_player = 1 - new_state.active_player
            events.append(GameEvent_class.TurnStartEvent.new(new_state.current_turn, new_state.active_player))

    return {"state": new_state, "events": events}

static func _calculate_damage(_state, _action) -> int:
    return randi_range(20, 40)

# Calculate turn order based on initiative
static func calculate_turn_order(state) -> Array[int]:
    var units_with_initiative = []
    for unit_id in state.units:
        var unit = state.units[unit_id]
        units_with_initiative.append({"id": unit_id, "initiative": unit.initiative})

    # Sort by initiative (highest first)
    units_with_initiative.sort_custom(func(a, b): return a.initiative > b.initiative)

    var turn_order: Array[int] = []
    for entry in units_with_initiative:
        turn_order.append(entry.id)

    return turn_order

# Advance to the next unit in initiative order
static func _advance_to_next_unit(state) -> Dictionary:
    const GameEvent_class = preload("res://scripts/core/events.gd")
    var events = []

    # Move to next unit
    state.current_unit_index += 1

    # Check if we've gone through all units (new round)
    if state.current_unit_index >= state.turn_order.size():
        state.current_unit_index = 0
        state.current_turn += 1
        # Reset has_acted and has_moved for all units
        for unit_id in state.units:
            state.units[unit_id].has_acted = false
            state.units[unit_id].has_moved = false
        events.append(GameEvent_class.TurnStartEvent.new(state.current_turn, -1))

    # Set active unit
    if state.turn_order.size() > 0:
        state.active_unit_id = state.turn_order[state.current_unit_index]
        var active_unit = state.units[state.active_unit_id]
        state.active_player = active_unit.team
        events.append(GameEvent_class.UnitActivatedEvent.new(state.active_unit_id, active_unit.team))

    return {"state": state, "events": events}

# Get valid movement positions for a unit
static func get_valid_moves(state, unit_id: int) -> Array[Vector2i]:
    if not state.units.has(unit_id):
        return []

    var unit = state.units[unit_id]
    var valid_moves: Array[Vector2i] = []
    var start_pos = unit.position

    # Check all tiles within movement range (Manhattan distance)
    for x in range(state.grid_width):
        for y in range(state.grid_height):
            var target_pos = Vector2i(x, y)
            var distance = abs(target_pos.x - start_pos.x) + abs(target_pos.y - start_pos.y)

            if distance <= unit.movement_range and distance > 0:
                # Check if tile is occupied
                var occupied = false
                for other_id in state.units:
                    if state.units[other_id].position == target_pos:
                        occupied = true
                        break

                if not occupied:
                    valid_moves.append(target_pos)

    return valid_moves

# Get valid attack targets for a unit
static func get_valid_attack_targets(state, unit_id: int) -> Array[int]:
    if not state.units.has(unit_id):
        return []

    var unit = state.units[unit_id]
    var valid_targets: Array[int] = []

    # Find all enemy units within attack range
    for other_id in state.units:
        var other_unit = state.units[other_id]
        if other_unit.team != unit.team:  # Must be enemy
            var distance = abs(other_unit.position.x - unit.position.x) + abs(other_unit.position.y - unit.position.y)
            if distance <= unit.attack_range:
                valid_targets.append(other_id)

    return valid_targets

# Simple AI: move towards nearest enemy and attack if possible
static func get_ai_action(state, unit_id: int) -> Dictionary:
    """Returns {action_type: 'move'|'attack'|'end_turn', move_to: Vector2i, attack_target: int}"""
    if not state.units.has(unit_id):
        return {"action_type": "end_turn"}

    var unit = state.units[unit_id]

    # First, check if we can attack from current position
    var attack_targets = get_valid_attack_targets(state, unit_id)
    if not attack_targets.is_empty():
        # Attack the first available target
        return {"action_type": "attack", "attack_target": attack_targets[0]}

    # If can't attack yet, try to move closer to nearest enemy
    var valid_moves = get_valid_moves(state, unit_id)

    if valid_moves.is_empty():
        return {"action_type": "end_turn"}

    # Find nearest enemy
    var nearest_enemy_pos = Vector2i(-1, -1)
    var min_distance = 999999

    for other_id in state.units:
        var other_unit = state.units[other_id]
        if other_unit.team != unit.team:
            var distance = abs(other_unit.position.x - unit.position.x) + abs(other_unit.position.y - unit.position.y)
            if distance < min_distance:
                min_distance = distance
                nearest_enemy_pos = other_unit.position

    # Pick move that gets closest to nearest enemy
    var best_move = unit.position
    var best_distance = min_distance

    for move_pos in valid_moves:
        var distance = abs(nearest_enemy_pos.x - move_pos.x) + abs(nearest_enemy_pos.y - move_pos.y)
        if distance < best_distance:
            best_distance = distance
            best_move = move_pos

    if best_move != unit.position:
        return {"action_type": "move", "move_to": best_move}
    else:
        return {"action_type": "end_turn"}

# Initialize a 3v3 battle setup
static func create_initial_3v3_state():
    const GameState_class = preload("res://scripts/core/gamestate.gd")
    var state = GameState_class.new()

    # Player units (team 0) - bottom side (RED - player controlled)
    state.units[0] = GameState_class.UnitData.new(0, Vector2i(1, 0), 0, 2)  # 2 tiles movement
    state.units[1] = GameState_class.UnitData.new(1, Vector2i(3, 0), 0, 3)  # 3 tiles movement
    state.units[2] = GameState_class.UnitData.new(2, Vector2i(5, 0), 0, 2)  # 2 tiles movement

    # Enemy units (team 1) - top side (BLUE - AI controlled)
    state.units[3] = GameState_class.UnitData.new(3, Vector2i(1, 5), 1, 2)  # 2 tiles movement
    state.units[4] = GameState_class.UnitData.new(4, Vector2i(3, 5), 1, 3)  # 3 tiles movement
    state.units[5] = GameState_class.UnitData.new(5, Vector2i(5, 5), 1, 2)  # 2 tiles movement

    # Calculate and set initiative order
    state.turn_order = calculate_turn_order(state)
    state.current_unit_index = 0
    if state.turn_order.size() > 0:
        state.active_unit_id = state.turn_order[0]
        state.active_player = state.units[state.active_unit_id].team

    return state

