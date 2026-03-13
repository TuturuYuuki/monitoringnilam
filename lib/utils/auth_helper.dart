import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  // Save user data after login
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Always update core fields
      await prefs.setInt('user_id', userData['id']);
      await prefs.setString('username', userData['username']);
      await prefs.setString('email', userData['email']);
      await prefs.setString('fullname', userData['fullname']);
      await prefs.setString('role', userData['role'] ?? '');

      // Merge optional fields without wiping existing values when missing
      final existingPhone = prefs.getString('phone') ?? '';
      final existingLocation = prefs.getString('location') ?? '';
      final existingDivision = prefs.getString('division') ?? '';

      final newPhone = (userData.containsKey('phone') &&
              (userData['phone'] ?? '').toString().isNotEmpty)
          ? userData['phone']
          : existingPhone;
      final newLocation = (userData.containsKey('location') &&
              (userData['location'] ?? '').toString().isNotEmpty)
          ? userData['location']
          : existingLocation;
      final newDivision = (userData.containsKey('division') &&
              (userData['division'] ?? '').toString().isNotEmpty)
          ? userData['division']
          : existingDivision;

      await prefs.setString('phone', newPhone);
      await prefs.setString('location', newLocation);
      await prefs.setString('division', newDivision);
    } catch (e) {
      // Gracefully handle SharedPreferences errors (e.g., MissingPluginException on Windows)
      print('Warning: Could not save user data to preferences: $e');
    }
  }

  // Get user data
  static Future<Map<String, String>> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'user_id': prefs.getInt('user_id')?.toString() ?? '',
        'username': prefs.getString('username') ?? '',
        'email': prefs.getString('email') ?? '',
        'fullname': prefs.getString('fullname') ?? '',
        'role': prefs.getString('role') ?? '',
        'phone': prefs.getString('phone') ?? '',
        'location': prefs.getString('location') ?? '',
        'division': prefs.getString('division') ?? '',
      };
    } catch (e) {
      // Return empty user data if preferences unavailable
      return {
        'user_id': '',
        'username': '',
        'email': '',
        'fullname': '',
        'role': '',
        'phone': '',
        'location': '',
        'division': '',
      };
    }
  }

  // Clear user data on logout
  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      // Gracefully handle SharedPreferences errors on Windows
      print('Warning: Could not clear user data from preferences: $e');
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('user_id');
    } catch (e) {
      // Handle MissingPluginException on Windows or other platforms
      // Default to not logged in if prefs unavailable
      return false;
    }
  }
}