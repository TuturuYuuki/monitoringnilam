import 'package:flutter/material.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/models/device_model.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/models/master_location_model.dart';
import 'package:monitoring/widgets/terminal_layout_static.dart';

class MapPickerDialog extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String? yard;

  const MapPickerDialog({
    super.key,
    this.initialLat = -7.209191,
    this.initialLng = 112.725250,
    this.yard,
  });

  @override
  State<MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<MapPickerDialog> {
  late double selectedLat;
  late double selectedLng;

  bool _isLoading = true;
  List<AddedDevice> _devices = [];
  List<Tower> _towers = [];
  List<MasterLocation> _masterLocations = [];

  @override
  void initState() {
    super.initState();
    selectedLat = widget.initialLat;
    selectedLng = widget.initialLng;
    _fetchData();
  }

  Future<void> _fetchData() async {
    final apiService = ApiService();
    try {
      final towers = await apiService.getAllTowers();
      final cameras = await apiService.getAllCameras();
      final nvrs = await apiService.getAllNVRs();
      final switches = await apiService.getAllSwitches();
      final mmts = await apiService.getAllMMTs();
      final rawMasters = await apiService.getAllMasterLocations();
      
      final masters = rawMasters.map((m) => MasterLocation.fromMap(m)).toList();
      
      final List<AddedDevice> allDevices = [];
      
      void addDevice(String idPrefix, String type, dynamic dev, String name, String ip, String loc, double lat, double lng, String yard, String status, String createdAt) {
        allDevices.add(AddedDevice(
          id: '${idPrefix}_${dev.hashCode}',
          type: type,
          name: name,
          ipAddress: ip,
          locationName: loc,
          latitude: lat,
          longitude: lng,
          containerYard: yard,
          createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
          status: status,
        ));
      }

      for (var c in cameras) {
        addDevice('camera', 'CCTV', c, c.cameraId, c.ipAddress, c.location, c.latitude ?? 0, c.longitude ?? 0, c.containerYard, c.status, c.createdAt);
      }
      for (var m in mmts) {
        addDevice('mmt', 'MMT', m, m.mmtId, m.ipAddress, m.location, 0, 0, m.containerYard, m.status, m.createdAt);
      }
      for (var n in nvrs) {
        addDevice('nvr', 'NVR', n, n.nvrId, n.ipAddress, n.location, n.latitude ?? 0, n.longitude ?? 0, n.containerYard, n.status, n.createdAt);
      }
      for (var s in switches) {
        addDevice('switch', 'SWITCH', s, s.switchId, s.ipAddress, s.location, s.latitude ?? 0, s.longitude ?? 0, s.containerYard, s.status, s.createdAt);
      }

      if (mounted) {
        setState(() {
          _towers = towers;
          _devices = allDevices;
          _masterLocations = masters;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If selected coordinates are relative and not exactly 0,0 (unset), use them to draw marker
    final bool isRelative = selectedLat >= 0.0 && selectedLat <= 1.0 && 
                            selectedLng >= 0.0 && selectedLng <= 1.0 &&
                            !(selectedLat == 0.0 && selectedLng == 0.0);

    return AlertDialog(
      backgroundColor: const Color(0xFFFCFDFF),
      surfaceTintColor: Colors.white,
      elevation: 18,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      title: const Text(
        'Choose Location',
        style: TextStyle(
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.w800,
          fontSize: 22,
          letterSpacing: 0.2,
        ),
      ),
      content: SizedBox(
        width: 980,
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.touch_app_rounded,
                      size: 18,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tap on the map to set location for ${widget.yard ?? "the area"}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFFFFF), Color(0xFFF1F7FF)],
                  ),
                  border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final innerW = constraints.maxWidth - 20;
                          final innerH = constraints.maxHeight - 20;

                          return Stack(
                            children: [
                              Positioned.fill(
                                child: TerminalLayoutStatic(
                                  devices: _devices,
                                  towers: _towers,
                                  masterLocations: _masterLocations,
                                  isPickMode: true,
                                  pickYardFilter: widget.yard,
                                  forcedAreaId: widget.yard,
                                  isZoomed: widget.yard != null,
                                  onAreaPicked: (areaId, relX, relY) {
                                    setState(() {
                                      selectedLat = relX;
                                      selectedLng = relY;
                                    });
                                  },
                                ),
                              ),
                              if (isRelative)
                                Positioned(
                                  left: 10 + (selectedLat * innerW),
                                  top: 10 + (selectedLng * innerH),
                                  child: Transform.translate(
                                    offset: const Offset(-18, -18),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFEF4444).withValues(alpha: 0.28),
                                            blurRadius: 14,
                                            spreadRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        margin: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFF87171), Color(0xFFEF4444)],
                                          ),
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.location_on_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCoordinateChip(
                      label: 'Lat (Rel X)',
                      value: selectedLat.toStringAsFixed(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCoordinateChip(
                      label: 'Lng (Rel Y)',
                      value: selectedLng.toStringAsFixed(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            {'latitude': selectedLat, 'longitude': selectedLng},
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
            shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.28),
          ),
          child: const Text(
            'Choose Location',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildCoordinateChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
