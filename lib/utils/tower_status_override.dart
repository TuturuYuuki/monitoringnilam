import '../models/camera_model.dart';
import '../models/tower_model.dart';

// Helper untuk cek status DOWN/WARNING
// Tidak ada lagi hardcoded tower numbers - semua data langsung dari database
bool isDownStatus(String status) {
  final normalized = status.toUpperCase();
  return normalized == 'DOWN' || normalized == 'WARNING';
}

String _normalizeStatus(String status) {
  final normalized = status.toUpperCase();
  if (normalized == 'UP') {
    return 'UP';
  }
  if (isDownStatus(normalized)) {
    return 'DOWN';
  }
  return 'UNKNOWN';
}

// Samakan status berdasarkan IP server.
// Jika satu IP DOWN, semua device dengan IP yang sama menjadi DOWN.
// Jika tidak ada yang DOWN tapi ada yang UP, semua menjadi UP.
List<Tower> applyForcedTowerStatus(List<Tower> towers) {
  final ipStatus = <String, String>{};

  for (final tower in towers) {
    final ip = tower.ipAddress.trim();
    if (ip.isEmpty) {
      continue;
    }

    final status = _normalizeStatus(tower.status);
    final current = ipStatus[ip];

    if (current == null) {
      ipStatus[ip] = status;
      continue;
    }

    if (status == 'UP') {
      ipStatus[ip] = 'UP';
    } else if (current != 'UP' && status == 'DOWN') {
      ipStatus[ip] = 'DOWN';
    }
  }

  return towers.map((tower) {
    final ip = tower.ipAddress.trim();
    final forced = ipStatus[ip];
    if (forced == null || forced == 'UNKNOWN') {
      return tower;
    }
    if (tower.status.toUpperCase() == forced) {
      return tower;
    }
    return Tower(
      id: tower.id,
      towerId: tower.towerId,
      towerNumber: tower.towerNumber,
      location: tower.location,
      ipAddress: tower.ipAddress,
      status: forced,
      containerYard: tower.containerYard,
      createdAt: tower.createdAt,
      updatedAt: tower.updatedAt,
    );
  }).toList(growable: false);
}

// Samakan status camera berdasarkan IP server.
// Jika satu IP DOWN, semua camera dengan IP yang sama menjadi DOWN.
// Jika tidak ada yang DOWN tapi ada yang UP, semua menjadi UP.
List<Camera> applyForcedCameraStatus(List<Camera> cameras) {
  final ipStatus = <String, String>{};

  for (final camera in cameras) {
    final ip = camera.ipAddress.trim();
    if (ip.isEmpty) {
      continue;
    }

    final status = _normalizeStatus(camera.status);
    final current = ipStatus[ip];

    if (current == null) {
      ipStatus[ip] = status;
      continue;
    }

    if (status == 'UP') {
      ipStatus[ip] = 'UP';
    } else if (current != 'UP' && status == 'DOWN') {
      ipStatus[ip] = 'DOWN';
    }
  }

  return cameras.map((camera) {
    final ip = camera.ipAddress.trim();
    final forced = ipStatus[ip];
    if (forced == null || forced == 'UNKNOWN') {
      return camera;
    }
    if (camera.status.toUpperCase() == forced) {
      return camera;
    }
    return Camera(
      id: camera.id,
      cameraId: camera.cameraId,
      location: camera.location,
      ipAddress: camera.ipAddress,
      status: forced,
      type: camera.type,
      containerYard: camera.containerYard,
      areaType: camera.areaType,
      createdAt: camera.createdAt,
      updatedAt: camera.updatedAt,
    );
  }).toList(growable: false);
}
