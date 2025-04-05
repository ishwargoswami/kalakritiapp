import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class ARModelViewer extends StatelessWidget {
  final String modelPath;
  final bool autoRotate;
  final bool ar;
  final bool cameraControls;
  final Color backgroundColor;
  
  const ARModelViewer({
    Key? key,
    required this.modelPath,
    this.autoRotate = true,
    this.ar = true,
    this.cameraControls = true,
    this.backgroundColor = Colors.transparent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (modelPath.isEmpty) {
      return Container(
        color: backgroundColor,
        child: const Center(
          child: Text('No 3D model available'),
        ),
      );
    }
    
    // Different handling for web vs mobile
    return Container(
      color: backgroundColor,
      child: ModelViewer(
        src: modelPath,
        alt: '3D Model',
        ar: ar && !kIsWeb && (Platform.isAndroid || Platform.isIOS),
        autoRotate: autoRotate,
        cameraControls: cameraControls,
        disableZoom: false,
        loading: Loading.lazy,
        backgroundColor: Colors.transparent,
        relatedCss: '''
          model-viewer {
            --poster-color: transparent;
            --progress-bar-color: transparent;
          }
        ''',
        // Add HTTPS requirement for Android
        iosSrc: modelPath.startsWith('http:') ? modelPath.replaceFirst('http:', 'https:') : modelPath,
      ),
    );
  }
} 