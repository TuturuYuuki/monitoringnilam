import 'package:flutter/material.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/models/device_model.dart';
import 'package:monitoring/models/camera_model.dart';
import 'package:monitoring/services/ping_service.dart';

class TowerDetailPanel extends StatefulWidget {
  final Tower tower;
  final List<AddedDevice> towers;
  final List<AddedDevice> devices;
  final List<Camera> cameras;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  const TowerDetailPanel({
    super.key,
    required this.tower,
    required this.towers,
    required this.devices,
    required this.cameras,
    required this.onEdit,
    required this.onDelete,
    required this.onClose,
  });

  @override
  State<TowerDetailPanel> createState() => _TowerDetailPanelState();
}

class _TowerDetailPanelState extends State<TowerDetailPanel> {
  final PingService _pingService = PingService();
  Map<String, bool> _deviceStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDeviceStatus();
  }

  Future<void> _checkDeviceStatus() async {
    setState(() => _isLoading = true);

    // Get all connected devices (towers, devices, cameras) in same container yard
    final allIPs = <String>[
      widget.tower.ipAddress,
      ...widget.towers.where((d) => d.containerYard == widget.tower.containerYard).map((d) => d.ipAddress),
      ...widget.devices.where((d) => d.containerYard == widget.tower.containerYard).map((d) => d.ipAddress),
      ...widget.cameras.where((c) => c.containerYard == widget.tower.containerYard).map((c) => c.ipAddress),
    ].where((ip) => ip.isNotEmpty).toList();

    if (allIPs.isNotEmpty) {
      final results = await _pingService.pingMultiple(allIPs);
      if (mounted) {
        setState(() {
          _deviceStatus = results;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final childTowers = widget.towers.where((d) => d.containerYard == widget.tower.containerYard && d.id != widget.tower.id.toString()).toList();
    final childDevices = widget.devices.where((d) => d.containerYard == widget.tower.containerYard).toList();
    final childCameras = widget.cameras.where((c) => c.containerYard == widget.tower.containerYard).toList();

    final towerStatus = _deviceStatus[widget.tower.ipAddress] ?? false;
    final towerStatusColor = towerStatus ? Colors.green : Colors.red;
    final towerStatusText = towerStatus ? 'UP' : 'DOWN';

    int upCount = 0;
    int downCount = 0;

    for (final child in [...childTowers, ...childDevices, ...childCameras]) {
      final ip = (child is AddedDevice) ? child.ipAddress : (child as Camera).ipAddress;
      if (_deviceStatus[ip] == true) {
        upCount++;
      } else {
        downCount++;
      }
    }

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tower.towerId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.tower.location,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: towerStatusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          towerStatusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IP Address
                  _buildInfoRow(
                    'IP Address:',
                    widget.tower.ipAddress,
                    Icons.router,
                  ),
                  const SizedBox(height: 12),

                  // Container Yard
                  _buildInfoRow(
                    'Container Yard:',
                    widget.tower.containerYard,
                    Icons.location_on,
                  ),
                  const SizedBox(height: 12),

                  // Device summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              upCount.toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text(
                              'UP',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        Column(
                          children: [
                            Text(
                              downCount.toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const Text(
                              'DOWN',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        Column(
                          children: [
                            Text(
                              (upCount + downCount).toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Text(
                              'Total',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Connected devices
            if (childTowers.isNotEmpty || childDevices.isNotEmpty || childCameras.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Text(
                      'Connected Devices',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : Column(
                            children: [
                              // Towers
                              ...childTowers.map((tower) {
                                final isUp = _deviceStatus[tower.ipAddress] ?? false;
                                return _buildDeviceRow(
                                  tower.name,
                                  tower.ipAddress ?? 'N/A',
                                  isUp,
                                  Icons.router,
                                );
                              }),
                              // Devices
                              ...childDevices.map((device) {
                                final isUp = _deviceStatus[device.ipAddress] ?? false;
                                return _buildDeviceRow(
                                  device.name,
                                  device.ipAddress ?? 'N/A',
                                  isUp,
                                  Icons.devices,
                                );
                              }),
                              // Cameras
                              ...childCameras.map((camera) {
                                final isUp = _deviceStatus[camera.ipAddress] ?? false;
                                return _buildDeviceRow(
                                  camera.cameraId,
                                  camera.ipAddress,
                                  isUp,
                                  Icons.videocam,
                                );
                              }),
                            ],
                          ),
                  ],
                ),
              ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Hapus Tower?'),
                            content: const Text('Aksi ini tidak dapat dibatalkan.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onDelete();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Refresh button
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _checkDeviceStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Status'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceRow(String name, String ip, bool isUp, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(
              color: isUp ? Colors.green : Colors.red,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ip,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isUp ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isUp ? 'UP' : 'DOWN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isUp ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
