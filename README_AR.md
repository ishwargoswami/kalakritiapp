# AR Functionality in KalaKriti App

This document provides an overview of the Augmented Reality (AR) functionality implemented in the KalaKriti App, enabling users to visualize handicraft products in their real-world environment.

## Features

### Buyer Side

1. **Product AR Viewer**: View 3D models of products in a web-based viewer.
2. **AR Placement**: Place 3D models in your real-world environment using your device's camera.
3. **Interactive Controls**: Rotate, scale, and move the 3D models to visualize them from different angles.
4. **Multi-Object AR** (New!): Add multiple different products to the same AR scene for better room planning.
5. **Model Selection Gallery**: Browse through available 3D models and add them to your space.

### Seller Side

1. **AR Model Upload**: Upload 3D model files (.glb format) for your products.
2. **Model Preview**: Preview how your 3D models will appear to potential buyers.
3. **Model Management**: Update or remove 3D models from your products.

## Technical Implementation

- We use the `model_viewer_plus` package for basic 3D model viewing.
- The `CustomCameraARView` provides camera-based AR capabilities in Flutter.
- **Native ARCore Integration** (New!): Advanced AR experience using native Android ARCore functionality.
- 3D models are stored in Firebase Storage and linked to products in Firestore.
- The app supports .glb (GL Binary) file format which is optimized for web and mobile experiences.
- Models are copied from Flutter assets to Android assets during build for native AR.

## Available 3D Models

The app includes the following 3D models in the `assets/models` directory:
- alien_flowers.glb
- chair.glb
- table.glb
- stand.glb
- AR-Code-1683007596576.glb

## Usage Instructions

### For Buyers

1. Navigate to a product detail page.
2. If a product has a 3D model available, an AR icon will appear in the app bar.
3. Tap the AR icon to view the product in 3D.
4. On supported devices, tap "View in AR" to place the product in your environment.
5. Follow on-screen instructions to place the model on a flat surface.
6. For multi-object AR (Android only):
   - Tap the AR icon in the top action bar
   - Select models from the bottom thumbnail gallery
   - Tap the "+" button to add models to your scene
   - Use the controls to manipulate each object individually

### For Sellers

1. Go to your product management section.
2. Select a product or create a new one.
3. In the product edit screen, use the AR model upload option.
4. Upload a .glb file from your device.
5. Preview how the 3D model will look to buyers.
6. Save your changes to make the AR model available to buyers.

## AR Implementation Options

The app provides two different AR experiences:

1. **Flutter-based AR**:
   - Uses Flutter's camera and 3D rendering capabilities
   - Works on most devices with a camera
   - Simpler implementation but less immersive

2. **Native ARCore AR** (Android Only):
   - Uses Google's ARCore platform for true AR experiences
   - Requires ARCore compatible devices
   - Provides advanced features like surface detection, lighting, and multi-object placement
   - Accessed via the AR button in the top action bar

## Requirements

- iOS 12+ or Android 9.0+ for AR functionality
- Device with ARCore (Android) or ARKit (iOS) support
- Camera permission enabled
- Internet connection for downloading 3D models

## Future Enhancements

- Support for more 3D file formats (.usdz, .obj)
- AR annotations with product information
- Expanded model library with more product categories
- AR measurements for better size visualization
- AR animations for interactive product demonstrations
- Shared AR experiences between users