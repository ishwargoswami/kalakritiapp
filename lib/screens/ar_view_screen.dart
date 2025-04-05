import 'package:flutter/material.dart';
import 'package:kalakritiapp/widgets/ar_model_viewer.dart';
import 'package:kalakritiapp/utils/ar_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ARViewScreen extends StatelessWidget {
  final String modelPath;
  final String modelName;

  const ARViewScreen({
    Key? key,
    required this.modelPath,
    required this.modelName,
  }) : super(key: key);

  // Helper method to get correct model path format
  String get _formattedModelPath => ARUtils.getModelPath(modelPath);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR View: $modelName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showARHelpDialog(context),
          ),
        ],
      ),
      body: ARModelViewer(
        modelPath: _formattedModelPath,
        autoRotate: true,
        ar: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        label: const Text('Close'),
        icon: const Icon(Icons.close),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Function() _showARHelpDialog(BuildContext context) {
    return () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Using AR Mode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To place this item in your space:\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '1. Tap the "View in AR" button on the 3D model\n'
                '2. Point your camera at a flat surface\n'
                '3. Move your device slowly until the item appears\n'
                '4. Tap to place the model in your space\n',
              ),
              const Text(
                'Need help?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  _launchUrl('https://developers.google.com/ar/devices');
                },
                child: const Text('Check if your device supports AR'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    };
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
} 