import 'dart:math';
import 'package:flutter/material.dart';
import 'package:monitoring/models/device_model.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/utils/layout_mapper.dart';
import 'package:monitoring/utils/device_icon_resolver.dart';
import 'package:monitoring/utils/location_label_utils.dart';
import 'package:monitoring/models/master_location_model.dart';

class _ParentPosition {
  final double cx;
  final double cy;
  final ContainerYardArea area;
  final bool hasPreview;
  final int priority;

  _ParentPosition({
    required this.cx,
    required this.cy,
    required this.area,
    this.hasPreview = false,
    this.priority = 0,
  });
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

class TerminalLayoutStatic extends StatefulWidget {
  final List<AddedDevice> devices;
  final List<Tower> towers;

  final List<MasterLocation> masterLocations;
  final Function(AddedDevice)? onDeviceTap;
  final Function(String towerId, double latitude, double longitude)?
      onTowerMoved;
  final Function(MasterLocation master, double latitude, double longitude)?
      onMasterMoved;
  final bool isFreeroamEditEnabled;
  final bool isPickMode;
  final String? pickYardFilter;
  final String? forcedAreaId;
  final void Function(String areaId, double relX, double relY)? onAreaPicked;

  const TerminalLayoutStatic({
    super.key,
    required this.devices,
    this.towers = const [],
    this.masterLocations = const [],
    this.onDeviceTap,
    this.onTowerMoved,
    this.onMasterMoved,
    this.isFreeroamEditEnabled = false,
    this.isPickMode = false,
    this.pickYardFilter,
    this.forcedAreaId,
    this.onAreaPicked,
    this.isZoomed = true,
  });

  final bool isZoomed;

  @override
  State<TerminalLayoutStatic> createState() => _TerminalLayoutStaticState();
}

class _TerminalLayoutStaticState extends State<TerminalLayoutStatic> {
  late List<ContainerYardArea> areas;
  String? _zoomedAreaId;
  final Map<String, Offset> _dragPreview = {};
  final Map<String, Offset> _masterDragPreview = {};
  List<Map<String, String>> _masterOptions = [];

  @override
  void initState() {
    super.initState();
    _masterOptions = buildMasterLocationOptions(
      widget.masterLocations.map((m) => m.toMap()).toList(),
    );
    _initializeLayout();
    _syncPickModeZoom(forceUpdate: true);
  }

  @override
  void didUpdateWidget(covariant TerminalLayoutStatic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.masterLocations != oldWidget.masterLocations) {
      _masterOptions = buildMasterLocationOptions(
        widget.masterLocations.map((m) => m.toMap()).toList(),
      );
    }
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
        id: 'CY1',
        label: 'CY 1',
        bgColor: const Color(0xFFF5DEB3).withValues(alpha: 0.7),
        borderColor: const Color(0xFFD2B48C),
        left: 0.02,
        top: 0.04,
        width: 0.56,
        height: 0.44,
      ),
      ContainerYardArea(
        id: 'CY2',
        label: 'CY 2',
        bgColor: const Color(0xFFC8E6C9).withValues(alpha: 0.7),
        borderColor: const Color(0xFF66BB6A),
        left: 0.60,
        top: 0.04,
        width: 0.38,
        height: 0.44,
      ),
      ContainerYardArea(
        id: 'PARKING',
        label: 'PARKING',
        bgColor: const Color(0xFFBBDEFB).withValues(alpha: 0.7),
        borderColor: const Color(0xFF2196F3),
        left: 0.60,
        top: 0.52,
        width: 0.18,
        height: 0.44,
      ),
      ContainerYardArea(
        id: 'CY3',
        label: 'CY 3',
        bgColor: const Color(0xFFF8BBBB).withValues(alpha: 0.7),
        borderColor: const Color(0xFFE57373),
        left: 0.02,
        top: 0.52,
        width: 0.56,
        height: 0.44,
      ),
      ContainerYardArea(
        id: 'GATE',
        label: 'GATE',
        bgColor: const Color(0xFFFFF9C4).withValues(alpha: 0.7),
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
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Prevent rendering if layout sizes are not yet available.
          // This avoids "Cannot hit test a render box that has never been laid out" error.
          if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
            return const SizedBox.shrink();
          }

          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final effectiveZoomAreaId = widget.forcedAreaId ??
              ((widget.isPickMode && widget.pickYardFilter != null)
                  ? widget.pickYardFilter
                  : _zoomedAreaId);
          final bool showZoomedDetail =
              effectiveZoomAreaId != null && widget.isZoomed;

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Container(
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(15))),
              if (!showZoomedDetail) ...[
                ...areas
                    .where((a) =>
                        widget.forcedAreaId == null ||
                        a.id == widget.forcedAreaId)
                    .map((area) => _buildAreaBox(area, w, h)),
                ..._buildMasterLocationMarkers(w, h),
                ..._buildAllMarkers(w, h),
              ] else ...[
                _buildZoomedArea(w, h, effectiveZoomAreaId),
              ],
            ],
          );
        },
      ),
    );
  }

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
          onTapDown: widget.isPickMode
              ? (details) {
                  if (canPickThisArea && widget.onAreaPicked != null) {
                    final relX = (details.localPosition.dx / (area.width * w))
                        .clamp(0.0, 1.0);
                    final relY = (details.localPosition.dy / (area.height * h))
                        .clamp(0.0, 1.0);
                    widget.onAreaPicked!(area.id, relX, relY);
                  }
                }
              : null,
          onTap: widget.isPickMode
              ? null
              : () => setState(() => _zoomedAreaId = area.id),
          child: Container(
            decoration: BoxDecoration(
              color: widget.isPickMode
                  ? (canPickThisArea
                      ? area.bgColor.withValues(alpha: 0.95)
                      : Colors.grey.shade300)
                  : area.bgColor,
              border: Border.all(
                  color: widget.isPickMode
                      ? (canPickThisArea
                          ? const Color(0xFF1976D2)
                          : Colors.grey.shade500)
                      : area.borderColor,
                  width: 2.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(area.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: Colors.black54))),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomedArea(double w, double h, String areaId) {
    final area =
        areas.firstWhere((a) => a.id == areaId, orElse: () => areas.first);
    final devicesInArea =
        widget.devices.where((d) => _findTargetArea(d).id == area.id).toList();

    return Positioned(
      left: 10,
      top: 10,
      width: w - 20,
      height: h - 20,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTapDown: widget.isPickMode
            ? (details) {
                if (widget.onAreaPicked != null) {
                  final relX =
                      (details.localPosition.dx / (w - 20)).clamp(0.0, 1.0);
                  final relY =
                      (details.localPosition.dy / (h - 20)).clamp(0.0, 1.0);
                  widget.onAreaPicked!(area.id, relX, relY);
                }
              }
            : null,
        onTap: widget.isPickMode
            ? null
            : (widget.forcedAreaId == null
                ? () => setState(() => _zoomedAreaId = null)
                : null),
        child: Container(
          decoration: BoxDecoration(
              color: area.bgColor,
              border: Border.all(color: area.borderColor, width: 3.5),
              borderRadius: BorderRadius.circular(12)),
          child: Stack(
            children: [
              Positioned(
                  top: 10,
                  left: 12,
                  child: Text(area.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Colors.black54))),
              Positioned(
                  top: 12,
                  right: 12,
                  child: Text(
                      widget.isPickMode
                          ? 'Tap area for zoom out'
                          : 'Tap area for zoom out',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600))),
              ..._buildZoomedMasterLocationMarkers(area, w - 20, h - 20),
              ..._buildZoomedMarkers(devicesInArea, area, w - 20, h - 20),
            ],
          ),
        ),
      ),
    );
  }

  bool _isRelativeCoordinate(double? value) =>
      value != null && value > 0.00001 && value <= 1.0;
  String _normalizeMatchKey(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  String _normalizeAreaId(String? id) {
    String s = (id ?? '').trim().toUpperCase().replaceAll(' ', '');
    // Handle CY 01 -> CY1, T 01 -> T1
    return s.replaceAllMapped(
        RegExp(r'([A-Z]+)0+(\d+)'), (m) => '${m[1]}${m[2]}');
  }

  MasterLocation? _findTowerMasterLocation(Tower tower) {
    final tid = _normalizeMatchKey(tower.towerId);
    final tloc = _normalizeMatchKey(tower.location);
    for (final loc in widget.masterLocations) {
      if (loc.locationType.toUpperCase() != 'TOWER') continue;
      final mcode = _normalizeMatchKey(loc.locationCode);
      final mname = _normalizeMatchKey(loc.locationName);
      if (mcode.isNotEmpty && (tid == mcode || tloc == mcode)) return loc;
      if (mname.isNotEmpty && (tid == mname || tloc == mname)) return loc;
    }
    return null;
  }

  Map<String, double>? _resolveTowerPosition(Tower tower) {
    final preview = _dragPreview[tower.towerId];
    if (preview != null) {
      return {
        'cx': preview.dx.clamp(0.0, 1.0),
        'cy': preview.dy.clamp(0.0, 1.0)
      };
    }
    final master = _findTowerMasterLocation(tower);
    if (master != null) {
      final mpreview = _masterDragPreview[_masterPreviewKey(master)];
      if (mpreview != null) {
        return {
          'cx': mpreview.dx.clamp(0.0, 1.0),
          'cy': mpreview.dy.clamp(0.0, 1.0)
        };
      }
      if (_isRelativeCoordinate(master.latitude) &&
          _isRelativeCoordinate(master.longitude)) {
        return {'cx': master.longitude, 'cy': master.latitude};
      }
    }
    if (_isRelativeCoordinate(tower.latitude) &&
        _isRelativeCoordinate(tower.longitude)) {
      return {'cx': tower.longitude!, 'cy': tower.latitude!};
    }
    return null;
  }

  String _masterPreviewKey(MasterLocation location) {
    if (location.id != 0) return 'ML_ID_${location.id}';
    // Use a more unique fallback key to prevent "ghost shifts" where multiple new items move together
    return 'ML_REF_${location.locationType}_${location.locationCode}_${location.locationName}_${location.containerYard}';
  }

  Offset? _resolveMasterPosition(MasterLocation location) {
    final preview = _masterDragPreview[_masterPreviewKey(location)];
    if (preview != null) return Offset(preview.dx, preview.dy);

    // If we have relative coordinates (0.0 to 1.0)
    if (_isRelativeCoordinate(location.latitude) &&
        _isRelativeCoordinate(location.longitude)) {
      return Offset(location.longitude, location.latitude);
    }

    // If we have real Lat/Lng, we must map them relative to their assigned Area Box
    if (location.latitude.abs() > 0 && location.longitude.abs() > 0) {
      final pixel =
          LayoutMapper.latLngToPixel(location.latitude, location.longitude);
      final globalX = pixel.x / LayoutMapper.PNG_WIDTH;
      final globalY = pixel.y / LayoutMapper.PNG_HEIGHT;

      final area = areas.firstWhere(
          (a) => a.id == _normalizeAreaId(location.containerYard),
          orElse: () => areas.first);

      // Translate global offset to local area-relative offset
      final localX = ((globalX - area.left) / area.width).clamp(0.0, 1.0);
      final localY = ((globalY - area.top) / area.height).clamp(0.0, 1.0);

      return Offset(localX, localY);
    }
    return null;
  }

  List<AddedDevice> _devicesForMasterLocation(MasterLocation location) {
    final mCode = normalizeLocationMatchKey(location.locationCode);
    final mName = normalizeLocationMatchKey(location.locationName);
    final mYard = _normalizeAreaId(location.containerYard);

    final filtered = widget.devices.where((d) {
      final dLoc = normalizeLocationMatchKey(d.locationName);
      final dYard = _normalizeAreaId(d.containerYard);

      // 1. Strict match (Exact)
      bool isMatch = (mCode.isNotEmpty && dLoc == mCode) ||
          (mName.isNotEmpty && dLoc == mName);

      // 2. Fuzzy match (Two-way contains)
      if (!isMatch) {
        // Device name contains Master code/name (e.g. "RTG 01 CCTV" matches "RTG 01")
        if (mCode.isNotEmpty && mCode.length > 1 && dLoc.contains(mCode)) {
          isMatch = true;
        }
        if (mName.isNotEmpty && mName.length > 2 && dLoc.contains(mName)) {
          isMatch = true;
        }

        // OR Master name contains Device name (e.g. "TOWER T5 PARKING" matches "T5")
        if (!isMatch && dLoc.length > 1) {
          if (mCode.isNotEmpty && mCode.contains(dLoc)) isMatch = true;
          if (mName.isNotEmpty && mName.contains(dLoc)) isMatch = true;
        }
      }

      if (isMatch) {
        // If name matches strongly, we allow it if yard matches OR either side is empty
        if (dYard == mYard || dYard.isEmpty || mYard.isEmpty) return true;
      }

      return false;
    }).toList();

    // Deduplicate by IP Address to solve "TIDAK TERDOUBLE"
    final Map<String, AddedDevice> unique = {};
    for (final d in filtered) {
      final ip = d.ipAddress.trim();
      if (ip.isNotEmpty && ip != '0.0.0.0' && ip != '127.0.0.1') {
        if (!unique.containsKey(ip) ||
            d.name.length < unique[ip]!.name.length) {
          unique[ip] = d;
        }
      } else {
        final nkey = d.name.toUpperCase().trim();
        if (!unique.containsKey(nkey)) {
          unique[nkey] = d;
        }
      }
    }
    return unique.values.toList();
  }

  _ParentPosition? _getParentPosition(
      String locationName, String containerYard) {
    if (locationName.trim().isEmpty) return null;

    final matched = matchMasterLocationOption(
      _masterOptions,
      locationName,
      currentContainerYard: containerYard,
    );
    if (matched == null) return null;

    final targetLabelKey = normalizeLocationMatchKey(matched['label'] ?? '');

    for (final locData in widget.masterLocations) {
      final loc = locData;
      final mlabel = buildMasterLocationLabel(
        locationType: loc.locationType,
        locationCode: loc.locationCode,
        locationName: loc.locationName,
        containerYard: loc.containerYard,
      );

      if (normalizeLocationMatchKey(mlabel) == targetLabelKey) {
        final pos = _resolveMasterPosition(loc);
        if (pos != null) {
          return _ParentPosition(
              cx: pos.dx,
              cy: pos.dy,
              area: areas.firstWhere(
                  (a) => a.id == _normalizeAreaId(loc.containerYard),
                  orElse: () => areas.first),
              hasPreview:
                  _masterDragPreview.containsKey(_masterPreviewKey(loc)),
              priority: 20);
        }
      }
    }

    final target = normalizeLocationMatchKey(locationName);
    final targetYard = _normalizeAreaId(containerYard);
    _ParentPosition? best;
    for (final tower in widget.towers) {
      final tid = normalizeLocationMatchKey(tower.towerId);
      final tloc = normalizeLocationMatchKey(tower.location);
      final tyard = _normalizeAreaId(tower.containerYard);

      bool matched = (target == tid || target == tloc);
      if (!matched && targetYard == tyard) {
        if (tid.isNotEmpty && target.contains(tid)) matched = true;
      }

      if (matched) {
        final pos = _resolveTowerPosition(tower);
        if (pos != null) {
          final current = _ParentPosition(
              cx: pos['cx']!,
              cy: pos['cy']!,
              area: areas.firstWhere((a) => a.id == tyard,
                  orElse: () => areas.first),
              hasPreview: _dragPreview.containsKey(tower.towerId),
              priority: (targetYard == tyard) ? 15 : 5);
          if (best == null ||
              (current.hasPreview && !best.hasPreview) ||
              current.priority > best.priority) {
            best = current;
          }
        }
      }
    }

    if (best == null) {
      // Final desperate fallback: only match if it's a very clear match
      for (final loc in widget.masterLocations) {
        if (_normalizeAreaId(loc.containerYard) != targetYard) continue;
        final mcode = normalizeLocationMatchKey(loc.locationCode);
        final mname = normalizeLocationMatchKey(loc.locationName);

        // Use more strict matching: either exact or surrounded by non-alphanumeric
        bool isMatch = (mcode.isNotEmpty && target == mcode) ||
            (mname.isNotEmpty && target == mname);

        if (!isMatch && mcode.length > 2) {
          // If code is long enough (like "RTG01"), check if it's a sub-part but carefully
          if (target.contains(mcode)) isMatch = true;
        }

        if (isMatch) {
          final pos = _resolveMasterPosition(loc);
          if (pos != null) {
            return _ParentPosition(
                cx: pos.dx,
                cy: pos.dy,
                area: areas.firstWhere(
                    (a) => a.id == _normalizeAreaId(loc.containerYard),
                    orElse: () => areas.first),
                priority: 1);
          }
        }
      }
    }

    return best;
  }

  List<Widget> _buildMasterLocationMarkers(double w, double h) {
    final markers = <Widget>[];
    for (final loc in widget.masterLocations) {
      final pos = _resolveMasterPosition(loc);
      if (pos == null) continue;

      // Filter by forced area if applicable
      if (widget.forcedAreaId != null) {
        if (_normalizeAreaId(loc.containerYard) != widget.forcedAreaId) {
          continue;
        }
      }

      final area = areas.firstWhere(
          (a) => a.id == _normalizeAreaId(loc.containerYard),
          orElse: () => areas.first);

      // Use area-relative positioning to keep them inside the box
      final baseX = (area.left + pos.dx * area.width) * w;
      final baseY = (area.top + pos.dy * area.height) * h;

      final devicesHere = _devicesForMasterLocation(loc);
      const size = 30.0;

      markers.add(Positioned(
        left: (baseX - size / 2)
            .clamp(area.left * w + 4, (area.left + area.width) * w - size - 4),
        top: (baseY - size / 2)
            .clamp(area.top * h + 4, (area.top + area.height) * h - size - 4),
        child: GestureDetector(
          onTap: () => _showMasterLocationPopup(loc),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildMasterTypeVisual(loc.locationType.toUpperCase(),
                  size: size),
            ],
          ),
        ),
      ));
    }
    return markers;
  }

  List<Widget> _buildAllMarkers(double w, double h) {
    final markers = <Widget>[];
    final Map<String, List<AddedDevice>> grouped = {};
    for (final d in widget.devices) {
      if (widget.forcedAreaId != null &&
          _normalizeAreaId(d.containerYard) != widget.forcedAreaId) {
        continue;
      }
      grouped
          .putIfAbsent(normalizeLocationLabel(d.locationName), () => [])
          .add(d);
    }

    grouped.forEach((locName, devs) {
      final yard = devs.first.containerYard;
      final parent = _getParentPosition(locName, yard);

      if (parent != null) {
        final area = parent.area;
        final rawBaseX = (area.left + parent.cx * area.width) * w;
        final rawBaseY = (area.top + parent.cy * area.height) * h;

        // Exact same clamping as MasterLocation markers (4px padding + 15px half-size)
        final baseX = rawBaseX.clamp(
            area.left * w + 19, (area.left + area.width) * w - 19);
        final baseY = rawBaseY.clamp(
            area.top * h + 19, (area.top + area.height) * h - 19);

        for (int i = 0; i < devs.length; i++) {
          final angle = (2 * pi * i / devs.length) - (pi / 2);
          const radius = 18.0;
          final x = baseX + radius * cos(angle);
          final y = baseY + radius * sin(angle);
          markers.add(_buildDeviceMarker(devs[i], x, y, w, h, area));
        }
      } else {
        // Render devices without parent
        for (int i = 0; i < devs.length; i++) {
          final d = devs[i];
          final area = _findTargetArea(d);
          double x, y;
          if (_isRelativeCoordinate(d.latitude) &&
              _isRelativeCoordinate(d.longitude)) {
            x = (area.left + d.longitude * area.width) * w;
            y = (area.top + d.latitude * area.height) * h;
          } else {
            // Ultimate fallback: center of the area box with small spread so they don't perfectly overlap
            final centerX = (area.left + area.width / 2) * w;
            final centerY = (area.top + area.height / 2) * h;
            final angle = (2 * pi * i / devs.length);
            final radius =
                5.0 + (i * 2.0).clamp(0.0, 15.0); // Spiraling out slightly
            x = centerX + radius * cos(angle);
            y = centerY + radius * sin(angle);
          }
          markers.add(_buildDeviceMarker(d, x, y, w, h, area));
        }
      }
    });

    return markers;
  }

  Widget _buildDeviceMarker(AddedDevice d, double x, double y, double w,
      double h, ContainerYardArea a) {
    const markerSize = 10.0;
    final color = d.status.toUpperCase() == 'UP' ? Colors.green : Colors.red;

    return Positioned(
      left: x.clamp(a.left * w + 5, (a.left + a.width) * w - 5) -
          (markerSize / 2),
      top:
          y.clamp(a.top * h + 5, (a.top + a.height) * h - 5) - (markerSize / 2),
      child: Container(
        width: markerSize,
        height: markerSize,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))
          ],
        ),
      ),
    );
  }

  List<Widget> _buildZoomedMasterLocationMarkers(
      ContainerYardArea area, double w, double h) {
    final markers = <Widget>[];
    for (final loc in widget.masterLocations) {
      if (_normalizeAreaId(loc.containerYard) != area.id) continue;
      final pos = _resolveMasterPosition(loc);
      if (pos == null) continue;

      final ltype = loc.locationType.toUpperCase();
      final canDrag = (['TOWER', 'RTG', 'RS', 'CC'].contains(ltype)) &&
          widget.isFreeroamEditEnabled;
      final key = _masterPreviewKey(loc);

      markers.add(Positioned(
        left: 0,
        top: 0,
        child: Builder(builder: (context) {
          final currentPos = _masterDragPreview[key] ?? pos;

          // In zoomed view, currentPos.dx/dy are treated as relative to the BOX (0-1)
          // Add a small inset (6.0) to prevent the 48px icon from hitting the 3.5px border
          final leftPos = (currentPos.dx * w - 24).clamp(6.0, w - 54);
          final topPos = (currentPos.dy * h - 24).clamp(6.0, h - 54);

          return Transform.translate(
            offset: Offset(leftPos, topPos),
            child: SizedBox(
              width: 48,
              height: 48,
              child: GestureDetector(
                onPanUpdate: canDrag
                    ? (det) {
                        setState(() {
                          final newX = (currentPos.dx + det.delta.dx / w)
                              .clamp(0.0, 1.0);
                          final newY = (currentPos.dy + det.delta.dy / h)
                              .clamp(0.0, 1.0);
                          _masterDragPreview[key] = Offset(newX, newY);
                        });
                      }
                    : null,
                onPanEnd: canDrag
                    ? (_) {
                        if (_masterDragPreview[key] != null) {
                          // Send relative 0-1 back to the server.
                          final globalX = area.left +
                              _masterDragPreview[key]!.dx * area.width;
                          final globalY = area.top +
                              _masterDragPreview[key]!.dy * area.height;
                          final latLng = LayoutMapper.pixelToLatLng(
                              globalX * LayoutMapper.PNG_WIDTH,
                              globalY * LayoutMapper.PNG_HEIGHT);
                          widget.onMasterMoved!(
                              loc, latLng['lat']!, latLng['lng']!);
                        }
                      }
                    : null,
                onTap: () => _showMasterLocationPopup(loc),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: _buildMasterTypeVisual(ltype, size: 44),
                ),
              ),
            ),
          );
        }),
      ));
    }
    return markers;
  }

  List<Widget> _buildZoomedMarkers(
      List<AddedDevice> devs, ContainerYardArea area, double w, double h) {
    final markers = <Widget>[];
    final Map<String, List<AddedDevice>> grouped = {};
    for (final d in devs) {
      grouped
          .putIfAbsent(normalizeLocationLabel(d.locationName), () => [])
          .add(d);
    }
    grouped.forEach((loc, g) {
      final yard = g.first.containerYard;
      final parent = _getParentPosition(loc, yard);

      double baseX, baseY;
      if (parent != null) {
        final rawX = parent.cx * w;
        final rawY = parent.cy * h;
        baseX = (rawX - 24).clamp(6.0, w - 54) + 24;
        baseY = (rawY - 24).clamp(6.0, h - 54) + 24;
      } else {
        // Fallback to center of the specific area box if parent is missing
        baseX = w * 0.5;
        baseY = h * 0.5;
      }

      for (int i = 0; i < g.length; i++) {
        // Slightly tighter radius but still outside the 48px master icon (radius 24)
        // Device radius is 14. 24 + 14 = 38 is the absolute minimum.
        final radius = g.length == 1 ? 22.0 : (g.length > 5 ? 28.0 : 25.0);
        final angle = (2 * pi * i / g.length) - (pi / 2);
        final x = (baseX + radius * cos(angle)).clamp(15.0, w - 15.0);
        final y = (baseY + radius * sin(angle)).clamp(15.0, h - 15.0);
        markers.add(_buildZoomedDeviceMarker(g[i], x, y, w, h));
      }
    });
    return markers;
  }

  Widget _buildZoomedDeviceMarker(
      AddedDevice d, double x, double y, double w, double h) {
    final color = d.status.toUpperCase() == 'UP' ? Colors.green : Colors.red;
    return Positioned(
      left: x - 14,
      top: y - 14,
      width: 28,
      height: 28,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Icon(DeviceIconResolver.iconForType(d.type),
            size: 15, color: color),
      ),
    );
  }

  ContainerYardArea _findTargetArea(AddedDevice d) {
    final loc = d.locationName.toLowerCase();
    if (loc.contains('park')) return areas.firstWhere((a) => a.id == 'PARKING');
    if (loc.contains('gate')) return areas.firstWhere((a) => a.id == 'GATE');
    final parent = _getParentPosition(d.locationName, d.containerYard);
    if (parent != null) return parent.area;
    final yard = _normalizeAreaId(d.containerYard);
    return areas.firstWhere((a) => a.id == yard, orElse: () => areas[0]);
  }

  Widget _buildMasterTypeVisual(String locType, {double size = 20}) {
    final normalizedType = DeviceIconResolver.normalizeType(locType);
    final asset = DeviceIconResolver.assetForType(normalizedType);
    final iconColor = DeviceIconResolver.colorForType(locType);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.9),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: asset != null
          ? Image.asset(
              asset,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                DeviceIconResolver.iconForType(locType),
                color: iconColor,
                size: size,
              ),
            )
          : Icon(
              DeviceIconResolver.iconForType(locType),
              color: iconColor,
              size: size,
            ),
    );
  }

  void _showMasterLocationPopup(MasterLocation location) {
    final devicesHere = _devicesForMasterLocation(location);
    final upCount =
        devicesHere.where((d) => d.status.toUpperCase() == 'UP').length;

    final cleanLabel = formatFullStandardLabel(
      location.locationType,
      location.locationCode.trim().isNotEmpty
          ? location.locationCode
          : location.locationName,
      location.containerYard,
    );

    showDialog(
      context: context,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Dialog(
            backgroundColor: Colors.white,
            elevation: 24,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DeviceIconResolver.colorForType(
                                  location.locationType)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _buildMasterTypeVisual(location.locationType,
                            size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cleanLabel,
                              style: const TextStyle(
                                color: Color(0xFF2C3E50),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'LOCATION DETAILS',
                              style: TextStyle(
                                color: Colors.blueGrey.withValues(alpha: 0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close,
                            color: Colors.grey, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STATUS',
                          style: TextStyle(
                            color: Colors.blueGrey.shade400,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            _buildMiniStatus(upCount, Colors.green),
                            const SizedBox(width: 8),
                            _buildMiniStatus(
                                devicesHere.length - upCount, Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (devicesHere.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Text(
                        'No device registered at this location',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: devicesHere.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (context, index) {
                            final d = devicesHere[index];
                            final isUp = d.status.toUpperCase() == 'UP';
                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              leading: Icon(
                                  DeviceIconResolver.iconForType(d.type),
                                  color: isUp ? Colors.green : Colors.red,
                                  size: 18),
                              title: Text(
                                d.name,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w800),
                              ),
                              subtitle: Text(
                                  'IP: ${d.ipAddress}\nLocation: ${resolveFullLocationLabel(_masterOptions, d.locationName, currentContainerYard: d.containerYard)}',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isUp ? Colors.green : Colors.red)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  d.status.toUpperCase(),
                                  style: TextStyle(
                                    color: isUp ? Colors.green : Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CLOSE',
                          style: TextStyle(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
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

  Widget _buildMiniStatus(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$count',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPopupDetailRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: Colors.blueGrey.shade300),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                    color: Colors.blueGrey.shade300,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
              Text(
                value,
                style: TextStyle(
                    color: valueColor ?? const Color(0xFF2C3E50),
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
