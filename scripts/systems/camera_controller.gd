# camera_controller.gd - Camera movement and rotation controls
extends Camera3D
class_name CameraController

# Movement settings
@export var move_speed: float = 10.0
@export var pan_speed: float = 5.0
@export var zoom_speed: float = 5.0

# Rotation settings
@export var rotation_speed: float = 1.0
@export var min_angle: float = 20.0  # Minimum pitch angle (degrees)
@export var max_angle: float = 80.0  # Maximum pitch angle (degrees)

# Current rotation
var current_yaw: float = 0.0
var current_pitch: float = 45.0

# Camera orbit center
var orbit_center: Vector3 = Vector3(7, 0, 5)  # Center of the battlefield
var orbit_distance: float = 17.0

func _ready():
    # Initialize camera rotation
    _update_camera_transform()

func _process(delta):
    _handle_movement(delta)
    _handle_rotation(delta)
    _handle_zoom(delta)

func _handle_movement(delta):
    var movement = Vector3.ZERO

    # Arrow keys for panning the camera
    if Input.is_action_pressed("ui_left"):
        movement.x -= 1
    if Input.is_action_pressed("ui_right"):
        movement.x += 1
    if Input.is_action_pressed("ui_up"):
        movement.z -= 1
    if Input.is_action_pressed("ui_down"):
        movement.z += 1

    # Normalize and apply movement relative to camera rotation
    if movement.length() > 0:
        movement = movement.normalized()

        # Convert movement to camera-relative space
        # Get camera's forward and right vectors (ignoring Y component for horizontal movement)
        var camera_forward = -global_transform.basis.z
        camera_forward.y = 0
        camera_forward = camera_forward.normalized()

        var camera_right = global_transform.basis.x
        camera_right.y = 0
        camera_right = camera_right.normalized()

        # Apply movement in camera-relative directions
        var relative_movement = (camera_right * movement.x + camera_forward * movement.z) * pan_speed * delta
        orbit_center += relative_movement
        _update_camera_transform()

func _handle_rotation(delta):
    var rotate_left = Input.is_action_pressed("camera_rotate_left")
    var rotate_right = Input.is_action_pressed("camera_rotate_right")
    var rotate_up = Input.is_action_pressed("camera_rotate_up")
    var rotate_down = Input.is_action_pressed("camera_rotate_down")

    # Horizontal rotation (yaw)
    if rotate_left:
        current_yaw += rotation_speed * delta * 60.0
    if rotate_right:
        current_yaw -= rotation_speed * delta * 60.0

    # Vertical rotation (pitch)
    if rotate_up:
        current_pitch = clamp(current_pitch - rotation_speed * delta * 60.0, min_angle, max_angle)
    if rotate_down:
        current_pitch = clamp(current_pitch + rotation_speed * delta * 60.0, min_angle, max_angle)

    # Update camera if rotation changed
    if rotate_left or rotate_right or rotate_up or rotate_down:
        _update_camera_transform()

func _handle_zoom(delta):
    # Mouse wheel or Q/E for zoom
    if Input.is_action_pressed("camera_zoom_in"):
        orbit_distance = clamp(orbit_distance - zoom_speed * delta * 10.0, 5.0, 30.0)
        _update_camera_transform()
    if Input.is_action_pressed("camera_zoom_out"):
        orbit_distance = clamp(orbit_distance + zoom_speed * delta * 10.0, 5.0, 30.0)
        _update_camera_transform()

func _input(event):
    # Handle mouse wheel zoom
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            orbit_distance = clamp(orbit_distance - 2.0, 5.0, 30.0)
            _update_camera_transform()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            orbit_distance = clamp(orbit_distance + 2.0, 5.0, 30.0)
            _update_camera_transform()

func _update_camera_transform():
    # Convert angles to radians
    var yaw_rad = deg_to_rad(current_yaw)
    var pitch_rad = deg_to_rad(current_pitch)

    # Calculate camera position using spherical coordinates
    var x = orbit_distance * cos(pitch_rad) * sin(yaw_rad)
    var y = orbit_distance * sin(pitch_rad)
    var z = orbit_distance * cos(pitch_rad) * cos(yaw_rad)

    # Set camera position relative to orbit center
    position = orbit_center + Vector3(x, y, z)

    # Look at the orbit center
    look_at(orbit_center, Vector3.UP)

func reset_camera():
    """Reset camera to default position"""
    orbit_center = Vector3(7, 0, 5)
    orbit_distance = 17.0
    current_yaw = 0.0
    current_pitch = 45.0
    _update_camera_transform()

