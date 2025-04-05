import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kalakritiapp/widgets/ar_model_viewer.dart';
import 'package:kalakritiapp/screens/ar_view_screen.dart';
import 'package:kalakritiapp/models/product.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class ProductARUpload extends StatefulWidget {
  final Product? product;

  const ProductARUpload({
    Key? key,
    this.product,
  }) : super(key: key);

  @override
  State<ProductARUpload> createState() => _ProductARUploadState();
}

class _ProductARUploadState extends State<ProductARUpload> {
  String? modelPath;
  bool isUploading = false;
  double uploadProgress = 0.0;
  String? errorMessage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.product != null && widget.product!.arModelUrl != null) {
      modelPath = widget.product!.arModelUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null 
            ? 'Update AR Model: ${widget.product!.name}'
            : 'Add AR Model'),
        actions: [
          if (modelPath != null &&
              !kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.android))
            IconButton(
              icon: const Icon(Icons.view_in_ar),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ARViewScreen(
                      modelPath: modelPath!,
                      modelName: widget.product?.name ?? 'Product',
                    ),
                  ),
                );
              },
              tooltip: 'Preview in AR',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                
              if (isUploading)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uploading 3D Model...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: uploadProgress),
                      const SizedBox(height: 4),
                      Text('${(uploadProgress * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              
              if (modelPath != null)
                Container(
                  height: 300,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ARModelViewer(
                      modelPath: modelPath!,
                      autoRotate: true,
                    ),
                  ),
                ),
              
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: Text(modelPath == null
                    ? 'Upload 3D Model (.glb)'
                    : 'Replace 3D Model'),
                onPressed: isUploading ? null : _uploadModel,
              ),
              
              if (modelPath != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove 3D Model'),
                  onPressed: isUploading ? null : _removeModel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: isUploading || modelPath == null
                    ? null
                    : () {
                        Navigator.pop(context, modelPath);
                      },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadModel() async {
    try {
      // We're using image_picker here because it can access files,
      // but we need to filter for .glb files
      final result = await _picker.pickMedia();
      
      if (result == null) return;
      
      final file = File(result.path);
      final extension = path.extension(file.path).toLowerCase();
      
      if (extension != '.glb') {
        setState(() {
          errorMessage = 'Please select a .glb 3D model file';
        });
        return;
      }
      
      setState(() {
        isUploading = true;
        uploadProgress = 0.0;
        errorMessage = null;
      });
      
      final fileName = 'models/${const Uuid().v4()}$extension';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      
      final uploadTask = storageRef.putFile(file);
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          uploadProgress = progress;
        });
      });
      
      await uploadTask;
      final downloadUrl = await storageRef.getDownloadURL();
      
      setState(() {
        modelPath = downloadUrl;
        isUploading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error uploading model: ${e.toString()}';
        isUploading = false;
      });
    }
  }

  void _removeModel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove 3D Model?'),
        content: const Text(
          'Are you sure you want to remove this 3D model? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                modelPath = null;
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
} 