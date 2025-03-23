@tool
class_name DeveloperTools extends Node

# Signal prefixed with underscore to indicate it's defined for future use
signal _toggle_debug_mode(enabled: bool)

# Debug visualization options
@export var show_grid_coordinates: bool = false
@export var show_grid_overlay: bool = false
@export var show_performance_stats: bool = false

# References to debug UI elements
var _debug_label: Label
var _grid_overlay: Node3D
var _coordinate_labels: Dictionary = {}  # Key: Vector2i grid pos, Value: Label3D
var _grid_manager: GridManager

# Performance tracking
var _fps_history: Array = []
var _draw_calls_history: Array = []
var _update_interval: float = 0.5
var _time_since_update: float = 0.0

func _ready() -> void:
	# Find grid manager reference
	_grid_manager = get_node_or_null("/root/Main/GridManager")
	
	# Create debug UI
	_setup_debug_ui()
	
	# Connect to map loaded signal if grid manager exists (commented out until used)
	# if _grid_manager:
	#     _grid_manager.connect("_map_loaded", _on_map_loaded)

func _process(delta: float) -> void:
	_time_since_update += delta
	
	# Update performance stats
	if show_performance_stats and _time_since_update >= _update_interval:
		_time_since_update = 0.0
		_update_performance_stats()
	
	# Update debug label
	if _debug_label:
		_debug_label.visible = show_performance_stats
		
	# Update grid overlay
	if _grid_overlay:
		_grid_overlay.visible = show_grid_overlay
	
	# Update coordinate labels
	for label in _coordinate_labels.values():
		label.visible = show_grid_coordinates

func _input(event: InputEvent) -> void:
	# Toggle debug mode with F3
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		set_debug_mode(!show_performance_stats)
	
	# Toggle grid overlay with F4
	if event is InputEventKey and event.pressed and event.keycode == KEY_F4:
		toggle_grid_overlay(!show_grid_overlay)
	
	# Toggle coordinate display with F5
	if event is InputEventKey and event.pressed and event.keycode == KEY_F5:
		toggle_coordinate_display(!show_grid_coordinates)

# Set up the debug UI elements
func _setup_debug_ui() -> void:
	# Create a CanvasLayer for UI
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "DebugLayer"
	canvas_layer.layer = 100  # High layer to render on top
	add_child(canvas_layer)
	
	# Create a Label for performance stats
	_debug_label = Label.new()
	_debug_label.name = "DebugLabel"
	_debug_label.position = Vector2(10, 10)
	_debug_label.text = "FPS: 0\nDraw Calls: 0"
	_debug_label.visible = show_performance_stats
	canvas_layer.add_child(_debug_label)
	
	# Create grid overlay
	_grid_overlay = Node3D.new()
	_grid_overlay.name = "GridOverlay"
	_grid_overlay.visible = show_grid_overlay
	add_child(_grid_overlay)

# Update the performance statistics
func _update_performance_stats() -> void:
	var fps = Engine.get_frames_per_second()
	_fps_history.append(fps)
	
	# Keep history limited to 10 entries
	if _fps_history.size() > 10:
		_fps_history.pop_front()
	
	# Calculate average FPS
	var avg_fps = 0.0
	for f in _fps_history:
		avg_fps += f
	avg_fps /= _fps_history.size()
	
	# Get draw calls from RenderingServer
	var draw_calls = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	_draw_calls_history.append(draw_calls)
	
	if _draw_calls_history.size() > 10:
		_draw_calls_history.pop_front()
	
	var avg_draw_calls = 0
	for dc in _draw_calls_history:
		avg_draw_calls += dc
	avg_draw_calls /= _draw_calls_history.size()
	
	# Update debug label
	if _debug_label:
		_debug_label.text = "FPS: %.1f\nDraw Calls: %d\nMemory: %.1f MB" % [
			avg_fps,
			avg_draw_calls,
			OS.get_static_memory_usage() / 1048576.0
		]

# Create the grid overlay for the current map
func _create_grid_overlay(map_size: Vector2i) -> void:
	# Clear existing overlay
	for child in _grid_overlay.get_children():
		child.queue_free()
	
	# Create grid lines
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1, 0.3)
	material.flags_transparent = true
	
	# Create horizontal and vertical lines
	for x in range(map_size.x + 1):
		for y in range(map_size.y + 1):
			if x < map_size.x:
				_add_grid_line(Vector3(x, 0, y), Vector3(x + 1, 0, y), material)
			if y < map_size.y:
				_add_grid_line(Vector3(x, 0, y), Vector3(x, 0, y + 1), material)

# Add a line to the grid overlay
func _add_grid_line(start: Vector3, end: Vector3, material: Material) -> void:
	var immediate_mesh = ImmediateMesh.new()
	var mesh_instance = MeshInstance3D.new()
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(start)
	immediate_mesh.surface_add_vertex(end)
	immediate_mesh.surface_end()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.material_override = material
	
	_grid_overlay.add_child(mesh_instance)

# Create coordinate labels for each tile
func _create_coordinate_labels(map_size: Vector2i) -> void:
	# Clear existing labels
	for label in _coordinate_labels.values():
		label.queue_free()
	_coordinate_labels.clear()
	
	# Create new labels
	for x in range(map_size.x):
		for y in range(map_size.y):
			var grid_pos = Vector2i(x, y)
			var world_pos = _grid_manager.grid_to_world(grid_pos)
			
			var label = Label3D.new()
			label.text = "(%d,%d)" % [x, y]
			label.position = world_pos + Vector3(0, 1, 0)  # Slightly above the tile
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.font_size = 8
			label.visible = show_grid_coordinates
			
			_grid_overlay.add_child(label)
			_coordinate_labels[grid_pos] = label

# Called when the map is loaded (commented out until used)
func _on_map_loaded(map_size: Vector2i) -> void:
	_create_grid_overlay(map_size)
	_create_coordinate_labels(map_size)

# Toggle debug mode
func set_debug_mode(enabled: bool) -> void:
	show_performance_stats = enabled
	# Signal emission commented out until used
	# emit_signal("_toggle_debug_mode", enabled)

# Toggle grid overlay
func toggle_grid_overlay(enabled: bool) -> void:
	show_grid_overlay = enabled

# Toggle coordinate display
func toggle_coordinate_display(enabled: bool) -> void:
	show_grid_coordinates = enabled

# Show a tile's info in a popup
func show_tile_info(tile_data: TileData) -> void:
	if not tile_data:
		return
	
	# Create info text
	var tile_type = tile_data.get("type")
	var info = "Tile: %s\n" % (tile_type.capitalize() if tile_type != null else "Unknown")
	
	var grid_pos = tile_data.get("grid_position")
	if grid_pos != null:
		info += "Position: (%d, %d)\n" % [grid_pos.x, grid_pos.y]
	else:
		info += "Position: Unknown\n"
	
	var height = tile_data.get("height")
	info += "Height: %.1f\n" % (height if height != null else 0.0)
	
	var resources = tile_data.get("resources")
	if resources != null and not resources.is_empty():
		info += "Resources: %s\n" % ", ".join(resources)
	
	var entities = tile_data.get("entities")
	if entities != null and not entities.is_empty():
		info += "Entities: %s\n" % ", ".join(entities)
	
	# Show in UI
	if _debug_label:
		_debug_label.text = info
		_debug_label.visible = true 
