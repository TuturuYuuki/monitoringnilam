// 🎯 navigation_helper.dart
// Centralized navigation management dengan error handling

import 'package:flutter/material.dart';

class NavigationHelper {
  /// Safe navigation dengan error handling
  static Future<void> navigateTo(
    BuildContext context,
    String routeName, {
    bool replace = false,
    dynamic arguments,
  }) async {
    try {
      if (context.mounted) {
        if (replace) {
          await Navigator.of(context).pushReplacementNamed(
            routeName,
            arguments: arguments,
          );
        } else {
          await Navigator.of(context).pushNamed(
            routeName,
            arguments: arguments,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Navigation Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation failed: $routeName'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Navigate and clear all previous routes
  static Future<void> navigateAndClear(
    BuildContext context,
    String routeName, {
    dynamic arguments,
  }) async {
    try {
      if (context.mounted) {
        await Navigator.of(context).pushNamedAndRemoveUntil(
          routeName,
          (route) => false,
          arguments: arguments,
        );
      }
    } catch (e) {
      debugPrint('❌ Navigation Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation failed: $routeName'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Pop with result
  static void popWithResult<T>(BuildContext context, T result) {
    try {
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      debugPrint('❌ Pop Error: $e');
    }
  }

  /// Simple pop
  static void pop(BuildContext context) {
    try {
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Pop Error: $e');
    }
  }
}
