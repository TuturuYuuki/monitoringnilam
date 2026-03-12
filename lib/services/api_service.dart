import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/tower_model.dart';
import '../models/camera_model.dart';
import '../models/mmt_model.dart';
import '../models/alert_model.dart';
import '../models/device_model.dart';
import 'device_storage_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class ApiService {
  static const String baseUrl =
      'http://localhost/monitoring_api/index.php'; // Pakai 10.0.2.2 jika Emulator
  static const String alertsUrl = 'http://localhost/monitoring_api/alerts.php';

  // ==================== CONNECTION TEST ====================

  /// Test if Flutter can connect to the backend API
  Future<Map<String, dynamic>> testConnection() async {
    try {
      print('\\n=== Testing Backend Connection ===');
      print('Target URL: $baseUrl');
      print('Attempting Connection...');

      final startTime = DateTime.now();
      final response = await http
          .get(
        Uri.parse('$baseUrl?endpoint=auth&action=check-connection'),
      )
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('❌ Connection Test TIMEOUT After 5 Seconds');
          return http.Response(
            '{"success":False,"Message":"Cannot Reach Backend - Timeout"}',
            408,
          );
        },
      );

      final duration = DateTime.now().difference(startTime);
      print('✓ Response Received in ${duration.inMilliseconds}ms');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 404) {
        // 200 or 404 means we reached the server
        print('✓ Backend is REACHABLE');
        print('=== Connection Test: SUCCESS ===\\n');
        return {
          'success': true,
          'message': 'Backend reachable',
          'responseTime': duration.inMilliseconds,
        };
      } else {
        print('⚠️ Unexpected status: ${response.statusCode}');
        print('=== Connection Test: UNEXPECTED ===\\n');
        return {
          'success': false,
          'message': 'Unexpected response: ${response.statusCode}',
        };
      }
    } catch (e, stackTrace) {
      print('❌❌❌ Connection test FAILED ❌❌❌');
      print('Error: $e');
      print('Stack: $stackTrace');
      print('=== Connection Test: FAILED ===\\n');
      return {
        'success': false,
        'message': 'Cannot connect: $e',
      };
    }
  }

  // ==================== AUTH ENDPOINTS ====================

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=auth&action=login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          // Response bukan JSON valid (kemungkinan HTML error dari backend)
          print('JSON Parse Error: $e');
          print('Response body: ${response.body}');
          return {
            'success': false,
            'message':
                'Server error: Invalid response format. Check backend logs.'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Login failed (Status: ${response.statusCode})'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> register(
      String username, String email, String password, String fullname) async {
    try {
      print('=== Registration Request ===');
      print('Username: $username');
      print('Email: $email');
      print('Fullname: $fullname');

      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=auth&action=register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'fullname': fullname,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Parse response body untuk semua status code
      try {
        final result = jsonDecode(response.body);

        if (response.statusCode == 200) {
          // Success
          return result;
        } else if (response.statusCode == 409) {
          // Conflict - username atau email sudah ada
          print('Conflict: ${result['message']}');
          return {
            'success': false,
            'message':
                result['message'] ?? 'Username atau email sudah terdaftar'
          };
        } else if (response.statusCode == 400) {
          // Bad request - data tidak lengkap
          return {
            'success': false,
            'message': result['message'] ?? 'Data tidak lengkap'
          };
        } else {
          // Other errors
          return {
            'success': false,
            'message': result['message'] ??
                'Registration failed with status: ${response.statusCode}'
          };
        }
      } catch (e) {
        print('JSON decode error: $e');
        return {
          'success': false,
          'message': 'Server error. Response: ${response.body}'
        };
      }
    } catch (e) {
      print('Registration error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<User?> getProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=auth&action=get-profile&user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return User.fromJson(json['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error in getProfile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      print('=== API getUserProfile ===');
      print('User ID: $userId');

      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=auth&action=get-profile&user_id=$userId'),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Decoded data: $data');
        return data;
      } else {
        return {'success': false, 'message': 'Failed to get profile'};
      }
    } catch (e) {
      print('Error in getUserProfile: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateProfile(
      int userId, Map<String, dynamic> data) async {
    try {
      final requestBody = {
        'user_id': userId,
        'fullname': data['fullname'],
        'email': data['email'],
        'username': data['username'],
        // division
        'division': data['division'],
        'divisi': data['division'],
        // phone
        'phone': data['phone'],
        'phone_number': data['phone'],
        'no_telp': data['phone'],
        'telp': data['phone'],
        // location
        'location': data['location'],
        'lokasi': data['location'],
        'address': data['location'],
      };

      print('=== API updateProfile Request ===');
      print('URL: $baseUrl?endpoint=auth&action=update-profile');
      print('Body: $requestBody');

      final response = await http
          .post(
            Uri.parse('$baseUrl?endpoint=auth&action=update-profile'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () => http.Response(
                '{"success":false,"message":"Request timeout setelah 12 detik"}',
                408),
          );

      print('=== API updateProfile Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('Decoded Result: $result');

        // Check response success flag
        bool isSuccess = result['success'] == true || result['success'] == 1;
        print('Is success: $isSuccess');

        return result;
      } else {
        return {
          'success': false,
          'message': 'Update failed with status ${response.statusCode}'
        };
      }
    } catch (e) {
      print('=== API updateProfile Error ===');
      print('Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Verify field was actually updated in database
  Future<Map<String, dynamic>> verifyProfileUpdate(
      int userId, String fieldName, dynamic expectedValue) async {
    try {
      print('=== Verifying $fieldName Update ===');

      final profile = await getProfile(userId);
      if (profile != null) {
        final json = profile.toJson();
        final actualValue = json[fieldName];

        print('Expected: $expectedValue');
        print('Actual: $actualValue');

        bool isMatched = actualValue == expectedValue;
        print('Match: $isMatched');

        return {
          'success': isMatched,
          'field': fieldName,
          'expected': expectedValue,
          'actual': actualValue,
          'matched': isMatched
        };
      }

      return {
        'success': false,
        'message': 'Failed to fetch profile for verification'
      };
    } catch (e) {
      print('Error verifying: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> changePassword(
      int userId, String oldPassword, String newPassword) async {
    try {
      final startTime = DateTime.now();
      print('=== Change Password Request START ===');
      print('Timestamp: ${startTime.toIso8601String()}');
      print('User ID: $userId');
      print('Old Password Length: ${oldPassword.length}');
      print('New Password Length: ${newPassword.length}');
      print('Base URL: $baseUrl');
      print('Full URL: $baseUrl?endpoint=auth&action=change-password');
      print('About to send HTTP POST request...');

      final response = await http
          .post(
        Uri.parse('$baseUrl?endpoint=auth&action=change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      )
          .timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          final duration = DateTime.now().difference(startTime);
          print('❌ TIMEOUT after ${duration.inSeconds} seconds');
          print('Change password timed out after 12 seconds');
          return http.Response(
              '{"success":false,"message":"Request timeout setelah 12 detik. Backend mungkin tidak dapat diakses dari Flutter."}',
              408);
        },
      );

      final duration = DateTime.now().difference(startTime);
      print('✓ HTTP Request completed in ${duration.inMilliseconds}ms');

      print('Change Password Response Status: ${response.statusCode}');
      print('Change Password Response Body: ${response.body}');
      print('Response Content-Type: ${response.headers["content-type"]}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('✓ SUCCESS - Parsed result: $result');
        print('=== Change Password Request END (SUCCESS) ===\n');
        return result;
      } else if (response.statusCode == 401) {
        // Unauthorized - wrong old password
        final result = jsonDecode(response.body);
        print('❌ UNAUTHORIZED - Wrong password');
        print('=== Change Password Request END (UNAUTHORIZED) ===\n');
        return result;
      } else if (response.statusCode == 404) {
        // User not found
        final result = jsonDecode(response.body);
        print('❌ NOT FOUND - User not found');
        print('=== Change Password Request END (NOT FOUND) ===\n');
        return result;
      } else if (response.statusCode == 408) {
        // Timeout
        final result = jsonDecode(response.body);
        print('❌ TIMEOUT - Request timed out');
        print('=== Change Password Request END (TIMEOUT) ===\n');
        return result;
      } else {
        print('⚠️ Unexpected status code: ${response.statusCode}');
        try {
          final result = jsonDecode(response.body);
          print('=== Change Password Request END (ERROR) ===\n');
          return result;
        } catch (e) {
          print('=== Change Password Request END (PARSE ERROR) ===\n');
          return {
            'success': false,
            'message': 'Gagal mengubah password (HTTP ${response.statusCode})'
          };
        }
      }
    } catch (e, stackTrace) {
      print('❌❌❌ EXCEPTION in changePassword ❌❌❌');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      print('=== Change Password Request END (EXCEPTION) ===\n');
      return {'success': false, 'message': 'Error koneksi: $e'};
    }
  }

  // ==================== FORGOT PASSWORD ENDPOINTS ====================

  /// Send OTP to email for password reset
  Future<Map<String, dynamic>> sendForgotPasswordOtp(String email) async {
    try {
      print('=== Forgot Password - Send OTP ===');
      print('Email: $email');

      final response = await http
          .post(
        Uri.parse('http://localhost/monitoring_api/forgot_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('❌ Request timeout');
          return http.Response(
              '{"success":false,"message":"Request timeout"}', 408);
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        try {
          final result = jsonDecode(response.body);
          return result;
        } catch (e) {
          return {'success': false, 'message': 'Failed to send OTP'};
        }
      }
    } catch (e) {
      print('Error in sendForgotPasswordOtp: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Verify OTP for password reset
  Future<Map<String, dynamic>> verifyResetPasswordOtp(
      String email, String otp) async {
    try {
      print('=== Verify Reset Password OTP ===');
      print('Email: $email');
      print('OTP: $otp');

      final response = await http
          .post(
        Uri.parse('http://localhost/monitoring_api/verify_reset_otp.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('❌ Request timeout');
          return http.Response(
              '{"success":false,"message":"Request timeout"}', 408);
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        try {
          final result = jsonDecode(response.body);
          return result;
        } catch (e) {
          return {'success': false, 'message': 'Failed to verify OTP'};
        }
      }
    } catch (e) {
      print('Error in verifyResetPasswordOtp: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Reset password with verified OTP
  Future<Map<String, dynamic>> resetPassword(
      String email, String otp, String newPassword) async {
    try {
      print('=== Reset Password ===');
      print('Email: $email');
      print('OTP: $otp');
      print('New Password Length: ${newPassword.length}');

      final response = await http
          .post(
        Uri.parse('http://localhost/monitoring_api/reset_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        }),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('❌ Request timeout');
          return http.Response(
              '{"success":false,"message":"Request timeout"}', 408);
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        try {
          final result = jsonDecode(response.body);
          return result;
        } catch (e) {
          return {'success': false, 'message': 'Failed to reset password'};
        }
      }
    } catch (e) {
      print('Error in resetPassword: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> requestEmailChangeOtp(
      int userId, String newEmail) async {
    try {
      print('=== API: Request Email Change OTP ===');
      print('URL: $baseUrl?endpoint=auth&action=request-email-change-otp');
      print('User ID: $userId');
      print('New Email: $newEmail');

      final response = await http
          .post(
            Uri.parse('$baseUrl?endpoint=auth&action=request-email-change-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'new_email': newEmail,
            }),
          )
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () => http.Response(
                '{"success":false,"message":"Request timeout setelah 12 detik"}',
                408),
          );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Decoded Response: $data');
        return data;
      } else {
        print('Failed with status code: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Gagal meminta OTP (Status: ${response.statusCode})'
        };
      }
    } catch (e) {
      print('Exception in requestEmailChangeOtp: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyEmailChangeOtp(
      int userId, String newEmail, String otp) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl?endpoint=auth&action=verify-email-change-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'new_email': newEmail,
              'otp_code': otp,
            }),
          )
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () => http.Response(
                '{"success":false,"message":"Request timeout setelah 12 detik"}',
                408),
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Gagal verifikasi OTP'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateProfileField(
      int userId, String fieldName, String fieldValue) async {
    try {
      print('=== Direct Field Update Request ===');
      print('User ID: $userId');
      print('Field: $fieldName = $fieldValue');

      // Build request body with field name directly
      final requestBody = {
        'user_id': userId,
        fieldName: fieldValue, // Use field name directly
      };

      print('Request Body: $requestBody');
      print('URL: $baseUrl?endpoint=auth&action=update-profile');

      final response = await http
          .post(
            Uri.parse('$baseUrl?endpoint=auth&action=update-profile'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () => http.Response(
                '{"success":false,"message":"Request timeout setelah 12 detik"}',
                408),
          );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final result = jsonDecode(response.body);
          print('Decoded Result: $result');
          return result;
        } catch (e) {
          print('Error decoding response: $e');
          return {'success': false, 'message': 'Error decoding response'};
        }
      } else {
        print('HTTP Error ${response.statusCode}');
        return {
          'success': false,
          'message': 'Update failed with status ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

// Update Access Point
  Future<Map<String, dynamic>> updateTower(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=network&action=update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, ...data}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi Gagal: $e'};
    }
  }

// Delete Access Point
  Future<Map<String, dynamic>> deleteTower(int id) async {
    String towerId = '';
    String ipAddress = '';

    try {
      final towers = await getAllTowers();
      final matched = towers.where((t) => t.id == id).toList(growable: false);
      if (matched.isNotEmpty) {
        towerId = matched.first.towerId;
        ipAddress = matched.first.ipAddress;
      }
    } catch (_) {}

    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=network&action=delete&id=$id'),
      );
      final result = jsonDecode(response.body) as Map<String, dynamic>;

      if (result['success'] == true) {
        await DeviceStorageService.removeByTypeAndNameOrIp(
          type: 'Access Point',
          name: towerId,
          ipAddress: ipAddress,
        );
        await DeviceStorageService.removeByTypeAndNameOrIp(
          type: 'Tower',
          name: towerId,
          ipAddress: ipAddress,
        );
        await _deleteAlertsByDevice(
          deviceType: 'ACCESS_POINT',
          deviceId: towerId,
          ipAddress: ipAddress,
        );
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi Gagal: $e'};
    }
  }

  // Enhanced update with field-by-field approach
  Future<Map<String, dynamic>> updateProfileFieldByField(
      int userId, Map<String, dynamic> data) async {
    try {
      print('=== Field by Field Update Start ===');

      Map<String, dynamic> finalResult = {
        'success': true,
        'message': 'All fields updated',
        'results': {}
      };

      // Map field names to database columns - try multiple variations
      final fieldVariations = {
        'fullname': ['fullname'],
        'email': ['email'],
        'username': ['username'],
        'phone': ['phone', 'phone_number', 'no_telp', 'telp'],
        'location': ['location', 'lokasi', 'address'],
        'division': ['division', 'divisi'],
      };

      for (var key in fieldVariations.keys) {
        if (data[key] != null && data[key].toString().isNotEmpty) {
          print('\nUpdating field: $key = ${data[key]}');

          final variations = fieldVariations[key]!;
          bool updated = false;

          // Try each field name variation
          for (var fieldVariant in variations) {
            final result =
                await _updateSingleField(userId, fieldVariant, data[key]);

            if (result['success'] == true) {
              print('✓ Successfully updated with field name: $fieldVariant');
              finalResult['results'][key] = result;
              updated = true;
              break;
            } else {
              print(
                  '✗ Failed with field name: $fieldVariant - ${result['message']}');
              finalResult['results']['${key}_$fieldVariant'] = result;
            }
          }

          if (!updated) {
            finalResult['success'] = false;
            print('✗ Failed to update $key with any field name variation');
          }
        }
      }

      print('\n=== Field by Field Update Complete ===');
      print('Final Result: $finalResult');
      return finalResult;
    } catch (e) {
      print('Error in field-by-field update: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Internal method for single field update
  Future<Map<String, dynamic>> _updateSingleField(
      int userId, String fieldName, dynamic fieldValue) async {
    try {
      final requestBody = {
        'user_id': userId,
        fieldName: fieldValue,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl?endpoint=auth&action=update-profile'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () => http.Response(
                '{"success":false,"message":"Request timeout setelah 12 detik"}',
                408),
          );

      if (response.statusCode == 200) {
        try {
          final result = jsonDecode(response.body);
          return result;
        } catch (e) {
          return {'success': false, 'message': 'Error decoding response'};
        }
      } else {
        return {'success': false, 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

// ==================== DASHBOARD ENDPOINTS ====================

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=dashboard&action=stats'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse[
              'data']; // Berisi: total_towers, total_cameras, total_warnings
        }
      }
      return {'total_towers': 0, 'total_cameras': 0, 'total_warnings': 0};
    } catch (e) {
      debugPrint('Error stats dashboard: $e');
      return {'total_towers': 0, 'total_cameras': 0, 'total_warnings': 0};
    }
  }

  // ==================== NETWORK/TOWER ENDPOINTS ====================

  Future<List<Tower>> getAllTowers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=network&action=all'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          List<Tower> towers = (json['data'] as List)
              .map((item) => Tower.fromJson(item as Map<String, dynamic>))
              .toList();
          return towers;
        }
      }
      return [];
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllMasterLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=network&action=all-locations'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] is List) {
          return (json['data'] as List)
              .whereType<Map>()
              .map(
                  (e) => e.map((key, value) => MapEntry(key.toString(), value)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching master locations: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createMasterLocation({
    required String locationType,
    required String locationCode,
    required String locationName,
    required String containerYard,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=network&action=create-location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'location_type': locationType,
          'location_code': locationCode,
          'location_name': locationName,
          'container_yard': containerYard,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to create master location'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateMasterLocation(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=network&action=update-location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, ...data}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to update master location'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteMasterLocation(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=network&action=delete-location&id=$id'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to delete master location'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Fungsi ini fleksibel untuk CY berapa pun
  Future<List<Tower>> getTowersByContainerYard(String yardName) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl?endpoint=network&action=by-yard&container_yard=$yardName'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          List<Tower> towers = (json['data'] as List)
              .map((item) => Tower.fromJson(item as Map<String, dynamic>))
              .toList();
          return towers;
        }
      }
      return [];
    } catch (e) {
      print('Error Fetching $yardName: $e');
      return [];
    }
  }

  Future<Tower?> getTowerById(int towerId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl?endpoint=accesspoint&action=by-id&tower_id=$towerId'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return Tower.fromJson(json['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getNetworkStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=accesspoint&action=stats'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return json['data'];
        }
      }
      return {};
    } catch (e) {
      print('Error fetching network stats: $e');
      return {};
    }
  }

  // ==================== CCTV/CAMERA ENDPOINTS ====================

  Future<List<Camera>> getAllCameras() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=cctv&action=all'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          List<Camera> cameras = (json['data'] as List)
              .map((item) => Camera.fromJson(item as Map<String, dynamic>))
              .toList();
          return cameras;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching cameras: $e');
      return [];
    }
  }

// Fungsi untuk mengupdate data kamera
  Future<Map<String, dynamic>> updateCamera(
      String cameraId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=cctv&action=update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'camera_id': cameraId,
          'ip_address': data['ip_address'],
          'location': data['location'],
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server Error: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Fungsi untuk menghapus kamera
  Future<Map<String, dynamic>> deleteCamera(String cameraId) async {
    String ipAddress = '';

    try {
      final cameras = await getAllCameras();
      final matched = cameras
          .where((c) => c.cameraId.toLowerCase() == cameraId.toLowerCase())
          .toList(growable: false);
      if (matched.isNotEmpty) {
        ipAddress = matched.first.ipAddress;
      }
    } catch (_) {}

    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=cctv&action=delete&camera_id=$cameraId'),
      );
      final result = jsonDecode(response.body) as Map<String, dynamic>;

      if (result['success'] == true) {
        await DeviceStorageService.removeByTypeAndNameOrIp(
          type: 'CCTV',
          name: cameraId,
          ipAddress: ipAddress,
        );
        await _deleteAlertsByDevice(
          deviceType: 'CCTV',
          deviceId: cameraId,
          ipAddress: ipAddress,
        );
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<Camera>> getCamerasByContainerYard(String containerYard) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl?endpoint=cctv&action=by-yard&container_yard=$containerYard'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          List<Camera> cameras = (json['data'] as List)
              .map((item) => Camera.fromJson(item as Map<String, dynamic>))
              .toList();
          return cameras;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching cameras by yard: $e');
      return [];
    }
  }

  Future<List<Camera>> getCamerasByAreaType(String areaType) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl?endpoint=cctv&action=by-area-type&area_type=$areaType'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          List<Camera> cameras = (json['data'] as List)
              .map((item) => Camera.fromJson(item as Map<String, dynamic>))
              .toList();
          return cameras;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching cameras by area type: $e');
      return [];
    }
  }

  Future<List<Camera>> getOfflineCameras() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=cctv&action=offline'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          List<Camera> cameras = (json['data'] as List)
              .map((item) => Camera.fromJson(item as Map<String, dynamic>))
              .toList();
          return cameras;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching offline cameras: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getCCTVStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=cctv&action=stats'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return json['data'];
        }
      }
      return {};
    } catch (e) {
      print('Error fetching CCTV stats: $e');
      return {};
    }
  }

  // ==================== MMT ENDPOINTS ====================

  Future<List<MMT>> getAllMMTs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=mmt&action=all'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          List<MMT> mmts = (json['data'] as List)
              .map((item) => MMT.fromJson(item as Map<String, dynamic>))
              .toList();
          return mmts;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching MMTs: $e');
      return [];
    }
  }

  Future<List<MMT>> getMMTsByContainerYard(String containerYard) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl?endpoint=mmt&action=by-yard&container_yard=$containerYard'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          List<MMT> mmts = (json['data'] as List)
              .map((item) => MMT.fromJson(item as Map<String, dynamic>))
              .toList();
          return mmts;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching MMTs by yard: $e');
      return [];
    }
  }

  Future<MMT?> getMMTById(int mmtId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=mmt&action=by-id&mmt_id=$mmtId'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return MMT.fromJson(json['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching MMT: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getMMTStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=mmt&action=stats'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return json['data'];
        }
      }
      return {};
    } catch (e) {
      print('Error fetching MMT stats: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> updateMMTStatus(
      String mmtId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=mmt&action=update-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mmt_id': mmtId,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to update MMT status'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ==================== ALERT ENDPOINTS ====================
// ==================== ALERT ENDPOINTS ====================

  /// 1. Ambil SEMUA Alerts (Untuk Halaman Alerts - Realtime/Today) - Dengan Pagination
  Future<Map<String, dynamic>> getAllAlerts({
    int limit = 100,
    int offset = 0,
    String source = 'ALL',
    String status = 'ALL',
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl?endpoint=alerts'
        '&source=${Uri.encodeQueryComponent(source)}'
        '&status=${Uri.encodeQueryComponent(status)}'
        '&limit=$limit&offset=$offset',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        dynamic jsonResponse = json.decode(response.body);

        // Handle both old format (array) and new format (object with data + pagination)
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('data')) {
          // New format with pagination
          final alertData = jsonResponse['data'] as List? ?? [];
          List<Alert> alerts = alertData
              .map((data) => Alert.fromJson(data as Map<String, dynamic>))
              .toList();
          return {
            'alerts': alerts,
            'pagination': jsonResponse['pagination'] ??
                {'total': alerts.length, 'limit': limit, 'offset': offset},
          };
        } else if (jsonResponse is List) {
          // Old format (fallback)
          List<Alert> alerts = jsonResponse
              .map((data) => Alert.fromJson(data as Map<String, dynamic>))
              .toList();
          return {
            'alerts': alerts,
            'pagination': {
              'total': alerts.length,
              'limit': limit,
              'offset': offset
            },
          };
        }
      }
      return {
        'alerts': [],
        'pagination': {'total': 0, 'limit': limit, 'offset': offset}
      };
    } catch (e) {
      debugPrint("Error Fetching All Alerts: $e");
      return {
        'alerts': [],
        'pagination': {'total': 0, 'limit': limit, 'offset': offset}
      };
    }
  }

  Future<List<Alert>> getAlertsReport({
    required DateTime startDate,
    required DateTime endDate,
    required String status,
  }) async {
    // Format tanggal ke YYYY-MM-DD agar dimengerti MySQL
    String start = DateFormat('yyyy-MM-dd').format(startDate);
    String end = DateFormat('yyyy-MM-dd').format(endDate);

    final response = await http.get(
      Uri.parse(
          '$baseUrl?endpoint=alerts&action=report&start=$start&end=$end&status=$status'),
    );

    if (response.statusCode == 200) {
      final dynamic jsonResponse = json.decode(response.body);
      
      List<dynamic> targetList = [];
      if (jsonResponse is List) {
        targetList = jsonResponse;
      } else if (jsonResponse is Map && jsonResponse['data'] is List) {
        targetList = jsonResponse['data'] as List;
      }

      print('DEBUG: getAlertsReport retrieved ${targetList.length} items');

      List<Alert> parsedAlerts = [];
      for (var item in targetList) {
        try {
          if (item is Map) {
            Map<String, dynamic> safeMap = {};
            item.forEach((key, value) {
              safeMap[key.toString()] = value;
            });
            parsedAlerts.add(Alert.fromJson(safeMap));
          }
        } catch (e) {
          print('DEBUG: Error parsing individual alert: $e');
        }
      }
      return parsedAlerts;
    } else {
      throw Exception('Failed To Load Report');
    }
  }

  /// Acknowledge a single alert by its DB id.
  Future<bool> acknowledgeAlert(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$alertsUrl?action=acknowledge&id=$id'),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body)['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('acknowledgeAlert error: $e');
      return false;
    }
  }

  /// Acknowledge all open alerts for a given device_id.
  Future<bool> acknowledgeAlertByDevice(String deviceId) async {
    try {
      final encoded = Uri.encodeQueryComponent(deviceId);
      final response = await http.get(
        Uri.parse('$alertsUrl?action=acknowledge_by_device&device_id=$encoded'),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body)['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('acknowledgeAlertByDevice error: $e');
      return false;
    }
  }

  /// 3. Fungsi Hapus Alert (Disederhanakan menggunakan baseUrl)
  Future<bool> deleteAlert(int id) async {
    try {
      // Perbaikan: Langsung panggil alertsUrl tanpa menumpuk index.php
      final response = await http
          .get(
            Uri.parse('$alertsUrl?action=delete&id=$id'),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("Respon Server: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Mengembalikan true jika PHP mengirim {"success": true}
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint("Gagal hapus alert: $e");
      return false;
    }
  }

  Future<bool> dismissCurrentAlert(String alertKey) async {
    try {
      final encodedKey = Uri.encodeQueryComponent(alertKey);
      final response = await http
          .get(
            Uri.parse(
                '$alertsUrl?action=dismiss_current&alert_key=$encodedKey'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint("Gagal dismiss current alert: $e");
      return false;
    }
  }

  Future<bool> deleteAllAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=alerts&action=delete_all'),
      );

      if (response.statusCode != 200) return false;
      final dynamic data = json.decode(response.body);
      if (data is Map<String, dynamic>) {
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Helper: Filter alert aktif berdasarkan status device
  /// Menghapus alert untuk device yang sudah kembali UP
  Future<List<Alert>> filterActiveAlerts(
    List<Alert> alerts,
    List<Tower> towers,
    List<Camera> cameras,
    List<AddedDevice> devices,
  ) async {
    // Build map of current device status
    final deviceStatus = <String, bool>{}; // true=DOWN, false=UP

    for (final tower in towers) {
      deviceStatus[tower.towerId.toUpperCase()] = _isDeviceDown(tower.status);
    }

    for (final camera in cameras) {
      deviceStatus[camera.cameraId.toUpperCase()] =
          _isDeviceDown(camera.status);
    }

    for (final device in devices) {
      deviceStatus[device.name.toUpperCase()] = _isDeviceDown(device.status);
    }

    // Filter alerts - hanya yang device-nya masih DOWN
    return alerts.where((alert) {
      // Extract device name dari title (misal "AP01 is DOWN" -> "AP01")
      final title = alert.title.toUpperCase();
      final cleanTitle = title.replaceAll(
          RegExp(r'\s+is\s+(down|up)\b', caseSensitive: false), '');

      // Check apakah device ini masih DOWN
      final isStillDown = deviceStatus[cleanTitle] ?? false;

      return isStillDown;
    }).toList(growable: false);
  }

  /// Helper: Cek apakah device dalam status DOWN
  bool _isDeviceDown(String status) {
    final normalized = status.trim().toUpperCase();
    return normalized == 'DOWN' ||
        normalized == 'WARNING' ||
        normalized == 'OFFLINE' ||
        normalized == 'UNREACHABLE';
  }

  /// Helper: Get color untuk status indicator
  Color _getStatusColor(String status) {
    return _isDeviceDown(status) ? Colors.red : Colors.green;
  }

  // Create device methods
  Future<Map<String, dynamic>> createTower({
    required String towerId,
    String? location,
    String? ipAddress,
    required String containerYard,
    required double latitude,
    required double longitude,
    int? deviceCount,
    String? status,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=network&action=create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tower_id': towerId,
          'location': location ?? '',
          'ip_address': ipAddress ?? '',
          'container_yard': containerYard,
          'latitude': latitude,
          'longitude': longitude,
          'device_count': deviceCount ?? 1,
          'status': status ?? 'DOWN',
        }),
      );

      print('Create Tower Response Status: ${response.statusCode}');
      print('Create Tower Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to create tower'};
      }
    } catch (e) {
      print('Error creating tower: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> createCamera({
    required String cameraId,
    required String location,
    required String ipAddress,
    required String containerYard,
    required double latitude,
    required double longitude,
    String? status,
    String? type,
    String? areaType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=cctv&action=create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'camera_id': cameraId,
          'location': location,
          'ip_address': ipAddress,
          'container_yard': containerYard,
          'latitude': latitude,
          'longitude': longitude,
          'status': status ?? 'UP',
          'type': type ?? 'Fixed',
          'area_type': areaType ?? 'Warehouse',
        }),
      );

      print('Create Camera Response Status: ${response.statusCode}');
      print('Create Camera Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to create camera'};
      }
    } catch (e) {
      print('Error creating camera: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> createMMT({
    required String mmtId,
    required String location,
    required String ipAddress,
    required String containerYard,
    String? status,
    String? type,
    int? deviceCount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=mmt&action=create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mmt_id': mmtId,
          'location': location,
          'ip_address': ipAddress,
          'container_yard': containerYard,
          'status': status ?? 'UP',
          'type': type ?? 'Mine Monitor',
          'device_count': deviceCount ?? 1,
        }),
      );

      print('Create MMT Response Status: ${response.statusCode}');
      print('Create MMT Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to create MMT'};
      }
    } catch (e) {
      print('Error creating MMT: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateMMT(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=mmt&action=update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'ip_address': data['ip_address'],
          'location': data['location'],
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi Gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteMMT(int id) async {
    String mmtId = '';
    String ipAddress = '';

    try {
      final mmts = await getAllMMTs();
      final matched = mmts.where((m) => m.id == id).toList(growable: false);
      if (matched.isNotEmpty) {
        mmtId = matched.first.mmtId;
        ipAddress = matched.first.ipAddress;
      }
    } catch (_) {}

    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=mmt&action=delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );
      final result = jsonDecode(response.body) as Map<String, dynamic>;

      if (result['success'] == true) {
        await DeviceStorageService.removeByTypeAndNameOrIp(
          type: 'MMT',
          name: mmtId,
          ipAddress: ipAddress,
        );
        await _deleteAlertsByDevice(
          deviceType: 'MMT',
          deviceId: mmtId,
          ipAddress: ipAddress,
        );
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi Gagal: $e'};
    }
  }

  Future<int> _deleteAlertsByDevice({
    required String deviceType,
    required String deviceId,
    required String ipAddress,
  }) async {
    try {
      final query = StringBuffer('action=delete_by_device');
      if (deviceType.trim().isNotEmpty) {
        query.write('&device_type=${Uri.encodeQueryComponent(deviceType)}');
      }
      if (deviceId.trim().isNotEmpty) {
        query.write('&device_id=${Uri.encodeQueryComponent(deviceId)}');
      }
      if (ipAddress.trim().isNotEmpty) {
        query.write('&ip_address=${Uri.encodeQueryComponent(ipAddress)}');
      }

      final response = await http.get(Uri.parse('$alertsUrl?$query'));
      if (response.statusCode != 200) {
        return 0;
      }

      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['success'] == true) {
        return (data['deleted_rows'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}

    return 0;
  }

  // Trigger realtime ping untuk semua devices
  Future<Map<String, dynamic>> triggerRealtimePing() async {
    try {
      print('=== Memulai Realtime Ping (Batas waktu 60 detik) ===');

      final response = await http
          .get(
        Uri.parse('$baseUrl?endpoint=realtime&action=all'),
      )
          .timeout(
        const Duration(
            seconds:
                60), // Memberikan waktu lebih lama untuk proses ping di server
        onTimeout: () {
          print('❌ Realtime ping GAGAL: Server tidak merespon dalam 60 detik');
          // Mengembalikan response buatan agar catch error bisa menangkapnya
          return http.Response(
              '{"success":false,"message":"Server Timeout"}', 408);
        },
      );

      print('Realtime Ping Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        print('✓ Ping Berhasil: ${decodedData['message']}');
        return decodedData;
      } else {
        return {
          'success': false,
          'message': 'Server Error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Error koneksi/ping: $e');
      return {
        'success': false,
        'message': 'Koneksi terputus atau server offline'
      };
    }
  }

  // Test connectivity untuk IP spesifik
  Future<Map<String, dynamic>> testDeviceConnectivity({
    required String targetIp,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=device-ping&action=test&ip=$targetIp'),
      );

      print('Device Connectivity Test Response: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to test connectivity'};
      }
    } catch (e) {
      print('Error testing device connectivity: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Report device status
  Future<Map<String, dynamic>> reportDeviceStatus({
    required String deviceType,
    required String deviceId,
    required String status,
    required String targetIp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=device-ping&action=report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': deviceType,
          'device_id': deviceId,
          'status': status,
          'target_ip': targetIp,
        }),
      );

      print('Report Device Status Response Status: ${response.statusCode}');
      print('Report Device Status Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to report device status'};
      }
    } catch (e) {
      print('Error reporting device status: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Update tower position (latitude/longitude)
  Future<Map<String, dynamic>> updateTowerPosition(
    int towerId,
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=network&action=update-position'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': towerId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to update tower position'};
      }
    } catch (e) {
      print('Error updating tower position: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Update tower position dengan history tracking (untuk freeroam)
  Future<Map<String, dynamic>> updateTowerPositionWithHistory(
    int towerId,
    double latitude,
    double longitude, {
    String changedBy = 'dragged',
    String changeReason = 'Position update via freeroam',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$baseUrl?endpoint=network&action=update-position-with-history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': towerId,
          'latitude': latitude,
          'longitude': longitude,
          'changed_by': changedBy,
          'change_reason': changeReason,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to update tower position'};
      }
    } catch (e) {
      print('Error updating tower position with history: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get tower position history
  Future<Map<String, dynamic>> getTowerPositionHistory(int towerId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl?endpoint=network&action=get-position-history&tower_id=$towerId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to get position history'};
      }
    } catch (e) {
      print('Error getting position history: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Validate tower position against bounds
  Future<Map<String, dynamic>> validateTowerPosition(
    String containerYard,
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=network&action=validate-position'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'container_yard': containerYard,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to validate position'};
      }
    } catch (e) {
      print('Error validating position: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
