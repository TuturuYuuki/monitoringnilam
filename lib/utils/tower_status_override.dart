import 'package:monitoring/models/camera_model.dart';
import 'package:monitoring/models/tower_model.dart';

// Helper untuk cek status DOWN/WARNING
bool isDownStatus(String status) {
  final normalized = status.toUpperCase().trim();
  return normalized == 'DOWN' || 
         normalized == 'WARNING' || 
         normalized == 'OFFLINE' || 
         normalized == 'UNREACHABLE' ||
         normalized == 'CRITICAL';
}

String _normalizeStatus(String status) {
  final normalized = status.toUpperCase().trim();
  if (normalized == 'UP') {
    return 'UP';
  }
  if (isDownStatus(normalized)) {
    return 'DOWN';
  }
  return 'UNKNOWN';
}

/// Menghapus logika paksaan status antar IP.
/// Sekarang setiap tower akan menggunakan statusnya sendiri dari database.
List<Tower> applyForcedTowerStatus(List<Tower> towers) {
  return towers.map((tower) {
    final status = _normalizeStatus(tower.status);
    if (status == 'UNKNOWN' || tower.status.toUpperCase().trim() == status) {
      return tower;
    }
    return Tower(
      id: tower.id,
      towerId: tower.towerId,
      towerNumber: tower.towerNumber,
      location: tower.location,
      ipAddress: tower.ipAddress,
      status: status,
      containerYard: tower.containerYard,
      createdAt: tower.createdAt,
      updatedAt: tower.updatedAt,
      latitude: tower.latitude,
      longitude: tower.longitude,
    );
  }).toList(growable: false);
}

/// Menghapus logika paksaan status antar IP.
/// Sekarang setiap camera akan menggunakan statusnya sendiri dari database.
List<Camera> applyForcedCameraStatus(List<Camera> cameras) {
  return cameras.map((camera) {
    final status = _normalizeStatus(camera.status);
    if (status == 'UNKNOWN' || camera.status.toUpperCase().trim() == status) {
      return camera;
    }
    return Camera(
      id: camera.id,
      cameraId: camera.cameraId,
      location: camera.location,
      ipAddress: camera.ipAddress,
      status: status,
      type: camera.type,
      containerYard: camera.containerYard,
      areaType: camera.areaType,
      createdAt: camera.createdAt,
      updatedAt: camera.updatedAt,
      latitude: camera.latitude,
      longitude: camera.longitude,
    );
  }).toList(growable: false);
}
