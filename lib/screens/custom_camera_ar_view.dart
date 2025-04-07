import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../services/native_ar_service.dart';
import '../utils/ar_utils.dart';

class CustomCameraARView extends StatefulWidget {
  final String modelPath;
  final String productName;
  final List<Map<String, dynamic>>? additionalItems; // Optional list of additional items

  const CustomCameraARView({
    Key? key,
    required this.modelPath,
    required this.productName,
    this.additionalItems,
  }) : super(key: key);

  @override
  State<CustomCameraARView> createState() => _CustomCameraARViewState();
}

class _CustomCameraARViewState extends State<CustomCameraARView> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isRearCameraSelected = true;
  
  // Model control parameters
  double _scale = 1.0;
  double _xPosition = 0.0;
  double _yPosition = 0.0;
  double _rotation = 0.0;
  bool _showControls = true;
  bool _showHelp = false;
  bool _isDragging = false;
  bool _isPlaced = false;
  bool _showOutline = true;
  
  // For multiple items
  List<PlacedItem> _placedItems = [];
  int _selectedItemIndex = -1; // -1 means main item is selected
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    
    // Add the main item to the placed items list
    _placedItems.add(
      PlacedItem(
        modelPath: widget.modelPath, 
        name: widget.productName,
        xPosition: _xPosition,
        yPosition: _yPosition,
        scale: _scale,
        rotation: _rotation,
      )
    );
    
    // Add any additional items if provided
    if (widget.additionalItems != null) {
      for (var item in widget.additionalItems!) {
        _placedItems.add(
          PlacedItem(
            modelPath: item['modelPath'],
            name: item['name'],
            xPosition: 50.0, // Initial offset
            yPosition: 50.0, // Initial offset
            scale: 0.8,
            rotation: 0.0,
          )
        );
      }
    }
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    
    if (_cameras.isNotEmpty) {
      final camera = _isRearCameraSelected 
          ? _cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first)
          : _cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first);
              
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _flipCamera() async {
    setState(() {
      _isCameraInitialized = false;
      _isRearCameraSelected = !_isRearCameraSelected;
    });
    await _cameraController?.dispose();
    await _initializeCamera();
  }

  void _resetPosition() {
    setState(() {
      if (_selectedItemIndex == -1) {
        _scale = 1.0;
        _xPosition = 0.0;
        _yPosition = 0.0;
        _rotation = 0.0;
        _updateMainItemPosition();
      } else if (_selectedItemIndex >= 0 && _selectedItemIndex < _placedItems.length) {
        _placedItems[_selectedItemIndex].scale = 1.0;
        _placedItems[_selectedItemIndex].xPosition = 0.0;
        _placedItems[_selectedItemIndex].yPosition = 0.0;
        _placedItems[_selectedItemIndex].rotation = 0.0;
      }
    });
  }
  
  void _updateMainItemPosition() {
    if (_placedItems.isNotEmpty) {
      _placedItems[0] = PlacedItem(
        modelPath: widget.modelPath,
        name: widget.productName,
        xPosition: _xPosition,
        yPosition: _yPosition,
        scale: _scale,
        rotation: _rotation,
      );
    }
  }
  
  void _toggleItemPlacement() {
    setState(() {
      _isPlaced = !_isPlaced;
      if (_isPlaced) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item placed! Tap on any item to select and adjust.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }
  
  void _addNewItem() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Item'),
        content: Text('This feature will let you add more items from your catalog in the next update!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _selectItem(int index) {
    setState(() {
      _selectedItemIndex = index;
      if (index >= 0 && index < _placedItems.length) {
        // Set the controls to match the selected item's properties
        final item = _placedItems[index];
        _scale = item.scale;
        _xPosition = item.xPosition;
        _yPosition = item.yPosition;
        _rotation = item.rotation;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('KalaKriti AR View - ${widget.productName}'),
        backgroundColor: Colors.black.withOpacity(0.5),
        actions: [
          // Native AR button (Android only)
          if (Platform.isAndroid)
            IconButton(
              icon: const Icon(Icons.view_in_ar),
              tooltip: 'Launch Native AR Experience',
              onPressed: () async {
                final success = await NativeArService.launchNativeAr();
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to launch native AR experience'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          IconButton(
            icon: Icon(_showHelp ? Icons.help : Icons.help_outline),
            onPressed: () {
              setState(() {
                _showHelp = !_showHelp;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview layer
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _cameraController!.value.previewSize!.height,
                height: _cameraController!.value.previewSize!.width,
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),
          
          // Grid overlay when placing items
          if (!_isPlaced)
            Container(
              color: Colors.white10,
              child: CustomPaint(
                painter: GridPainter(),
                size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
              ),
            ),
          
          // Placed items
          ..._placedItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            
            // Create a widget for each item in the list
            return Positioned(
              left: MediaQuery.of(context).size.width / 2 + item.xPosition - 150, // Center offset
              top: MediaQuery.of(context).size.height / 2 + item.yPosition - 150, // Center offset
              child: GestureDetector(
                onTap: () {
                  if (_isPlaced) {
                    _selectItem(index);
                  }
                },
                onPanUpdate: _isPlaced ? null : (details) {
                  setState(() {
                    if (index == 0) {
                      _xPosition += details.delta.dx;
                      _yPosition += details.delta.dy;
                      _updateMainItemPosition();
                    } else {
                      _placedItems[index].xPosition += details.delta.dx;
                      _placedItems[index].yPosition += details.delta.dy;
                    }
                  });
                },
                child: Container(
                  height: 300,
                  width: 300,
                  decoration: BoxDecoration(
                    border: _showOutline 
                      ? Border.all(
                          color: _selectedItemIndex == index ? Colors.yellow : Colors.white30,
                          width: _selectedItemIndex == index ? 2.0 : 1.0,
                        ) 
                      : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Transform.rotate(
                    angle: item.rotation,
                    child: Transform.scale(
                      scale: item.scale,
                      child: ModelViewer(
                        backgroundColor: Colors.transparent,
                        src: ARUtils.getModelViewerPath(item.modelPath),
                        alt: item.name,
                        ar: false,
                        autoRotate: false,
                        cameraControls: true,
                        disableZoom: _isPlaced,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          
          // Controls panel
          if (_showControls)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black.withOpacity(0.7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Camera flip button
                        FloatingActionButton(
                          heroTag: 'flip',
                          mini: true,
                          backgroundColor: Colors.white,
                          onPressed: _flipCamera,
                          child: Icon(
                            Icons.flip_camera_ios,
                            color: Colors.black,
                          ),
                        ),
                        
                        // Reset position button
                        FloatingActionButton(
                          heroTag: 'reset',
                          mini: true,
                          backgroundColor: Colors.white,
                          onPressed: _resetPosition,
                          child: Icon(
                            Icons.restart_alt,
                            color: Colors.black,
                          ),
                        ),
                        
                        // Capture photo button (future feature)
                        FloatingActionButton(
                          heroTag: 'capture',
                          backgroundColor: Colors.redAccent,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Photo capture coming in the next update!'),
                                backgroundColor: Colors.amber[700],
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                        ),
                        
                        // Add new item button
                        FloatingActionButton(
                          heroTag: 'addItem',
                          backgroundColor: Colors.green,
                          onPressed: _addNewItem,
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                        ),
                        
                        // Place/Move toggle button
                        FloatingActionButton(
                          heroTag: 'placeToggle',
                          backgroundColor: _isPlaced ? Colors.amber : Colors.blue,
                          onPressed: _toggleItemPlacement,
                          child: Icon(
                            _isPlaced ? Icons.edit : Icons.push_pin,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    Text(
                      _selectedItemIndex == -1 
                          ? 'Editing: Main Item' 
                          : 'Editing: ${_placedItems[_selectedItemIndex].name}',
                      style: TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    
                    SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Size',
                                style: TextStyle(color: Colors.white),
                              ),
                              Slider(
                                value: _scale,
                                min: 0.2,
                                max: 3.0,
                                divisions: 28,
                                label: _scale.toStringAsFixed(1),
                                onChanged: (value) {
                                  setState(() {
                                    _scale = value;
                                    if (_selectedItemIndex == -1) {
                                      _updateMainItemPosition();
                                    } else {
                                      _placedItems[_selectedItemIndex].scale = value;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Rotation',
                                style: TextStyle(color: Colors.white),
                              ),
                              Slider(
                                value: _rotation,
                                min: -3.14,
                                max: 3.14,
                                divisions: 36,
                                label: (_rotation * 180 / 3.14).toStringAsFixed(0) + '°',
                                onChanged: (value) {
                                  setState(() {
                                    _rotation = value;
                                    if (_selectedItemIndex == -1) {
                                      _updateMainItemPosition();
                                    } else {
                                      _placedItems[_selectedItemIndex].rotation = value;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'X Position',
                                style: TextStyle(color: Colors.white),
                              ),
                              Slider(
                                value: _xPosition,
                                min: -200,
                                max: 200,
                                divisions: 40,
                                label: _xPosition.toStringAsFixed(0),
                                onChanged: (value) {
                                  setState(() {
                                    _xPosition = value;
                                    if (_selectedItemIndex == -1) {
                                      _updateMainItemPosition();
                                    } else {
                                      _placedItems[_selectedItemIndex].xPosition = value;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Y Position',
                                style: TextStyle(color: Colors.white),
                              ),
                              Slider(
                                value: _yPosition,
                                min: -200,
                                max: 200,
                                divisions: 40,
                                label: _yPosition.toStringAsFixed(0),
                                onChanged: (value) {
                                  setState(() {
                                    _yPosition = value;
                                    if (_selectedItemIndex == -1) {
                                      _updateMainItemPosition();
                                    } else {
                                      _placedItems[_selectedItemIndex].yPosition = value;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _showOutline,
                              onChanged: (value) {
                                setState(() {
                                  _showOutline = value ?? true;
                                });
                              },
                              checkColor: Colors.black,
                              fillColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  return Colors.white;
                                },
                              ),
                            ),
                            Text(
                              'Show Outline',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          icon: Icon(
                            _showControls ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Hide Controls',
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            setState(() {
                              _showControls = !_showControls;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
          // Quick toggle for controls
          if (!_showControls)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'showControls',
                backgroundColor: Colors.black54,
                onPressed: () {
                  setState(() {
                    _showControls = true;
                  });
                },
                child: Icon(
                  Icons.settings,
                  color: Colors.white,
                ),
              ),
            ),
            
          // Help overlay
          if (_showHelp)
            Container(
              color: Colors.black.withOpacity(0.9),
              padding: EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Enhanced KalaKriti AR Controls',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24),
                    _helpItem(Icons.flip_camera_ios, 'Flip Camera', 'Switch between front and rear cameras'),
                    _helpItem(Icons.restart_alt, 'Reset', 'Reset selected item position and size'),
                    _helpItem(Icons.camera_alt, 'Take Photo', 'Coming soon - Save your AR view as an image'),
                    _helpItem(Icons.add, 'Add Item', 'Add more items to your virtual space'),
                    _helpItem(Icons.push_pin, 'Pin/Edit Toggle', 'Switch between placing and editing items'),
                    _helpItem(Icons.straighten, 'Size Slider', 'Adjust the size of the selected item'),
                    _helpItem(Icons.rotate_right, 'Rotation', 'Rotate the selected item'),
                    _helpItem(Icons.swap_horiz, 'X Position', 'Move the item left or right'),
                    _helpItem(Icons.swap_vert, 'Y Position', 'Move the item up or down'),
                    _helpItem(Icons.border_style, 'Show Outline', 'Toggle item outline for better visibility'),
                    _helpItem(Icons.drag_handle, 'Direct Manipulation', 'Drag items directly when not pinned'),
                    _helpItem(Icons.touch_app, 'Item Selection', 'Tap any item to select it when items are pinned'),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showHelp = false;
                        });
                      },
                      child: Text('Got it!'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _helpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Grid painter for visual reference when placing objects
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1;

    // Draw horizontal lines
    for (int i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i.toDouble()), Offset(size.width, i.toDouble()), paint);
    }

    // Draw vertical lines
    for (int i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble(), size.height), paint);
    }
    
    // Draw center crosshair
    final centerPaint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 2;
    
    canvas.drawLine(
      Offset(size.width / 2 - 20, size.height / 2),
      Offset(size.width / 2 + 20, size.height / 2),
      centerPaint,
    );
    
    canvas.drawLine(
      Offset(size.width / 2, size.height / 2 - 20),
      Offset(size.width / 2, size.height / 2 + 20),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Class to represent a placed item in the scene
class PlacedItem {
  final String modelPath;
  final String name;
  double xPosition;
  double yPosition;
  double scale;
  double rotation;
  
  PlacedItem({
    required this.modelPath,
    required this.name,
    required this.xPosition,
    required this.yPosition,
    required this.scale,
    required this.rotation,
  });
} 