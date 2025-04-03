import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';

enum AnimatedNavItemType { home, category, rentals, wishlist, cart, profile }

class AnimatedNavigation extends StatefulWidget {
  final AnimatedNavItemType selectedItem;
  final Function(AnimatedNavItemType) onItemSelected;
  final int wishlistCount;
  final int cartItemCount;

  const AnimatedNavigation({
    Key? key,
    required this.selectedItem,
    required this.onItemSelected,
    this.wishlistCount = 0,
    this.cartItemCount = 0,
  }) : super(key: key);

  @override
  State<AnimatedNavigation> createState() => _AnimatedNavigationState();
}

class _AnimatedNavigationState extends State<AnimatedNavigation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
      child: FadeInUp(
        duration: const Duration(milliseconds: 400),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                AnimatedNavItemType.home,
                'Home',
                Icons.home_outlined,
                Icons.home,
              ),
              _buildNavItem(
                AnimatedNavItemType.category,
                'Categories',
                Icons.category_outlined,
                Icons.category,
              ),
              _buildNavItem(
                AnimatedNavItemType.rentals,
                'Rentals',
                Icons.watch_later_outlined,
                Icons.watch_later,
              ),
              _buildNavItem(
                AnimatedNavItemType.wishlist,
                'Wishlist',
                Icons.favorite_border,
                Icons.favorite,
                hasNotification: widget.wishlistCount > 0,
                count: widget.wishlistCount,
              ),
              _buildNavItem(
                AnimatedNavItemType.cart,
                'Cart',
                Icons.shopping_cart_outlined,
                Icons.shopping_cart,
                hasNotification: widget.cartItemCount > 0,
                count: widget.cartItemCount,
              ),
              _buildNavItem(
                AnimatedNavItemType.profile,
                'Profile',
                Icons.person_outline,
                Icons.person,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    AnimatedNavItemType type,
    String label,
    IconData icon,
    IconData activeIcon, {
    bool hasNotification = false,
    int count = 0,
  }) {
    final isSelected = widget.selectedItem == type;
    
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          _controller.reset();
          _controller.forward();
          widget.onItemSelected(type);

          // Add haptic feedback
          HapticFeedback.lightImpact();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.grey,
                    size: 22,
                  ),
                  if (hasNotification)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 