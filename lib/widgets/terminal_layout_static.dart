import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/device_model.dart';
import '../models/tower_model.dart';
import '../utils/device_icon_resolver.dart';

class TowerCoordinateFallback {
  static const Map<int, Map<String, double>> byTowerNumber = {
    1: {'lat': -7.209459, 'lng': 112.724717},
    2: {'lat': -7.209191, 'lng': 112.725250},
    3: {'lat': -7.208561, 'lng': 112.724946},
    4: {'lat': -7.208150, 'lng': 112.724395},
    5: {'lat': -7.208262, 'lng': 112.724161},
    6: {'lat': -7.208956, 'lng': 112.724173},
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
      final num = int.tryParse(idMatch.group(1)!);
      if (num != null && byTowerNumber.containsKey(num)) {
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
  final List<Map<String, dynamic>> masterLocations;
  final Function(AddedDevice)? onDeviceTap;
  final Function(String towerId, double latitude, double longitude)? onTowerMoved;
  final Function(Map<String, dynamic> master, double latitude, double longitude)? onMasterMoved;
  final bool isFreeroamEditEnabled;
  final bool isPickMode;
  final String? pickYardFilter;
  final void Function(String areaId, double relX, double relY)? onAreaPicked;

  const TerminalLayoutStatic({
    super.key,
    required this.devices,
    this.towers = const [],
    this.towerPoints = const [],
    this.masterLocations = const [],
    this.onDeviceTap,
    this.onTowerMoved,
    this.onMasterMoved,
    this.isFreeroamEditEnabled = false,
    this.isPickMode = false,
    this.pickYardFilter,
    this.onAreaPicked,
  });

  @override
  State<TerminalLayoutStatic> createState() => _TerminalLayoutStaticState();
}

class _TerminalLayoutStaticState extends State<TerminalLayoutStatic> {
  late List<ContainerYardArea> areas;
  AddedDevice? _selectedDevice;
  String? _zoomedAreaId;
  Tower? _selectedTower;
  final List<AddedDevice> _devicesAtTower = [];
  double? _pickedCx;  // ← For precise position picking
  double? _pickedCy;  // ← For precise position picking
  final Map<String, Offset> _dragPreview = {};
  final Map<String, Offset> _masterDragPreview = {};

  // ─────────────────────────────────────────────────────────────
  // Posisi tower hardcoded — dikalibrasi sesuai permintaan user:
  // cx (0.0 - 1.0): 0.0=Kiri, 1.0=Kanan
  // cy (0.0 - 1.0): 0.0=Atas, 1.0=Bawah
  // ─────────────────────────────────────────────────────────────
  static const Map<String, Map<String, double>> _towerPos = {

    // ── CY1 (Container Yard 1) ───────────────────────────────
    // Tower 7-15 only (T1-T3 belong to CY2, T4-T6 reserved for future)
    // KIRI PINGGIR (T11, T12A)
    'Tower 11 - CY1':  {'cx': 0.06, 'cy': 0.30},
    'Tower 12A - CY1': {'cx': 0.06, 'cy': 0.70},
    
    // KIRI AGAK TENGAH (T10, T12)
    'Tower 10 - CY1':  {'cx': 0.25, 'cy': 0.30},
    'Tower 12 - CY1':  {'cx': 0.25, 'cy': 0.70},
    
    // BAWAH TENGAH (T13, T14)
    'Tower 13 - CY1':  {'cx': 0.42, 'cy': 0.85},
    'Tower 14 - CY1':  {'cx': 0.58, 'cy': 0.85},
    
    // KANAN AGAK TENGAH (T15, T9)
    'Tower 9 - CY1':   {'cx': 0.75, 'cy': 0.30},
    'Tower 15 - CY1':  {'cx': 0.75, 'cy': 0.70},
    
    // KANAN PINGGIR (T7, T8)
    'Tower 7 - CY1':   {'cx': 0.94, 'cy': 0.30},
    'Tower 8 - CY1':   {'cx': 0.94, 'cy': 0.70},
    
    // ── CY2 (Container Yard 2) ───────────────────────────────
    // Tower 1-6 (all towers in CY2)
    'Tower 1 - CY2':   {'cx': 0.94, 'cy': 0.65},
    'Tower 2 - CY2':   {'cx': 0.94, 'cy': 0.25},
    'Tower 3 - CY2':   {'cx': 0.46, 'cy': 0.06},
    'Tower 4 - CY2':   {'cx': 0.04, 'cy': 0.28},
    'Tower 5 - CY2':   {'cx': 0.04, 'cy': 0.68},
    'Tower 6 - CY2':   {'cx': 0.46, 'cy': 0.90},

    // ── CY3 (Container Yard 3) ───────────────────────────────
    // Tower 16-26 (T1-T3 are hidden/not rendered)
    'Tower 16 - CY3':  {'cx': 0.40, 'cy': 0.06},
    'Tower 17 - CY3':  {'cx': 0.60, 'cy': 0.06},
    'Tower 18 - CY3':  {'cx': 0.92, 'cy': 0.24},
    'Tower 19 - CY3':  {'cx': 0.92, 'cy': 0.48},
    'Tower 20 - CY3':  {'cx': 0.92, 'cy': 0.72},
    'Tower 21 - CY3':  {'cx': 0.38, 'cy': 0.88},
    'Tower 22 - CY3':  {'cx': 0.52, 'cy': 0.88},
    'Tower 23 - CY3':  {'cx': 0.66, 'cy': 0.88},
    'Tower 24 - CY3':  {'cx': 0.08, 'cy': 0.24},
    'Tower 25 - CY3':  {'cx': 0.08, 'cy': 0.48},
    'Tower 26 - CY3':  {'cx': 0.08, 'cy': 0.72},
  };

  @override
  void initState() {
    super.initState();
    _initializeLayout();
    _syncPickModeZoom(forceUpdate: true);
  }

  @override
  void didUpdateWidget(covariant TerminalLayoutStatic oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPickModeZoom();
  }

  void _syncPickModeZoom({bool forceUpdate = false}) {
    if (widget.isPickMode && widget.pickYardFilter != null) {
      if (forceUpdate || _zoomedAreaId != widget.pickYardFilter) {
        _zoomedAreaId = widget.pickYardFilter;
      }
    }
  }

  void _initializeLayout() {
    areas = [
      ContainerYardArea(
        id: 'CY1', label: 'CY 1',
        bgColor: const Color(0xFFF5DEB3).withOpacity(0.7),
        borderColor: const Color(0xFFD2B48C),
        left: 0.02, top: 0.04, width: 0.56, height: 0.44,
      ),
      ContainerYardArea(
        id: 'CY2', label: 'CY 2',
        bgColor: const Color(0xFFC8E6C9).withOpacity(0.7),
        borderColor: const Color(0xFF66BB6A),
        left: 0.60, top: 0.04, width: 0.38, height: 0.44,
      ),
      ContainerYardArea(
        id: 'PARKING', label: 'PARKING AREA',
        bgColor: const Color(0xFFBBDEFB).withOpacity(0.7),
        borderColor: const Color(0xFF2196F3),
        left: 0.60, top: 0.52, width: 0.18, height: 0.44,
      ),
      ContainerYardArea(
        id: 'CY3', label: 'CY 3',
        bgColor: const Color(0xFFF8BBBB).withOpacity(0.7),
        borderColor: const Color(0xFFE57373),
        left: 0.02, top: 0.52, width: 0.56, height: 0.44,
      ),
      ContainerYardArea(
        id: 'GATE', label: 'GATE IN/OUT',
        bgColor: const Color(0xFFFFF9C4).withOpacity(0.7),
        borderColor: const Color(0xFFFBC02D),
        left: 0.80, top: 0.52, width: 0.18, height: 0.44,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _debugLogTowerDistribution();
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final effectiveZoomAreaId =
            (widget.isPickMode && widget.pickYardFilter != null)
                ? widget.pickYardFilter
                : _zoomedAreaId;
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            if (effectiveZoomAreaId == null) ...[
              ...areas.map((area) => _buildAreaBox(area, w, h)),
              ..._buildMasterLocationMarkers(w, h),
              ..._buildAllMarkers(w, h),
              ..._buildTowerMarkers(w, h),
            ] else ...[
              _buildZoomedArea(w, h, effectiveZoomAreaId),
            ],
          ],
        );
      },
    );
  }

  // ─── Area box ────────────────────────────────────────────────
  Widget _buildAreaBox(ContainerYardArea area, double w, double h) {
    final canPickThisArea =
        widget.pickYardFilter == null || widget.pickYardFilter == area.id;

    return Positioned(
      left: area.left * w,
      top: area.top * h,
      width: area.width * w,
      height: area.height * h,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (TapDownDetails details) {
            if (widget.isPickMode) {
              if (canPickThisArea && widget.onAreaPicked != null) {
                // ═══════════════════════════════════════════════════════════
                // PRECISE POSITION PICKING
                // Return the exact click coordinates within the area
                // ═══════════════════════════════════════════════════════════
                final areaLeft = area.left * w;
                final areaTop = area.top * h;
                final areaWidth = area.width * w;
                final areaHeight = area.height * h;
                
                // Local position relative to area
                final relX = (details.localPosition.dx / areaWidth).clamp(0.0, 1.0);
                final relY = (details.localPosition.dy / areaHeight).clamp(0.0, 1.0);
                
                // Store picked position for tower update
                _pickedCx = relX;
                _pickedCy = relY;
                
                print('✓ Precise pick: Area=${area.id} RelPos=(${relX.toStringAsFixed(3)}, ${relY.toStringAsFixed(3)})');
                
                widget.onAreaPicked!(area.id, relX, relY);
              }
              return;
            }
            setState(() => _zoomedAreaId = area.id);
          },
          child: Container(
            decoration: BoxDecoration(
              color: widget.isPickMode
                  ? (canPickThisArea
                      ? area.bgColor.withOpacity(0.95)
                      : Colors.grey.shade300.withOpacity(0.65))
                  : area.bgColor,
              border: Border.all(
                color: widget.isPickMode
                    ? (canPickThisArea ? const Color(0xFF1976D2) : Colors.grey.shade500)
                    : area.borderColor,
                width: widget.isPickMode ? 3 : 2.5,
              ),
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
                  Icon(
                    widget.isPickMode
                        ? (canPickThisArea ? Icons.check_circle_outline : Icons.block)
                        : Icons.zoom_in,
                    size: 16,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Zoomed area ─────────────────────────────────────────────
  Widget _buildZoomedArea(double w, double h, String areaId) {
    final area = areas.firstWhere((a) => a.id == areaId, orElse: () => areas.first);
    final devicesInArea = widget.devices.where((d) => _findTargetArea(d).id == area.id).toList();

    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('ZOOM IN: ${area.id} (${area.label})');
      print('Total devices in widget: ${widget.devices.length}');
      print('Devices filtered for this area: ${devicesInArea.length}');
      for (var d in devicesInArea) {
        print('  - ${d.name} (${d.type}) @ ${d.locationName}');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    return Positioned(
      left: 10, top: 10,
      width: w - 20, height: h - 20,
      child: GestureDetector(
        onTapDown: (details) {
          if (widget.isPickMode && widget.onAreaPicked != null) {
            final relX = (details.localPosition.dx / (w - 20)).clamp(0.0, 1.0);
            final relY = (details.localPosition.dy / (h - 20)).clamp(0.0, 1.0);
            widget.onAreaPicked!(area.id, relX, relY);
            return;
          }
          setState(() => _zoomedAreaId = null);
        },
        child: Container(
          decoration: BoxDecoration(
            color: area.bgColor,
            border: Border.all(color: area.borderColor, width: 3.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 10, left: 12,
                child: Text(area.label,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black54)),
              ),
              Positioned(
                top: 12, right: 12,
                child: Text(
                  widget.isPickMode ? 'Tap untuk pilih posisi tower' : 'Tap Area For Zoom Out',
                  style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.55), fontWeight: FontWeight.w600)),
              ),
              ..._buildZoomedMasterLocationMarkers(area, w - 20, h - 20),
              ..._buildZoomedTowerMarkers(area, w - 20, h - 20),
              // Keep devices on top in zoom mode so they are not hidden by master markers.
              ..._buildZoomedMarkers(devicesInArea, area, w - 20, h - 20),

              // Debug: tampilkan tower yang tidak ketemu posisinya
              if (kDebugMode)
                ...() {
                  final missing = widget.towers
                      .where((t) => _normalizeAreaId(t.containerYard) == area.id)
                      .where((t) => !_isHiddenCy3Tower(t))
                      .where((t) => _resolveTowerPosition(t) == null)
                      .toList();
                  return missing.asMap().entries.map((e) {
                    final t = e.value;
                    return Positioned(
                      bottom: 8.0 + (e.key * 50.0), left: 8,
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
                            const Text('❌ NO POSITION', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text('location: "${t.location}"',   style: const TextStyle(color: Colors.yellow, fontSize: 9)),
                            Text('towerId:  "${t.towerId}"',    style: const TextStyle(color: Colors.yellow, fontSize: 9)),
                            Text('number:   ${t.towerNumber}',  style: const TextStyle(color: Colors.yellow, fontSize: 9)),
                            Text('cy:       "${t.containerYard}"', style: const TextStyle(color: Colors.yellow, fontSize: 9)),
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

  // ─── Tower position resolver ─────────────────────────────────
  bool _isRelativeCoordinate(double? value) {
    if (value == null) return false;
    return value >= 0.0 && value <= 1.0;
  }

  String _normalizeMatchKey(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  Map<String, dynamic>? _findTowerMasterLocation(Tower tower) {
    final towerIdKey = _normalizeMatchKey(tower.towerId);
    final locKey = _normalizeMatchKey(tower.location);

    for (final location in widget.masterLocations) {
      final type = (location['location_type'] ?? '').toString().toUpperCase();
      if (type != 'TOWER') continue;

      final code = _normalizeMatchKey((location['location_code'] ?? '').toString());
      final name = _normalizeMatchKey((location['location_name'] ?? '').toString());

      final isMatch =
          (code.isNotEmpty && (towerIdKey.contains(code) || locKey.contains(code))) ||
          (name.isNotEmpty && (towerIdKey.contains(name) || locKey.contains(name)));

      if (isMatch) {
        return location;
      }
    }

    return null;
  }

  // Check if tower matches ANY master location (TOWER/RTG/RS/CC)
  Map<String, dynamic>? _findAnyMasterLocationForTower(Tower tower) {
    final towerIdKey = _normalizeMatchKey(tower.towerId);
    final locKey = _normalizeMatchKey(tower.location);

    for (final location in widget.masterLocations) {
      final code = _normalizeMatchKey((location['location_code'] ?? '').toString());
      final name = _normalizeMatchKey((location['location_name'] ?? '').toString());

      final isMatch =
          (code.isNotEmpty && (towerIdKey.contains(code) || locKey.contains(code))) ||
          (name.isNotEmpty && (towerIdKey.contains(name) || locKey.contains(name)));

      if (isMatch) {
        return location;
      }
    }

    return null;
  }

  Map<String, double>? _resolveTowerPosition(Tower tower) {
    final preview = _dragPreview[tower.towerId];
    if (preview != null) {
      return {
        'cx': preview.dx.clamp(0.0, 1.0),
        'cy': preview.dy.clamp(0.0, 1.0),
      };
    }

    final masterTower = _findTowerMasterLocation(tower);
    if (masterTower != null) {
      final lat = double.tryParse((masterTower['latitude'] ?? '').toString());
      final lng = double.tryParse((masterTower['longitude'] ?? '').toString());
      if (_isRelativeCoordinate(lat) && _isRelativeCoordinate(lng)) {
        return {
          'cx': lat!,
          'cy': lng!,
        };
      }
    }

    // Gunakan hanya koordinat relatif 0..1 dari input user/pick mode.
    if (_isRelativeCoordinate(tower.latitude) && _isRelativeCoordinate(tower.longitude)) {
      return {
        'cx': tower.latitude!,
        'cy': tower.longitude!,
      };
    }
    return null;
  }

  bool _isDraggableMasterType(String locType) {
    return locType == 'TOWER' || locType == 'RTG' || locType == 'RS' || locType == 'CC';
  }

  String _masterPreviewKey(Map<String, dynamic> location) {
    final itemId = (location['item_id'] ?? '').toString();
    if (itemId.isNotEmpty) {
      return 'ID:$itemId';
    }
    final type = (location['location_type'] ?? '').toString().toUpperCase();
    final code = (location['location_code'] ?? '').toString().toUpperCase();
    final yard = (location['container_yard'] ?? '').toString().toUpperCase();
    return '$type#$code#$yard';
  }

  Offset? _resolveMasterPosition(Map<String, dynamic> location) {
    final key = _masterPreviewKey(location);
    final preview = _masterDragPreview[key];
    if (preview != null) {
      return Offset(preview.dx.clamp(0.0, 1.0), preview.dy.clamp(0.0, 1.0));
    }

    final lat = double.tryParse((location['latitude'] ?? '0').toString()) ?? 0.0;
    final lng = double.tryParse((location['longitude'] ?? '0').toString()) ?? 0.0;
    if (!_isRelativeCoordinate(lat) || !_isRelativeCoordinate(lng)) {
      return null;
    }
    return Offset(lat, lng);
  }

  // ─── Tower label helpers ─────────────────────────────────────
  String _extractTowerCode(Tower tower) {
    if (tower.towerNumber > 0) return tower.towerNumber.toString();
    final idMatch = RegExp(r'(\d+[A-Z]?)', caseSensitive: false).firstMatch(tower.towerId)?.group(1)?.toUpperCase();
    if (idMatch != null && idMatch.isNotEmpty) return idMatch;
    final locMatch = RegExp(r'TOWER\s*(\d+[A-Z]?)', caseSensitive: false).firstMatch(tower.location)?.group(1)?.toUpperCase();
    if (locMatch != null && locMatch.isNotEmpty) return locMatch;
    return '';
  }

  String _towerShortLabel(Tower tower) {
    final code = _extractTowerCode(tower);
    return code.isNotEmpty ? 'T$code' : 'T';
  }

  String _towerLongLabel(Tower tower) {
    final code = _extractTowerCode(tower);
    if (code.isNotEmpty) return 'Tower $code';
    return tower.towerId.isNotEmpty ? tower.towerId : tower.location;
  }

  bool _isHiddenCy3Tower(Tower tower) {
    if (_normalizeAreaId(tower.containerYard) != 'CY3') return false;
    final code = _extractTowerCode(tower);
    return code == '1' || code == '2' || code == '3';
  }

  // ─── Dedup ───────────────────────────────────────────────────
  String _towerDedupKey(Tower tower) {
    final areaId = _normalizeAreaId(tower.containerYard);
    final code = _extractTowerCode(tower);
    if (areaId.isNotEmpty && code.isNotEmpty) return '$areaId#$code';
    return '$areaId#${tower.towerId.toUpperCase()}#${tower.location.toUpperCase()}';
  }

  List<Tower> _uniqueTowersForRender() {
    final seen = <String>{};
    final unique = <Tower>[];
    for (final tower in widget.towers) {
      if (seen.add(_towerDedupKey(tower))) unique.add(tower);
    }
    return unique;
  }

  bool _isKeyRelated(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    return a == b || a.contains(b) || b.contains(a);
  }

  List<AddedDevice> _devicesForTower(Tower tower) {
    final towerIdKey = _normalizeMatchKey(tower.towerId);
    final towerLocKey = _normalizeMatchKey(tower.location);

    return widget.devices.where((device) {
      final deviceLocKey = _normalizeMatchKey(device.locationName);
      return _isKeyRelated(deviceLocKey, towerIdKey) ||
          _isKeyRelated(deviceLocKey, towerLocKey);
    }).toList(growable: false);
  }

  List<AddedDevice> _devicesForMasterLocation(Map<String, dynamic> location) {
    final locType = (location['location_type'] ?? '').toString().toUpperCase();
    final codeKey = _normalizeMatchKey((location['location_code'] ?? '').toString());
    final nameKey = _normalizeMatchKey((location['location_name'] ?? '').toString());

    // Debug logging for RTG matching
    if (kDebugMode && locType == 'RTG') {
      debugPrint('[RTG MATCH DEBUG] Location: $nameKey / $codeKey');
      debugPrint('[RTG MATCH DEBUG] Available devices:');
      for (final device in widget.devices) {
        final deviceLocKey = _normalizeMatchKey(device.locationName);
        debugPrint('  - Device location: $deviceLocKey (${device.name})');
      }
    }

    if (locType == 'TOWER') {
      final relatedTowerKeys = <String>{};
      for (final tower in widget.towers) {
        final towerIdKey = _normalizeMatchKey(tower.towerId);
        final towerLocKey = _normalizeMatchKey(tower.location);
        final isRelated =
            _isKeyRelated(towerIdKey, codeKey) ||
            _isKeyRelated(towerLocKey, codeKey) ||
            _isKeyRelated(towerIdKey, nameKey) ||
            _isKeyRelated(towerLocKey, nameKey);

        if (!isRelated) continue;
        if (towerIdKey.isNotEmpty) relatedTowerKeys.add(towerIdKey);
        if (towerLocKey.isNotEmpty) relatedTowerKeys.add(towerLocKey);
      }

      return widget.devices.where((device) {
        final deviceLocKey = _normalizeMatchKey(device.locationName);
        for (final key in relatedTowerKeys) {
          if (_isKeyRelated(deviceLocKey, key)) return true;
        }
        return false;
      }).toList(growable: false);
    }

    // For RTG, RS, CC, etc., match by location name or code
    final matches = widget.devices.where((device) {
      final deviceLocKey = _normalizeMatchKey(device.locationName);
      final typeKey = _normalizeMatchKey(device.type);
      
      // Match by exact location
      final locationMatch = _isKeyRelated(deviceLocKey, codeKey) ||
          _isKeyRelated(deviceLocKey, nameKey);
      
      // Also check if device type contains the location type (e.g., CCTV at RTG02)
      final typeMatch = typeKey.contains(locType) && 
                        (deviceLocKey.contains(codeKey) || codeKey.contains(deviceLocKey));
      
      return locationMatch || typeMatch;
    }).toList(growable: false);
    
    if (kDebugMode && locType == 'RTG') {
      debugPrint('[RTG MATCH DEBUG] Found ${matches.length} devices for $nameKey');
    }
    
    return matches;
  }

  // ─── Tower color ─────────────────────────────────────────────
  Color _resolveTowerColor(List<AddedDevice> devicesHere) {
    if (devicesHere.isEmpty) return const Color(0xFF78909C);
    if (devicesHere.every((d) => d.status.toUpperCase() == 'UP')) return Colors.green;
    if (devicesHere.every((d) => d.status.toUpperCase() == 'DOWN')) return Colors.red;
    return Colors.orange;
  }

  // ─── Badge ───────────────────────────────────────────────────
  Widget _buildTowerCountBadge(int count, {required bool zoomed}) {
    return Container(
      padding: EdgeInsets.all(zoomed ? 3.0 : 2.0),
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: zoomed ? 1.5 : 1.0),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: zoomed ? 4.0 : 3.0)],
      ),
      child: Text('$count',
        style: TextStyle(color: Colors.white, fontSize: zoomed ? 9.0 : 8.0, fontWeight: FontWeight.bold)),
    );
  }

  // ─── Tower marker builder (shared) ───────────────────────────
  Widget _buildTowerMarkerWidget({
    required Tower tower,
    required List<AddedDevice> devicesHere,
    required bool zoomed,
  }) {
    final color = _resolveTowerColor(devicesHere);
    final size = zoomed ? 52.0 : 36.0;
    final padding = zoomed ? 7.0 : 5.0;
    final iconSize = zoomed ? 20.0 : 14.0;
    final label = zoomed ? _towerLongLabel(tower) : _towerShortLabel(tower);
    final labelFontSize = zoomed ? 9.0 : 7.0;
    final labelPadH = zoomed ? 6.0 : 4.0;
    final labelPadV = zoomed ? 2.0 : 1.0;
    final badgeOffset = zoomed ? -4.0 : -3.0;

    return GestureDetector(
      onTap: () => _showTowerDetailPopup(tower, devicesHere),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: size, height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [color, color.withOpacity(0.8)],
                    ),
                    border: Border.all(color: Colors.white, width: zoomed ? 2.5 : 2.0),
                    boxShadow: [BoxShadow(color: color.withOpacity(zoomed ? 0.6 : 0.5),
                        blurRadius: zoomed ? 10 : 6, spreadRadius: zoomed ? 2 : 1)],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Icon(Icons.place, size: iconSize, color: Colors.white),
                  ),
                ),
                if (devicesHere.isNotEmpty)
                  Positioned(
                    right: badgeOffset, top: badgeOffset,
                    child: _buildTowerCountBadge(devicesHere.length, zoomed: zoomed),
                  ),
              ],
            ),
            SizedBox(height: zoomed ? 4 : 2),
            Container(
              padding: EdgeInsets.symmetric(horizontal: labelPadH, vertical: labelPadV),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(zoomed ? 4 : 3),
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 8,
                    fontWeight: FontWeight.bold, height: 1)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Fallback tower marker (untuk tower tanpa upstream data) ───
  Widget _buildFallbackTowerMarkerWidget({
    required String code,
    required bool zoomed,
  }) {
    final size = zoomed ? 52.0 : 36.0;
    final padding = zoomed ? 7.0 : 5.0;
    final iconSize = zoomed ? 20.0 : 14.0;
    final labelFontSize = zoomed ? 9.0 : 7.0;
    final labelPadH = zoomed ? 6.0 : 4.0;
    final labelPadV = zoomed ? 2.0 : 1.0;

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF78909C),
                  const Color(0xFF607D8B).withOpacity(0.85),
                ],
              ),
              border: Border.all(color: Colors.white, width: zoomed ? 2.5 : 2.0),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF607D8B).withOpacity(zoomed ? 0.55 : 0.45),
                  blurRadius: zoomed ? 10 : 6,
                  spreadRadius: zoomed ? 2 : 1,
                )
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Icon(Icons.place, size: iconSize, color: Colors.white),
            ),
          ),
          SizedBox(height: zoomed ? 4 : 2),
          Container(
            padding: EdgeInsets.symmetric(horizontal: labelPadH, vertical: labelPadV),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(zoomed ? 0.75 : 0.7),
              borderRadius: BorderRadius.circular(zoomed ? 4 : 3),
            ),
            child: Text(
              zoomed ? 'Tower $code' : 'T$code',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: labelFontSize,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Overview tower markers ───────────────────────────────────
  List<Widget> _buildTowerMarkers(double w, double h) {
    final markers = <Widget>[];

    for (final tower in _uniqueTowersForRender()) {
      if (_isHiddenCy3Tower(tower)) continue;
      
      // Skip tower if it matches with non-TOWER master location (RTG/RS/CC)
      final anyMaster = _findAnyMasterLocationForTower(tower);
      if (anyMaster != null) {
        final masterType = (anyMaster['location_type'] ?? '').toString().toUpperCase();
        if (masterType != 'TOWER') continue;
      }
      
      final pos = _resolveTowerPosition(tower);
      if (pos == null) continue;

      final areaId = _normalizeAreaId(tower.containerYard);
      ContainerYardArea area;
      try {
        area = areas.firstWhere((a) => a.id == areaId);
      } catch (_) { continue; }

      final devicesHere = _devicesForTower(tower);
      final x = (area.left + pos['cx']! * area.width) * w;
      final y = (area.top  + pos['cy']! * area.height) * h;

      const markerW = 46.0, markerH = 52.0;
      final left = (x - 23).clamp(area.left * w + 2, (area.left + area.width) * w - markerW - 2);
      final top  = (y - 26).clamp(area.top  * h + 2, (area.top  + area.height) * h - markerH - 2);

      markers.add(Positioned(
        left: left, top: top, width: markerW, height: markerH,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: _buildTowerMarkerWidget(tower: tower, devicesHere: devicesHere, zoomed: false),
        ),
      ));
    }

    return markers;
  }

  // ─── Zoomed tower markers ─────────────────────────────────────
  List<Widget> _buildZoomedTowerMarkers(ContainerYardArea area, double w, double h) {
    final markers = <Widget>[];

    for (final tower in _uniqueTowersForRender()) {
      if (_normalizeAreaId(tower.containerYard) != area.id) continue;
      if (_isHiddenCy3Tower(tower)) continue;
      
      // Skip tower if it matches with non-TOWER master location (RTG/RS/CC)
      final anyMaster = _findAnyMasterLocationForTower(tower);
      if (anyMaster != null) {
        final masterType = (anyMaster['location_type'] ?? '').toString().toUpperCase();
        if (masterType != 'TOWER') continue;
      }
      
      final pos = _resolveTowerPosition(tower);
      if (pos == null) continue;

      final devicesHere = _devicesForTower(tower);
      final x = pos['cx']! * w;
      final y = pos['cy']! * h;

      const markerW = 64.0, markerH = 72.0;
      final left = (x - 32).clamp(2.0, w - markerW - 2);
      final top  = (y - 36).clamp(2.0, h - markerH - 2);

      // ═══════════════════════════════════════════════════════════
      // DRAGGABLE TOWER MARKER - Freeroam Support
      // ═══════════════════════════════════════════════════════════
      markers.add(
        Positioned(
          left: left,
          top: top,
          width: markerW,
          height: markerH,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: _buildTowerMarkerWidget(tower: tower, devicesHere: devicesHere, zoomed: true),
          ),
        ),
      );
    }

    return markers;
  }

  // ─── Master Location markers (RTG, RS, CC, TOWER) ─────────────
  List<Widget> _buildMasterLocationMarkers(double w, double h) {
    final markers = <Widget>[];
    
    if (widget.masterLocations.isEmpty) {
      return markers;
    }
    
    for (final location in widget.masterLocations) {
      final locType = (location['location_type'] ?? '').toString().toUpperCase();
      final locCode = (location['location_code'] ?? '').toString();
      final locName = (location['location_name'] ?? '').toString();
      final containerYard = (location['container_yard'] ?? '').toString();
      final resolved = _resolveMasterPosition(location);

      // Marker layout ini pakai koordinat relatif 0..1.
      if (resolved == null) continue;
      
      // Find which area this master location belongs to
      final area = areas.firstWhere(
        (a) => a.id == _normalizeAreaId(containerYard),
        orElse: () => areas.first,
      );
      
      final markerColor = DeviceIconResolver.colorForType(locType);
      
      final cx = resolved.dx;
      final cy = resolved.dy;
      
      // Calculate position within the area
      final baseX = (area.left + cx * area.width) * w;
      final baseY = (area.top + cy * area.height) * h;
      
      const markerW = 64.0, markerH = 64.0;
      final left = (baseX - markerW / 2).clamp(area.left * w + 2, (area.left + area.width) * w - markerW - 2);
      final top = (baseY - markerH / 2).clamp(area.top * h + 2, (area.top + area.height) * h - markerH - 2);
      
      markers.add(Positioned(
        left: left,
        top: top,
        child: GestureDetector(
          onTap: () => _showMasterLocationPopup(location),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.45),
                    blurRadius: 6,
                    spreadRadius: -1,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMasterTypeVisual(locType, size: 48),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: markerColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Text(
                      locCode.isNotEmpty ? locCode : locName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,  
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
    }
    
    return markers;
  }

  List<Widget> _buildZoomedMasterLocationMarkers(ContainerYardArea area, double w, double h) {
    final markers = <Widget>[];
    for (final location in widget.masterLocations) {
      final containerYard = _normalizeAreaId((location['container_yard'] ?? '').toString());
      if (containerYard != area.id) continue;

      final resolved = _resolveMasterPosition(location);
      if (resolved == null) continue;

      final x = resolved.dx * w;
      final y = resolved.dy * h;
      const markerW = 72.0;
      const markerH = 72.0;
      final left = (x - markerW / 2).clamp(2.0, w - markerW - 2.0);
      final top = (y - markerH / 2).clamp(2.0, h - markerH - 2.0);

      final locType = (location['location_type'] ?? '').toString().toUpperCase();
      final locCode = (location['location_code'] ?? '').toString();
      final locName = (location['location_name'] ?? '').toString();
      final markerColor = DeviceIconResolver.colorForType(locType);
      final canDrag = _isDraggableMasterType(locType) && widget.isFreeroamEditEnabled;
      final key = _masterPreviewKey(location);

      const labelWidth = 80.0;
      const totalHeight = markerH + 2 + 16; // marker + spacing + label height

      markers.add(Positioned(
        left: (x - labelWidth / 2).clamp(2.0, w - labelWidth - 2.0),
        top: (y - markerH / 2).clamp(2.0, h - totalHeight - 2.0),
        child: GestureDetector(
          onPanUpdate: canDrag
              ? (details) {
                  final current = _masterDragPreview[key] ?? Offset(resolved.dx, resolved.dy);
                  final newCx = (current.dx + (details.delta.dx / w)).clamp(0.0, 1.0);
                  final newCy = (current.dy + (details.delta.dy / h)).clamp(0.0, 1.0);
                  setState(() {
                    _masterDragPreview[key] = Offset(newCx, newCy);
                  });
                }
              : null,
          onPanEnd: canDrag
              ? (_) {
                  final preview = _masterDragPreview[key];
                  if (preview != null && widget.onMasterMoved != null) {
                    widget.onMasterMoved!(location, preview.dx, preview.dy);
                  }
                }
              : null,
          onTap: () => _showMasterLocationPopup(location),
          child: MouseRegion(
            cursor: canDrag ? SystemMouseCursors.move : SystemMouseCursors.click,
            child: SizedBox(
              width: labelWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.45),
                          blurRadius: 6,
                          spreadRadius: -1,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    child: _buildMasterTypeVisual(locType, size: 48),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: markerColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Text(
                      locCode.isNotEmpty ? locCode : locName,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
    }
    return markers;
  }

  Widget _buildMasterTypeVisual(String locType, {double size = 20}) {
    final asset = DeviceIconResolver.assetForType(locType);
    final iconColor = DeviceIconResolver.colorForType(locType);

    if (asset != null) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            DeviceIconResolver.iconForType(locType),
            color: iconColor,
            size: size,
          ),
        ),
      );
    }

    return Icon(
      DeviceIconResolver.iconForType(locType),
      color: iconColor,
      size: size,
    );
  }

  void _showMasterLocationPopup(
    Map<String, dynamic> location,
  ) {
    final locType = (location['location_type'] ?? '-').toString();
    final locCode = (location['location_code'] ?? '-').toString();
    final locName = (location['location_name'] ?? '-').toString();
    final yard = (location['container_yard'] ?? '-').toString();
    final markerColor = DeviceIconResolver.colorForType(locType);
    final devicesHere = _devicesForMasterLocation(location);
    final upCount = devicesHere.where((d) => d.status.toUpperCase() == 'UP').length;
    final downCount = devicesHere.length - upCount;

    final sortedDevices = devicesHere.toList()
      ..sort((a, b) {
        final aDown = a.status.toUpperCase() != 'UP';
        final bDown = b.status.toUpperCase() != 'UP';
        if (aDown != bDown) return aDown ? -1 : 1;
        return a.name.toUpperCase().compareTo(b.name.toUpperCase());
      });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 300),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: markerColor,
                    child: _buildMasterTypeVisual(locType.toUpperCase(), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$locType • $locCode',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Name: $locName', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 2),
              Text('Area: $yard', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total Device: ${devicesHere.length} | UP: $upCount | DOWN: $downCount',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              if (sortedDevices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Belum ada device di master ini',
                    style: TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: sortedDevices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final device = sortedDevices[index];
                      final devUp = device.status.toUpperCase() == 'UP';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: devUp ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: devUp ? Colors.green.shade300 : Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              DeviceIconResolver.iconForType(device.type),
                              size: 14,
                              color: devUp ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${device.name} • ${device.type}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              device.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: devUp ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Device markers (Parent-Child Offset System) ─────────────
  List<Widget> _buildAllMarkers(double w, double h) {
    final markers = <Widget>[];
    
    // Group devices by parent location (Tower/Location)
    final devicesByLocation = <String, List<AddedDevice>>{};
    for (final device in widget.devices) {
      devicesByLocation.putIfAbsent(device.locationName, () => []).add(device);
    }
    
    if (kDebugMode && devicesByLocation.isNotEmpty) {
      print('\n═══ Device Grouping ═══');
      devicesByLocation.forEach((loc, devs) {
        print('📍 $loc: ${devs.length} device(s)');
      });
    }
    
    // Render each group with circular offset pattern
    devicesByLocation.forEach((location, devices) {
      final parentPos = _getParentPosition(location);
      if (parentPos == null) {
        // Fallback to area center if parent not found
        if (kDebugMode) print('⚠️ Using fallback for: $location (${devices.length} devices)');
        for (final device in devices) {
          final area = _findTargetArea(device);
          final x = (area.left + area.width * 0.5) * w;
          final y = (area.top + area.height * 0.5) * h;
          markers.add(_buildDeviceMarker(device, x, y, w, h, area));
        }
        return;
      }
      
      final area = parentPos['area'] as ContainerYardArea;
      final cx = parentPos['cx'] as double;
      final cy = parentPos['cy'] as double;
      
      // Base position (parent Tower coordinates)
      final baseX = (area.left + cx * area.width) * w;
      final baseY = (area.top + cy * area.height) * h;
      
      // Apply trigonometric circular offset.
      // Single device is also shifted slightly so it does not sit exactly on parent icon.
      final deviceCount = devices.length;
      final radius = deviceCount == 1 ? 24.0 : 40.0;
      
      for (var i = 0; i < deviceCount; i++) {
        // For a single device, pin it to a fixed angle for consistent UI.
        final angle = deviceCount == 1 ? -pi / 2 : (2 * pi * i) / deviceCount;
        final offsetX = radius * cos(angle);
        final offsetY = radius * sin(angle);
        
        final x = baseX + offsetX;
        final y = baseY + offsetY;
        
        markers.add(_buildDeviceMarker(devices[i], x, y, w, h, area));
      }
    });
    
    return markers;
  }
  
  // Build device marker widget
  Widget _buildDeviceMarker(AddedDevice device, double x, double y, double w, double h, ContainerYardArea area) {
    const markerSize = 28.0;
    const iconSize = 14.0;
    const half = markerSize / 2;

    // Clamp to area bounds
    final clampedX = x.clamp(area.left * w + half, (area.left + area.width) * w - half);
    final clampedY = y.clamp(area.top * h + half, (area.top + area.height) * h - half);
    
    return Positioned(
      left: clampedX - half,
      top: clampedY - half,
      child: GestureDetector(
        onTap: () { _showDeviceDetailPopup(device); widget.onDeviceTap?.call(device); },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: markerSize, height: markerSize,
            decoration: BoxDecoration(
              color: device.status.toUpperCase() == 'UP' ? Colors.green : Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Center(child: Icon(
              _getDeviceIconType(device.type),
              size: iconSize, color: Colors.white)),
          ),
        ),
      ),
    );
  }
  
  // Get parent position from tower coordinates
  Map<String, dynamic>? _getParentPosition(String locationName) {
    final target = locationName.toUpperCase();
    final targetKey = _normalizeMatchKey(locationName);

    for (final location in widget.masterLocations) {
      final locCode = (location['location_code'] ?? '').toString().toUpperCase();
      final locName = (location['location_name'] ?? '').toString().toUpperCase();
      final locCodeKey = _normalizeMatchKey(locCode);
      final locNameKey = _normalizeMatchKey(locName);
      final yard = _normalizeAreaId((location['container_yard'] ?? '').toString());
      final resolved = _resolveMasterPosition(location);

      if (resolved == null) {
        continue;
      }

      final isMatch =
          target == locName ||
          target == locCode ||
          (locCode.isNotEmpty && target.contains(locCode)) ||
          (locName.isNotEmpty && target.contains(locName)) ||
          (locCodeKey.isNotEmpty && targetKey.contains(locCodeKey)) ||
          (locNameKey.isNotEmpty && targetKey.contains(locNameKey));

      if (!isMatch) continue;

      final area = areas.firstWhere(
        (a) => a.id == yard,
        orElse: () => areas.first,
      );
      return {
        'cx': resolved.dx,
        'cy': resolved.dy,
        'area': area,
      };
    }

    if (kDebugMode) print('⚠️ Parent NOT found for: $locationName');
    return null;
  }
  
  // Find area by location name
  ContainerYardArea? _findAreaByLocation(String locationName) {
    final upper = locationName.toUpperCase();
    if (upper.contains('CY1')) return areas.firstWhere((a) => a.id == 'CY1', orElse: () => areas[0]);
    if (upper.contains('CY2')) return areas.firstWhere((a) => a.id == 'CY2', orElse: () => areas[1]);
    if (upper.contains('CY3')) return areas.firstWhere((a) => a.id == 'CY3', orElse: () => areas.first);
    if (upper.contains('GATE')) return areas.firstWhere((a) => a.id == 'GATE', orElse: () => areas.last);
    if (upper.contains('PARK')) return areas.firstWhere((a) => a.id == 'PARKING', orElse: () => areas[2]);
    return areas[0];
  }
  
  // Get device icon by type
  IconData _getDeviceIconType(String type) {
    return DeviceIconResolver.iconForType(type);
  }

  // ─── Zoomed device markers ────────────────────────────────────
  List<Widget> _buildZoomedMarkers(
    List<AddedDevice> devices,
    ContainerYardArea area,
    double w,
    double h,
  ) {
    if (kDebugMode) {
      print('━━━ _buildZoomedMarkers called ━━━');
      print('Area: ${area.id}, Size: ${w}x$h');
      print('Total devices passed: ${devices.length}');
      for (var d in devices) {
        print('  - ${d.name} (${d.type}) at ${d.locationName}');
      }
    }

    if (devices.isEmpty) {
      if (kDebugMode) print('⚠️ No devices to render in zoom view');
      return [];
    }
    
    final markers = <Widget>[];
    
    // Group devices by location name
    final devicesByLocation = <String, List<AddedDevice>>{};
    for (final device in devices) {
      final key = device.locationName.trim();
      devicesByLocation.putIfAbsent(key, () => []).add(device);
    }

    if (kDebugMode) {
      print('Grouped into ${devicesByLocation.length} locations:');
      devicesByLocation.forEach((loc, devs) {
        print('  $loc: ${devs.length} device(s)');
      });
    }

    // Render each group
    devicesByLocation.forEach((locationName, grouped) {
      final parentPos = _getParentPosition(locationName);
      
      double baseX, baseY;
      
      // Case 1: Parent not found → render at center as fallback
      if (parentPos == null) {
        if (kDebugMode) print('⚠️ Parent NOT found for "$locationName", using center (${grouped.length} devices)');
        baseX = w * 0.5;
        baseY = h * 0.5;
      } else {
        // Case 2: Parent found → use parent position
        final cx = parentPos['cx'] as double;
        final cy = parentPos['cy'] as double;
        baseX = cx * w;
        baseY = cy * h;
        if (kDebugMode) print('✓ Parent found for "$locationName" at ($cx, $cy) → pixel ($baseX, $baseY)');
      }

      // Render devices around base position.
      // Keep behavior consistent with non-zoom mode.
      final count = grouped.length;
      final radius = count == 1 ? 24.0 : 40.0;

      for (var i = 0; i < count; i++) {
        final angle = count == 1 ? -pi / 2 : (2 * pi * i) / count;
        final x = baseX + radius * cos(angle);
        final y = baseY + radius * sin(angle);
        if (kDebugMode) print('  → Rendering ${grouped[i].name} at ($x, $y)');
        markers.add(_buildZoomedDeviceMarker(grouped[i], x, y, w, h));
      }
    });

    if (kDebugMode) print('✓ Created ${markers.length} device markers for zoom view');
    return markers;
  }

  Widget _buildZoomedDeviceMarker(AddedDevice device, double x, double y, double w, double h) {
    const markerSize = 28.0;
    const iconSize = 13.0;
    const half = markerSize / 2;
    final clampedX = x.clamp(half, w - half);
    final clampedY = y.clamp(half + 4, h - (half + 4));

    return Positioned(
      left: clampedX - half,
      top: clampedY - half,
      child: GestureDetector(
        onTap: () {
          _showDeviceDetailPopup(device);
          widget.onDeviceTap?.call(device);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: markerSize,
            height: markerSize,
            decoration: BoxDecoration(
              color: device.status.toUpperCase() == 'UP' ? Colors.green : Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Center(
              child: Icon(
                DeviceIconResolver.iconForType(device.type),
                size: iconSize,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Normalize area ID ────────────────────────────────────────
  String _normalizeAreaId(String value) {
    final c = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (c == 'CY01' || c == 'CY1' || c == 'CONTAINERYARD1' || c == 'CONTAINERYARD01' || c == 'YARD1') return 'CY1';
    if (c == 'CY02' || c == 'CY2' || c == 'CONTAINERYARD2' || c == 'CONTAINERYARD02' || c == 'YARD2') return 'CY2';
    if (c == 'CY03' || c == 'CY3' || c == 'CONTAINERYARD3' || c == 'CONTAINERYARD03' || c == 'YARD3') return 'CY3';
    return c;
  }

  // ─── Find area for device ─────────────────────────────────────
  ContainerYardArea _findTargetArea(AddedDevice d) {
    final loc = d.locationName.toLowerCase();
    if (loc.contains('park')) return areas.firstWhere((a) => a.id == 'PARKING');
    if (loc.contains('gate')) return areas.firstWhere((a) => a.id == 'GATE');

    // Prefer parent mapping from master location code/name so area stays correct
    // even if containerYard from API is stale or inconsistent.
    final parentPos = _getParentPosition(d.locationName);
    if (parentPos != null) {
      final parentArea = parentPos['area'] as ContainerYardArea;
      return parentArea;
    }

    final normalizedYard = _normalizeAreaId(d.containerYard);
    final explicitArea = areas.where((a) => a.id == normalizedYard).toList(growable: false);
    if (explicitArea.isNotEmpty) {
      return explicitArea.first;
    }

    return areas[0];
  }

  void _showTowerDetailPopup(Tower tower, List<AddedDevice> devicesHere) {
    final isUp = tower.status.toUpperCase() == 'UP';
    final statusColor = isUp ? Colors.green : Colors.red;
    final upCount = devicesHere.where((d) => d.status.toUpperCase() == 'UP').length;
    final downCount = devicesHere.length - upCount;
    final sortedDevices = devicesHere.toList()
      ..sort((a, b) {
        final aDown = a.status.toUpperCase() != 'UP';
        final bDown = b.status.toUpperCase() != 'UP';
        if (aDown != bDown) return aDown ? -1 : 1;
        return a.name.toUpperCase().compareTo(b.name.toUpperCase());
      });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 300),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: statusColor,
                      child: const Icon(Icons.router, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${tower.towerId} • ${tower.containerYard}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Location: ${tower.location}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Total Device: ${devicesHere.length} | UP: $upCount | DOWN: $downCount',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                if (sortedDevices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Belum ada device di tower ini',
                      style: TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: sortedDevices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final device = sortedDevices[index];
                        final devUp = device.status.toUpperCase() == 'UP';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: devUp ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: devUp ? Colors.green.shade300 : Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                DeviceIconResolver.iconForType(device.type),
                                size: 14,
                                color: devUp ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${device.name} • ${device.type}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                device.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: devUp ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeviceDetailPopup(AddedDevice device) {
    final isUp = device.status.toUpperCase() == 'UP';
    final statusColor = isUp ? Colors.green : Colors.red;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 300),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: statusColor,
                      radius: 20,
                      child: Icon(
                        DeviceIconResolver.iconForType(device.type),
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              device.status.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildDeviceInfoRow(Icons.settings_input_component, 'Type', device.type),
                const SizedBox(height: 8),
                _buildDeviceInfoRow(Icons.location_on, 'Location', device.locationName),
                const SizedBox(height: 8),
                _buildDeviceInfoRow(Icons.router, 'IP Address', device.ipAddress),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── Debug log ────────────────────────────────────────────────
  void _debugLogTowerDistribution() {
    if (!kDebugMode) return;
    final unique = _uniqueTowersForRender();
    final cy1 = unique.where((t) => _normalizeAreaId(t.containerYard) == 'CY1').toList();
    final cy2 = unique.where((t) => _normalizeAreaId(t.containerYard) == 'CY2').toList();
    final cy3 = unique.where((t) => _normalizeAreaId(t.containerYard) == 'CY3').toList();
    debugPrint('\n========== TOWER DISTRIBUTION ==========');
    debugPrint('CY1 (${cy1.length}): ${cy1.map(_extractTowerCode).join(", ")}');
    debugPrint('CY2 (${cy2.length}): ${cy2.map(_extractTowerCode).join(", ")}');
    debugPrint('CY3 (${cy3.length}): ${cy3.map(_extractTowerCode).join(", ")}');
    debugPrint('Total: ${unique.length}');
    debugPrint('=========================================\n');
    final missing = unique.where((t) => _resolveTowerPosition(t) == null).toList();
    if (missing.isNotEmpty) {
      debugPrint('⚠️ MISSING POSITIONS (${missing.length}):');
      for (final t in missing) {
        debugPrint('  loc="${t.location}" id="${t.towerId}" num=${t.towerNumber} cy="${t.containerYard}"');
      }
    }
  }

  // ─── Tower info popup ─────────────────────────────────────────
  Widget _buildTowerInfo() {
    final isUp = _selectedTower!.status.toUpperCase() == 'UP';
    final statusColor = isUp ? Colors.green : Colors.red;

    return Positioned(
      bottom: 12, left: 12, right: 12,
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
                        backgroundColor: statusColor,
                        child: const Icon(Icons.router, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedTower!.towerId,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis),
                            Text('${_selectedTower!.containerYard} • ${_selectedTower!.location}',
                              style: const TextStyle(fontSize: 11, color: Colors.black54),
                              overflow: TextOverflow.ellipsis, maxLines: 2),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: statusColor.withOpacity(0.5)),
                        ),
                        child: Text(isUp ? 'UP' : 'DOWN',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
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
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Text('Total Device: ${_devicesAtTower.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ),
                  const SizedBox(height: 8),
                  if (_devicesAtTower.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Belum ada device di tower ini',
                        style: TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic)),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6, runSpacing: 6,
                          children: (_devicesAtTower.toList()
                            ..sort((a, b) {
                              final aDown = a.status.toUpperCase() != 'UP';
                              final bDown = b.status.toUpperCase() != 'UP';
                              return aDown == bDown ? 0 : (aDown ? -1 : 1);
                            }))
                            .map((device) {
                              final devUp = device.status.toUpperCase() == 'UP';
                              return Chip(
                                label: Text('${device.name} • ${device.type} • ${device.status.toUpperCase()}',
                                  style: const TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis, maxLines: 1),
                                backgroundColor: devUp ? Colors.green.shade100 : Colors.red.shade100,
                                side: BorderSide(color: devUp ? Colors.green : Colors.red),
                                avatar: Icon(
                                  DeviceIconResolver.iconForType(device.type),
                                  size: 12,
                                  color: devUp ? Colors.green : Colors.red,
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
}
