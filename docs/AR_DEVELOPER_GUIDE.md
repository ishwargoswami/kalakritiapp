# KalaKriti AR - Developer Guide

This guide provides technical details for developers who want to maintain or extend the AR functionality in the KalaKriti app.

## Architecture Overview

### Components

1. **Flutter AR Components**
   - `ARModelViewer`: Flutter widget that wraps the model_viewer_plus package
   - `CustomCameraARView`: Flutter-based AR view using device camera
   - `ARUtils`: Utility class for handling model paths and AR compatibility

2. **Native AR Components**
   - `MultiObjectArActivity`: Kotlin activity for native ARCore implementation
   - `NativeArService`: Flutter service to communicate with native code
   - `method_channel`: Communication bridge between Flutter and native code

3. **Asset Management**
   - Models stored in `assets/models/` directory in GLB format
   - Build process copies models to Android assets directory

## Code Map

### Flutter Components

#### `lib/utils/ar_utils.dart`
Utility class for AR paths and compatibility checks:
```dart
static String getModelPath(String assetPath) { ... }
static String getModelViewerPath(String assetPath) { ... }
static bool isPotentiallySupportedDevice() { ... }
```

#### `lib/widgets/ar_model_viewer.dart`
Widget for displaying 3D models:
```dart
class ARModelViewer extends StatelessWidget {
  final String modelPath;
  final bool autoRotate;
  final bool ar;
  // ...
}
```

#### `lib/screens/custom_camera_ar_view.dart`
Flutter-based AR experience:
```dart
class CustomCameraARView extends StatefulWidget {
  final String modelPath;
  final String productName;
  // ...
}
```

#### `lib/services/native_ar_service.dart`
Service to launch native AR experience:
```dart
static Future<bool> launchNativeAr() async {
  // Method channel communication with native code
}
```

### Native Components

#### `android/app/src/main/kotlin/com/example/kalakritiapp/MultiObjectArActivity.kt`
Native ARCore implementation:
```kotlin
class MultiObjectArActivity : AppCompatActivity() {
    companion object {
        private val AVAILABLE_MODELS = listOf(
            "alien_flowers.glb", "chair.glb", "table.glb", "stand.glb", "AR-Code-1683007596576.glb"
        )
        // ...
    }
    // ...
}
```

#### `android/app/src/main/kotlin/com/example/kalakritiapp/MainActivity.kt`
Method channel implementation:
```kotlin
override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
        when (call.method) {
            "launchAr" -> {
                // Launch AR activity
            }
            // ...
        }
    }
}
```

## Adding New 3D Models

To add a new 3D model to the app:

1. Place the new `.glb` file in the `assets/models/` directory
2. Add the model to the list of available models in `MultiObjectArActivity.kt`:
   ```kotlin
   private val AVAILABLE_MODELS = listOf(
       "alien_flowers.glb",
       "chair.glb",
       "your_new_model.glb", // Add new model here
       // ...
   )
   ```
3. Add a thumbnail resource for the new model in `getModelThumbnailResource()`:
   ```kotlin
   private fun getModelThumbnailResource(modelName: String): Int {
       return when(modelName) {
           // ...
           "your_new_model.glb" -> android.R.drawable.ic_menu_gallery,
           // ...
       }
   }
   ```
4. Update the assets section in `pubspec.yaml` if needed
5. Run `flutter pub get` and rebuild the app

## Extending AR Functionality

### Adding Physics Simulation

To add physics-based interactions between models:

1. Add a physics engine like Bullet Physics to the native AR implementation
2. Implement collision detection between placed objects
3. Add mass and gravity properties to the `ArModel` class

### Implementing Surface Material Detection

To detect and respond to different surface materials:

1. Use ARCore's `PlaneRenderer` to detect different surface types
2. Add material properties to the detected planes
3. Modify the rendering to reflect surface materials

### Supporting More File Formats

To support additional 3D model formats:

1. Add appropriate loaders in the native implementation
2. Update the file extension checks in `product_ar_upload.dart`
3. Implement converters if needed for web compatibility

## Troubleshooting Common Issues

### Model Loading Failures

If models fail to load:
- Check that the model path is correct
- Verify that the model is copied to the Android assets
- Ensure the model file is valid GLB format

### ARCore Initialization Issues

If ARCore fails to initialize:
- Check that the device supports ARCore
- Verify Google Play Services for AR is installed
- Check ARCore permissions in AndroidManifest.xml

### Method Channel Communication Errors

If Flutter fails to communicate with native code:
- Verify the channel name is consistent in both Flutter and native code
- Check that method names match exactly
- Ensure proper error handling in both directions

## Performance Optimization

### Memory Management

- Limit the number of concurrent 3D models
- Implement level-of-detail (LOD) for complex models
- Release resources when AR view is closed

### Rendering Optimization

- Use simplified collision meshes
- Implement occlusion for hidden objects
- Optimize lighting calculations for mobile devices

## Future Development Roadmap

1. Cloud Anchors for shared AR experiences
2. Occlusion with real-world objects
3. AR annotations and product information overlay
4. Integration with ARKit for iOS
5. Advanced lighting and shadow effects 