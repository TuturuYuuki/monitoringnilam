import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/tower_model.dart';
import '../models/camera_model.dart';
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
        Uri.parse('$baseUrl?endpoint=auth&action=profile&user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return User.fromJson(json['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> updateProfile(
      int userId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?endpoint=auth&action=update-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, ...data}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Update failed'};
      }
    } catch (e) {
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
}
