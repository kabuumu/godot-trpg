# battlefield_view.gd - 3D battlefield rendering
extends Node3D
class_name BattlefieldView

@export var grid_width: int = 8
@export var grid_height: int = 6
@export var tile_size: float = 2.0

var grid_tiles: Array[Node3D] = []
var move_indicators: Array[Node3D] = []

func _ready():
    print("=== Creating Battlefield Grid ===")
    print("Grid size: %d x %d tiles" % [grid_width, grid_height])
    print("Tile size: %.1f" % tile_size)
    _create_grid()
    print("Grid created with %d tiles" % grid_tiles.size())

func _create_grid():
    # Create a visual grid using plane meshes
    for x in range(grid_width):
        for z in range(grid_height):
            var tile = _create_tile(x, z)
            add_child(tile)
            # Now that it's in tree, add collision children
            _add_collision_to_tile(tile)
            grid_tiles.append(tile)

func _create_tile(x: int, z: int) -> Node3D:
    # Create a static body for collision detection
    var static_body = StaticBody3D.new()
    # Position at tile CENTER, not corner
    static_body.position = Vector3(
        x * tile_size + tile_size / 2.0,
        0,
        z * tile_size + tile_size / 2.0
    )
    return static_body

func _add_collision_to_tile(static_body: StaticBody3D):
    var tile = MeshInstance3D.new()
    var mesh = PlaneMesh.new()
    mesh.size = Vector2(tile_size * 0.9, tile_size * 0.9)  # Small gap between tiles
    tile.mesh = mesh

    # Get grid position from world position (accounting for center offset)
    var world_pos = static_body.position
    var x = int((world_pos.x - tile_size / 2.0) / tile_size)
    var z = int((world_pos.z - tile_size / 2.0) / tile_size)

    # Create material with checkerboard pattern
    var material = StandardMaterial3D.new()
    if (x + z) % 2 == 0:
        material.albedo_color = Color(0.8, 0.8, 0.8)
    else:
        material.albedo_color = Color(0.6, 0.6, 0.6)
    tile.material_override = material

    # Create collision shape
    var collision = CollisionShape3D.new()
    var box_shape = BoxShape3D.new()
    box_shape.size = Vector3(tile_size * 0.9, 0.1, tile_size * 0.9)
    collision.shape = box_shape

    static_body.add_child(tile)
    static_body.add_child(collision)

func grid_to_world(grid_pos: Vector2i) -> Vector3:
    # Position at tile CENTER
    return Vector3(
        grid_pos.x * tile_size + tile_size / 2.0,
        0,
        grid_pos.y * tile_size + tile_size / 2.0
    )

func world_to_grid(world_pos: Vector3) -> Vector2i:
    # Convert world position to grid by dividing by tile size
    # Each tile occupies a tile_size x tile_size area
    return Vector2i(
        int(world_pos.x / tile_size),
        int(world_pos.z / tile_size)
    )

func show_move_indicator(grid_pos: Vector2i):
    # Create a static body for the indicator so it can be clicked
    var static_body = StaticBody3D.new()

    var indicator = MeshInstance3D.new()
    var mesh = PlaneMesh.new()
    mesh.size = Vector2(tile_size * 0.8, tile_size * 0.8)
    indicator.mesh = mesh

    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.0, 1.0, 0.0, 0.5)  # Green with transparency
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    indicator.material_override = material

    # Add collision shape so raycast can detect clicks on the indicator
    var collision = CollisionShape3D.new()
    var box_shape = BoxShape3D.new()
    box_shape.size = Vector3(tile_size * 0.8, 0.1, tile_size * 0.8)
    collision.shape = box_shape

    # Position at tile CENTER, slightly above ground
    static_body.position = Vector3(
        grid_pos.x * tile_size + tile_size / 2.0,
        0.05,
        grid_pos.y * tile_size + tile_size / 2.0
    )

    static_body.add_child(indicator)
    static_body.add_child(collision)
    add_child(static_body)
    move_indicators.append(static_body)

func clear_move_indicators():
    for indicator in move_indicators:
        indicator.queue_free()
    move_indicators.clear()

