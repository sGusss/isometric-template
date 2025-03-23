# Godot Isometric Template Project Documentation
## Overview
The Godot Isometric Template is a comprehensive foundation for developing isometric games and applications, prioritizing **developer experience**, **customization**, and **performance**. Designed for 3D implementation with 2D workflow simplicity, it features dynamic grid management and camera controls optimized for strategy games. This template aims to simplify the setup for an isometric view in Godot by pre-configuring tilemaps, proper sorting, and camera controls.

## Purpose
The primary goal of this template is to:
1. **Simplify Isometric Setup**: Provide a straightforward system for creating and rendering isometric maps.
2. **Flexible Data Structure**: Offer a clear and flexible structure for developers to quickly add or modify tile data, visual assets, and game mechanics.
3. **Enable Strategy Genre Aspects**: Support turn-based or real-time strategy genre aspects by offering essential foundations such as tile-based data handling, custom tile overlays, and a smooth, dynamic camera.

## Core Features

### 1. Isometric Grid System
- **2D Array Parsing**: Accepts JSON/CSV input with tile data structure:
  ```json
  {
    "tiles": [
      {"type": "grass", "height": 1, "resources": ["wood"], "entities": ["villster"]},
      {"type": "water", "height": 0, "navigation": {"boat": true}}
    ]
  }
  ```
- **Dynamic Tile Generation**: Auto-generates isometric meshes from input dimensions.
- **Mixed Tile Sizes**: Supports mixed tile sizes (64x32 base + custom sizes).

### 2. Rendering Pipeline
- **YSort-Based Layering**: Automatic depth sorting for proper object layering.
  ```gdscript
  # Example from TileFactory.gd
  _tile_container.add_child(tile_instance)
  ```
- **Multi-Layer Support**: Includes layers for base terrain, height variations, resource overlays, and entities.

### 3. Camera System
| Feature              | Implementation                                   |
|----------------------|--------------------------------------------------|
| Edge Panning         | Screen boundary detection in CameraController.gd |
| Smooth Zoom          | Exponential interpolation in CameraController.gd |
| Rotation             | 45° increments (Q/E keys) in CameraController.gd |
| Focus Tracking       | Object-centered view locking in CameraController.gd |

### 4. Customization Framework
- **Extensible Tile System**: Base tile class for inheritance with override hooks for custom behaviors.
- **Appearance Customization**: Adjustable tile dimensions, support for different art styles, and shader support for special effects.
- **Gameplay Integration**: Built-in functions for handling user interaction, pathfinding, and turn-based logic.

### 5. Developer Tools
- **Runtime Inspector**: Click tiles to view and edit their properties (via DeveloperTools.gd).
- **Debug Visualization**: Optional grid overlays and coordinate display (F4 and F5 keys).
- **Performance Monitoring**: Track draw calls and rendering statistics (F3 key).

## Technical Specifications

### Data Structure
```gdscript
# Implementation in scripts/TileData.gd
class_name TileData extends Resource
var type: String
var height: float
var resources: Array
var entities: Array
var navigation: Dictionary
```

### Key Components
1. **GridManager** (scripts/GridManager.gd) - Handles coordinate conversions and isometric projections.
2. **TileFactory** (scripts/TileFactory.gd) - Procedural mesh generation for dynamic tile creation.
3. **CameraController** (scripts/CameraController.gd) - Smooth movement logic for edge panning, zooming, and rotation.

## Project Structure
The actual project hierarchy:
* **scenes/**
  + main.tscn (Main scene with camera, grid, factory components)
  + tile.tscn (Base tile scene)
* **scripts/**
  + GridManager.gd (Grid and coordinate management)
  + TileFactory.gd (Visual generation of tiles)
  + CameraController.gd (Camera movement and controls)
  + TileData.gd (Data structure for tiles)
  + DataParser.gd (JSON/CSV map loading)
  + DeveloperTools.gd (Debug visualization)
  + MapInteractionHandler.gd (Click and hover logic)
  + GameManager.gd (Game state management)
  + InitialSetup.gd (Project initialization)
* **assets/**
  + textures/ (Texture assets - add your own)
  + materials/ (Material assets - add your own)
  + tilesets/ (Tileset assets - add your own)
* **data/**
  + demo_map.json (Example map demonstrating features)

## Usage Guide

### Initial Setup
1. **Download or Clone**: Download or clone the template into your Godot project.
2. **Open in Godot**: Open the project in Godot 4.3 or higher.
3. **Run the Game**: Press F5 or click the play button to run the demo.

### Creating Maps
```gdscript
# Example of loading a map from JSON
# From scripts/GameManager.gd
func load_map(file_path: String) -> void:
    var map_data = _data_parser.parse_json_file(file_path)
    _grid_manager.create_map(map_data)

# Example of modifying a tile
# From scripts/GridManager.gd
func set_tile_property(grid_pos: Vector2i, property: String, value) -> void:
    var tile = get_tile(grid_pos)
    if tile and property in tile:
        tile.set(property, value)
```

### Customizing Tiles
1. **Define New Tile Types**: Extend the tile type definitions in `scripts/TileFactory.gd`.
2. **Create Materials**: Add new materials in `assets/materials/` for your tile types.
3. **Add Logic**: Extend the interaction logic in `scripts/MapInteractionHandler.gd`.

## Roadmap
- **Advanced Tile Management**: Improved layering for multi-tile objects and support for isometric 3D meshes that adapt to height maps.
- **Enhanced Data API**: More robust tile metadata for modifiable properties and built-in support for saving/loading tile states.
- **Editor Tools**: Godot-editor-based tile placement and painting tools, and visual debugging overlays to check tile indexes or highlight pathfinding routes.
- **Performance Updates**: Level-of-detail (LOD) to handle large maps, and GPU instancing or chunk-based rendering for better performance.

## Contributing
1. **Pull Requests**: Feel free to open pull requests for bug fixes, new features, or documentation updates.
2. **Issues**: Use the project's issue tracker to report bugs or request features.
3. **Community Contributions**: We encourage custom tile art, expansions for advanced 3D usage, or specialized camera plugins.

## License
This template is available under the MIT License. You are free to use it in personal or commercial projects, modify it, and distribute your changes, subject to the license conditions.

## Conclusion
The Godot Isometric Template is designed to be a powerful yet straightforward base for building isometric games. By organizing the project in a modular fashion, offering convenient data management, and providing a dynamic camera, it enables rapid prototyping and easy collaboration. Whether you're making a small puzzle game or a deep strategy title, this template aims to reduce tedious setup and let you focus on the fun parts of game development.