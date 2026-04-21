import 'package:flutter/material.dart';
import 'package:monitoring/models/device_model.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/models/camera_model.dart';
import 'package:monitoring/widgets/terminal_layout_static.dart';
import 'package:monitoring/widgets/tower_detail_panel.dart';
import 'package:monitoring/services/api_service.dart';

class EnhancedTerminalLayout extends StatefulWidget {
  final List<AddedDevice> devices;
  final List<Tower> towers;
  final List<Camera> cameras;

  const EnhancedTerminalLayout({
    super.key,
    required this.devices,
    required this.towers,
    required this.cameras,
  });

  @override
  State<EnhancedTerminalLayout> createState() => _EnhancedTerminalLayoutState();
}

class _EnhancedTerminalLayoutState extends State<EnhancedTerminalLayout> {
  final ApiService _apiService = ApiService();
  late Map<int, Offset> _towerOffsets = {};
  Tower? _selectedTower;
  bool _isDraggingTower = false;
  int? _draggingTowerId;

  @override
  void initState() {
    super.initState();
    _initializeTowerOffsets();
  }

  void _initializeTowerOffsets() {
    // Initialize tower offsets from their lat/lng coordinates
    _towerOffsets = {};
    for (final tower in widget.towers) {
      if (tower.latitude != null && tower.longitude != null) {
        _towerOffsets[tower.id] = Offset(
          tower.longitude!,
          tower.latitude!,
        );
      }
    }
  }

  Future<void> _updateTowerPosition(Tower tower, double newLat, double newLng) async {
    try {
      print('Updating tower ${tower.towerId} to lat:$newLat, lng:$newLng');
      
      // Call backend API to update position
      await _apiService.updateTowerPosition(tower.id, newLat, newLng);
      
      print('✅ Tower position updated successfully');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${tower.towerId} position updated'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating tower position: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main map with interactive viewer for zoom/pan
        InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: GestureDetector(
            onPanDown: (details) {
              // Check if tapping on a tower
              _checkTowerTap(details.localPosition);
            },
            child: TerminalLayoutStatic(
              devices: widget.devices,
              towers: widget.towers,
              towerPoints: const [],
            ),
          ),
        ),

        // Draggable towers overlay
        ..._buildDraggableTowers(),

        // Detail panel
        if (_selectedTower != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: TowerDetailPanel(
              tower: _selectedTower!,
              towers: widget.devices,
              devices: widget.devices,
              cameras: widget.cameras,
              onEdit: () {
                // TODO: Implement edit
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit feature coming soon')),
                );
              },
              onDelete: () async {
                try {
                  await _apiService.deleteTower(_selectedTower!.id);
                  if (mounted) {
                    setState(() => _selectedTower = null);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Tower deleted')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              onClose: () {
                setState(() => _selectedTower = null);
              },
            ),
          ),
      ],
    );
  }

  List<Widget> _buildDraggableTowers() {
    return widget.towers.map((tower) {
      if (tower.latitude == null || tower.longitude == null) {
        return const SizedBox.shrink();
      }

      // Convert lat/lng to screen position (simplified - assumes direct mapping)
      // In real implementation, you'd need proper geo-to-screen conversion
      final position = Offset(
        tower.longitude! * 100000,
        tower.latitude! * 100000,
      );

      return Positioned(
        left: position.dx,
        top: position.dy,
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              _isDraggingTower = true;
              _draggingTowerId = tower.id;
            });
          },
          onPanUpdate: (details) {
            // Update visual position during drag
            // This would require a more complex state management
          },
          onPanEnd: (details) {
            // Save new position to database
            //  _updateTowerPosition(tower, newLat, newLng);
            setState(() {
              _isDraggingTower = false;
              _draggingTowerId = null;
            });
          },
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedTower = tower);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tower.status == 'UP' ? Colors.green : Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedTower?.id == tower.id ? Colors.blue : Colors.white,
                  width: _selectedTower?.id == tower.id ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (tower.status == 'UP' ? Colors.green : Colors.red)
                        .withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Center(
                child: Text(
                  tower.towerNumber.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _checkTowerTap(Offset position) {
    // Check if tap is within any tower's bounds
    for (final tower in widget.towers) {
      if (tower.latitude == null || tower.longitude == null) continue;

      final towerPos = Offset(
        tower.longitude! * 100000,
        tower.latitude! * 100000,
      );

      // Check if position is within tower's tap area (±30px)
      if ((position - towerPos).distance < 30) {
        setState(() => _selectedTower = tower);
        return;
      }
    }

    // No tower tapped, close detail panel
    setState(() => _selectedTower = null);
  }
}
