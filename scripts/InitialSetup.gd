@tool
extends Node

# This script handles the initial setup of the game
# It's attached to the InitialSetup node in the main scene

var _game_manager: GameManager

func _ready() -> void:
	print("Initializing Godot Isometric Template...")
	
	# Create the GameManager
	_game_manager = GameManager.new()
	_game_manager.name = "GameManager"
	
	# Schedule node operations for the next idle frame to avoid "busy parent" errors
	call_deferred("_setup_game_manager")
	
func _setup_game_manager() -> void:
	# Get the parent node
	var parent = get_parent()
	
	# Set the game manager properties
	_game_manager.demo_map_path = "res://data/demo_map.json"
	_game_manager.load_map_on_ready = true
	
	# Replace this node with the game manager
	parent.call_deferred("remove_child", self)
	parent.call_deferred("add_child", _game_manager)
	
	# Clean up this node
	call_deferred("queue_free")
	
	print("Initialization complete!") 
