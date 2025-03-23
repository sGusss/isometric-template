@tool
class_name CameraController extends Node3D

# Camera configuration
@export var camera_distance: float = 10.0
@export var min_zoom: float = 5.0
@export var max_zoom: float = 20.0
@export var zoom_speed: float = 0.5
@export var pan_speed: float = 10.0
@export var edge_pan_margin: float = 20.0
@export var rotation_speed: float = 0.1
@export var rotation_angle: float = 45.0  # Degrees to rotate per step

# Camera control modes
@export var edge_panning_enabled: bool = true
@export var keyboard_panning_enabled: bool = true
@export var focus_object_enabled: bool = false

# Camera target
var _target_position: Vector3 = Vector3.ZERO
var _target_rotation: float = 0.0  # Degrees
var _target_zoom: float = 10.0
var _focus_object: Node3D = null

# Smoothing factors
@export var position_smoothing: float = 0.1
@export var rotation_smoothing: float = 0.1
@export var zoom_smoothing: float = 0.2

# Screen bounds
var _viewport_size: Vector2 = Vector2(1024, 600)  # Default size
var _bounds: Rect2 = Rect2(0, 0, 1, 1)  # Initialize with non-zero size

# Camera reference
var _camera: Camera3D

func _ready() -> void:
	# Find or create the camera
	_camera = find_child("Camera3D")
	if not _camera:
		_camera = Camera3D.new()
		_camera.name = "Camera3D"
		add_child(_camera)
	
	# Set initial values
	_target_zoom = camera_distance
	_camera.position = Vector3(0, camera_distance, 0)
	_camera.rotation = Vector3(-PI/2, 0, 0)  # Looking down by default
	
	# Update viewport size for edge panning
	var viewport = get_viewport()
	if viewport:
		_viewport_size = viewport.get_visible_rect().size
	
	# Initialize bounds with safe values
	_update_bounds()

func _update_bounds() -> void:
	# Ensure edge_pan_margin is reasonable
	var safe_margin = min(edge_pan_margin, min(_viewport_size.x, _viewport_size.y) / 4)
	
	# Calculate width and height with maximum safety
	var width = max(1.0, _viewport_size.x - safe_margin * 2)
	var height = max(1.0, _viewport_size.y - safe_margin * 2)
	
	# Create the bounds rectangle
	_bounds = Rect2(safe_margin, safe_margin, width, height)

func _process(delta: float) -> void:
	# Update viewport size if changed
	var viewport = get_viewport()
	if viewport:
		var current_viewport_size = viewport.get_visible_rect().size
		if current_viewport_size != _viewport_size and current_viewport_size.x > 0 and current_viewport_size.y > 0:
			_viewport_size = current_viewport_size
			_update_bounds()
	
	# Handle edge panning if enabled
	if edge_panning_enabled:
		handle_edge_panning(delta)
	
	# Handle keyboard panning if enabled
	if keyboard_panning_enabled:
		handle_keyboard_panning(delta)
	
	# Follow focus object if set
	if focus_object_enabled and _focus_object:
		_target_position = _focus_object.global_position
	
	# Smooth camera movement
	smooth_camera_movement()

func _input(event: InputEvent) -> void:
	# Handle mouse wheel for zooming
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
			
	# Handle keyboard rotation
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			rotate_camera_left()
		elif event.keycode == KEY_E:
			rotate_camera_right()

# Handle panning when mouse is at screen edges
func handle_edge_panning(delta: float) -> void:
	var mouse_pos = Vector2.ZERO
	var viewport = get_viewport()
	if viewport:
		mouse_pos = viewport.get_mouse_position()
	
	# Skip if mouse is within bounds
	if _bounds.has_point(mouse_pos):
		return
		
	var pan_direction = Vector3.ZERO
	
	# Determine direction based on which edge the mouse is near
	if mouse_pos.x < _bounds.position.x:  # Left edge
		pan_direction.x -= 1
	elif mouse_pos.x > _bounds.position.x + _bounds.size.x:  # Right edge
		pan_direction.x += 1
		
	if mouse_pos.y < _bounds.position.y:  # Top edge
		pan_direction.z -= 1
	elif mouse_pos.y > _bounds.position.y + _bounds.size.y:  # Bottom edge
		pan_direction.z += 1
	
	# Apply rotation to panning direction
	pan_direction = pan_direction.rotated(Vector3.UP, deg_to_rad(_target_rotation))
	
	# Update target position
	_target_position += pan_direction * pan_speed * delta

# Handle keyboard-based panning
func handle_keyboard_panning(delta: float) -> void:
	var input_dir = Vector3.ZERO
	
	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.z += 1
	if Input.is_action_pressed("ui_up"):
		input_dir.z -= 1
	
	# Apply rotation to input direction
	input_dir = input_dir.rotated(Vector3.UP, deg_to_rad(_target_rotation))
	
	# Update target position
	_target_position += input_dir * pan_speed * delta

# Smoothly update camera position and rotation
func smooth_camera_movement() -> void:
	# Smooth position
	global_position = global_position.lerp(_target_position, position_smoothing)
	
	# Smooth rotation around Y axis (keeping camera looking down)
	var current_rotation = rad_to_deg(rotation.y)
	var shortest_angle = fmod((fmod(_target_rotation - current_rotation, 360) + 540), 360) - 180
	rotation.y = rotation.y + deg_to_rad(shortest_angle * rotation_smoothing)
	
	# Smooth zoom (camera height)
	_camera.position.y = lerp(_camera.position.y, _target_zoom, zoom_smoothing)

# Set camera bounds
func set_bounds(min_x: float, min_z: float, max_x: float, max_z: float) -> void:
	# Ensure positive width and height
	var width = max(1.0, max_x - min_x)
	var height = max(1.0, max_z - min_z)
	_bounds = Rect2(min_x, min_z, width, height)

# Zoom controls
func zoom_in() -> void:
	_target_zoom = max(_target_zoom - zoom_speed, min_zoom)
	
func zoom_out() -> void:
	_target_zoom = min(_target_zoom + zoom_speed, max_zoom)

# Rotation controls
func rotate_camera_left() -> void:
	_target_rotation = fmod(_target_rotation - rotation_angle, 360)
	
func rotate_camera_right() -> void:
	_target_rotation = fmod(_target_rotation + rotation_angle, 360)

# Set camera focus on an object
func set_focus(object: Node3D) -> void:
	_focus_object = object
	focus_object_enabled = object != null
	
	if object:
		_target_position = object.global_position

# Move camera to a specific world position
func move_to_position(target_pos: Vector3) -> void:
	_target_position = target_pos 