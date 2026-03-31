import 'package:flutter/material.dart';

/// Shared dropdown menu overlay: rounded + semi-opaque dark for readability.
abstract final class AppDropdownStyle {
  static const Color menuBackground = Color(0xE6283238);
  static BorderRadius get menuBorderRadius => BorderRadius.circular(20);
}
