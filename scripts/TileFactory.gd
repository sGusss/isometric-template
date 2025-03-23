@tool
class_name TileFactory extends Node3D

# Tile visual properties
@export var base_tile_width: float = 64.0
@export var base_tile_height: float = 32.0
@export var height_scale: float = 10.0

# Tile visual resources
@export var default_material: Material
@export var highlight_material: Material
@export var selection_material: Material

# Containers for organizing tiles
var _tile_container: Node3D
var _tile_instances: Dictionary = {}  # Key: String representation of grid pos, Value: Node3D instance

# Tile type definitions and associated materials/meshes
var _tile_definitions: Dictionary = {}

# Helper function to get string key from grid position
func _grid_pos_to_key(grid_pos: Vector2i) -> String:
	return "%d,%d" % [grid_pos.x, grid_pos.y]

func _ready() -> void:
	# Create a container node for all tile instances
	_tile_container = Node3D.new()
	_tile_container.name = "TileContainer"
	add_child(_tile_container)
	
	# Create default materials if none are set
	if default_material == null:
		default_material = StandardMaterial3D.new()
		default_material.albedo_color = Color(0.8, 0.8, 0.8)
		
	if highlight_material == null:
		highlight_material = StandardMaterial3D.new()
		highlight_material.albedo_color = Color(1.0, 1.0, 0.6)
		highlight_material.emission_enabled = true
		highlight_material.emission = Color(0.5, 0.5, 0.3)
		
	if selection_material == null:
		selection_material = StandardMaterial3D.new()
		selection_material.albedo_color = Color(0.6, 1.0, 0.6)
		selection_material.emission_enabled = true
		selection_material.emission = Color(0.3, 0.5, 0.3)
	
	# Define tile types with default materials
	_setup_tile_definitions()

# Setup tile definitions with default materials if resources don't exist
func _setup_tile_definitions() -> void:
	var grass_mat = StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.2, 0.8, 0.2)
	
	var water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.2, 0.4, 0.8)
	water_mat.metallic = 0.5
	water_mat.roughness = 0.1
	
	var sand_mat = StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.9, 0.8, 0.5)
	
	_tile_definitions = {
		"grass": {
			"material": grass_mat,
			"mesh": null
		},
		"water": {
			"material": water_mat,
			"mesh": null
		},
		"sand": {
			"material": sand_mat,
			"mesh": null
		}
	}

# Create a visual representation of a tile
func create_tile_visual(tile_data: TileData) -> void:
	if tile_data == null:
		return
		
	# Get grid position safely using get() method
	var grid_pos = Vector2i.ZERO
	if tile_data.get("grid_position") != null:
		grid_pos = tile_data.get("grid_position")
	
	# Create a key for the tile instance dictionary
	var grid_key = _grid_pos_to_key(grid_pos)
	
	# Check if a tile instance already exists
	if _tile_instances.has(grid_key):
		# Update existing instance
		update_tile_visual(tile_data)
		return
	
	# Create a new tile instance
	var tile_instance = Node3D.new()
	tile_instance.name = "Tile_" + str(grid_pos.x) + "_" + str(grid_pos.y)
	
	# Position the tile in world space - get world_position safely
	var world_pos = Vector3.ZERO
	if tile_data.get("world_position") != null:
		world_pos = tile_data.get("world_position")
	tile_instance.position = world_pos
	
	# Add mesh instance for the base tile
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TileMesh"
	
	# Try to get type-specific mesh and material, or create default
	var mesh = null
	var material = null
	
	var tile_type = tile_data.get("type") if tile_data.get("type") != null else "empty"
	
	if tile_type in _tile_definitions:
		var definition = _tile_definitions[tile_type]
		mesh = definition.mesh
		material = definition.material
	
	# Create default mesh if none exists
	if mesh == null:
		mesh = create_isometric_tile_mesh(base_tile_width, base_tile_height)
	
	# Use default material if none exists
	if material == null:
		material = default_material
	
	# Apply mesh and material
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material.duplicate()
	
	# Apply visual states
	var selected = tile_data.get("selected") if tile_data.get("selected") != null else false
	var highlighted = tile_data.get("highlighted") if tile_data.get("highlighted") != null else false
	
	if selected:
		mesh_instance.material_override = selection_material.duplicate()
	elif highlighted:
		mesh_instance.material_override = highlight_material.duplicate()
	
	# Add to scene and store reference
	tile_instance.add_child(mesh_instance)
	_tile_container.add_child(tile_instance)
	_tile_instances[grid_key] = tile_instance
	
	# Create height blocks if tile has height
	var height = tile_data.get("height") if tile_data.get("height") != null else 0.0
	if height > 0:
		create_height_blocks(tile_instance, height)
	
	# Add resource indicators if any
	var resources = tile_data.get("resources") if tile_data.get("resources") != null else []
	for resource in resources:
		add_resource_indicator(tile_instance, resource)
	
	# Add entity visuals if any
	var entities = tile_data.get("entities") if tile_data.get("entities") != null else []
	for entity in entities:
		add_entity_visual(tile_instance, entity)

# Update an existing tile's visual representation
func update_tile_visual(tile_data: TileData) -> void:
	# Get grid position safely
	var grid_pos = Vector2i.ZERO
	if tile_data.get("grid_position") != null:
		grid_pos = tile_data.get("grid_position")
	
	var grid_key = _grid_pos_to_key(grid_pos)
	
	if not _tile_instances.has(grid_key):
		create_tile_visual(tile_data)
		return
	
	var tile_instance = _tile_instances[grid_key]
	
	# Update position (in case height changed)
	var world_pos = Vector3.ZERO
	if tile_data.get("world_position") != null:
		world_pos = tile_data.get("world_position")
	tile_instance.position = world_pos
	
	# Update material based on selection/highlight state
	var mesh_instance = tile_instance.get_node("TileMesh") as MeshInstance3D
	if mesh_instance:
		var selected = tile_data.get("selected") if tile_data.get("selected") != null else false
		var highlighted = tile_data.get("highlighted") if tile_data.get("highlighted") != null else false
		var tile_type = tile_data.get("type") if tile_data.get("type") != null else "empty"
		
		if selected:
			mesh_instance.material_override = selection_material.duplicate()
		elif highlighted:
			mesh_instance.material_override = highlight_material.duplicate()
		else:
			# Reset to type-specific material
			var material = default_material
			if tile_type in _tile_definitions and _tile_definitions[tile_type].material:
				material = _tile_definitions[tile_type].material
			mesh_instance.material_override = material.duplicate()

# Create height blocks for elevated tiles
func create_height_blocks(tile_instance: Node3D, height: float) -> void:
	# Remove existing height blocks
	for child in tile_instance.get_children():
		if child.name.begins_with("HeightBlock"):
			child.queue_free()
	
	# For simplicity, we'll create a single block representing the height
	var height_mesh = BoxMesh.new()
	height_mesh.size = Vector3(base_tile_width, height * height_scale, base_tile_height)
	
	var height_instance = MeshInstance3D.new()
	height_instance.name = "HeightBlock"
	height_instance.mesh = height_mesh
	height_instance.position = Vector3(0, -height_scale * height / 2, 0)
	
	var height_material = StandardMaterial3D.new()
	height_material.albedo_color = Color(0.6, 0.6, 0.6)
	height_instance.material_override = height_material
	
	tile_instance.add_child(height_instance)

# Add a visual indicator for a resource
func add_resource_indicator(tile_instance: Node3D, resource_name: String) -> void:
	# For simplicity, we'll just add a colored sphere for each resource
	var sphere = SphereMesh.new()
	sphere.radius = 5.0
	sphere.height = 10.0
	
	var sphere_instance = MeshInstance3D.new()
	sphere_instance.name = "Resource_" + resource_name
	sphere_instance.mesh = sphere
	
	# Position the resource indicator above the tile
	sphere_instance.position = Vector3(0, 5.0, 0)
	
	# Create a unique material based on resource type
	var resource_material = StandardMaterial3D.new()
	
	match resource_name:
		"wood":
			resource_material.albedo_color = Color(0.6, 0.4, 0.2)
		"stone":
			resource_material.albedo_color = Color(0.6, 0.6, 0.6)
		"iron":
			resource_material.albedo_color = Color(0.7, 0.7, 0.8)
		"gold":
			resource_material.albedo_color = Color(1.0, 0.8, 0.0)
		_:
			resource_material.albedo_color = Color(1.0, 0.0, 1.0)
	
	sphere_instance.material_override = resource_material
	tile_instance.add_child(sphere_instance)

# Add a visual representation for an entity
func add_entity_visual(tile_instance: Node3D, entity_name: String) -> void:
	# For simplicity, we'll add a simple shape to represent entities
	var entity_mesh = CylinderMesh.new()
	entity_mesh.top_radius = 2.0
	entity_mesh.bottom_radius = 4.0
	entity_mesh.height = 10.0
	
	var entity_instance = MeshInstance3D.new()
	entity_instance.name = "Entity_" + entity_name
	entity_instance.mesh = entity_mesh
	
	# Position the entity on the tile
	entity_instance.position = Vector3(0, 5.0, 0)
	
	# Create a unique material based on entity type
	var entity_material = StandardMaterial3D.new()
	entity_material.albedo_color = Color(0.2, 0.6, 0.9)
	
	entity_instance.material_override = entity_material
	tile_instance.add_child(entity_instance)

# Create a default isometric tile mesh
func create_isometric_tile_mesh(width: float, height: float) -> Mesh:
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Define the 4 corners of an isometric diamond
	vertices.append(Vector3(0, 0, -height/2))  # Top
	vertices.append(Vector3(width/2, 0, 0))    # Right
	vertices.append(Vector3(0, 0, height/2))   # Bottom
	vertices.append(Vector3(-width/2, 0, 0))   # Left
	
	# All vertices face upward
	normals.append(Vector3(0, 1, 0))
	normals.append(Vector3(0, 1, 0))
	normals.append(Vector3(0, 1, 0))
	normals.append(Vector3(0, 1, 0))
	
	# UV coordinates
	uvs.append(Vector2(0.5, 0))
	uvs.append(Vector2(1, 0.5))
	uvs.append(Vector2(0.5, 1))
	uvs.append(Vector2(0, 0.5))
	
	# Define the quad using triangle indices
	indices.append(0)
	indices.append(1)
	indices.append(2)
	indices.append(0)
	indices.append(2)
	indices.append(3)
	
	# Assign arrays to surface
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	# Create mesh
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	return mesh

# Update all tile visuals (for example, after selection change)
func update_all_visuals() -> void:
	var grid_manager = get_parent()
	
	for grid_key in _tile_instances.keys():
		# Extract grid position from key
		var parts = grid_key.split(",")
		if parts.size() == 2:
			var grid_pos = Vector2i(int(parts[0]), int(parts[1]))
			var tile_data = grid_manager.get_tile(grid_pos)
			if tile_data:
				update_tile_visual(tile_data)

# Clear all tile instances
func clear_tiles() -> void:
	for instance in _tile_instances.values():
		instance.queue_free()
	
	_tile_instances.clear() 
