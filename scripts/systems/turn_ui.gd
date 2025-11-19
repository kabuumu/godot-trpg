# scripts/systems/turn_ui.gd - Simple UI to show current turn
extends Control
class_name TurnUI

@onready var turn_label: Label = $TurnLabel
@onready var unit_label: Label = $UnitLabel
@onready var instruction_label: Label = $InstructionLabel

func update_turn_info(round: int, unit_id: int, unit_team: int, unit_initiative: int):
    turn_label.text = "Round %d" % round

    var team_name = "PLAYER (RED)" if unit_team == 0 else "AI (BLUE)"
    unit_label.text = "Unit %d - %s (Initiative: %d)" % [unit_id, team_name, unit_initiative]

    if unit_team == 0:
        instruction_label.text = "Click a green tile to move your unit"
    else:
        instruction_label.text = "AI is thinking..."

func _ready():
    turn_label.text = "Battle Starting..."
    unit_label.text = ""
    instruction_label.text = "Waiting for battle to begin"

