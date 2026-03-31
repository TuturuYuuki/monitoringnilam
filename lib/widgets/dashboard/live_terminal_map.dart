import 'package:flutter/material.dart';
import 'package:monitoring/constants/terminal_data.dart';
import 'package:monitoring/models/device_model.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/widgets/terminal_layout_static.dart';

class LiveTerminalMap extends StatefulWidget {
  final List<AddedDevice> devices;
  final List<Tower> towers;
  final List<Map<String, dynamic>> masterLocations;
  final bool isPickMode;
  final String? pickYardFilter;
  final Function(String areaId, double relX, double relY) onAreaPicked;
  final Function(String towerId, double latitude, double longitude)
      onTowerMoved;
  final Function(Map<String, dynamic> master, double latitude, double longitude)
      onMasterMoved;
  final Future<void> Function({bool force}) onTriggerPingCheck;
  final Future<void> Function() onLoadDashboardData;

  const LiveTerminalMap({
    super.key,
    required this.devices,
    required this.towers,
    required this.masterLocations,
    this.isPickMode = false,
    this.pickYardFilter,
    required this.onAreaPicked,
    required this.onTowerMoved,
    required this.onMasterMoved,
    required this.onTriggerPingCheck,
    required this.onLoadDashboardData,
  });

  @override
  State<LiveTerminalMap> createState() => _LiveTerminalMapState();
}

class _LiveTerminalMapState extends State<LiveTerminalMap> {
  bool _isFreeroamEditMode = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapWidth = constraints.maxWidth;
        final mapHeight = constraints.maxHeight;

        return Container(
          width: mapWidth,
          height: mapHeight,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF3B4D63).withOpacity(0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child:
                        const Icon(Icons.map, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Live Terminal Map',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  if (widget.isPickMode)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        'Pick Mode: ${widget.pickYardFilter ?? 'Pilih area CY'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isFreeroamEditMode = !_isFreeroamEditMode;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isFreeroamEditMode
                                ? 'Edit Freeroam ON'
                                : 'Edit Freeroam OFF',
                          ),
                          backgroundColor:
                              _isFreeroamEditMode ? Colors.orange : Colors.blueGrey,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: Icon(
                      _isFreeroamEditMode ? Icons.edit_off : Icons.edit,
                      size: 18,
                    ),
                    label: Text(_isFreeroamEditMode ? 'Save' : 'Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFreeroamEditMode
                          ? Colors.orange
                          : const Color(0xFF607D8B).withOpacity(0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Checking Status...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      await widget.onTriggerPingCheck(force: true);
                      await widget.onLoadDashboardData();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Status Updated!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Check Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF4CAF50).withOpacity(0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black.withOpacity(0.1),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: TerminalLayoutStatic(
                    devices: widget.devices,
                    towers: widget.towers,
                    masterLocations: widget.masterLocations,
                    isPickMode: widget.isPickMode,
                    pickYardFilter: widget.pickYardFilter,
                    onAreaPicked: widget.onAreaPicked,
                    isFreeroamEditEnabled: _isFreeroamEditMode,
                    onTowerMoved: widget.onTowerMoved,
                    onMasterMoved: widget.onMasterMoved,
                    towerPoints: towerPoints
                        .map(
                          (p) => StaticTowerPoint(
                            number: p.number,
                            label: p.label,
                            latitude: p.latitude,
                            longitude: p.longitude,
                            containerYard: p.containerYard,
                            towerIdHint: p.towerIdHint,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
