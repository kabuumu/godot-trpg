# unit_view.gd - 3D unit representation (presentation only)
extends Node3D
class_name UnitView

@export var unit_id: int = -1
@export var team: int = 0

@onready var model: MeshInstance3D = $StaticBody3D/Model
@onready var label: Label3D = $Label

var grid_position: Vector2i = Vector2i.ZERO
var is_highlighted: bool = false
var current_health: int = 100
var max_health: int = 100

# Health bar nodes (created dynamically)
var health_bar_bg: MeshInstance3D
var health_bar_fg: MeshInstance3D

func _ready():
	print("UnitView _ready() called for unit %d, team %d" % [unit_id, team])
	print("  Visible: %s, Model exists: %s, Label exists: %s" % [visible, model != null, label != null])
	_setup_model()
	_setup_label()
	_setup_health_bar()
	print("  Model setup complete, position: %v" % position)
	print("  Final check - Model visible: %s, in tree: %s" % [model.visible, is_inside_tree()])

func _setup_model():
	print("  Setting up model for unit %d" % unit_id)

	# Ensure we have a mesh
	if model.mesh == null:
		print("    WARNING: Model has no mesh, creating one")
		var mesh = CapsuleMesh.new()
		mesh.height = 2.0  # Taller capsule
		mesh.radius = 0.4  # Wider capsule
		model.mesh = mesh

	# Create and apply material with bright colors
	var material = StandardMaterial3D.new()
	if team == 0:
		material.albedo_color = Color.RED  # Red for player
		print("    Material: RED (player)")
	else:
		material.albedo_color = Color.BLUE  # Blue for AI/enemy
		print("    Material: BLUE (AI)")

	# Use shaded mode so emission works
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	model.material_override = material
	print("    Model mesh: %s" % model.mesh)
	print("    Model material applied: %s" % model.material_override)

func _setup_label():
	if label:
		label.text = "U%d" % unit_id
		label.position.y = 2.5
		label.pixel_size = 0.01
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		print("  Label setup: %s at %v" % [label.text, label.position])

func _setup_health_bar():
	print("  Setting up health bar for unit %d" % unit_id)
	# Create background bar (dark red/gray)
	health_bar_bg = MeshInstance3D.new()
	var bg_mesh = BoxMesh.new()
	bg_mesh.size = Vector3(0.8, 0.1, 0.05)
	health_bar_bg.mesh = bg_mesh
	var bg_material = StandardMaterial3D.new()
	bg_material.albedo_color = Color(0.2, 0.0, 0.0)
	bg_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	health_bar_bg.material_override = bg_material
	health_bar_bg.position = Vector3(0, 2.2, 0)  # Position above unit
	health_bar_bg.top_level = false
	add_child(health_bar_bg)
	print("    Health bar background created")

	# Create foreground bar (bright green)
	health_bar_fg = MeshInstance3D.new()
	var fg_mesh = BoxMesh.new()
	fg_mesh.size = Vector3(0.76, 0.08, 0.03)  # Slightly smaller than background
	health_bar_fg.mesh = fg_mesh
	var fg_material = StandardMaterial3D.new()
	fg_material.albedo_color = Color(0.0, 1.0, 0.0)  # Bright green
	fg_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	health_bar_fg.material_override = fg_material
	health_bar_fg.position = Vector3(0, 2.2, 0.01)  # Slightly forward
	health_bar_fg.top_level = false
	add_child(health_bar_fg)
	print("    Health bar foreground created")

	update_health(max_health, max_health)
	print("    Health bar initialized with health: %d/%d" % [max_health, max_health])

# Make health bars always face camera
func _process(_delta):
	if health_bar_bg and health_bar_fg:
		var camera = get_viewport().get_camera_3d()
		if camera:
			# Billboard effect - rotate to face camera
			health_bar_bg.look_at(camera.global_position, Vector3.UP)
			health_bar_fg.look_at(camera.global_position, Vector3.UP)

func update_health(health: int, max_hp: int):
	current_health = health
	max_health = max_hp

	if health_bar_fg == null:
		return

	# Update health bar scale
	var health_percent = float(health) / float(max_hp) if max_hp > 0 else 0.0
	health_percent = clamp(health_percent, 0.0, 1.0)

	# Scale the bar horizontally
	health_bar_fg.scale.x = health_percent

	# Offset position so it shrinks from right to left
	health_bar_fg.position.x = -0.38 * (1.0 - health_percent)

	# Keep health bar green at all times
	var fg_material = health_bar_fg.material_override as StandardMaterial3D
	fg_material.albedo_color = Color(0.0, 1.0, 0.0)  # Always bright green

func set_grid_position(pos: Vector2i, tile_size: float = 2.0):
	grid_position = pos
	# Position at tile CENTER
	position = Vector3(
		pos.x * tile_size + tile_size / 2.0,
		0,
		pos.y * tile_size + tile_size / 2.0
	)
	print("  Set grid position (%d, %d) -> world (%v)" % [pos.x, pos.y, position])

func animate_move(path: Array[Vector2i], duration: float, tile_size: float = 2.0) -> void:
	for grid_pos in path:
		# Position at tile CENTER
		var world_pos = Vector3(
			grid_pos.x * tile_size + tile_size / 2.0,
			0,
			grid_pos.y * tile_size + tile_size / 2.0
		)
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

func animate_death() -> void:
	# Fade out and sink into ground
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", -2.0, 0.5)
	tween.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.5)
	await tween.finished
	queue_free()

func set_highlight(highlight: bool):
	is_highlighted = highlight
	if model and model.material_override:
		var material = model.material_override as StandardMaterial3D
		if highlight:
			material.emission_enabled = true
			material.emission = material.albedo_color
			material.emission_energy = 0.5
		else:
			material.emission_enabled = false

