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
var turn_order: Array[int] = []  # Array of unit IDs in initiative order
var current_unit_index: int = 0  # Index in turn_order
var active_unit_id: int = -1  # ID of currently active unit

func _init():
    pass

func duplicate():
    var new_state = get_script().new()
    new_state.grid_width = grid_width
    new_state.grid_height = grid_height
    new_state.units = units.duplicate(true)
    new_state.current_turn = current_turn
    new_state.active_player = active_player
    new_state.turn_order = turn_order.duplicate()
    new_state.current_unit_index = current_unit_index
    new_state.active_unit_id = active_unit_id
    return new_state

# Unit data structure
class UnitData:
    var id: int
    var position: Vector2i
    var team: int  # 0 = player, 1 = enemy
    var health: int
    var max_health: int
    var movement_range: int
    var attack_range: int  # Melee range
    var attack_damage: int
    var initiative: int  # Higher = acts first
    var has_acted: bool  # Has this unit completed their turn?
    var has_moved: bool  # Has this unit moved this turn?

    func _init(unit_id: int, pos: Vector2i, unit_team: int, move_range: int = 2):
        id = unit_id
        position = pos
        team = unit_team
        health = 100
        max_health = 100
        movement_range = move_range
        attack_range = 1  # Melee range = 1 tile
        attack_damage = 30
        initiative = randi_range(1, 20)  # Random initiative 1-20
        has_acted = false
        has_moved = false
