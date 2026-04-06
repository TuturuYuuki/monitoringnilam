import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/models/camera_model.dart';
import 'package:monitoring/constants/terminal_data.dart';

/// 🧪 Mock Data Service for Development & Testing
/// Provides towers and cameras with coordinates from backup data
/// 
/// Use this service when backend is not yet returning coordinates

class MockDataService {
  /// Get towers with coordinates from backup data
  static List<Tower> getMockTowers() {
    List<Tower> towers = [];
    
    for (var point in towerPoints) {
      towers.add(Tower(
        id: point.number,
        towerId: point.name,
        towerNumber: point.number,
        location: 'TPK Nilam - ${point.containerYard}',
        ipAddress: '192.168.1.${100 + point.number}',
        status: point.number % 3 == 0 ? 'DOWN' : 'UP', // Simulate some down devices
        containerYard: point.containerYard,
        createdAt: DateTime.now().subtract(Duration(days: point.number)).toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        latitude: point.latitude,
        longitude: point.longitude,
      ));
    }
    
    return towers;
  }

  /// Get cameras with coordinates from backup data
  static List<Camera> getMockCameras() {
    return [
      Camera(
        id: 1,
        cameraId: 'CC01',
        location: 'CC01 - CY1',
        ipAddress: '192.168.1.201',
        status: 'UP',
        type: 'Fixed',
        containerYard: 'CY1',
        areaType: 'Entry',
        createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        latitude: -7.204768,
        longitude: 112.723299,
      ),
      Camera(
        id: 2,
        cameraId: 'CC02',
        location: 'CC02 - CY1',
        ipAddress: '192.168.1.202',
        status: 'UP',
        type: 'Fixed',
        containerYard: 'CY1',
        areaType: 'Exit',
        createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        latitude: -7.205358,
        longitude: 112.723571,
      ),
      Camera(
        id: 3,
        cameraId: 'CC03',
        location: 'CC03 - CY1',
        ipAddress: '192.168.1.203',
        status: 'DOWN', // Simulate down camera
        type: 'Fixed',
        containerYard: 'CY1',
        areaType: 'Center',
        createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        latitude: -7.205947,
        longitude: 112.723840,
      ),
      Camera(
        id: 4,
        cameraId: 'CC04',
        location: 'CC04 - CY1',
        ipAddress: '192.168.1.204',
        status: 'UP',
        type: 'Fixed',
        containerYard: 'CY1',
        areaType: 'Monitor',
        createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        latitude: -7.206656,
        longitude: 112.724164,
      ),
    ];
  }

  /// Check if device should be in DOWN status for demo purposes
  static bool isDemoDown(String id) {
    return id.hashCode % 5 == 0; // ~20% of devices are down for demo
  }
}
