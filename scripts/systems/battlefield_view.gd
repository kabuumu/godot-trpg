# battlefield_view.gd - 3D battlefield rendering
extends Node3D
class_name BattlefieldView

@export var grid_width: int = 8
@export var grid_height: int = 6
@export var tile_size: float = 2.0

var grid_tiles: Array[MeshInstance3D] = []

func _ready():
    _create_grid()

func _create_grid():
    # Create a visual grid using plane meshes
    for x in range(grid_width):
        for z in range(grid_height):
            var tile = _create_tile(x, z)
            add_child(tile)
            grid_tiles.append(tile)

func _create_tile(x: int, z: int) -> MeshInstance3D:
    var tile = MeshInstance3D.new()
    var mesh = PlaneMesh.new()
    mesh.size = Vector2(tile_size * 0.9, tile_size * 0.9)  # Small gap between tiles
    tile.mesh = mesh
    
    # Create material
    var material = StandardMaterial3D.new()
    
    # Checkerboard pattern
    if (x + z) % 2 == 0:
        material.albedo_color = Color(0.8, 0.8, 0.8)
    else:
        material.albedo_color = Color(0.6, 0.6, 0.6)
    
    tile.material_override = material
    
    # Position in 3D space
    tile.position = Vector3(x * tile_size, 0, z * tile_size)
    
    return tile

func grid_to_world(grid_pos: Vector2i) -> Vector3:
    return Vector3(grid_pos.x * tile_size, 0, grid_pos.y * tile_size)

func world_to_grid(world_pos: Vector3) -> Vector2i:
    return Vector2i(
        int(world_pos.x / tile_size),
        int(world_pos.z / tile_size)
    )
