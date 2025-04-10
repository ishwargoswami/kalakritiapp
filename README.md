# KalaKriti App

KalaKriti is a marketplace app for handicraft products, built with Flutter, featuring an immersive Augmented Reality (AR) experience to help buyers visualize products in their real environment.

## Features

### For Buyers
- **Product Discovery**: Browse a curated collection of handcrafted items from artisans
- **Detailed Product Views**: High-quality images, descriptions, and specifications
- **In-App Purchase**: Secure checkout and payment processing
- **AR Visualization**: Place multiple 3D models in your space to see how products look in your environment
- **Multi-Object AR**: Add and arrange multiple handicraft items in a single AR scene
- **Customizable Views**: Adjust size, rotation, and position of 3D models

### For Sellers
- **Product Management**: Add, edit, and manage product listings
- **3D Model Upload**: Upload .glb format 3D models for your products
- **Sales Analytics**: Track order status and sales performance
- **GLB Creation Guide**: Resources for creating 3D models of your products

### AR Features
- **Native AR Experience**: Built using ARCore on Android for high-performance AR
- **Multiple Model Selection**: Choose from different models in the assets library
- **Real-time Placement**: Easily place and adjust multiple items in the same scene
- **Interactive Controls**: Resize, rotate, and reposition objects in AR space
- **Screenshot Capability**: Capture your AR compositions to share or save
- **User-Friendly Interface**: Intuitive controls for positioning and manipulating objects

## Technical Details
- Built with Flutter for the front-end
- Firebase for authentication, database, and storage
- Native AR implementation with ARCore (Android)
- Model Viewer Plus for 3D preview
- Supports .glb 3D model format
- Camera integration for AR visualization

## Getting Started

### Prerequisites
- Flutter SDK 3.0.0 or higher
- Dart 2.17.0 or higher
- Android Studio or Visual Studio Code
- Firebase project set up
- Android device with ARCore support (for AR features)

### Installation
1. Clone the repository:
   ```
   git clone https://github.com/yourusername/kalakritiapp.git
   ```

2. Navigate to the project directory:
   ```
   cd kalakritiapp
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Run the app:
   ```
   flutter run
   ```

## AR Usage Guide

### Viewing Products in AR
1. Browse the product catalog and select a product
2. Tap on the "View in AR" button on the product detail page
3. Point your camera at a flat surface
4. Once the surface is detected, tap to place the product
5. Use gestures to resize, rotate, or move the placed item

### Using Multi-Object AR Mode
1. Navigate to the AR view screen
2. Tap the native AR experience button (Android only)
3. Select different models from the bottom thumbnails row
4. Tap the "+" button next to each thumbnail to add it to the scene
5. Adjust each item using the on-screen controls
6. Use the pin/edit toggle to switch between placing and editing items
7. Capture screenshots with the camera button

## Troubleshooting AR Issues
- Ensure your device supports ARCore (Android)
- Make sure you have sufficient lighting for surface detection
- Clear flat surfaces work best for stable AR placement
- If models appear too large or small, use the scale controls to adjust

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements
- ARCore by Google
- Model Viewer Plus by Google
- All the contributors and testers who helped improve the app
#   k a l a k r i t i a p p 
 
 