import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/tower_model.dart';
import '../models/camera_model.dart';
import '../models/mmt_model.dart';
import '../models/alert_model.dart';

class ApiService {
  static const String baseUrl = 'http://localhost/monitoring_api/index.php';

  // ==================== AUTH ENDPOINTS ====================

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=auth&action=login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> register(
      String username, String email, String password, String fullname) async {
    try {
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

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          print('JSON decode error: $e');
          return {
            'success': false,
            'message':
                'Server returned invalid response. Please check if XAMPP is running.'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Registration failed with status: ${response.statusCode}'
        };
      }
    } catch (e) {
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

      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=auth&action=update-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('=== API updateProfile Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('Decoded Result: $result');

        // Check response success flag
        bool isSuccess = result['success'] == true || result['success'] == 1;
        print('Is Success: $isSuccess');

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
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=auth&action=change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Gagal mengubah password'};
      }
    } catch (e) {
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

      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=auth&action=request-email-change-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'new_email': newEmail,
        }),
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
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=auth&action=verify-email-change-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'new_email': newEmail,
          'otp_code': otp,
        }),
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

      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=auth&action=update-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
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

      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=auth&action=update-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
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
      print('Error fetching towers: $e');
      return [];
    }
  }

  Future<List<Tower>> getTowersByContainerYard(String containerYard) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl?endpoint=network&action=by-yard&container_yard=$containerYard'),
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
      print('Error fetching towers by yard: $e');
      return [];
    }
  }

  Future<Tower?> getTowerById(int towerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=network&action=by-id&tower_id=$towerId'),
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
        Uri.parse('$baseUrl?endpoint=network&action=stats'),
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

  Future<List<Alert>> getAllAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=alert&action=all'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          List<Alert> alerts = (json['data'] as List)
              .map((item) => Alert.fromJson(item as Map<String, dynamic>))
              .toList();
          return alerts;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching alerts: $e');
      return [];
    }
  }

  Future<List<Alert>> getUnreadAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=alert&action=unread'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          List<Alert> alerts = (json['data'] as List)
              .map((item) => Alert.fromJson(item as Map<String, dynamic>))
              .toList();
          return alerts;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching unread alerts: $e');
      return [];
    }
  }

  Future<List<Alert>> getAlertsBySeverity(String severity) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl?endpoint=alert&action=by-severity&severity=$severity'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          List<Alert> alerts = (json['data'] as List)
              .map((item) => Alert.fromJson(item as Map<String, dynamic>))
              .toList();
          return alerts;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching alerts by severity: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getAlertStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=alert&action=stats'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return json['data'];
        }
      }
      return {};
    } catch (e) {
      print('Error fetching alert stats: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> markAlertAsRead(int alertId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=alert&action=mark-read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'alert_id': alertId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to mark alert as read'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> markAllAlertsAsRead() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=alert&action=mark-all-read'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to mark all alerts as read'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Create device methods
  Future<Map<String, dynamic>> createTower({
    required String towerId,
    required String location,
    required String ipAddress,
    required String containerYard,
    int? deviceCount,
    String? status,
    String? traffic,
    String? uptime,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=network&action=create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tower_id': towerId,
          'location': location,
          'ip_address': ipAddress,
          'container_yard': containerYard,
          'device_count': deviceCount ?? 1,
          'status': status ?? 'UP',
          'traffic': traffic ?? '0 Mbps',
          'uptime': uptime ?? '0%',
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
    String? traffic,
    String? uptime,
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
          'traffic': traffic ?? '0 Mbps',
          'uptime': uptime ?? '0%',
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

  // Device connectivity test
  Future<Map<String, dynamic>> testDeviceConnectivity({
    String targetIp = '10.2.71.60',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=device-ping&action=test&ip=$targetIp'),
      );

      print('Device Ping Test Response Status: ${response.statusCode}');
      print('Device Ping Test Response Body: ${response.body}');

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
    String targetIp = '10.2.71.60',
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
}
