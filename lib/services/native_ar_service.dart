import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

/// Service to access the native AR experience in Android
class NativeArService {
  static const MethodChannel _channel = MethodChannel('com.example.kalakritiapp/ar');
  
  /// Launch the native AR experience on Android
  /// Returns true if successful, false otherwise
  static Future<bool> launchNativeAr() async {
    try {
      if (!Platform.isAndroid) {
        debugPrint('Native AR only supported on Android');
        return false;
      }
      
      final result = await _channel.invokeMethod<bool>('launchAr');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to launch native AR: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error launching native AR: $e');
      return false;
    }
  }
} 