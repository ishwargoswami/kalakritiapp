import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Utility class for image-related functions
class ImageUtils {
  /// Check if an image URL is valid
  static Future<bool> isValidImageUrl(String url) async {
    try {
      final response = await HttpClient().getUrl(Uri.parse(url))
        ..close();
      return response.statusCode == HttpStatus.ok;
    } catch (e) {
      return false;
    }
  }
  
  /// Get a fallback image URL based on category
  static String getFallbackImageUrl(String category) {
    switch (category.toLowerCase()) {
      case 'handicrafts':
        return 'https://images.pexels.com/photos/12029653/pexels-photo-12029653.jpeg';
      case 'traditional':
        return 'https://images.pexels.com/photos/6192401/pexels-photo-6192401.jpeg';
      case 'handloom textiles':
        return 'https://images.pexels.com/photos/6193101/pexels-photo-6193101.jpeg';
      case 'home decor':
        return 'https://images.pexels.com/photos/6194021/pexels-photo-6194021.jpeg';
      case 'pottery & ceramics':
        return 'https://images.pexels.com/photos/6258031/pexels-photo-6258031.jpeg';
      default:
        return 'https://images.pexels.com/photos/6464421/pexels-photo-6464421.jpeg';
    }
  }
  
  /// Clear the image cache
  static void clearImageCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
  
  /// Create a widget for displaying a product placeholder
  static Widget buildProductPlaceholder(
    String productName, 
    {double? height, double? width, Color? backgroundColor}
  ) {
    return Container(
      height: height,
      width: width,
      color: backgroundColor ?? Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey[400],
            size: 36,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              productName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 