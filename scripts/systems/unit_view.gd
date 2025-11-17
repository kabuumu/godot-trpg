# unit_view.gd - 3D unit representation (presentation only)
extends Node3D
class_name UnitView

@export var unit_id: int = -1
@export var team: int = 0

@onready var model: MeshInstance3D = $Model
@onready var label: Label3D = $Label

var grid_position: Vector2i = Vector2i.ZERO

func _ready():
    _setup_model()
    _setup_label()

func _setup_model():
    # Create a simple capsule for the unit
    var mesh = CapsuleMesh.new()
    mesh.height = 1.5
    mesh.radius = 0.3
    model.mesh = mesh
    
    # Create material based on team
    var material = StandardMaterial3D.new()
    if team == 0:
        material.albedo_color = Color(0.2, 0.5, 0.9)  # Blue for player
    else:
        material.albedo_color = Color(0.9, 0.2, 0.2)  # Red for enemy
    
    model.material_override = material
    
    # Position model above ground
    model.position.y = 0.75

func _setup_label():
    if label:
        label.text = "U%d" % unit_id
        label.position.y = 2.0
        label.pixel_size = 0.01
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func set_grid_position(pos: Vector2i, tile_size: float = 2.0):
    grid_position = pos
    position = Vector3(pos.x * tile_size, 0, pos.y * tile_size)

func animate_move(path: Array[Vector2i], duration: float, tile_size: float = 2.0) -> void:
    for grid_pos in path:
        var world_pos = Vector3(grid_pos.x * tile_size, 0, grid_pos.y * tile_size)
        var tween = create_tween()
        tween.tween_property(self, "position", world_pos, duration)
        await tween.finished
    grid_position = path[-1] if path.size() > 0 else grid_position

func animate_attack(target_pos: Vector3) -> void:
    # Simple attack animation - bob forward
    var original_pos = position
    var direction = (target_pos - position).normalized()
    var attack_pos = position + direction * 0.5
    
    var tween = create_tween()
    tween.tween_property(self, "position", attack_pos, 0.2)
    tween.tween_property(self, "position", original_pos, 0.2)
    await tween.finished
