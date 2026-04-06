import 'package:flutter/material.dart';

class AppDropdownStyle {
  // SolarWinds-inspired dark theme colors
  static const Color menuBackground = Color(0xFF1B2C4E); // Deep navy
  static const Color itemHoverColor = Color(0xFF2A4270); // Brighter navy for hover
  static const Color textColor = Colors.white;
  static const Color iconColor = Colors.white70;
  
  // Layout constants
  static final BorderRadius menuBorderRadius = BorderRadius.circular(12);
  
  // Box Decorations
  static BoxDecoration menuDecoration = BoxDecoration(
    color: menuBackground,
    borderRadius: menuBorderRadius,
    border: Border.all(color: Colors.white.withOpacity(0.12)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 15,
        offset: const Offset(0, 6),
      ),
    ],
  );
  
  // Text Styles
  static const TextStyle itemTextStyle = TextStyle(
    color: textColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}
