# battle_controller.gd - Bridges game logic and presentation
extends Node
class_name BattleController

var current_state: GameState

@onready var battlefield_view: BattlefieldView = $BattlefieldView
@onready var units_container: Node3D = $Units

var unit_views: Dictionary = {}  # Maps unit_id to UnitView

func _ready():
    _initialize_battle()

func _initialize_battle():
    # Create initial 3v3 game state
    current_state = GameLogic.create_initial_3v3_state()
    
    # Spawn unit views based on state
    _spawn_unit_views()

func _spawn_unit_views():
    # Load unit scene
    var unit_scene = preload("res://scenes/units/unit_view.tscn")
    
    # Create a view for each unit in the state
    for unit_id in current_state.units:
        var unit_data = current_state.units[unit_id]
        var unit_view = unit_scene.instantiate() as UnitView
        
        unit_view.unit_id = unit_data.id
        unit_view.team = unit_data.team
        
        units_container.add_child(unit_view)
        unit_view.set_grid_position(unit_data.position, battlefield_view.tile_size)
        
        unit_views[unit_id] = unit_view

func execute_action(action: GameLogic.GameAction) -> void:
    var result = GameLogic.update_gamestate(current_state, action)
    current_state = result.state
    
    # Play animations from events
    for event in result.events:
        await _play_event(event)

func _play_event(event: GameEvent) -> void:
    match event.event_type:
        "move":
            var move_event = event as GameEvent.MoveEvent
            if unit_views.has(move_event.unit_id):
                await unit_views[move_event.unit_id].animate_move(
                    move_event.path,
                    move_event.duration,
                    battlefield_view.tile_size
                )
        
        "attack":
            var attack_event = event as GameEvent.AttackEvent
            if unit_views.has(attack_event.attacker_id) and unit_views.has(attack_event.target_id):
                var target_pos = unit_views[attack_event.target_id].position
                await unit_views[attack_event.attacker_id].animate_attack(target_pos)
        
        "turn_start":
            # Could show UI notification here
            pass
