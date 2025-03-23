@tool
class_name DataParser extends Node

# Signals - prefixed with underscore to indicate they're defined for future use
signal _parsing_complete(map_data: Dictionary)
signal _parsing_error(error_message: String)

# Parse a JSON file and return map data
func parse_json_file(file_path: String) -> Dictionary:
	# Check if the file exists
	if not FileAccess.file_exists(file_path):
		push_error("File not found: " + file_path)
		return {}
	
	# Open the file
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	# Parse JSON
	var json = JSON.new()
	var error = json.parse(content)
	
	if error != OK:
		var error_message = "JSON Parse Error at line %d: %s" % [json.get_error_line(), json.get_error_message()]
		push_error(error_message)
		return {}
	
	var map_data = json.get_data()
	
	# Validate map data
	if not validate_map_data(map_data):
		push_error("Invalid map data format")
		return {}
	
	# Emit signal (commented out until used)
	# emit_signal("_parsing_complete", map_data)
	return map_data

# Parse a CSV file and return map data
func parse_csv_file(file_path: String, has_header: bool = true) -> Dictionary:
	# Check if the file exists
	if not FileAccess.file_exists(file_path):
		push_error("File not found: " + file_path)
		return {}
	
	# Open the file
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	var rows = []
	var _header = []  # Prefixed with underscore to indicate unused variable
	var line_count = 0
	
	# Read the file line by line
	while not file.eof_reached():
		var line = file.get_line()
		if line.is_empty():
			continue
			
		var values = line.split(",", false)
		
		if line_count == 0 and has_header:
			_header = values
		else:
			rows.append(values)
		
		line_count += 1
	
	file.close()
	
	# Convert CSV data to map data format
	var map_data = {}
	map_data["tiles"] = []
	
	var width = 0
	var height = len(rows)
	
	for y in range(rows.size()):
		var row = rows[y]
		width = max(width, row.size())
		
		for x in range(row.size()):
			var tile_type = row[x].strip_edges()
			
			# Skip empty cells
			if tile_type.is_empty():
				continue
				
			# Create a basic tile
			var tile = {
				"position": {"x": x, "y": y},
				"type": tile_type,
				"height": 0.0
			}
			
			map_data["tiles"].append(tile)
	
	# Add dimensions
	map_data["dimensions"] = {
		"width": width,
		"height": height
	}
	
	# Emit signal (commented out until used)
	# emit_signal("_parsing_complete", map_data)
	return map_data

# Validate that map data has the correct format
func validate_map_data(map_data: Dictionary) -> bool:
	# Check if it has a tiles array
	if not "tiles" in map_data or not map_data["tiles"] is Array:
		return false
	
	# Check that each tile has required properties
	for tile in map_data["tiles"]:
		if not tile is Dictionary:
			return false
		
		# Must have a type
		if not "type" in tile:
			return false
			
		# If position is specified, it should have x and y
		if "position" in tile:
			if not "x" in tile.position or not "y" in tile.position:
				return false
	
	return true

# Save map data to a JSON file
func save_to_json(map_data: Dictionary, file_path: String) -> bool:
	# Convert map_data to JSON string
	var json_string = JSON.stringify(map_data, "  ")
	
	# Open file for writing
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: " + file_path)
		return false
	
	# Write to file
	file.store_string(json_string)
	file.close()
	
	return true

# Generate an empty map with default tiles
func generate_empty_map(width: int, height: int, default_tile_type: String = "grass") -> Dictionary:
	var map_data = {
		"dimensions": {
			"width": width,
			"height": height
		},
		"tiles": []
	}
	
	for y in range(height):
		for x in range(width):
			var tile = {
				"position": {"x": x, "y": y},
				"type": default_tile_type,
				"height": 0.0,
				"resources": [],
				"entities": [],
				"navigation": {}
			}
			
			map_data["tiles"].append(tile)
	
	return map_data

# Generate a simple demo map
func generate_demo_map() -> Dictionary:
	var map_data = {
		"dimensions": {
			"width": 10,
			"height": 10
		},
		"tiles": []
	}
	
	# Generate a mix of tile types
	for y in range(10):
		for x in range(10):
			var tile_type = "grass"
			var height = 0.0
			var resources = []
			var entities = []
			
			# Add some water along one edge
			if x < 2:
				tile_type = "water"
			
			# Add some sand as a transition from water to grass
			elif x == 2:
				tile_type = "sand"
			
			# Add some mountains (elevated terrain)
			elif x > 7 and y > 7:
				height = 2.0
			elif x > 6 and y > 6:
				height = 1.0
				
			# Add resources to some tiles
			if tile_type == "grass" and randf() < 0.2:
				resources.append("wood")
			
			# Add an entity to a specific tile
			if x == 5 and y == 5:
				entities.append("villster")
			
			# Create the tile data
			var tile = {
				"position": {"x": x, "y": y},
				"type": tile_type,
				"height": height,
				"resources": resources,
				"entities": entities
			}
			
			# Add navigation data for water tiles
			if tile_type == "water":
				tile["navigation"] = {"boat": true, "foot": false}
			else:
				tile["navigation"] = {"foot": true, "boat": false}
			
			map_data["tiles"].append(tile)
	
	return map_data 