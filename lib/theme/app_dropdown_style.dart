import 'package:flutter/material.dart';

class AppDropdownStyle {
  // SolarWinds-inspired dark theme colors
  static const Color menuBackground = Color(0xFF1C2A3E); // Deep navy from header
  static const Color itemHoverColor = Color(0xFF2A3650); // Subtle hover
  static const Color accentColor = Color(0xFF3B82F6); // Standard tech blue
  static const Color textColor = Colors.white;
  static const Color textColorDim = Colors.white70;
  static const Color iconColor = Colors.white70;
  static const Color standardPageBackground = Color(0xFF1E293B); // Standard background for all pages
  
  // Layout constants
  static final BorderRadius menuBorderRadius = BorderRadius.circular(16);
  
  // Box Decorations
  static BoxDecoration menuDecoration = BoxDecoration(
    color: menuBackground,
    borderRadius: menuBorderRadius,
    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
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
