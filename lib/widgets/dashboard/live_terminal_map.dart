import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  static const List<String> _mobileAreas = [
    'CY1',
    'CY2',
    'CY3',
    'PARKING',
    'GATE',
  ];
  String? _mobileFocusedArea;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: const Color(0xFF3B4D63).withValues(alpha: 0.92),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.map,
                      color: Colors.white,
                      size: isMobile ? 22 : 28,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Live Terminal Map',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 21 : 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (widget.isPickMode)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        'Pick: ${widget.pickYardFilter ?? 'CY'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment:
                    kIsWeb ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  kIsWeb
                      ? SizedBox(
                          width: 150,
                          child: _buildEditButton(),
                        )
                      : Expanded(
                          child: _buildEditButton(),
                        ),
                  const SizedBox(width: 8),
                  kIsWeb
                      ? SizedBox(
                          width: 150,
                          child: _buildRefreshButton(),
                        )
                      : Expanded(
                          child: _buildRefreshButton(),
                        ),
                ],
              ),
              SizedBox(height: isMobile ? 10 : 18),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, mapConstraints) {
                    final baseMap = Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black.withValues(alpha: 0.1),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: TerminalLayoutStatic(
                        devices: widget.devices,
                        towers: widget.towers,
                        masterLocations: widget.masterLocations,
                        isPickMode: widget.isPickMode,
                        pickYardFilter: widget.pickYardFilter,
                        forcedAreaId: null,
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
                    );

                    if (!isMobile) {
                      return baseMap;
                    }

                    return ListView.separated(
                      itemCount: _mobileAreas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final areaId = _mobileAreas[index];
                        final isFocused = _mobileFocusedArea == areaId;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _mobileFocusedArea = isFocused ? null : areaId;
                            });
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: isFocused ? 250 : 220,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white24),
                                color: Colors.black.withValues(alpha: 0.08),
                              ),
                              child: TerminalLayoutStatic(
                                devices: widget.devices,
                                towers: widget.towers,
                                masterLocations: widget.masterLocations,
                                isPickMode: widget.isPickMode,
                                pickYardFilter: widget.pickYardFilter,
                                forcedAreaId: areaId,
                                isZoomed: isFocused,
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
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditButton() {
    return ElevatedButton.icon(
      onPressed: () {
        final messenger = ScaffoldMessenger.of(context);
        setState(() {
          _isFreeroamEditMode = !_isFreeroamEditMode;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _isFreeroamEditMode ? 'Edit Freeroam ON' : 'Edit Freeroam OFF',
            ),
            backgroundColor:
                _isFreeroamEditMode ? Colors.orange : Colors.blueGrey,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      icon: Icon(
        _isFreeroamEditMode ? Icons.edit_off : Icons.edit,
        size: kIsWeb ? 14 : 16,
      ),
      label: Text(_isFreeroamEditMode ? 'Save' : 'Edit'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isFreeroamEditMode
            ? Colors.orange
            : const Color(0xFF607D8B).withValues(alpha: 0.8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: kIsWeb ? 6 : 10,
          vertical: kIsWeb ? 4 : 8,
        ),
        textStyle: const TextStyle(
          fontSize: kIsWeb ? 10 : 12,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Checking Status...'),
            duration: Duration(seconds: 2),
          ),
        );
        await widget.onTriggerPingCheck(force: true);
        await widget.onLoadDashboardData();
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('✓ Status Updated!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      },
      icon: const Icon(Icons.refresh, size: kIsWeb ? 14 : 16),
      label: const Text('Check Status'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: kIsWeb ? 6 : 10,
          vertical: kIsWeb ? 4 : 8,
        ),
        textStyle: const TextStyle(
          fontSize: kIsWeb ? 10 : 12,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
