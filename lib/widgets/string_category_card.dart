import 'package:flutter/material.dart';
import 'package:kalakritiapp/screens/category_by_name_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class StringCategoryCard extends StatelessWidget {
  final String categoryName;

  const StringCategoryCard({
    super.key,
    required this.categoryName,
  });

  // Map of category names to image URLs
  static final Map<String, String> categoryImages = {
    'Handicrafts': 'https://images.pexels.com/photos/12029653/pexels-photo-12029653.jpeg',
    'Traditional': 'https://images.pexels.com/photos/6192401/pexels-photo-6192401.jpeg',
    'Handloom Textiles': 'https://images.pexels.com/photos/6193101/pexels-photo-6193101.jpeg',
    'Home Decor': 'https://images.pexels.com/photos/6194021/pexels-photo-6194021.jpeg',
    'Pottery & Ceramics': 'https://images.pexels.com/photos/6258031/pexels-photo-6258031.jpeg',
    'Jewelry': 'https://images.pexels.com/photos/8100784/pexels-photo-8100784.jpeg',
    'Art & Paintings': 'https://images.pexels.com/photos/102127/pexels-photo-102127.jpeg',
    'Wooden Crafts': 'https://images.pexels.com/photos/4871220/pexels-photo-4871220.jpeg',
    'Metal Crafts': 'https://images.pexels.com/photos/3363851/pexels-photo-3363851.jpeg',
    'Gifts & Souvenirs': 'https://images.pexels.com/photos/264771/pexels-photo-264771.jpeg',
    'Featured': 'https://images.pexels.com/photos/6464421/pexels-photo-6464421.jpeg',
    'New Arrivals': 'https://images.pexels.com/photos/6192401/pexels-photo-6192401.jpeg',
    'Best Sellers': 'https://images.pexels.com/photos/11721610/pexels-photo-11721610.jpeg',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryByNameScreen(categoryName: categoryName),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 60,
                width: 60,
                child: CachedNetworkImage(
                  imageUrl: _getCategoryImageUrl(categoryName),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: _getCategoryColor(categoryName, context).withOpacity(0.2),
                    child: Icon(
                      _getCategoryIcon(categoryName),
                      size: 30,
                      color: _getCategoryColor(categoryName, context),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Category name
            Text(
              categoryName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Method to get image URL based on category name
  String _getCategoryImageUrl(String categoryName) {
    // Try to get the exact match first
    if (categoryImages.containsKey(categoryName)) {
      return categoryImages[categoryName]!;
    }
    
    // Try to find a partial match
    for (var entry in categoryImages.entries) {
      if (categoryName.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    
    // Default image
    return 'https://images.pexels.com/photos/6464421/pexels-photo-6464421.jpeg';
  }
  
  // Method to get icon based on category name
  IconData _getCategoryIcon(String categoryName) {
    final lowercaseName = categoryName.toLowerCase();
    
    if (lowercaseName.contains('handicraft')) {
      return Icons.handyman;
    } else if (lowercaseName.contains('handloom') || lowercaseName.contains('textile')) {
      return Icons.design_services;
    } else if (lowercaseName.contains('home') || lowercaseName.contains('decor')) {
      return Icons.home;
    } else if (lowercaseName.contains('pottery') || lowercaseName.contains('ceramic')) {
      return Icons.emoji_objects;
    } else if (lowercaseName.contains('jewelry') || lowercaseName.contains('jewellery')) {
      return Icons.diamond;
    } else if (lowercaseName.contains('painting') || lowercaseName.contains('art')) {
      return Icons.palette;
    } else if (lowercaseName.contains('wooden') || lowercaseName.contains('wood')) {
      return Icons.forest;
    } else if (lowercaseName.contains('metal') || lowercaseName.contains('brass')) {
      return Icons.iron;
    } else if (lowercaseName.contains('traditional')) {
      return Icons.auto_awesome;
    } else if (lowercaseName.contains('gift') || lowercaseName.contains('souvenir')) {
      return Icons.card_giftcard;
    }
    
    // Default icon
    return Icons.category;
  }
  
  // Method to get color based on category name
  Color _getCategoryColor(String categoryName, BuildContext context) {
    final lowercaseName = categoryName.toLowerCase();
    
    if (lowercaseName.contains('handicraft')) {
      return Colors.brown;
    } else if (lowercaseName.contains('handloom') || lowercaseName.contains('textile')) {
      return Colors.indigo;
    } else if (lowercaseName.contains('home') || lowercaseName.contains('decor')) {
      return Colors.teal;
    } else if (lowercaseName.contains('pottery') || lowercaseName.contains('ceramic')) {
      return Colors.amber.shade800;
    } else if (lowercaseName.contains('jewelry') || lowercaseName.contains('jewellery')) {
      return Colors.purple;
    } else if (lowercaseName.contains('painting') || lowercaseName.contains('art')) {
      return Colors.blue;
    } else if (lowercaseName.contains('wooden') || lowercaseName.contains('wood')) {
      return Colors.brown.shade800;
    } else if (lowercaseName.contains('metal') || lowercaseName.contains('brass')) {
      return Colors.blueGrey;
    } else if (lowercaseName.contains('traditional')) {
      return Colors.deepOrange;
    } else if (lowercaseName.contains('gift') || lowercaseName.contains('souvenir')) {
      return Colors.red;
    }
    
    // Default color
    return Theme.of(context).colorScheme.primary;
  }
} 