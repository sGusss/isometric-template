# Godot Isometric Template

A comprehensive template for creating isometric games with Godot 4.3+, focusing on developer experience, customization, and performance.

## Features

- **Isometric Grid System**: Easy-to-use coordinate system with automatic conversion between grid and world coordinates
- **Flexible Data Structure**: Load maps from JSON or CSV, with support for various tile properties
- **Camera System**: Smooth camera controls with edge panning, zooming, and rotation
- **Customization Framework**: Extensible design for adding custom tile types and behaviors
- **Developer Tools**: Built-in debugging tools like grid overlay and coordinate display

## Getting Started

### Requirements

- Godot Engine 4.3 or higher

### Setup

1. Clone this repository or download it as a ZIP file
2. Open the project in Godot
3. Run the project to see the demo map

## Usage

### Loading Maps

The template can load maps from JSON or CSV files. By default, it will load a demo map from `data/demo_map.json`. You can create your own maps following the same format:

```json
{
  "dimensions": {
    "width": 10,
    "height": 10
  },
  "tiles": [
    {
      "position": {"x": 0, "y": 0},
      "type": "grass",
      "height": 0.0,
      "resources": ["wood"],
      "entities": []
    },
    // More tiles...
  ]
}
```

### Camera Controls

- **WASD**: Pan the camera
- **Mouse at Screen Edge**: Pan the camera (edge panning)
- **Mouse Wheel**: Zoom in/out
- **Q/E**: Rotate camera by 45°

### Developer Tools

Press the following keys to toggle debug features:

- **F3**: Toggle performance statistics
- **F4**: Toggle grid overlay
- **F5**: Toggle grid coordinates

## Customization

### Adding New Tile Types

1. Add new tile type definitions in `TileFactory.gd`
2. Create materials and meshes for your new tile types
3. Update the demo map or create a new map with your tile types

### Extending Functionality

The template is designed to be extended with new features:

- Add new properties to `TileData.gd`
- Extend `MapInteractionHandler.gd` for custom interactions
- Modify `GridManager.gd` for advanced grid behaviors

## Project Structure

- **scenes/**: Contains all scene files
  - **main.tscn**: Main scene with all core components
  - **tile.tscn**: Basic tile scene
- **scripts/**: Contains all GDScript files
  - **GridManager.gd**: Manages the isometric grid
  - **TileFactory.gd**: Creates and updates tile visuals
  - **CameraController.gd**: Handles camera movement
  - **TileData.gd**: Data structure for tile properties
  - **DataParser.gd**: Loads maps from JSON/CSV
  - **DeveloperTools.gd**: Debug visualization tools
  - **MapInteractionHandler.gd**: Handles user interactions
  - **GameManager.gd**: Coordinates game systems
- **data/**: Contains map data files
  - **demo_map.json**: Example map
- **assets/**: Contains visual assets (empty in template)

## License

This template is available under the MIT License. See the LICENSE file for details.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to help improve this template.

## Acknowledgements

Created for the Godot game development community to streamline isometric game development. 