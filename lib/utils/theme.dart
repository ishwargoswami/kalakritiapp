import 'package:flutter/material.dart';

// App color palette
const Color kPrimaryColor = Color(0xFF111D4A); // Dark Navy
const Color kSecondaryColor = Color(0xFF3587A4); // Teal
const Color kBackgroundColor = Color(0xFFDDFFF7); // Light Mint
const Color kTextColor = Color(0xFF235277); // Medium Blue
const Color kAccentColor = Color(0xFFC62E65); // Pink/Fuchsia
const Color kSlateGray = Color(0xFF778EA1); // Slate Gray
const Color kRose = Color(0xFFD76E8E); // Rose
const Color kLightPink = Color(0xFFE8AEB7); // Light Pink

// App color scheme
final ColorScheme kalakritiColorScheme = ColorScheme(
  primary: kPrimaryColor,
  primaryContainer: kPrimaryColor.withOpacity(0.8),
  secondary: kSecondaryColor,
  secondaryContainer: kRose,
  surface: Colors.white,
  background: kBackgroundColor,
  error: kAccentColor,
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onSurface: kTextColor,
  onBackground: kTextColor,
  onError: Colors.white,
  brightness: Brightness.light,
); 