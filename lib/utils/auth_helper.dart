import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  // Save user data after login
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userData['id']);
    await prefs.setString('username', userData['username']);
    await prefs.setString('email', userData['email']);
    await prefs.setString('fullname', userData['fullname']);
    await prefs.setString('role', userData['role']);
    await prefs.setString('phone', userData['phone'] ?? '');
    await prefs.setString('location', userData['location'] ?? '');
    await prefs.setString('division', userData['division'] ?? '');
  }

  // Get user data
  static Future<Map<String, String>> getUserData() async {
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
  }

  // Clear user data on logout
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user_id');
  }
}
