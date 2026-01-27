import '../models/tower_model.dart';

// Towers that should always show as DOWN to reflect known outages
const Set<int> forcedDownTowerNumbers = {2, 10, 21};

bool isForcedDown(int towerNumber) =>
    forcedDownTowerNumbers.contains(towerNumber);

bool isDownStatus(String status) {
  final normalized = status.toUpperCase();
  return normalized == 'DOWN' || normalized == 'WARNING';
}

Tower _cloneWithStatus(Tower tower, String status) {
  return Tower(
    id: tower.id,
    towerId: tower.towerId,
    towerNumber: tower.towerNumber,
    location: tower.location,
    ipAddress: tower.ipAddress,
    deviceCount: tower.deviceCount,
    status: status,
    traffic: tower.traffic,
    uptime: tower.uptime,
    containerYard: tower.containerYard,
    createdAt: tower.createdAt,
  );
}

List<Tower> applyForcedTowerStatus(List<Tower> towers) {
  return towers
      .map((tower) => isForcedDown(tower.towerNumber)
          ? _cloneWithStatus(tower, 'DOWN')
          : tower)
      .toList();
}
