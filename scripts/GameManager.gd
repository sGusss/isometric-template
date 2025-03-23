@tool
class_name GameManager extends Node

# References to other nodes
var _grid_manager: GridManager
var _data_parser: DataParser
var _camera_controller: CameraController
var _dev_tools: DeveloperTools
var _map_interaction: MapInteractionHandler

# Configuration
@export var demo_map_path: String = "res://data/demo_map.json"
@export var load_map_on_ready: bool = true

func _ready() -> void:
	# Get references to required nodes
	_grid_manager = get_node_or_null("/root/Main/GridManager")
	_data_parser = get_node_or_null("/root/Main/DataParser")
	_camera_controller = get_node_or_null("/root/Main/CameraController") 
	_dev_tools = get_node_or_null("/root/Main/DeveloperTools")
	_map_interaction = get_node_or_null("/root/Main/MapInteractionHandler")
	
	if not _grid_manager or not _data_parser:
		push_error("GameManager: Required nodes not found")
		return
	
	# Connect signals
	if _data_parser:
		_data_parser.connect("parsing_complete", _on_parsing_complete)
		_data_parser.connect("parsing_error", _on_parsing_error)
	
	if _map_interaction:
		_map_interaction.connect("tile_clicked", _on_tile_clicked)
	
	# Load the demo map if requested
	if load_map_on_ready:
		load_demo_map()

# Load the demo map
func load_demo_map() -> void:
	if FileAccess.file_exists(demo_map_path):
		print("Loading demo map from: ", demo_map_path)
		var map_data = _data_parser.parse_json_file(demo_map_path)
		if not map_data.is_empty():
			_grid_manager.create_map(map_data)
	else:
		# If demo map doesn't exist, generate one
		print("Demo map not found, generating a new one")
		var map_data = _data_parser.generate_demo_map()
		_data_parser.save_to_json(map_data, demo_map_path)
		_grid_manager.create_map(map_data)

# Load a map from a file path
func load_map(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		var extension = file_path.get_extension().to_lower()
		var map_data = {}
		
		if extension == "json":
			map_data = _data_parser.parse_json_file(file_path)
		elif extension == "csv":
			map_data = _data_parser.parse_csv_file(file_path)
		else:
			push_error("GameManager: Unsupported file format: " + extension)
			return
			
		if not map_data.is_empty():
			_grid_manager.create_map(map_data)
	else:
		push_error("GameManager: File not found: " + file_path)

# Save the current map to a file
func save_map(file_path: String) -> bool:
	var map_data = {}
	var tiles = []
	
	# Get all tile data
	for grid_pos in _grid_manager._tiles.keys():
		var tile = _grid_manager._tiles[grid_pos]
		tiles.append(tile.to_dict())
	
	map_data["dimensions"] = {
		"width": _grid_manager.map_width,
		"height": _grid_manager.map_height
	}
	map_data["tiles"] = tiles
	
	return _data_parser.save_to_json(map_data, file_path)

# Create a new empty map
func create_new_map(width: int, height: int, default_tile_type: String = "grass") -> void:
	var map_data = _data_parser.generate_empty_map(width, height, default_tile_type)
	_grid_manager.create_map(map_data)
	
	# Move camera to center of map
	if _camera_controller:
		var center_pos = Vector3(width / 2.0, 0, height / 2.0)
		_camera_controller.move_to_position(center_pos)

# Signal callbacks
func _on_parsing_complete(map_data: Dictionary) -> void:
	print("Map parsing complete, dimensions: ", map_data.get("dimensions", {"width": 0, "height": 0}))

func _on_parsing_error(error_message: String) -> void:
	push_error("GameManager: Parsing error: " + error_message)

func _on_tile_clicked(tile_data: TileData) -> void:
	# Example of handling tile click
	print("Tile clicked: ", tile_data.type, " at position ", tile_data.grid_position)
	
	# You could implement additional logic here, like:
	# - Focus camera on the clicked tile
	# - Show a UI with tile details
	# - Trigger game events based on tile type 
