import 'package:flutter/material.dart';

// App color palette
const Color kPrimaryColor = Color(0xFFE65100); // Deep Orange
const Color kSecondaryColor = Color(0xFF2E7D32); // Green
const Color kBackgroundColor = Color(0xFFFFF8E1); // Light Cream
const Color kTextColor = Color(0xFF424242); // Dark Grey
const Color kAccentColor = Color(0xFF9C27B0); // Purple

// App color scheme
final ColorScheme kalakritiColorScheme = ColorScheme(
  primary: kPrimaryColor,
  primaryContainer: kPrimaryColor.withOpacity(0.8),
  secondary: kSecondaryColor,
  secondaryContainer: kSecondaryColor.withOpacity(0.8),
  surface: Colors.white,
  background: kBackgroundColor,
  error: Colors.red,
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onSurface: kTextColor,
  onBackground: kTextColor,
  onError: Colors.white,
  brightness: Brightness.light,
); 