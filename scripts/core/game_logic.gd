# game_logic.gd - Pure game logic, no Node dependencies
class_name GameLogic

# Action types
enum ActionType {
    MOVE_UNIT,
    ATTACK,
    END_TURN
}

class GameAction:
    var type: ActionType
    var unit_id: int
    var target_pos: Vector2i
    var target_id: int
    var path: Array[Vector2i]

# Main state update function - returns new state + events
static func update_gamestate(current_state: GameState, action: GameAction) -> Dictionary:
    var new_state = current_state.duplicate()
    var events = []
    
    match action.type:
        ActionType.MOVE_UNIT:
            if new_state.units.has(action.unit_id):
                new_state.units[action.unit_id].position = action.target_pos
                events.append(GameEvent.MoveEvent.new(action.unit_id, action.path))
        
        ActionType.ATTACK:
            if new_state.units.has(action.unit_id) and new_state.units.has(action.target_id):
                var damage = _calculate_damage(new_state, action)
                new_state.units[action.target_id].health -= damage
                var is_crit = randf() < 0.2  # 20% crit chance
                events.append(GameEvent.AttackEvent.new(action.unit_id, action.target_id, damage, is_crit))
        
        ActionType.END_TURN:
            new_state.current_turn += 1
            new_state.active_player = 1 - new_state.active_player
            events.append(GameEvent.TurnStartEvent.new(new_state.current_turn, new_state.active_player))
    
    return {"state": new_state, "events": events}

static func _calculate_damage(_state: GameState, _action: GameAction) -> int:
    return randi_range(20, 40)

# Initialize a 3v3 battle setup
static func create_initial_3v3_state() -> GameState:
    var state = GameState.new()
    
    # Player units (team 0) - bottom side
    state.units[0] = GameState.UnitData.new(0, Vector2i(1, 0), 0)
    state.units[1] = GameState.UnitData.new(1, Vector2i(3, 0), 0)
    state.units[2] = GameState.UnitData.new(2, Vector2i(5, 0), 0)
    
    # Enemy units (team 1) - top side
    state.units[3] = GameState.UnitData.new(3, Vector2i(1, 5), 1)
    state.units[4] = GameState.UnitData.new(4, Vector2i(3, 5), 1)
    state.units[5] = GameState.UnitData.new(5, Vector2i(5, 5), 1)
    
    return state
