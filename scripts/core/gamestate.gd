# gamestate.gd - Core game state data structure
class_name GameState

# Grid dimensions
var grid_width: int = 8
var grid_height: int = 6

# Unit data - dictionary mapping unit_id to unit data
var units: Dictionary = {}

# Current turn information
var current_turn: int = 0
var active_player: int = 0  # 0 = player, 1 = enemy

func _init():
    pass

func duplicate() -> GameState:
    var new_state = GameState.new()
    new_state.grid_width = grid_width
    new_state.grid_height = grid_height
    new_state.units = units.duplicate(true)
    new_state.current_turn = current_turn
    new_state.active_player = active_player
    return new_state

# Unit data structure
class UnitData:
    var id: int
    var position: Vector2i
    var team: int  # 0 = player, 1 = enemy
    var health: int
    var max_health: int
    var movement_range: int
    var attack_range: int
    
    func _init(unit_id: int, pos: Vector2i, unit_team: int):
        id = unit_id
        position = pos
        team = unit_team
        health = 100
        max_health = 100
        movement_range = 4
        attack_range = 3
