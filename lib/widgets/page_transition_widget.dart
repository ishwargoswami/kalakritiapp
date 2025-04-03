import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

enum PageTransitionType {
  fade,
  slideRight,
  slideLeft,
  slideUp,
  slideDown,
  scale,
  rotate,
}

class PageTransitionWidget extends StatelessWidget {
  final Widget child;
  final PageTransitionType type;
  final Duration duration;
  final Curve curve;

  const PageTransitionWidget({
    Key? key,
    required this.child,
    this.type = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case PageTransitionType.fade:
        return FadeIn(
          duration: duration,
          child: child,
        );
      case PageTransitionType.slideRight:
        return SlideInRight(
          duration: duration,
          child: child,
        );
      case PageTransitionType.slideLeft:
        return SlideInLeft(
          duration: duration,
          child: child,
        );
      case PageTransitionType.slideUp:
        return SlideInUp(
          duration: duration,
          child: child,
        );
      case PageTransitionType.slideDown:
        return SlideInDown(
          duration: duration,
          child: child,
        );
      case PageTransitionType.scale:
        return ZoomIn(
          duration: duration,
          child: child,
        );
      case PageTransitionType.rotate:
        return Bounce(
          duration: duration,
          child: child,
        );
    }
  }
} 