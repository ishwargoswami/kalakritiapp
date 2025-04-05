# AR Functionality in KalaKriti App

This document provides an overview of the Augmented Reality (AR) functionality implemented in the KalaKriti App, enabling users to visualize handicraft products in their real-world environment.

## Features

### Buyer Side

1. **Product AR Viewer**: View 3D models of products in a web-based viewer.
2. **AR Placement**: Place 3D models in your real-world environment using your device's camera.
3. **Interactive Controls**: Rotate, scale, and move the 3D models to visualize them from different angles.

### Seller Side

1. **AR Model Upload**: Upload 3D model files (.glb format) for your products.
2. **Model Preview**: Preview how your 3D models will appear to potential buyers.
3. **Model Management**: Update or remove 3D models from your products.

## Technical Implementation

- We use the `model_viewer_plus` package for basic 3D model viewing.
- The `ar_flutter_plugin` provides native AR capabilities on iOS and Android.
- 3D models are stored in Firebase Storage and linked to products in Firestore.
- The app supports .glb (GL Binary) file format which is optimized for web and mobile experiences.

## Sample Model

A sample 3D model (`alien_flowers.glb`) is included in the `assets/models` directory for testing purposes.

## Usage Instructions

### For Buyers

1. Navigate to a product detail page.
2. If a product has a 3D model available, an AR icon will appear in the app bar.
3. Tap the AR icon to view the product in 3D.
4. On supported devices, tap "View in AR" to place the product in your environment.
5. Follow on-screen instructions to place the model on a flat surface.

### For Sellers

1. Go to your product management section.
2. Select a product or create a new one.
3. In the product edit screen, use the AR model upload option.
4. Upload a .glb file from your device.
5. Preview how the 3D model will look to buyers.
6. Save your changes to make the AR model available to buyers.

## Requirements

- iOS 12+ or Android 9.0+ for AR functionality
- Device with ARCore (Android) or ARKit (iOS) support
- Camera permission enabled
- Internet connection for downloading 3D models

## Future Enhancements

- Support for more 3D file formats (.usdz, .obj)
- AR annotations with product information
- Multi-model AR scene composition
- AR measurements for better size visualization
- AR animations for interactive product demonstrations