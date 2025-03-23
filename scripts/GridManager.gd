@tool
class_name GridManager extends Node

# Signals - Renamed with underscore to indicate they're defined for future use
signal _tile_selected(tile_data: TileData)
signal _map_loaded(map_size: Vector2i)

# Grid configuration
@export var tile_width: float = 64.0
@export var tile_height: float = 32.0
@export var tile_depth: float = 10.0  # Height per level

# Map dimensions
var map_width: int = 0
var map_height: int = 0

# Store all tile data
var _tiles: Dictionary = {}  # Key: String representation of grid position, Value: TileData

# Reference to scene instances
var _tile_scene: PackedScene
var _tile_factory: TileFactory

func _ready() -> void:
	_tile_factory = $TileFactory if has_node("TileFactory") else null
	
	# Load the tile scene
	_tile_scene = load("res://scenes/tile.tscn")
	if _tile_scene == null:
		push_error("Failed to load tile scene")

# Convert grid position to isometric world position
func grid_to_world(grid_pos: Vector2i) -> Vector3:
	var world_x = (grid_pos.x - grid_pos.y) * (tile_width / 2.0)
	var world_z = (grid_pos.x + grid_pos.y) * (tile_height / 2.0)
	
	var tile_height_value = 0.0
	var tile_data = get_tile(grid_pos)
	if tile_data:
		# Use get() method to safely access the height property
		var height_property = tile_data.get("height")
		if height_property != null:
			tile_height_value = height_property * tile_depth
	
	return Vector3(world_x, tile_height_value, world_z)

# Convert world position to grid position
func world_to_grid(world_pos: Vector3) -> Vector2i:
	# Solve the isometric projection equations
	var grid_x = int(round((world_pos.x / (tile_width / 2.0) + world_pos.z / (tile_height / 2.0)) / 2))
	var grid_y = int(round((world_pos.z / (tile_height / 2.0) - world_pos.x / (tile_width / 2.0)) / 2))
	
	return Vector2i(grid_x, grid_y)

# Check if a grid position is valid within the map bounds
func is_valid_grid_position(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < map_width and grid_pos.y >= 0 and grid_pos.y < map_height

# Get a string key from grid position for dictionary lookup
func _grid_pos_to_key(grid_pos: Vector2i) -> String:
	return "%d,%d" % [grid_pos.x, grid_pos.y]

# Parse a grid position key back to Vector2i
func _key_to_grid_pos(key: String) -> Vector2i:
	var parts = key.split(",")
	if parts.size() == 2:
		return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i.ZERO

# Add a tile to the grid
func add_tile(tile_data: TileData) -> void:
	# Get grid position via get() method to avoid direct property access
	var tile_grid_pos = Vector2i.ZERO
	
	# Use a safe approach to get the grid_position
	if tile_data.get("grid_position") != null:
		var pos = tile_data.get("grid_position")
		tile_grid_pos = Vector2i(pos.x, pos.y)
	
	if not is_valid_grid_position(tile_grid_pos):
		return
	
	# Store using string key for reliability
	var grid_key = _grid_pos_to_key(tile_grid_pos)
	_tiles[grid_key] = tile_data
	
	# Update world position
	var world_pos = grid_to_world(tile_grid_pos)
	tile_data.set("world_position", world_pos)
	
	# Instantiate visual representation if tile factory exists
	if _tile_factory:
		_tile_factory.create_tile_visual(tile_data)

# Get tile data at grid position
func get_tile(grid_pos: Vector2i) -> TileData:
	var grid_key = _grid_pos_to_key(grid_pos)
	return _tiles.get(grid_key)

# Set a specific property on a tile
func set_tile_property(grid_pos: Vector2i, property: String, value) -> void:
	var tile = get_tile(grid_pos)
	if tile and property in tile:
		tile.set(property, value)
		
		# Update visual if needed
		if _tile_factory:
			_tile_factory.update_tile_visual(tile)

# Load map from a data structure
func create_map(map_data: Dictionary) -> void:
	# Clear existing map
	clear_map()
	
	if "dimensions" in map_data:
		map_width = map_data.dimensions.width
		map_height = map_data.dimensions.height
	else:
		# Try to determine dimensions from tiles array
		var max_x = 0
		var max_y = 0
		
		for tile in map_data.get("tiles", []):
			if "position" in tile:
				max_x = max(max_x, tile.position.x + 1)
				max_y = max(max_y, tile.position.y + 1)
		
		map_width = max(map_width, max_x)
		map_height = max(max_y, map_height)
	
	# Create tiles from data
	for tile_info in map_data.get("tiles", []):
		var tile_grid_pos = Vector2i.ZERO
		
		if "position" in tile_info:
			tile_grid_pos = Vector2i(tile_info.position.x, tile_info.position.y)
		elif "x" in tile_info and "y" in tile_info:
			tile_grid_pos = Vector2i(tile_info.x, tile_info.y)
		
		# Create tile data object
		var tile_data = TileData.new()
		
		# Manually set properties from tile_info
		for key in tile_info:
			if key != "position" and key in tile_data:  # Skip position, we'll handle it separately
				tile_data.set(key, tile_info[key])
		
		# Set position properties separately to ensure correct types
		tile_data.set("grid_position", tile_grid_pos)
		tile_data.set("world_position", grid_to_world(tile_grid_pos))
		
		# Add tile to grid
		add_tile(tile_data)
	
	# Emit signal with map size - commented for now until used
	# emit_signal("_map_loaded", Vector2i(map_width, map_height))

# Clear the current map
func clear_map() -> void:
	_tiles.clear()
	
	if _tile_factory:
		_tile_factory.clear_tiles()
	
	map_width = 0
	map_height = 0

# Handle tile selection
func select_tile_at_position(world_pos: Vector3) -> void:
	var grid_pos = world_to_grid(world_pos)
	var tile = get_tile(grid_pos)
	
	if tile:
		# Deselect all tiles
		for key in _tiles.keys():
			var t = _tiles[key]
			t.set("selected", false)
			
		# Select this tile
		tile.set("selected", true)
		
		# Emit signal with selected tile - commented for now until used
		# emit_signal("_tile_selected", tile)
		
		# Update visuals
		if _tile_factory:
			_tile_factory.update_all_visuals()

# Get neighbors of a tile
func get_neighbors(grid_pos: Vector2i) -> Array:
	var neighbors = []
	var directions = [
		Vector2i(1, 0),   # East
		Vector2i(1, 1),   # Southeast
		Vector2i(0, 1),   # South
		Vector2i(-1, 1),  # Southwest
		Vector2i(-1, 0),  # West
		Vector2i(-1, -1), # Northwest
		Vector2i(0, -1),  # North
		Vector2i(1, -1)   # Northeast
	]
	
	for dir in directions:
		var neighbor_pos = grid_pos + dir
		if is_valid_grid_position(neighbor_pos):
			var neighbor = get_tile(neighbor_pos)
			if neighbor:
				neighbors.append(neighbor)
	
	return neighbors 
