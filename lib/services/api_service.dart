import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:monitoring/models/user_model.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/models/camera_model.dart';
import 'package:monitoring/models/mmt_model.dart';
import 'package:monitoring/models/alert_model.dart';
import 'package:monitoring/models/device_model.dart';
import 'package:monitoring/models/nvr_model.dart';
import 'package:monitoring/models/switch_model.dart';
import 'package:monitoring/services/device_storage_service.dart';
import 'package:intl/intl.dart';
import 'package:monitoring/utils/tower_utils.dart';
import 'package:monitoring/utils/tower_status_override.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String _apiRootOverride =
      String.fromEnvironment('API_ROOT', defaultValue: '');
  static String? _activeApiRoot;
  static bool _hasAttemptedLoad = false;

  static Future<void> ensureInitialized() async {
    if (_hasAttemptedLoad) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRoot = prefs.getString('active_api_root');
      if (savedRoot != null && savedRoot.isNotEmpty) {
        _activeApiRoot = savedRoot;
        debugPrint('ApiService restored root from storage => $savedRoot');
      }
    } catch (e) {
      debugPrint('ApiService failed to load root from storage: $e');
    }
    _hasAttemptedLoad = true;
  }

  static String get _defaultApiRoot => 'http://localhost/monitoring_api';
  
  static String _cleanRoot(String root) {
    if (root.isEmpty) return root;
    // Remove query parameters if any
    if (root.contains('?')) {
      root = root.split('?').first;
    }
    // Remove trailing slash and specific file names
    root = root.replaceAll(RegExp(r'/(index|performance|alerts)\.php$'), '');
    if (root.endsWith('/')) {
      root = root.substring(0, root.length - 1);
    }
    return root;
  }

  static String get _apiRoot {
    String root = _activeApiRoot ?? _apiRootOverride;
    if (root.isEmpty) {
      root = _defaultApiRoot;
    }
    return _cleanRoot(root);
  }

  static String get baseUrl => '$_apiRoot/index.php';
  static String get alertsUrl => '$_apiRoot/alerts.php';
  static String get performanceUrl => '$_apiRoot/performance.php';
  static String get performanceUrlFallback => '$_apiRoot/performance.php';

  static List<String> get _rootCandidates {
    final values = <String>[];
    void add(String v) {
      if (v.isNotEmpty && !values.contains(v)) {
        values.add(v);
      }
    }

    add(_activeApiRoot ?? '');
    if (_apiRootOverride.isNotEmpty) {
      add(_apiRootOverride);
    }
    add(_defaultApiRoot);

    if (!kIsWeb) {
      // Keep localhost without port as fallback, but prefer :8080.
      add('http://localhost/monitoring_api');
      // Android emulator default host mapping.
      add('http://10.0.2.2/monitoring_api');
      add('http://10.0.2.2:8080/monitoring_api');
      add('http://127.0.0.1/monitoring_api');
      add('http://127.0.0.1:8080/monitoring_api');
    }

    return values;
  }

  static List<String> get _authRootCandidates => _rootCandidates;

  static void _setActiveRoot(String root) {
    if (root.isEmpty) return;
    _activeApiRoot = root;
    debugPrint('ApiService active root => $root');
    _saveRoot(root);
  }

  static Future<void> _saveRoot(String root) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_api_root', root);
    } catch (e) {
      debugPrint('ApiService failed to save root: $e');
    }
  }

  // ==================== CONNECTION TEST ====================

  /// Test if Flutter can connect to the backend API
  Future<Map<String, dynamic>> testConnection() async {
    dynamic lastError;
    final candidates = {
      ..._rootCandidates,
      'http://127.0.0.1/monitoring_api',
      'http://localhost/monitoring_api',
    }.toList();

    for (final root in candidates) {
      try {
        debugPrint('🔍 Testing API Candidate: $root/index.php?endpoint=test');
        final response = await http.get(
          Uri.parse('$root/index.php?endpoint=test'),
        ).timeout(const Duration(seconds: 4));

        debugPrint('📡 Response from $root: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          // Relaxed check: if it returns 'path' containing 'monitoring_api', it's ours.
          final isMonitoringApi = (decoded['success'] == true) && 
              (decoded['message']?.toString().contains('Monitoring') == true || 
               decoded['path']?.toString().contains('monitoring_api') == true);

          if (isMonitoringApi) {
            _setActiveRoot(root);
            debugPrint('✅ Found Active Monitoring API at: $root');
            return {
              'success': true,
              'message': 'Connected to Monitoring API',
              'root': root,
              'path': decoded['path'],
            };
          }
        }
        lastError = 'Status: ${response.statusCode} (Not the correct API) @ $root';
      } catch (e) {
        debugPrint('❌ Candidate failed: $root -> $e');
        lastError = '$e @ $root';
      }
    }

    return {
      'success': false,
      'message': 'Backend connection failed: $lastError',
    };
  }

  // ==================== AUTH ENDPOINTS ====================

  Future<Map<String, dynamic>> login(String username, String password) async {
    dynamic lastError;
    for (final root in _authRootCandidates) {
      try {
        debugPrint('Trying Login Root: $root');
        final response = await http.post(
          Uri.parse('$root/index.php?endpoint=auth&action=login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        ).timeout(const Duration(seconds: 5));

          try {
            final decoded = jsonDecode(response.body);
            if (response.statusCode == 200) {
              _setActiveRoot(root);
              return decoded;
            }
            // If server reached but returned 401/400 etc, stop and return its message
            if (response.statusCode == 401 ||
                response.statusCode == 400 ||
                response.statusCode == 403) {
              return {
                'success': false,
                'message': decoded['message'] ?? 'Login failed (${response.statusCode})'
              };
            }
            lastError = decoded['message'] ?? 'Status: ${response.statusCode}';
          } catch (e) {
            lastError = 'Status: ${response.statusCode} - $e';
            if (response.statusCode == 401) {
              return {'success': false, 'message': 'Username atau password salah'};
            }
          }
          continue;
      } catch (e) {
        lastError = e;
      }
    }

    return {
      'success': false,
      'message':
          'Network error: $lastError. For physical Android use adb reverse tcp:8080 tcp:80, or set API_ROOT.'
    };
  }

  Future<Map<String, dynamic>> register(
      String username, String email, String password, String fullname) async {
    dynamic lastError;
    for (final root in _authRootCandidates) {
      try {
        debugPrint('Trying Register Root: $root');
        final response = await http.post(
          Uri.parse('$root/index.php?endpoint=auth&action=register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'email': email,
            'password': password,
            'fullname': fullname,
          }),
        ).timeout(const Duration(seconds: 5));

        try {
          final result = jsonDecode(response.body);
          if (response.statusCode == 200) {
            _setActiveRoot(root);
            return result;
          }
          // If server reached but returned error, stop and return its message
          if (response.statusCode == 409 ||
              response.statusCode == 400 ||
              response.statusCode == 401) {
            return {
              'success': false,
              'message': result['message'] ?? 'Registration failed (${response.statusCode})',
            };
          }
          lastError = result['message'] ?? 'Status: ${response.statusCode}';
        } catch (e) {
          lastError = 'Status: ${response.statusCode} - $e';
        }
        continue;
      } catch (e) {
        lastError = e;
      }
    }

    return {
      'success': false,
      'message':
          'Network error: $lastError. \n\nTips:\n1. Pastikan XAMPP/Apache (MySQL) sudah Aktif.\n2. Jika HP Fisik, jalankan: adb reverse tcp:80 tcp:80 (atau port 8080).\n3. Terakhir gagal di: $lastError'
    };
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
      debugPrint('Error in getProfile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      debugPrint('=== API getUserProfile ===');
      debugPrint('User ID: $userId');

      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=auth&action=get-profile&user_id=$userId'),
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Decoded data: $data');
        return data;
      } else {
        return {'success': false, 'message': 'Failed to get profile'};
      }
    } catch (e) {
      debugPrint('Error in getUserProfile: $e');
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

      debugPrint('=== API updateProfile Request ===');
      debugPrint('URL: $baseUrl?endpoint=auth&action=update-profile');
      debugPrint('Body: $requestBody');

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

      debugPrint('=== API updateProfile Response ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('Decoded Result: $result');

        // Check response success flag
        bool isSuccess = result['success'] == true || result['success'] == 1;
        debugPrint('Is success: $isSuccess');

        return result;
      } else {
        return {
          'success': false,
          'message': 'Update failed with status ${response.statusCode}'
        };
      }
    } catch (e) {
      debugPrint('=== API updateProfile Error ===');
      debugPrint('Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Verify field was actually updated in database
  Future<Map<String, dynamic>> verifyProfileUpdate(
      int userId, String fieldName, dynamic expectedValue) async {
    try {
      debugPrint('=== Verifying $fieldName Update ===');

      final profile = await getProfile(userId);
      if (profile != null) {
        final json = profile.toJson();
        final actualValue = json[fieldName];

        debugPrint('Expected: $expectedValue');
        debugPrint('Actual: $actualValue');

        bool isMatched = actualValue == expectedValue;
        debugPrint('Match: $isMatched');

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
      debugPrint('Error verifying: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> changePassword(
      int userId, String oldPassword, String newPassword) async {
    try {
      final startTime = DateTime.now();
      debugPrint('=== Change Password Request START ===');
      debugPrint('Timestamp: ${startTime.toIso8601String()}');
      debugPrint('User ID: $userId');
      debugPrint('Old Password Length: ${oldPassword.length}');
      debugPrint('New Password Length: ${newPassword.length}');
      debugPrint('Base URL: $baseUrl');
      debugPrint('Full URL: $baseUrl?endpoint=auth&action=change-password');
      debugPrint('About to send HTTP POST request...');

      final requestBody = {
        'user_id': userId,
        'old_password': oldPassword,
        'current_password': oldPassword,
        'password': oldPassword,
        'new_password': newPassword,
        'password_new': newPassword,
        'confirm_password': newPassword,
      };

      debugPrint('Request Body: $requestBody');

      final response = await http
          .post(
        Uri.parse('$baseUrl?endpoint=auth&action=change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          final duration = DateTime.now().difference(startTime);
          debugPrint('❌ TIMEOUT after ${duration.inSeconds} seconds');
          debugPrint('Change password timed out after 12 seconds');
          return http.Response(
              '{"success":false,"message":"Request timeout setelah 12 detik. Backend mungkin tidak dapat diakses dari Flutter."}',
              408);
        },
      );

      final duration = DateTime.now().difference(startTime);
      debugPrint('✓ HTTP Request completed in ${duration.inMilliseconds}ms');
      debugPrint('Change Password Response Status: ${response.statusCode}');
      debugPrint('Change Password Response Body: ${response.body}');
      debugPrint('Response Content-Type: ${response.headers["content-type"]}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✓ SUCCESS - Parsed result: $result');
        debugPrint('=== Change Password Request END (SUCCESS) ===\n');
        return result;
      } else if (response.statusCode == 401) {
        // Unauthorized - wrong old password
        final result = jsonDecode(response.body);
        debugPrint('❌ UNAUTHORIZED - Wrong password');
        debugPrint('=== Change Password Request END (UNAUTHORIZED) ===\n');
        return result;
      } else if (response.statusCode == 404) {
        // User not found
        final result = jsonDecode(response.body);
        debugPrint('❌ NOT FOUND - User not found');
        debugPrint('=== Change Password Request END (NOT FOUND) ===\n');
        return result;
      } else if (response.statusCode == 408) {
        // Timeout
        final result = jsonDecode(response.body);
        debugPrint('❌ TIMEOUT - Request timed out');
        debugPrint('=== Change Password Request END (TIMEOUT) ===\n');
        return result;
      } else {
        debugPrint('⚠️ Unexpected status code: ${response.statusCode}');
        try {
          final result = jsonDecode(response.body);
          debugPrint('=== Change Password Request END (ERROR) ===\n');
          return result;
        } catch (e) {
          debugPrint('=== Change Password Request END (PARSE ERROR) ===\n');
          return {
            'success': false,
            'message': 'Gagal mengubah password (HTTP ${response.statusCode})'
          };
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌❌❌ EXCEPTION in changePassword ❌❌❌');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error message: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('=== Change Password Request END (EXCEPTION) ===\n');
      return {'success': false, 'message': 'Error koneksi: $e'};
    }
  }

  // ==================== FORGOT PASSWORD ENDPOINTS ====================

  /// Send OTP to email for password reset
  Future<Map<String, dynamic>> sendForgotPasswordOtp(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      debugPrint('=== Forgot Password - Send OTP ===');
      debugPrint('Email: $normalizedEmail');

      final response = await http
          .post(
        Uri.parse(alertsUrl.replaceAll('alerts.php', 'forgot_password.php')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': normalizedEmail}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('❌ Request timeout');
          return http.Response(
              '{"success":false,"message":"Request timeout"}', 408);
        },
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

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
      debugPrint('Error in sendForgotPasswordOtp: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Verify OTP for password reset
  Future<Map<String, dynamic>> verifyResetPasswordOtp(
      String email, String otp) async {
    try {
      debugPrint('=== Verify Reset Password OTP ===');
      debugPrint('Email: $email');
      debugPrint('OTP: $otp');

      final response = await http
          .post(
        Uri.parse(alertsUrl.replaceAll('alerts.php', 'verify_reset_otp.php')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('❌ Request timeout');
          return http.Response(
              '{"success":false,"message":"Request timeout"}', 408);
        },
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

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
      debugPrint('Error in verifyResetPasswordOtp: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Reset password with verified OTP
  Future<Map<String, dynamic>> resetPassword(
      String email, String otp, String newPassword) async {
    try {
      debugPrint('=== Reset Password ===');
      debugPrint('Email: $email');
      debugPrint('OTP: $otp');
      debugPrint('New Password Length: ${newPassword.length}');

      final response = await http
          .post(
        Uri.parse(alertsUrl.replaceAll('alerts.php', 'reset_password.php')),
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
          debugPrint('❌ Request timeout');
          return http.Response(
              '{"success":false,"message":"Request timeout"}', 408);
        },
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

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
      debugPrint('Error in resetPassword: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> requestEmailChangeOtp(
      int userId, String newEmail) async {
    try {
      debugPrint('=== API: Request Email Change OTP ===');
      debugPrint('URL: $baseUrl?endpoint=auth&action=request-email-change-otp');
      debugPrint('User ID: $userId');
      debugPrint('New Email: $newEmail');

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

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Decoded Response: $data');
        return data;
      } else {
        debugPrint('Failed with status code: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Gagal meminta OTP (Status: ${response.statusCode})'
        };
      }
    } catch (e) {
      debugPrint('Exception in requestEmailChangeOtp: $e');
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
      debugPrint('=== Direct Field Update Request ===');
      debugPrint('User ID: $userId');
      debugPrint('Field: $fieldName = $fieldValue');

      // Build request body with field name directly
      final requestBody = {
        'user_id': userId,
        fieldName: fieldValue, // Use field name directly
      };

      debugPrint('Request Body: $requestBody');
      debugPrint('URL: $baseUrl?endpoint=auth&action=update-profile');

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

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final result = jsonDecode(response.body);
          debugPrint('Decoded Result: $result');
          return result;
        } catch (e) {
          debugPrint('Error decoding response: $e');
          return {'success': false, 'message': 'Error decoding response'};
        }
      } else {
        debugPrint('HTTP Error ${response.statusCode}');
        return {
          'success': false,
          'message': 'Update failed with status ${response.statusCode}'
        };
      }
    } catch (e) {
      debugPrint('Exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

// Update Access Point
  Future<Map<String, dynamic>> updateTower(
      int id, Map<String, dynamic> data) async {
    try {
      Tower? existingTower;
      try {
        final towers = await getAllTowers();
        for (final tower in towers) {
          if (tower.id == id) {
            existingTower = tower;
            break;
          }
        }
      } catch (_) {}

      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=network&action=update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, ...data}),
      );

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if (result['success'] == true && existingTower != null) {
        final oldType = (existingTower.towerId.toUpperCase().startsWith('AP') ||
                existingTower.location.toUpperCase().contains('AP'))
            ? 'Access Point'
            : 'Tower';
        await DeviceStorageService.updateDeviceFields(
          type: oldType,
          name: existingTower.towerId,
          previousIpAddress: existingTower.ipAddress,
          updates: {
            'type': oldType,
            'name': existingTower.towerId,
            'ipAddress': data['ip_address']?.toString() ?? existingTower.ipAddress,
            'locationName': data['location']?.toString() ?? existingTower.location,
            'containerYard': data['container_yard']?.toString() ?? existingTower.containerYard,
            'status': existingTower.status,
          },
        );
      }

      return result;
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
        // Alert history preserved - alerts remain after device deletion
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
      debugPrint('=== Field by Field Update Start ===');

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
          debugPrint('\nUpdating field: $key = ${data[key]}');

          final variations = fieldVariations[key]!;
          bool updated = false;

          // Try each field name variation
          for (var fieldVariant in variations) {
            final result =
                await _updateSingleField(userId, fieldVariant, data[key]);

            if (result['success'] == true) {
              debugPrint('✓ Successfully updated with field name: $fieldVariant');
              finalResult['results'][key] = result;
              updated = true;
              break;
            } else {
              debugPrint(
                  '✗ Failed with field name: $fieldVariant - ${result['message']}');
              finalResult['results']['${key}_$fieldVariant'] = result;
            }
          }

          if (!updated) {
            finalResult['success'] = false;
            debugPrint('✗ Failed to update $key with any field name variation');
          }
        }
      }

      if (finalResult['success'] == true) {
        final profile = await getProfile(userId);
        if (profile == null) {
          return {
            'success': false,
            'message': 'Update sent, but backend profile could not be verified'
          };
        }

        final profileJson = profile.toJson();

        bool matches(String field, dynamic expected) {
          final actual = profileJson[field]?.toString().trim() ?? '';
          final wanted = expected?.toString().trim() ?? '';
          return actual == wanted;
        }

        final verified =
            (!data.containsKey('fullname') || matches('fullname', data['fullname'])) &&
            (!data.containsKey('email') || matches('email', data['email'])) &&
            (!data.containsKey('username') || matches('username', data['username'])) &&
            (!data.containsKey('phone') ||
                matches('phone', data['phone']) ||
                matches('phone_number', data['phone']) ||
                matches('no_telp', data['phone']) ||
                matches('telp', data['phone'])) &&
            (!data.containsKey('location') ||
                matches('location', data['location']) ||
                matches('lokasi', data['location']) ||
                matches('address', data['location'])) &&
            (!data.containsKey('division') ||
                matches('division', data['division']) ||
                matches('divisi', data['division']));

        if (!verified) {
          debugPrint('✗ Backend verification failed after update: $profileJson');
          return {
            'success': false,
            'message': 'Update response received, but backend data was not persisted'
          };
        }
      }

      debugPrint('\n=== Field by Field Update Complete ===');
      debugPrint('Final Result: $finalResult');
      return finalResult;
    } catch (e) {
      debugPrint('Error in field-by-field update: $e');
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
      debugPrint('Error: $e');
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
      debugPrint('Error fetching master locations: $e');
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

  Future<Map<String, dynamic>> updateMasterLocationPosition(
      int id, double latitude, double longitude) async {
    return updateMasterLocation(id, {
      'latitude': latitude,
      'longitude': longitude,
    });
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
        } else {
          debugPrint('API Error (getTowersByContainerYard): ${json['message'] ?? 'Unknown error'}');
        }
      } else {
        debugPrint('HTTP Error (getTowersByContainerYard): ${response.statusCode} - ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');
      }
      return [];
    } catch (e) {
      debugPrint('Exception (getTowersByContainerYard): $e');
      return [];
    }
  }

  /// Fetches towers for a specific yard, applies status overrides, and sorts them.
  Future<List<Tower>> getValidatedTowersByYard(String yardName) async {
    final rawTowers = await getTowersByContainerYard(yardName);
    return TowerUtils.normalizeAndSortTowers(applyForcedTowerStatus(rawTowers));
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
      debugPrint('Error fetching network stats: $e');
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
        } else {
          debugPrint('API Error (getAllCameras): ${json['message'] ?? 'Unknown error'}');
        }
      } else {
        debugPrint('HTTP Error: ${response.statusCode} - ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');
      }
      return [];
    } catch (e) {
      debugPrint('Exception (getAllCameras): $e');
      return [];
    }
  }

  Future<List<Camera>> getCamerasByContainerYard(String yardName) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl?endpoint=cctv&action=by-yard&container_yard=$yardName'),
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
      debugPrint('Error Fetching $yardName Cameras: $e');
      return [];
    }
  }

  /// Fetches cameras for a specific yard, applies status overrides, and sorts them by ID.
  Future<List<Camera>> getValidatedCamerasByYard(String yardName) async {
    final rawCameras = await getCamerasByContainerYard(yardName);
    final validated = applyForcedCameraStatus(rawCameras);
    validated.sort((a, b) => a.cameraId.compareTo(b.cameraId));
    return validated;
  }

// Fungsi untuk mengupdate data kamera
  Future<Map<String, dynamic>> updateCamera(
      int id, Map<String, dynamic> data) async {
    try {
      Camera? existingCamera;
      try {
        final cameras = await getAllCameras();
        for (final camera in cameras) {
          if (camera.id == id) {
            existingCamera = camera;
            break;
          }
        }
      } catch (_) {}

      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=cctv&action=update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          ...data,
        }),
      );

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Server Error: ${response.statusCode}'
        };
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if (result['success'] == true && existingCamera != null) {
        await DeviceStorageService.updateDeviceFields(
          type: 'CCTV',
          name: existingCamera.cameraId,
          previousIpAddress: existingCamera.ipAddress,
          updates: {
            'type': 'CCTV',
            'name': data['camera_id']?.toString() ?? existingCamera.cameraId,
            'ipAddress': data['ip_address']?.toString() ?? existingCamera.ipAddress,
            'locationName': data['location']?.toString() ?? existingCamera.location,
            'containerYard': data['container_yard']?.toString() ?? existingCamera.containerYard,
            'status': existingCamera.status,
          },
        );
      }

      return result;
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
        // Alert history preserved - alerts remain after device deletion
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
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
      debugPrint('Error fetching cameras by area type: $e');
      return [];
    }
  }

  /// Fetches cameras for a specific area type, applies status overrides, and sorts them by ID.
  Future<List<Camera>> getValidatedCamerasByAreaType(String areaType) async {
    final rawCameras = await getCamerasByAreaType(areaType);
    final validated = applyForcedCameraStatus(rawCameras);
    validated.sort((a, b) => a.cameraId.compareTo(b.cameraId));
    return validated;
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
      debugPrint('Error fetching offline cameras: $e');
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
      debugPrint('Error fetching CCTV stats: $e');
      return {};
    }
  }

  // ==================== MMT ENDPOINTS ====================

  /// Fetches MMTs for a specific yard, applies status overrides, and sorts them by ID.
  Future<List<MMT>> getValidatedMMTsByYard(String yardName) async {
    final rawMMTs = await getMMTsByContainerYard(yardName);
    // Applying same logic as towers if there was an override utility,
    // but for now we'll just sort them.
    rawMMTs.sort((a, b) => a.mmtId.compareTo(b.mmtId));
    return rawMMTs;
  }

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
      debugPrint('Error fetching MMTs: $e');
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
      debugPrint('Error fetching MMTs by yard: $e');
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
      debugPrint('Error fetching MMT: $e');
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
      debugPrint('Error fetching MMT stats: $e');
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


  /// Fetches MMTs by area type (Wait, MMT might only use Yard filtering, check backend if area_type exists).
  /// For now, we will use Yard-based filtering which is consistent with the current implementation.
  Future<List<MMT>> getValidatedMMTsByAreaType(String areaType) async {
    // Current MMT pages use Yard names like 'CY1', 'CY2', etc.
    return getValidatedMMTsByYard(areaType);
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
        '&window_days=30&archive_older=1'
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

    // Use source=ALL to get both current devices and historical alerts (not just empty ARCHIVE)
    final response = await http.get(
      Uri.parse(
          '$baseUrl?endpoint=alerts&action=report&source=ALL&start=$start&end=$end&status=$status'),
    );

    if (response.statusCode == 200) {
      final dynamic jsonResponse = json.decode(response.body);
      
      List<dynamic> targetList = [];
      if (jsonResponse is List) {
        targetList = jsonResponse;
      } else if (jsonResponse is Map && jsonResponse['data'] is List) {
        targetList = jsonResponse['data'] as List;
      }

      debugPrint('getAlertsReport retrieved ${targetList.length} items');

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
          debugPrint('Error parsing individual alert: $e');
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

      debugPrint('Create Tower Response Status: ${response.statusCode}');
      debugPrint('Create Tower Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to create tower'};
      }
    } catch (e) {
      debugPrint('Error creating tower: $e');
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

      debugPrint('Create Camera Response Status: ${response.statusCode}');
      debugPrint('Create Camera Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to create camera'};
      }
    } catch (e) {
      debugPrint('Error creating camera: $e');
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

      debugPrint('Create MMT Response Status: ${response.statusCode}');
      debugPrint('Create MMT Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to create MMT'};
      }
    } catch (e) {
      debugPrint('Error creating MMT: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateMMT(
      int id, Map<String, dynamic> data) async {
    try {
      MMT? existingMMT;
      try {
        final mmts = await getAllMMTs();
        for (final mmt in mmts) {
          if (mmt.id == id) {
            existingMMT = mmt;
            break;
          }
        }
      } catch (_) {}

      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=mmt&action=update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          ...data,
        }),
      );

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if (result['success'] == true && existingMMT != null) {
        final oldType = existingMMT.type.trim().isEmpty ||
                existingMMT.type.trim().toLowerCase() == 'standard'
            ? 'Access Point'
            : existingMMT.type;

        await DeviceStorageService.updateDeviceFields(
          type: oldType,
          name: existingMMT.mmtId,
          previousIpAddress: existingMMT.ipAddress,
          updates: {
            'type': oldType,
            'name': existingMMT.mmtId,
            'ipAddress': data['ip_address']?.toString() ?? existingMMT.ipAddress,
            'locationName': data['location']?.toString() ?? existingMMT.location,
            'containerYard': data['container_yard']?.toString() ?? existingMMT.containerYard,
            'status': existingMMT.status,
          },
        );
      }

      return result;
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
        // Alert history preserved - alerts remain after device deletion
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi Gagal: $e'};
    }
  }

  // Trigger realtime ping untuk semua devices
  Future<Map<String, dynamic>> triggerRealtimePing() async {
    try {
      debugPrint('=== Memulai Realtime Ping (Batas waktu 60 detik) ===');

      final response = await http
          .get(
        Uri.parse('$baseUrl?endpoint=realtime&action=all'),
      )
          .timeout(
        const Duration(
            seconds:
                60), // Memberikan waktu lebih lama untuk proses ping di server
        onTimeout: () {
          debugPrint('❌ Realtime ping GAGAL: Server tidak merespon dalam 60 detik');
          // Mengembalikan response buatan agar catch error bisa menangkapnya
          return http.Response(
              '{"success":false,"message":"Server Timeout"}', 408);
        },
      );

      debugPrint('Realtime Ping Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        debugPrint('✓ Ping Berhasil: ${decodedData['message']}');
        return decodedData;
      } else {
        return {
          'success': false,
          'message': 'Server Error: ${response.statusCode}'
        };
      }
    } catch (e) {
      debugPrint('❌ Error koneksi/ping: $e');
      return {
        'success': false,
        'message': 'Koneksi terputus atau server offline'
      };
    }
  }

  Future<Map<String, dynamic>> getDevicePerformance({
    required String deviceType,
    required String deviceId,
    int? hours,
  }) async {
    try {
      var type = deviceType.trim().toLowerCase();
      final id = deviceId.trim();

      if (type == 'tower' || type == 'ap' || type == 'accesspoint') {
        type = 'access_point';
      } else if (type == 'cctv') {
        type = 'camera';
      }

      if (id.isEmpty ||
          (type != 'access_point' && type != 'camera' && type != 'mmt')) {
        return {
          'success': false,
          'message': 'Invalid performance request parameter'
        };
      }

      final safeHours = (hours ?? 12).clamp(1, 720);

      return _requestPerformanceWithFallback(
        queryParameters: {
          'device_type': type,
          'device_id': id,
          'hours': safeHours.toString(),
        },
        timeoutMessage: 'Performance API timeout',
        defaultMessage: 'Failed to fetch performance telemetry',
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching performance telemetry: $e'
      };
    }
  }

  Future<Map<String, dynamic>> getGlobalDiagnostics({int? hours}) async {
    try {
      final safeHours = (hours ?? 12).clamp(1, 720);
      return _requestPerformanceWithFallback(
        queryParameters: {
          'scope': 'global',
          'hours': safeHours.toString(),
        },
        timeoutMessage: 'Global diagnostics API timeout',
        defaultMessage: 'Failed to fetch global diagnostics',
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching global diagnostics: $e',
      };
    }
  }

  List<Uri> _buildPerformanceCandidateUris({
    required Map<String, String> queryParameters,
  }) {
    final orderedUris = <Uri>[];
    final seen = <String>{};

    void addUri(Uri? uri) {
      if (uri == null) {
        return;
      }
      final key = uri.toString();
      if (seen.add(key)) {
        orderedUris.add(uri);
      }
    }

    Uri? buildPerformanceUriFromRoot(String root) {
      final parsed = Uri.tryParse(root);
      if (parsed == null) {
        return null;
      }
      final basePath = parsed.path.endsWith('/')
          ? parsed.path.substring(0, parsed.path.length - 1)
          : parsed.path;
      final performancePath = '$basePath/performance.php';
      return parsed.replace(
        path: performancePath,
        queryParameters: queryParameters,
      );
    }

    for (final root in _rootCandidates) {
      addUri(buildPerformanceUriFromRoot(root));
    }

    // Keep legacy candidates for compatibility.
    addUri(Uri.tryParse(performanceUrl)?.replace(queryParameters: queryParameters));
    addUri(Uri.tryParse(performanceUrlFallback)
        ?.replace(queryParameters: queryParameters));

    // Final fallback: explicit canonical path.
    final configuredBase = Uri.tryParse(baseUrl);
    if (configuredBase != null) {
      addUri(configuredBase.replace(
        path: '/monitoring_api/performance.php',
        queryParameters: queryParameters,
      ));
    }

    return orderedUris;
  }

  Future<Map<String, dynamic>> _requestPerformanceWithFallback({
    required Map<String, String> queryParameters,
    required String timeoutMessage,
    required String defaultMessage,
  }) async {
    final candidates =
        _buildPerformanceCandidateUris(queryParameters: queryParameters);

    String? lastMessage;
    for (final uri in candidates) {
      try {
        final response = await http.get(uri).timeout(
          const Duration(seconds: 12),
          onTimeout: () => http.Response(
            '{"success":false,"message":"$timeoutMessage"}',
            408,
          ),
        );

        final body = response.body.trimLeft();
        if (!_looksLikeJson(body)) {
          lastMessage = 'Endpoint $uri returned non-JSON response';
          continue;
        }

        final decoded = jsonDecode(body) as Map<String, dynamic>;
        if (response.statusCode == 200 && decoded['success'] == true) {
          _setActiveRoot(_rootFromPerformanceUri(uri));
          return decoded;
        }

        lastMessage = decoded['message']?.toString();
      } catch (e) {
        lastMessage = _friendlyPerformanceError(e, defaultMessage);
      }
    }

    return {
      'success': false,
      'message': lastMessage ??
          '$defaultMessage. Periksa koneksi API backend (localhost/adb reverse/API_ROOT).',
    };
  }

  String _rootFromPerformanceUri(Uri uri) {
    return uri.replace(path: '/monitoring_api', queryParameters: null).toString();
  }

  String _friendlyPerformanceError(Object error, String defaultMessage) {
    final raw = error.toString();
    final lowered = raw.toLowerCase();

    if (lowered.contains('connection refused') ||
        lowered.contains('clientexception') ||
        lowered.contains('socketexception') ||
        lowered.contains('failed host lookup')) {
      return '$defaultMessage: tidak bisa terhubung ke API. '
          'Jika pakai Android device fisik, jalankan adb reverse tcp:8080 tcp:80 atau set API_ROOT.';
    }

    return '$defaultMessage: $raw';
  }

  bool _looksLikeJson(String body) {
    if (body.isEmpty) {
      return false;
    }
    final first = body[0];
    return first == '{' || first == '[';
  }

  // Test connectivity untuk IP spesifik
  Future<Map<String, dynamic>> testDeviceConnectivity({
    required String targetIp,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=device-ping&action=test&ip=$targetIp'),
      );

      debugPrint('Device Connectivity Test Response: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to test connectivity'};
      }
    } catch (e) {
      debugPrint('Error testing device connectivity: $e');
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

      debugPrint('Report Device Status Response Status: ${response.statusCode}');
      debugPrint('Report Device Status Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to report device status'};
      }
    } catch (e) {
      debugPrint('Error reporting device status: $e');
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
      debugPrint('Error updating tower position: $e');
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
      debugPrint('Error updating tower position with history: $e');
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
      debugPrint('Error getting position history: $e');
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
      debugPrint('Error validating position: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  // ==================== NVR METHODS ====================
  Future<List<NVR>> getAllNVRs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?endpoint=nvr&action=all'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List).map((i) => NVR.fromJson(i)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching all NVRs: $e');
      return [];
    }
  }

  Future<List<NVR>> getValidatedNVRsByYard(String yard) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=nvr&action=by-yard&container_yard=$yard'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List).map((i) => NVR.fromJson(i)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching NVRs: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updateNVR(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=nvr&action=update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, ...data}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createNVR(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=nvr&action=create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteNVR(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?endpoint=nvr&action=delete&id=$id'));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== SWITCH METHODS ====================
  Future<List<SwitchModel>> getAllSwitches() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?endpoint=switch&action=all'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List).map((i) => SwitchModel.fromJson(i)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching all Switches: $e');
      return [];
    }
  }

  Future<List<SwitchModel>> getValidatedSwitchesByYard(String yard) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=switch&action=by-yard&container_yard=$yard'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List).map((i) => SwitchModel.fromJson(i)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching Switches: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updateSwitch(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=switch&action=update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, ...data}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createSwitch(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=switch&action=create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteSwitch(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?endpoint=switch&action=delete&id=$id'));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Fetches a true global summary of all devices (Towers, Cameras, MMTs, NVRs, Switches)
  Future<Map<String, int>> getGlobalDeviceSummary() async {
    try {
      final results = await Future.wait([
        getAllTowers(),
        getAllCameras(),
        getAllMMTs(),
        getAllNVRs(),
        getAllSwitches(),
      ]);

      final towers = results[0] as List<Tower>;
      final cameras = results[1] as List<Camera>;
      final mmts = results[2] as List<MMT>;
      final nvrs = results[3] as List<NVR>;
      final switches = results[4] as List<SwitchModel>;

      int up = 0;
      int total = 0;

      total += towers.length;
      up += towers.where((t) => !isDownStatus(t.status)).length;

      total += cameras.length;
      up += cameras.where((c) => !isDownStatus(c.status)).length;

      total += mmts.length;
      // For MMT, we might need special status check if it uses override, 
      // but usually the list status is sufficient for global count.
      up += mmts.where((m) => !isDownStatus(m.status)).length;

      total += nvrs.length;
      up += nvrs.where((n) => !isDownStatus(n.status)).length;

      total += switches.length;
      up += switches.where((s) => !isDownStatus(s.status)).length;

      return {
        'total': total,
        'up': up,
        'down': (total - up).clamp(0, 999999),
      };
    } catch (e) {
      debugPrint('Error in getGlobalDeviceSummary: $e');
      return {'total': 0, 'up': 0, 'down': 0};
    }
  }
}
