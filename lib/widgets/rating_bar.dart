import 'package:flutter/material.dart';

class RatingBar extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final bool showLabel;
  final MainAxisAlignment alignment;

  const RatingBar({
    super.key,
    required this.rating,
    this.size = 18,
    this.color,
    this.showLabel = false,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Colors.amber[700];
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        // Stars
        ...List.generate(5, (index) {
          final starPosition = index + 1;
          final isHalfStar = starPosition > rating && starPosition - 0.5 <= rating;
          final isFullStar = starPosition <= rating;
          
          return Icon(
            isFullStar 
                ? Icons.star 
                : (isHalfStar ? Icons.star_half : Icons.star_border),
            color: starColor,
            size: size,
          );
        }),
        
        // Label
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: size * 0.8,
            ),
          ),
        ],
      ],
    );
  }
} 