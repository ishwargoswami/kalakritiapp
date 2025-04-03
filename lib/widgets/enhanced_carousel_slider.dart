import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';

class EnhancedCarouselSlider extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Duration autoPlayAnimationDuration;
  final bool enlargeCenterPage;
  final Function(int, CarouselPageChangedReason)? onPageChanged;
  final BorderRadius? borderRadius;

  const EnhancedCarouselSlider({
    Key? key,
    required this.items,
    this.height = 200.0,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.autoPlayAnimationDuration = const Duration(milliseconds: 800),
    this.enlargeCenterPage = true,
    this.onPageChanged,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<EnhancedCarouselSlider> createState() => _EnhancedCarouselSliderState();
}

class _EnhancedCarouselSliderState extends State<EnhancedCarouselSlider> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          items: widget.items.map((item) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: FadeIn(
                    child: GestureDetector(
                      onTap: () {
                        if (item['onTap'] != null) {
                          item['onTap']();
                        }
                      },
                      child: ClipRRect(
                        borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            _buildImage(item),
                            _buildGradientOverlay(item),
                            _buildCaption(item),
                            if (item['badge'] != null)
                              _buildBadge(item),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
          options: CarouselOptions(
            height: widget.height,
            aspectRatio: 16/9,
            viewportFraction: 0.85,
            enlargeCenterPage: widget.enlargeCenterPage,
            enableInfiniteScroll: true,
            autoPlay: widget.autoPlay,
            autoPlayInterval: widget.autoPlayInterval,
            autoPlayAnimationDuration: widget.autoPlayAnimationDuration,
            autoPlayCurve: Curves.fastOutSlowIn,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
              if (widget.onPageChanged != null) {
                widget.onPageChanged!(index, reason);
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildIndicators(),
      ],
    );
  }

  Widget _buildImage(Map<String, dynamic> item) {
    return CachedNetworkImage(
      imageUrl: item['image'],
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(color: Colors.white),
      ),
      errorWidget: (context, url, error) => const Icon(Icons.error),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget _buildGradientOverlay(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            (item['color'] ?? Colors.black).withOpacity(0.8),
          ],
        ),
      ),
    );
  }

  Widget _buildCaption(Map<String, dynamic> item) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['title'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (item['subtitle'] != null) ...[
            const SizedBox(height: 8),
            Text(
              item['subtitle'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
          if (item['button'] != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: item['buttonAction'],
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: item['color'] ?? Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(item['button']),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(Map<String, dynamic> item) {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: item['badgeColor'] ?? Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          item['badge'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.items.asMap().entries.map((entry) {
        final index = entry.key;
        return GestureDetector(
          onTap: () {
            // Instead of animating directly, we use state change
            setState(() {
              _currentIndex = index;
            });
          },
          child: Container(
            width: 10.0,
            height: 10.0,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentIndex == index 
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
        );
      }).toList(),
    );
  }
} 