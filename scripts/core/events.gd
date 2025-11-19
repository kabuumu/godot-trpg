# events.gd - Event classes for animations
class_name GameEvent

# Base event class
var event_type: String

# Movement event
class MoveEvent extends GameEvent:
    var unit_id: int
    var path: Array[Vector2i]
    var duration: float
    
    func _init(u_id: int, move_path: Array[Vector2i], move_duration: float = 0.5):
        event_type = "move"
        unit_id = u_id
        path = move_path
        duration = move_duration

# Attack event
class AttackEvent extends GameEvent:
    var attacker_id: int
    var target_id: int
    var damage: int
    var is_critical: bool
    
    func _init(atk_id: int, tgt_id: int, dmg: int, crit: bool = false):
        event_type = "attack"
        attacker_id = atk_id
        target_id = tgt_id
        damage = dmg
        is_critical = crit

# Turn start event
class TurnStartEvent extends GameEvent:
    var turn_number: int
    var active_player: int
    
    func _init(turn: int, player: int):
        event_type = "turn_start"
        turn_number = turn
        active_player = player

# Unit activated event (for initiative order)
class UnitActivatedEvent extends GameEvent:
    var unit_id: int
    var team: int

    func _init(u_id: int, u_team: int):
        event_type = "unit_activated"
        unit_id = u_id
        team = u_team

# Unit died event
class UnitDiedEvent extends GameEvent:
    var unit_id: int

    func _init(u_id: int):
        event_type = "unit_died"
        unit_id = u_id

