@tool
class_name TileData extends Resource

# Basic tile properties
@export var type: String = "empty"
@export var height: float = 0.0
@export var resources: Array = []
@export var entities: Array = []
@export var navigation: Dictionary = {}

# Position properties
@export var grid_position: Vector2i = Vector2i.ZERO  # Position in grid coordinates
@export var world_position: Vector3 = Vector3.ZERO   # Position in 3D world space

# Visual properties
@export var highlighted: bool = false
@export var selected: bool = false

func _init(data: Dictionary = {}) -> void:
	for key in data:
		if key in self:
			set(key, data[key])

# Helper methods for property access
func add_resource(resource_name: String) -> void:
	if not resource_name in resources:
		resources.append(resource_name)

func remove_resource(resource_name: String) -> void:
	resources.erase(resource_name)
	
func add_entity(entity_name: String) -> void:
	if not entity_name in entities:
		entities.append(entity_name)
		
func remove_entity(entity_name: String) -> void:
	entities.erase(entity_name)
	
func set_navigation(travel_type: String, can_navigate: bool) -> void:
	navigation[travel_type] = can_navigate
	
func can_navigate(travel_type: String) -> bool:
	return navigation.get(travel_type, false)
	
func get_display_name() -> String:
	return type.capitalize()
	
func to_dict() -> Dictionary:
	return {
		"type": type,
		"height": height,
		"resources": resources.duplicate(),
		"entities": entities.duplicate(),
		"navigation": navigation.duplicate(),
		"grid_position": {"x": grid_position.x, "y": grid_position.y}
	} 
