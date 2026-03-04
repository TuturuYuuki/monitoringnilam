import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../models/tower_model.dart';

/// Tower Coordinate Fallback Map
/// Extracted from coordinates_backup.dart
/// Key format: "Tower {number}" or "{towerNumber}" or location name
/// Used when API doesn't provide lat/lng data
class TowerCoordinateFallback {
  static const Map<int, Map<String, double>> byTowerNumber = {
    // CY2 Towers (1-6)
    1: {'lat': -7.209459, 'lng': 112.724717},
    2: {'lat': -7.209191, 'lng': 112.725250},
    3: {'lat': -7.208561, 'lng': 112.724946},
    4: {'lat': -7.208150, 'lng': 112.724395},
    5: {'lat': -7.208262, 'lng': 112.724161},
    6: {'lat': -7.208956, 'lng': 112.724173},
    // CY1 Towers (7-17)
    7: {'lat': -7.207690, 'lng': 112.723693},
    8: {'lat': -7.207567, 'lng': 112.723945},
    9: {'lat': -7.207156, 'lng': 112.724302},
    10: {'lat': -7.204341, 'lng': 112.722956},
    11: {'lat': -7.204080, 'lng': 112.722354},
    12: {'lat': -7.204228, 'lng': 112.722045},
    13: {'lat': -7.204460, 'lng': 112.721970},
    14: {'lat': -7.205410, 'lng': 112.722386},
    15: {'lat': -7.206786, 'lng': 112.723023},
    16: {'lat': -7.207566, 'lng': 112.723469},
    17: {'lat': -7.207342, 'lng': 112.723059},
    18: {'lat': -7.209240, 'lng': 112.723915},
    // CY3 Towers (19-27)
    19: {'lat': -7.210090, 'lng': 112.724321},
    20: {'lat': -7.210336, 'lng': 112.723639},
    21: {'lat': -7.210082, 'lng': 112.723303},
    22: {'lat': -7.209070, 'lng': 112.722914},
    23: {'lat': -7.208501, 'lng': 112.722942},
    24: {'lat': -7.208017, 'lng': 112.722195},
    25: {'lat': -7.207314, 'lng': 112.722005},
    26: {'lat': -7.207213, 'lng': 112.722232},
    27: {'lat': -7.207029, 'lng': 112.722613},
  };

  static Map<String, double>? getCoordinates(Tower tower) {
    if (tower.towerNumber > 0 && byTowerNumber.containsKey(tower.towerNumber)) {
      return byTowerNumber[tower.towerNumber];
    }

    final idMatch = RegExp(r'(\d+)').firstMatch(tower.towerId);
    if (idMatch != null) {
      final num = int.tryParse(idMatch.group(1) ?? '');
      if (num != null && num > 0 && byTowerNumber.containsKey(num)) {
        return byTowerNumber[num];
      }
    }

    return null;
  }
}

class ContainerYardArea {
  final String id;
  final String label;
  final Color bgColor;
  final Color borderColor;
  final double left, top, width, height;

  ContainerYardArea({
    required this.id,
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

class StaticTowerPoint {
  final int number;
  final String label;
  final double latitude;
  final double longitude;
  final String containerYard;
  final String? towerIdHint;

  const StaticTowerPoint({
    required this.number,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.containerYard,
    this.towerIdHint,
  });
}

class TerminalLayoutStatic extends StatefulWidget {
  final List<AddedDevice> devices;
  final List<Tower> towers;
  final List<StaticTowerPoint> towerPoints;
  final Function(AddedDevice)? onDeviceTap;

  const TerminalLayoutStatic({
    super.key,
    required this.devices,
    this.towers = const [],
    this.towerPoints = const [],
    this.onDeviceTap,
  });

  @override
  State<TerminalLayoutStatic> createState() => _TerminalLayoutStaticState();
}

class _TerminalLayoutStaticState extends State<TerminalLayoutStatic> {
  late List<ContainerYardArea> areas;
  AddedDevice? _selectedDevice;
  String? _zoomedAreaId;
  Tower? _selectedTower;
  List<AddedDevice> _devicesAtTower = [];

  static const Map<String, Map<String, double>> _towerPos = {
    'Tower 10 - CY1': {'cx': 0.04, 'cy': 0.22},
    'Tower 11 - CY1': {'cx': 0.04, 'cy': 0.42},
    'Tower 12A - CY1': {'cx': 0.03, 'cy': 0.62},
    'Tower 12 - CY1': {'cx': 0.03, 'cy': 0.80},
    'Tower 13 - CY1': {'cx': 0.20, 'cy': 0.78},
    'Tower 14 - CY1': {'cx': 0.38, 'cy': 0.82},
    'Tower 16 - CY1': {'cx': 0.52, 'cy': 0.78},
    'Tower 15 - CY1': {'cx': 0.60, 'cy': 0.88},
    'Tower 7 - CY1': {'cx': 0.68, 'cy': 0.88},
    'Tower 8 - CY1': {'cx': 0.74, 'cy': 0.84},
    'Tower 9 - CY1': {'cx': 0.82, 'cy': 0.74},
    'Tower 17 - CY1': {'cx': 0.95, 'cy': 0.88},
    // CY2 - berbagai format varian
    'Tower 1 - CY2': {'cx': 0.93, 'cy': 0.75},
    'Tower 1 - CY 2': {'cx': 0.93, 'cy': 0.75},
    'Tower 2 - CY2': {'cx': 0.93, 'cy': 0.08},
    'Tower 2 - CY 2': {'cx': 0.93, 'cy': 0.08},
    'Tower 3 - CY2': {'cx': 0.05, 'cy': 0.05},
    'Tower 3 - CY 2': {'cx': 0.05, 'cy': 0.05},
    'Tower 4 - CY2': {'cx': 0.05, 'cy': 0.35},
    'Tower 4 - CY 2': {'cx': 0.05, 'cy': 0.35},
    'Tower 5 - CY2': {'cx': 0.05, 'cy': 0.70},
    'Tower 5 - CY 2': {'cx': 0.05, 'cy': 0.70},
    'Tower 6 - CY2': {'cx': 0.50, 'cy': 0.88},
    'Tower 6 - CY 2': {'cx': 0.50, 'cy': 0.88},
    'Tower 26 - CY3': {'cx': 0.04, 'cy': 0.18},
    'Tower 25 - CY3': {'cx': 0.04, 'cy': 0.38},
    'Tower 24 - CY3': {'cx': 0.03, 'cy': 0.56},
    'Tower 23 - CY3': {'cx': 0.08, 'cy': 0.75},
    'Tower 22 - CY3': {'cx': 0.14, 'cy': 0.88},
    'Tower 21 - CY3': {'cx': 0.25, 'cy': 0.84},
    'Tower 20 - CY3': {'cx': 0.38, 'cy': 0.88},
    'Tower 19 - CY3': {'cx': 0.52, 'cy': 0.92},
    'Tower 18 - CY3': {'cx': 0.84, 'cy': 0.18},
  };

  @override
  void initState() {
    super.initState();
    _initializeLayout();
  }

  void _initializeLayout() {
    areas = [
      ContainerYardArea(
        id: 'CY1',
        label: 'CY 1',
        bgColor: const Color(0xFFF5DEB3).withOpacity(0.7),
        borderColor: const Color(0xFFD2B48C),
        left: 0.02,
        top: 0.04,
        width: 0.56,
        height: 0.44,
      ),
      ContainerYardArea(
        id: 'CY2',
        label: 'CY 2',
        bgColor: const Color(0xFFC8E6C9).withOpacity(0.7),
        borderColor: const Color(0xFF66BB6A),
        left: 0.60,
        top: 0.04,
        width: 0.38,
        height: 0.44,
      ),
      ContainerYardArea(
        id: 'PARKING',
        label: 'PARKING AREA',
        bgColor: const Color(0xFFBBDEFB).withOpacity(0.7),
        borderColor: const Color(0xFF2196F3),
        left: 0.60,
        top: 0.52,
        width: 0.18,
        height: 0.44,
      ),
      ContainerYardArea(
        id: 'CY3',
        label: 'CY 3',
        bgColor: const Color(0xFFF8BBBB).withOpacity(0.7),
        borderColor: const Color(0xFFE57373),
        left: 0.02,
        top: 0.52,
        width: 0.56,
        height: 0.44,
      ),
      ContainerYardArea(
        id: 'GATE',
        label: 'GATE IN/OUT',
        bgColor: const Color(0xFFFFF9C4).withOpacity(0.7),
        borderColor: const Color(0xFFFBC02D),
        left: 0.80,
        top: 0.52,
        width: 0.18,
        height: 0.44,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            if (_zoomedAreaId == null) ...[
              ...areas.map((area) => _buildAreaBox(area, w, h)),
              ..._buildAllMarkers(w, h),
              ..._buildTowerMarkers(w, h),
            ] else ...[
              _buildZoomedArea(w, h),
            ],
            if (_selectedDevice != null) _buildSelectedInfo(),
            if (_selectedTower != null) _buildTowerInfo(),
          ],
        );
      },
    );
  }

  Widget _buildAreaBox(ContainerYardArea area, double w, double h) {
    return Positioned(
      left: area.left * w,
      top: area.top * h,
      width: area.width * w,
      height: area.height * h,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _zoomedAreaId = area.id),
          child: Container(
            decoration: BoxDecoration(
              color: area.bgColor,
              border: Border.all(color: area.borderColor, width: 2.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      area.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const Icon(Icons.zoom_in, size: 16, color: Colors.black54),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomedArea(double w, double h) {
    final area = areas.firstWhere((a) => a.id == _zoomedAreaId, orElse: () => areas.first);
    final devicesInArea = widget.devices.where((d) => _findTargetArea(d).id == area.id).toList();

    return Positioned(
      left: 10,
      top: 10,
      width: w - 20,
      height: h - 20,
      child: GestureDetector(
        onTap: () => setState(() => _zoomedAreaId = null),
        child: Container(
          decoration: BoxDecoration(
            color: area.bgColor,
            border: Border.all(color: area.borderColor, width: 3.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 10,
                left: 12,
                child: Text(
                  area.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Text(
                  'Tap area untuk keluar',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ..._buildZoomedMarkers(devicesInArea, w - 20, h - 20),
              ..._buildZoomedTowerMarkers(area, w - 20, h - 20),
              // DEBUG — tampilkan info tower yang tidak ketemu posisinya
              // Hapus setelah semua tower sudah muncul dengan benar
              ...() {
                final missingTowers = widget.towers
                    .where((t) => _normalizeAreaId(t.containerYard) == area.id)
                    .where((t) => _resolveTowerPosition(t) == null)
                    .toList();
                
                return missingTowers.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final t = entry.value;
                  return Positioned(
                    bottom: 8.0 + (idx * 50.0),
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '❌ TOWER TIDAK KETEMU (${idx + 1}/${missingTowers.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'location: "${t.location}"',
                            style: const TextStyle(color: Colors.yellow, fontSize: 9),
                          ),
                          Text(
                            'towerId: "${t.towerId}"',
                            style: const TextStyle(color: Colors.yellow, fontSize: 9),
                          ),
                          Text(
                            'towerNumber: ${t.towerNumber}',
                            style: const TextStyle(color: Colors.yellow, fontSize: 9),
                          ),
                          Text(
                            'containerYard: "${t.containerYard}"',
                            style: const TextStyle(color: Colors.yellow, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList();
              }(),
            ],
          ),
        ),
      ),
    );
  }

  String _normalizeTowerKey(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  Map<String, double>? _resolveTowerPosition(Tower tower) {
    // 1. Coba exact match dulu
    if (_towerPos.containsKey(tower.location)) {
      debugPrint('[TowerPos] ✓ Exact match: "${tower.location}"');
      return _towerPos[tower.location];
    }

    // 2. Coba build key dari towerNumber + containerYard
    final areaId = _normalizeAreaId(tower.containerYard);
    if (tower.towerNumber > 0) {
      final key = 'Tower ${tower.towerNumber} - $areaId';
      debugPrint('[TowerPos] Trying towerNumber: "$key"');
      if (_towerPos.containsKey(key)) {
        debugPrint('[TowerPos] ✓ Matched via towerNumber');
        return _towerPos[key];
      }
    }

    // 3. Coba extract angka dari towerId
    final numMatch = RegExp(r'(\d+[A-Z]?)', caseSensitive: false)
        .firstMatch(tower.towerId)
        ?.group(1)
        ?.toUpperCase();
    if (numMatch != null) {
      final key = 'Tower $numMatch - $areaId';
      debugPrint('[TowerPos] Trying towerId extract: "$key"');
      if (_towerPos.containsKey(key)) {
        debugPrint('[TowerPos] ✓ Matched via towerId extract');
        return _towerPos[key];
      }
    }

    // 4. Coba fuzzy match — normalize semua spasi/simbol lalu bandingkan
    final locNorm = tower.location.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    debugPrint('[TowerPos] Trying fuzzy match: normalized="${locNorm}"');
    for (final entry in _towerPos.entries) {
      final keyNorm = entry.key.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (keyNorm == locNorm) {
        debugPrint('[TowerPos] ✓ Fuzzy match: "${entry.key}"');
        return entry.value;
      }
    }

    // 5. Debug print agar kita tahu tower mana yang tidak ketemu
    debugPrint('[TowerPos] ❌ NO MATCH for:');
    debugPrint('  location: "${tower.location}"');
    debugPrint('  towerId: "${tower.towerId}"');
    debugPrint('  towerNumber: ${tower.towerNumber}');
    debugPrint('  containerYard: "${tower.containerYard}" -> normalized: "$areaId"');

    return null;
  }

  String _towerShortLabel(Tower tower) {
    final source = '${tower.towerId} ${tower.location}';
    final match = RegExp(r'(\d+[A-Z]?)', caseSensitive: false).firstMatch(source);
    if (match != null) {
      return 'T${match.group(1)!.toUpperCase()}';
    }
    return 'T';
  }

  String _towerLongLabel(Tower tower) {
    final source = '${tower.towerId} ${tower.location}';
    final match = RegExp(r'(\d+[A-Z]?)', caseSensitive: false).firstMatch(source);
    if (match != null) {
      return 'Tower ${match.group(1)!.toUpperCase()}';
    }
    return tower.towerId.isNotEmpty ? tower.towerId : tower.location;
  }

  Color _resolveTowerColor(List<AddedDevice> devicesHere) {
    if (devicesHere.isEmpty) {
      return const Color(0xFF78909C);
    }
    if (devicesHere.every((d) => d.status.toUpperCase() == 'UP')) {
      return Colors.green;
    }
    if (devicesHere.every((d) => d.status.toUpperCase() == 'DOWN')) {
      return Colors.red;
    }
    return Colors.orange;
  }

  Widget _buildTowerCountBadge(int count, {required bool zoomed}) {
    final padding = zoomed ? 3.0 : 2.0;
    final borderWidth = zoomed ? 1.5 : 1.0;
    final fontSize = zoomed ? 9.0 : 8.0;
    final blurRadius = zoomed ? 4.0 : 3.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: borderWidth),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: blurRadius),
        ],
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<Widget> _buildZoomedMarkers(List<AddedDevice> devices, double w, double h) {
    if (devices.isEmpty) {
      return [
        Positioned(
          left: (w / 2) - 70,
          top: h / 2,
          child: const Text(
            'No devices in this area',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ];
    }

    const cols = 6;
    final rows = (devices.length / cols).ceil();
    final cellW = (w * 0.8) / cols;
    final cellH = (h * 0.6) / rows;
    final startX = w * 0.1;
    final startY = h * 0.25;

    return devices.asMap().entries.map((entry) {
      final index = entry.key;
      final device = entry.value;
      final row = (index / cols).floor();
      final col = index % cols;

      final x = startX + (col * cellW) + (cellW / 2);
      final y = startY + (row * cellH) + (cellH / 2);

      return Positioned(
        left: x - 14,
        top: y - 14,
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedDevice = device);
            widget.onDeviceTap?.call(device);
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: device.status.toUpperCase() == 'UP' ? Colors.green : Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Icon(
                  device.type == 'CCTV' ? Icons.videocam : Icons.router,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildAllMarkers(double w, double h) {
    return widget.devices.map((device) {
      final area = _findTargetArea(device);
      final devicesInSameArea = widget.devices.where((d) => _findTargetArea(d).id == area.id).toList();
      final index = devicesInSameArea.indexOf(device);

      final cols = (area.width > 0.4) ? 5 : 3;
      final colWidth = (area.width * w) / (cols + 1);
      final rowHeight = (area.height * h) / 5;

      final x = (area.left * w) + ((index % cols) + 1) * colWidth;
      final y = (area.top * h) + ((index / cols).floor() + 1.5) * rowHeight;

      return Positioned(
        left: x - 11,
        top: y - 11,
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedDevice = device);
            widget.onDeviceTap?.call(device);
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: device.status.toUpperCase() == 'UP' ? Colors.green : Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Center(
                child: Icon(
                  device.type == 'CCTV' ? Icons.videocam : Icons.router,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildTowerMarkers(double w, double h) {
    final List<Widget> markers = [];

    for (final tower in widget.towers) {
      final pos = _resolveTowerPosition(tower);
      if (pos == null) continue;

      final areaId = _normalizeAreaId(tower.containerYard);
      ContainerYardArea? area;
      try {
        area = areas.firstWhere((a) => a.id == areaId);
      } catch (_) {
        continue;
      }

      final devicesHere = widget.devices.where((d) => d.locationName == tower.location).toList();

      final markerColor = _resolveTowerColor(devicesHere);

      final x = (area.left + pos['cx']! * area.width) * w;
      final y = (area.top + pos['cy']! * area.height) * h;
      final towerLabel = _towerShortLabel(tower);

      final areaLeft = area.left * w;
      final areaTop = area.top * h;
      final areaRight = (area.left + area.width) * w;
      final areaBottom = (area.top + area.height) * h;

      const markerW = 46.0;
      const markerH = 52.0;
      final markerLeft = (x - 23).clamp(areaLeft + 2, areaRight - markerW - 2);
      final markerTop = (y - 26).clamp(areaTop + 2, areaBottom - markerH - 2);

      markers.add(
        Positioned(
          left: markerLeft,
          top: markerTop,
          width: 46,
          height: 52,
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedTower = tower;
              _devicesAtTower = devicesHere;
            }),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [markerColor, markerColor.withOpacity(0.8)],
                          ),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: markerColor.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Image.asset(
                            'assets/images/Tower.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.router,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (devicesHere.isNotEmpty)
                        Positioned(
                          right: -3,
                          top: -3,
                          child: _buildTowerCountBadge(devicesHere.length, zoomed: false),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      towerLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  List<Widget> _buildZoomedTowerMarkers(ContainerYardArea area, double w, double h) {
    final List<Widget> markers = [];

    for (final tower in widget.towers) {
      if (_normalizeAreaId(tower.containerYard) != area.id) continue;

      final pos = _resolveTowerPosition(tower);
      if (pos == null) continue;

      final devicesHere = widget.devices.where((d) => d.locationName == tower.location).toList();

      final markerColor = _resolveTowerColor(devicesHere);

      final x = pos['cx']! * w;
      final y = pos['cy']! * h;
      final towerLabel = _towerLongLabel(tower);

      const markerW = 64.0;
      const markerH = 72.0;
      final markerLeft = ((x - 32).clamp(2, w - markerW - 2) as double);
      final markerTop = ((y - 36).clamp(2, h - markerH - 2) as double);

      markers.add(
        Positioned(
          left: markerLeft,
          top: markerTop,
          width: 64,
          height: 72,
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedTower = tower;
              _devicesAtTower = devicesHere;
            }),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [markerColor, markerColor.withOpacity(0.8)],
                          ),
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: markerColor.withOpacity(0.6),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(7),
                          child: Image.asset(
                            'assets/images/Tower.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.router,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (devicesHere.isNotEmpty)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: _buildTowerCountBadge(devicesHere.length, zoomed: true),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      towerLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  String _normalizeAreaId(String value) {
    final cleaned = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleaned == 'CY01') return 'CY1';
    if (cleaned == 'CY02') return 'CY2';
    if (cleaned == 'CY03') return 'CY3';
    return cleaned;
  }

  Widget _buildTowerInfo() {
    final towerStatusUp = _selectedTower!.status.toUpperCase() == 'UP';
    final towerStatusColor = towerStatusUp ? Colors.green : Colors.red;

    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: towerStatusColor,
                        child: const Icon(Icons.router, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedTower!.towerId,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${_selectedTower!.containerYard} • ${_selectedTower!.location}',
                              style: const TextStyle(fontSize: 11, color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: towerStatusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: towerStatusColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          towerStatusUp ? 'UP' : 'DOWN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: towerStatusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => setState(() => _selectedTower = null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Total Device: ${_devicesAtTower.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_devicesAtTower.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Belum ada device di tower ini',
                        style: TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: (() {
                            final sorted = _devicesAtTower.toList();
                            sorted.sort((a, b) {
                              final aIsDown = a.status.toUpperCase() != 'UP';
                              final bIsDown = b.status.toUpperCase() != 'UP';
                              if (aIsDown && !bIsDown) return -1; // DOWN first
                              if (!aIsDown && bIsDown) return 1;
                              return 0;
                            });
                            return sorted;
                          }())
                            .map((device) {
                            final isUp = device.status.toUpperCase() == 'UP';
                            return Chip(
                              label: Text(
                                '${device.name} • ${device.type} • ${device.status.toUpperCase()}',
                                style: const TextStyle(fontSize: 9),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              backgroundColor: isUp ? Colors.green.shade100 : Colors.red.shade100,
                              side: BorderSide(color: isUp ? Colors.green : Colors.red),
                              avatar: Icon(
                                device.type == 'CCTV' ? Icons.videocam : Icons.router,
                                size: 12,
                                color: isUp ? Colors.green : Colors.red,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ContainerYardArea _findTargetArea(AddedDevice d) {
    final loc = d.locationName.toLowerCase();
    if (loc.contains('park')) return areas.firstWhere((a) => a.id == 'PARKING');
    if (loc.contains('gate')) return areas.firstWhere((a) => a.id == 'GATE');
    return areas.firstWhere((a) => a.id == d.containerYard, orElse: () => areas[0]);
  }

  Widget _buildSelectedInfo() {
    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: _selectedDevice!.status == 'UP' ? Colors.green : Colors.red,
            child: Icon(
              _selectedDevice!.type == 'CCTV' ? Icons.videocam : Icons.router,
              color: Colors.white,
              size: 16,
            ),
          ),
          title: Text(
            _selectedDevice!.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'IP: ${_selectedDevice!.ipAddress} | ${_selectedDevice!.locationName}',
            style: const TextStyle(fontSize: 10),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => setState(() => _selectedDevice = null),
          ),
        ),
      ),
    );
  }
}
