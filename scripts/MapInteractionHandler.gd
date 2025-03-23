@tool
class_name MapInteractionHandler extends Node

# Signals - prefixed with underscore to indicate they're defined for future use
signal _tile_clicked(tile_data: TileData)
signal _tile_hovered(tile_data: TileData)

# References
var _grid_manager: GridManager
var _camera: Camera3D
var _dev_tools: DeveloperTools

# Interaction state
var _last_hovered_grid_pos: Vector2i = Vector2i(-1, -1)
var _mouse_position: Vector2 = Vector2.ZERO
var _interaction_enabled: bool = true

func _ready() -> void:
	# Find the required references
	_grid_manager = get_node("/root/Main/GridManager") if has_node("/root/Main/GridManager") else null
	_dev_tools = get_node("/root/Main/DeveloperTools") if has_node("/root/Main/DeveloperTools") else null
	
	if not _grid_manager:
		push_error("MapInteractionHandler: GridManager not found")
		return
	
	# Connect signals (commented out since signals are not used yet)
	# if _grid_manager:
	#     _grid_manager.connect("_tile_selected", _on_tile_selected)

func _process(_delta: float) -> void:
	if not _interaction_enabled or not _grid_manager:
		return
	
	# Get the current camera
	if not _camera or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d() if get_viewport() else null
		if not _camera:
			return
	
	# Cast a ray from mouse position
	var ray_result = cast_ray_from_mouse(_mouse_position)
	
	if ray_result:
		var hit_position = ray_result.position
		var grid_pos = _grid_manager.world_to_grid(hit_position)
		
		# Handle hover
		if grid_pos != _last_hovered_grid_pos:
			_last_hovered_grid_pos = grid_pos
			handle_tile_hover(grid_pos)

func _input(event: InputEvent) -> void:
	if not _interaction_enabled or not _grid_manager:
		return
	
	if event is InputEventMouseMotion:
		_mouse_position = event.position
	
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_mouse_click(_mouse_position)

# Cast a ray from mouse position to 3D world
func cast_ray_from_mouse(mouse_pos: Vector2) -> Dictionary:
	if not _camera:
		return {}
	
	# Get ray origin and direction from mouse position
	var ray_origin = _camera.project_ray_origin(mouse_pos)
	var ray_direction = _camera.project_ray_normal(mouse_pos)
	
	# Perform ray cast
	var viewport = get_viewport()
	if not viewport:
		return {}
		
	var space_state = viewport.get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = ray_origin
	ray_query.to = ray_origin + ray_direction * 1000  # Long enough to hit the ground
	ray_query.collision_mask = 1  # Use the appropriate collision layer
	
	var ray_result = space_state.intersect_ray(ray_query)
	
	# If we don't hit a collider, try to find a plane intersection
	if ray_result.is_empty():
		# Define a ground plane at y=0
		var plane = Plane(Vector3.UP, 0)
		var intersection = plane.intersects_ray(ray_origin, ray_direction)
		
		if intersection:
			return {
				"position": intersection,
				"normal": Vector3.UP
			}
	
	return ray_result

# Handle mouse click on the map
func handle_mouse_click(mouse_pos: Vector2) -> void:
	var ray_result = cast_ray_from_mouse(mouse_pos)
	
	if ray_result and "position" in ray_result:
		var hit_position = ray_result.position
		var grid_pos = _grid_manager.world_to_grid(hit_position)
		
		# Select the tile at the grid position
		_grid_manager.select_tile_at_position(hit_position)
		
		# Get tile data
		var tile_data = _grid_manager.get_tile(grid_pos)
		if tile_data:
			# Signal emission (commented out until used)
			# emit_signal("_tile_clicked", tile_data)
			
			# Show tile info in developer tools if available
			if _dev_tools:
				_dev_tools.show_tile_info(tile_data)

# Handle mouse hover over a tile
func handle_tile_hover(grid_pos: Vector2i) -> void:
	# Clear highlighted state on all tiles
	for tile in _grid_manager._tiles.values():
		tile.set("highlighted", false)
	
	# Highlight this tile
	var tile_data = _grid_manager.get_tile(grid_pos)
	if tile_data:
		tile_data.set("highlighted", true)
		# Signal emission (commented out until used)
		# emit_signal("_tile_hovered", tile_data)
		
		# Update the tile's visual
		if _grid_manager._tile_factory:
			_grid_manager._tile_factory.update_tile_visual(tile_data)

# Callback when a tile is selected (commented out since not used yet)
# func _on_tile_selected(tile_data: TileData) -> void:
#     if tile_data:
#         emit_signal("_tile_clicked", tile_data)

# Enable/disable interaction
func set_interaction_enabled(enabled: bool) -> void:
	_interaction_enabled = enabled 
