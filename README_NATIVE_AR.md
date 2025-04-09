# Native AR Experience in KalaKriti App

This document covers the native AR implementation in KalaKriti using ARCore on Android, which allows users to place and interact with multiple 3D models in the same scene.

## Key Features

### Multiple Model Support
- **Model Selection**: Choose from various 3D models available in the app's assets
- **Model Thumbnails**: Visual selector with thumbnails for each available model
- **Add Multiple Items**: Place different models in the same AR scene

### AR Interaction
- **Surface Detection**: Automatically detects horizontal surfaces for placing models
- **Touch Placement**: Tap to place models on detected surfaces
- **Multi-Object Manipulation**: Select and modify each placed object independently
- **Object Controls**:
  - Scale: Adjust the size of models
  - Rotation: Rotate models around their vertical axis
  - Position: Move models to precise locations in your space

### User Interface
- **Intuitive Controls**: Easy-to-use buttons and sliders for object manipulation
- **Visual Feedback**: Clear highlighting of selected items
- **Help System**: Built-in instructions and tooltips

## Technical Implementation

### Architecture
The native AR experience is built using:
- **ARCore**: Google's platform for building AR experiences on Android
- **Filament**: Google's real-time physically based rendering engine for Android
- **Kotlin**: Native Android implementation for optimal performance

### Model Loading
- Supports GLB format files (GL Transmission Format Binary)
- Models are stored in the app's assets and copied to Android assets during build
- Dynamic model loading at runtime to support multiple models

### Integration with Flutter
- **Method Channel**: Communication between Flutter and native Android code
- **Native Service**: Flutter service to launch and interact with the native AR activity

## Available 3D Models
The app includes the following models that you can use in AR:
- alien_flowers.glb
- chair.glb
- table.glb
- stand.glb
- AR-Code-1683007596576.glb

## Using the Native AR Experience

1. From the AR View screen, tap the AR icon in the top right
2. When the native AR screen opens, you'll see:
   - A bottom bar with model thumbnails
   - Control buttons for scene manipulation
   - Help button for instructions
3. To add items to your scene:
   - Select a model by tapping its thumbnail
   - Tap the "+" button next to the thumbnail
   - Point your camera at a flat surface
   - Tap on the surface to place the model
4. To manipulate placed items:
   - Tap the pin/edit toggle to switch between placing and editing
   - Select an item by tapping on it
   - Use the control sliders to adjust size, rotation, and position
5. Use the action buttons for:
   - Reset: Clear all placed models
   - Capture: Take a screenshot of your AR scene
   - Help: View usage instructions

## Troubleshooting

### Common Issues
- **Models not appearing**: Make sure you're pointing at a well-lit flat surface
- **Tracking lost**: Avoid fast camera movements and ensure good lighting
- **Models flickering**: This may occur on surfaces with reflections or patterns

### Device Compatibility
- Requires an ARCore-compatible Android device
- Android 9.0 (API level 28) or higher recommended
- Device must have Google Play Services for AR installed

## Future Enhancements
- Physics-based interactions between models
- Surface material detection
- Cloud anchors for shared AR experiences
- More realistic lighting and shadows
- Additional model categories 