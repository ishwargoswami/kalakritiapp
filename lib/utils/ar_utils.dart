import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class ARUtils {
  // Check if AR is potentially supported on the device
  static bool isPotentiallySupportedDevice() {
    // AR is supported on iOS and Android, but not on web or desktop
    if (kIsWeb) return false;
    
    return Platform.isAndroid || Platform.isIOS;
  }
  
  // Get asset path for model
  static String getModelAssetPath(String modelName) {
    return 'assets/models/$modelName';
  }
  
  // Transform a local asset path to a web-compatible path for model_viewer
  static String getModelPath(String assetPath) {
    if (assetPath.isEmpty) {
      return '';
    }
    
    if (assetPath.startsWith('http://')) {
      // Convert HTTP URLs to HTTPS to avoid cleartext traffic issues
      return assetPath.replaceFirst('http://', 'https://');
    } else if (assetPath.startsWith('https://')) {
      // Already a secure URL
      return assetPath;
    } else if (assetPath.startsWith('assets/')) {
      // This is a local asset path
      return assetPath;
    } else {
      // Unknown format, return as is
      return assetPath;
    }
  }
  
  // Get the alien_flowers model path with correct formatting
  static String getDefaultModelPath() {
    return 'assets/models/alien_flowers.glb';
  }
} 