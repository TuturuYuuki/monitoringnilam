import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'services/api_service.dart';
import 'models/camera_model.dart';
import 'models/tower_model.dart';
import 'models/alert_model.dart';
import 'models/device_model.dart';
import 'network.dart';
import 'cctv.dart';
import 'alerts.dart';
import 'profile.dart';
import 'add_device.dart';
import 'services/device_storage_service.dart';
import 'utils/tower_status_override.dart';

// Konstanta lokasi TPK Nilam - sesuai layout gambar
class TPKNilamLocation {
  static const String name = 'Terminal Nilam';
  static const double latitude = -7.207277;
  static const double longitude = 112.723613;
  static const LatLng coordinate = LatLng(latitude, longitude);
  static const double defaultZoom = 16.5;
}

// Container Yards - sesuai layout gambar ilustrasi
class ContainerYard {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final Color color;

  ContainerYard({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.color,
  });

  LatLng get coordinate => LatLng(latitude, longitude);
}

// Tower/Access Point - sesuai layout gambar ilustrasi
class TowerPoint {
  final int number;
  final String name;
  final String label;
  final double latitude;
  final double longitude;
  final String containerYard;
  final String? towerIdHint;

  TowerPoint({
    required this.number,
    required this.name,
    String? label,
    required this.latitude,
    required this.longitude,
    required this.containerYard,
    this.towerIdHint,
  }) : label = label ?? name;

  LatLng get coordinate => LatLng(latitude, longitude);
}

// Data Container Yards - koordinat presisi
final List<ContainerYard> containerYards = [
  ContainerYard(
    id: 'CY1',
    name: 'Container Yard 1',
    latitude: -7.205843,
    longitude: 112.723164,
    color: const Color(0xFFFFB74D), // Orange
  ),
  ContainerYard(
    id: 'CY2',
    name: 'Container Yard 2',
    latitude: -7.209152,
    longitude: 112.724487,
    color: const Color(0xFF66BB6A), // Hijau
  ),
  ContainerYard(
    id: 'CY3',
    name: 'Container Yard 3',
    latitude: -7.208712,
    longitude: 112.723270,
    color: const Color(0xFFEF9A9A), // Pink
  ),
];

// Special Locations
class SpecialLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final Color color;
  final IconData icon;
  final String? iconAsset;

  SpecialLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.color,
    required this.icon,
    this.iconAsset,
  });

  LatLng get coordinate => LatLng(latitude, longitude);
}

class DeviceLocationPoint {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String containerYard;
  final Color color;
  final String iconAsset;
  String status; // UP or DOWN - mutable for updates

  DeviceLocationPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.containerYard,
    required this.color,
    required this.iconAsset,
    this.status = 'UP', // default UP
  });

  LatLng get coordinate => LatLng(latitude, longitude);
}

final List<SpecialLocation> specialLocations = [
  SpecialLocation(
    id: 'GATE',
    name: 'Gate In/Out',
    latitude: -7.2099123,
    longitude: 112.7244489,
    color: const Color.fromARGB(255, 0, 0, 0),
    icon: Icons.directions_walk,
    iconAsset: 'assets/images/Gate.png',
  ),
  SpecialLocation(
    id: 'PARKING',
    name: 'Parking',
    latitude: -7.209907,
    longitude: 112.724877,
    color: const Color.fromARGB(255, 0, 0, 0),
    icon: Icons.local_parking,
    iconAsset: 'assets/images/Parking.png',
  ),
];

final List<DeviceLocationPoint> deviceLocationPoints = [
  // CC (CY1)
  DeviceLocationPoint(
    id: 'CC01',
    name: 'CC01 - CY1',
    latitude: -7.204768,
    longitude: 112.723299,
    containerYard: 'CY1',
    color: const Color(0xFF455A64),
    iconAsset: 'assets/images/CC.png',
  ),
  DeviceLocationPoint(
    id: 'CC02',
    name: 'CC02 - CY1',
    latitude: -7.205358,
    longitude: 112.723571,
    containerYard: 'CY1',
    color: const Color(0xFF455A64),
    iconAsset: 'assets/images/CC.png',
  ),
  DeviceLocationPoint(
    id: 'CC03',
    name: 'CC03 - CY1',
    latitude: -7.205947,
    longitude: 112.723840,
    containerYard: 'CY1',
    color: const Color(0xFF455A64),
    iconAsset: 'assets/images/CC.png',
  ),
  DeviceLocationPoint(
    id: 'CC04',
    name: 'CC04 - CY1',
    latitude: -7.206656,
    longitude: 112.724164,
    containerYard: 'CY1',
    color: const Color(0xFF455A64),
    iconAsset: 'assets/images/CC.png',
  ),
  // RTG
  DeviceLocationPoint(
    id: 'RTG01',
    name: 'RTG01 - CY1',
    latitude: -7.204805,
    longitude: 112.722550,
    containerYard: 'CY1',
    color: const Color(0xFFFF9800),
    iconAsset: 'assets/images/RTG.png',
  ),
  DeviceLocationPoint(
    id: 'RTG02',
    name: 'RTG02 - CY1',
    latitude: -7.205129,
    longitude: 112.723000,
    containerYard: 'CY1',
    color: const Color(0xFFFF9800),
    iconAsset: 'assets/images/RTG.png',
  ),
  DeviceLocationPoint(
    id: 'RTG03',
    name: 'RTG03 - CY1',
    latitude: -7.205998,
    longitude: 112.722836,
    containerYard: 'CY1',
    color: const Color(0xFFFF9800),
    iconAsset: 'assets/images/RTG.png',
  ),
  DeviceLocationPoint(
    id: 'RTG04',
    name: 'RTG04 - CY1',
    latitude: -7.206359,
    longitude: 112.723258,
    containerYard: 'CY1',
    color: const Color(0xFFFF9800),
    iconAsset: 'assets/images/RTG.png',
  ),
  DeviceLocationPoint(
    id: 'RTG05',
    name: 'RTG05 - CY1',
    latitude: -7.206749,
    longitude: 112.723464,
    containerYard: 'CY1',
    color: const Color(0xFFFF9800),
    iconAsset: 'assets/images/RTG.png',
  ),
  DeviceLocationPoint(
    id: 'RTG06',
    name: 'RTG06 - CY1',
    latitude: -7.207079,
    longitude: 112.723899,
    containerYard: 'CY1',
    color: const Color(0xFFFF9800),
    iconAsset: 'assets/images/RTG.png',
  ),
  DeviceLocationPoint(
    id: 'RTG07',
    name: 'RTG07 - CY2',
    latitude: -7.208641,
    longitude: 112.724410,
    containerYard: 'CY2',
    color: const Color(0xFFFF9800),
    iconAsset: 'assets/images/RTG.png',
  ),
  DeviceLocationPoint(
    id: 'RTG08',
    name: 'RTG08 - CY2',
    latitude: -7.208957,
    longitude: 112.724877,
    containerYard: 'CY2',
    color: const Color(0xFFFF9800),
    iconAsset: 'assets/images/RTG.png',
  ),
  // RS
  DeviceLocationPoint(
    id: 'RS',
    name: 'RS - CY3',
    latitude: -7.207700,
    longitude: 112.723028,
    containerYard: 'CY3',
    color: const Color(0xFF7B1FA2),
    iconAsset: 'assets/images/RS.png',
  ),
];

// Tower Points - 26 towers sesuai list koordinat
final List<TowerPoint> towerPoints = [
  // CY2 Towers (1-6)
  TowerPoint(
      number: 1,
      name: 'Tower 1',
      label: '1',
      latitude: -7.209459,
      longitude: 112.724717,
      containerYard: 'CY2'),
  TowerPoint(
      number: 2,
      name: 'Tower 2',
      label: '2',
      latitude: -7.209191,
      longitude: 112.725250,
      containerYard: 'CY2'),
  TowerPoint(
      number: 3,
      name: 'Tower 3',
      label: '3',
      latitude: -7.208561,
      longitude: 112.724946,
      containerYard: 'CY2'),
  TowerPoint(
      number: 4,
      name: 'Tower 4',
      label: '4',
      latitude: -7.208150,
      longitude: 112.724395,
      containerYard: 'CY2'),
  TowerPoint(
      number: 5,
      name: 'Tower 5',
      label: '5',
      latitude: -7.208262,
      longitude: 112.724161,
      containerYard: 'CY2'),
  TowerPoint(
      number: 6,
      name: 'Tower 6',
      label: '6',
      latitude: -7.208956,
      longitude: 112.724173,
      containerYard: 'CY2'),

  // CY1 Towers (7-17)
  TowerPoint(
      number: 7,
      name: 'Tower 7',
      label: '7',
      latitude: -7.207690,
      longitude: 112.723693,
      containerYard: 'CY1'),
  TowerPoint(
      number: 8,
      name: 'Tower 8',
      label: '8',
      latitude: -7.207567,
      longitude: 112.723945,
      containerYard: 'CY1'),
  TowerPoint(
      number: 9,
      name: 'Tower 9',
      label: '9',
      latitude: -7.207156,
      longitude: 112.724302,
      containerYard: 'CY1'),
  TowerPoint(
      number: 10,
      name: 'Tower 10',
      label: '10',
      latitude: -7.204341,
      longitude: 112.722956,
      containerYard: 'CY1'),
  TowerPoint(
      number: 11,
      name: 'Tower 11',
      label: '11',
      latitude: -7.204080,
      longitude: 112.722354,
      containerYard: 'CY1'),
  TowerPoint(
      number: 27,
      name: 'Tower 12A',
      label: '12A',
      towerIdHint: '12A',
      latitude: -7.204228,
      longitude: 112.722045,
      containerYard: 'CY1'),
  TowerPoint(
      number: 12,
      name: 'Tower 12',
      label: '12',
      latitude: -7.204460,
      longitude: 112.721970,
      containerYard: 'CY1'),
  TowerPoint(
      number: 13,
      name: 'Tower 13',
      label: '13',
      latitude: -7.205410,
      longitude: 112.722386,
      containerYard: 'CY1'),
  TowerPoint(
      number: 14,
      name: 'Tower 14',
      label: '14',
      latitude: -7.206786,
      longitude: 112.723023,
      containerYard: 'CY1'),
  TowerPoint(
      number: 15,
      name: 'Tower 15',
      label: '15',
      latitude: -7.207566,
      longitude: 112.723469,
      containerYard: 'CY1'),
  TowerPoint(
      number: 16,
      name: 'Tower 16',
      label: '16',
      latitude: -7.207342,
      longitude: 112.723059,
      containerYard: 'CY1'),
  TowerPoint(
      number: 17,
      name: 'Tower 17',
      label: '17',
      latitude: -7.209240,
      longitude: 112.723915,
      containerYard: 'CY1'),

  // CY3 Towers (18-26)
  TowerPoint(
      number: 18,
      name: 'Tower 18',
      label: '18',
      latitude: -7.210090,
      longitude: 112.724321,
      containerYard: 'CY3'),
  TowerPoint(
      number: 19,
      name: 'Tower 19',
      label: '19',
      latitude: -7.210336,
      longitude: 112.723639,
      containerYard: 'CY3'),
  TowerPoint(
      number: 20,
      name: 'Tower 20',
      label: '20',
      latitude: -7.210082,
      longitude: 112.723303,
      containerYard: 'CY3'),
  TowerPoint(
      number: 21,
      name: 'Tower 21',
      label: '21',
      latitude: -7.209070,
      longitude: 112.722914,
      containerYard: 'CY3'),
  TowerPoint(
      number: 22,
      name: 'Tower 22',
      label: '22',
      latitude: -7.208501,
      longitude: 112.722942,
      containerYard: 'CY3'),
  TowerPoint(
      number: 23,
      name: 'Tower 23',
      label: '23',
      latitude: -7.208017,
      longitude: 112.722195,
      containerYard: 'CY3'),
  TowerPoint(
      number: 24,
      name: 'Tower 24',
      label: '24',
      latitude: -7.207314,
      longitude: 112.722005,
      containerYard: 'CY3'),
  TowerPoint(
      number: 25,
      name: 'Tower 25',
      label: '25',
      latitude: -7.207213,
      longitude: 112.722232,
      containerYard: 'CY3'),
  TowerPoint(
      number: 26,
      name: 'Tower 26',
      label: '26',
      latitude: -7.207029,
      longitude: 112.722613,
      containerYard: 'CY3'),
];

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late MapController mapController;

  late ApiService apiService;
  List<Camera> cameras = [];
  List<Tower> towers = [];
  List<Alert> alerts = [];
  List<AddedDevice> addedDevices = [];
  Map<String, String> deviceStatuses = {};
  Timer? _refreshTimer;
  Timer? _blinkTimer;
  int totalUpCameras = 0;
  int totalDownCameras = 0;
  int totalOnlineTowers = 0;
  int totalTowers = 0;

  // Tracking blinking locations with multiple devices where at least one is DOWN
  Set<String> _locationKeysWithDownDevices = {};
  bool _isBlinkVisible = true;

  int get totalDownTowers => totalTowers - totalOnlineTowers;
  double get towerUptimePercent =>
      totalTowers == 0 ? 0 : (totalOnlineTowers / totalTowers) * 100;
  List<Alert> get activeAlerts => alerts
      .where((a) => a.severity == 'critical' || a.severity == 'warning')
      .toList();
  int get totalActiveAlerts => activeAlerts.length;
  int get criticalAlertsCount =>
      activeAlerts.where((a) => a.severity == 'critical').length;
  int get warningAlertsCount =>
      activeAlerts.where((a) => a.severity == 'warning').length;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    apiService = ApiService();
    _loadDashboardData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _loadDashboardData();
      }
    });

    // Start blinking animation timer (toggle every 500ms = 1 second cycle)
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted && _locationKeysWithDownDevices.isNotEmpty) {
        setState(() {
          _isBlinkVisible = !_isBlinkVisible;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning from add device or other pages
    // This ensures added device icons appear immediately on map
    if (mounted) {
      _loadDashboardData();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _blinkTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Trigger realtime ping check first to update all statuses
      // Add timeout to prevent hanging on long standby
      await _triggerPingCheck().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Warning: Ping check timed out after 15 seconds');
        },
      );

      // Load core data with timeout
      final fetchedCameras = await apiService.getAllCameras().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Warning: Get cameras timed out');
          return cameras; // Return existing data if timeout
        },
      );

      final fetchedTowers = await apiService.getAllTowers().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Warning: Get towers timed out');
          return towers; // Return existing data if timeout
        },
      );

      final fetchedAlerts = await apiService.getAllAlerts().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Warning: Get alerts timed out');
          return alerts; // Return existing alerts if timeout
        },
      );

      // Apply forced status overrides before generating alerts
      final updatedTowers = applyForcedTowerStatus(fetchedTowers);
      final updatedCameras = applyForcedCameraStatus(fetchedCameras);

      // Auto-generate DOWN alerts so the dashboard card matches Alerts page
      final generatedAlerts = <Alert>[];

      // Update device location point statuses from MMT data (with timeout)
      await _updateDeviceLocationStatuses().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Warning: Update device location statuses timed out');
        },
      );

      for (final tower in updatedTowers) {
        if (isDownStatus(tower.status)) {
          String route = '/ ';
          if (tower.containerYard == 'CY2') {
            route = '/network-cy2';
          } else if (tower.containerYard == 'CY3') {
            route = '/network-cy3';
          }

          final timestamp = tower.updatedAt.isNotEmpty
              ? tower.updatedAt
              : (tower.createdAt.isNotEmpty
                  ? tower.createdAt
                  : DateTime.now().toString());

          generatedAlerts.add(Alert(
            id: 'tower-${tower.id}',
            title: 'Access Point DOWN - ${tower.towerId}',
            description:
                '${tower.location} access point offline (${tower.towerId})',
            severity: 'critical',
            timestamp: timestamp,
            route: route,
            category: 'Access Point',
          ));
        }
      }

      for (final camera in updatedCameras) {
        if (isDownStatus(camera.status)) {
          String route = '/cctv';
          if (camera.containerYard == 'CY2') {
            route = '/cctv-cy2';
          } else if (camera.containerYard == 'CY3') {
            route = '/cctv-cy3';
          }

          final timestamp = camera.updatedAt.isNotEmpty
              ? camera.updatedAt
              : (camera.createdAt.isNotEmpty
                  ? camera.createdAt
                  : DateTime.now().toString());

          generatedAlerts.add(Alert(
            id: 'camera-${camera.id}',
            title: 'CCTV DOWN - ${camera.cameraId}',
            description:
                '${camera.location} camera offline (${camera.cameraId})',
            severity: 'critical',
            timestamp: timestamp,
            route: route,
            category: 'CCTV',
          ));
        }
      }
      // Load added devices from storage (with error handling)
      List<AddedDevice> devices = [];
      try {
        devices = await DeviceStorageService.getDevices().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('Warning: Get devices from storage timed out');
            return addedDevices; // Return existing data if timeout
          },
        );
      } catch (e) {
        print('Error loading devices from storage: $e');
        devices = addedDevices; // Keep existing data on error
      }

      // Update added devices status from MMT/Tower/Camera data
      for (var device in devices) {
        if (device.type == 'MMT') {
          device.status = deviceStatuses[device.name] ??
              deviceStatuses[device.id] ??
              'DOWN';
        } else if (device.type == 'Access Point' || device.type == 'Tower') {
          final tower = updatedTowers.firstWhere(
            (t) => t.towerId == device.name || t.ipAddress == device.ipAddress,
            orElse: () => updatedTowers.first,
          );
          if (tower.towerId == device.name ||
              tower.ipAddress == device.ipAddress) {
            device.status = tower.status;
          }
        } else if (device.type == 'CCTV') {
          final camera = updatedCameras.firstWhere(
            (c) => c.cameraId == device.name || c.ipAddress == device.ipAddress,
            orElse: () => updatedCameras.first,
          );
          if (camera.cameraId == device.name ||
              camera.ipAddress == device.ipAddress) {
            device.status = camera.status;
          }
        }
      }

      // Sort added devices so the newest appears on top (reverse order for drawing)
      devices.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Only update state if we got valid data (not empty)
      // This prevents status becoming 0 after long standby errors
      if (mounted &&
          (updatedCameras.isNotEmpty ||
              updatedTowers.isNotEmpty ||
              cameras.isNotEmpty ||
              towers.isNotEmpty)) {
        setState(() {
          cameras = updatedCameras.isNotEmpty ? updatedCameras : cameras;
          totalUpCameras = cameras.where((c) => !isDownStatus(c.status)).length;
          totalDownCameras =
              cameras.where((c) => isDownStatus(c.status)).length;

          towers = updatedTowers.isNotEmpty ? updatedTowers : towers;
          totalOnlineTowers =
              towers.where((t) => !isDownStatus(t.status)).length;
          totalTowers = towers.length;

          alerts = [...fetchedAlerts, ...generatedAlerts];
          addedDevices = devices;

          // Detect locations with multiple devices where at least one is DOWN
          _updateBlinkingLocations();
        });
      } else if (mounted && cameras.isEmpty && towers.isEmpty) {
        // First load case - set even if empty
        setState(() {
          cameras = updatedCameras;
          totalUpCameras = cameras.where((c) => !isDownStatus(c.status)).length;
          totalDownCameras =
              cameras.where((c) => isDownStatus(c.status)).length;

          towers = updatedTowers;
          totalOnlineTowers =
              towers.where((t) => !isDownStatus(t.status)).length;
          totalTowers = towers.length;

          alerts = [...fetchedAlerts, ...generatedAlerts];
          addedDevices = devices;

          // Detect locations with multiple devices where at least one is DOWN
          _updateBlinkingLocations();
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      // Don't clear data on error - keep existing state to prevent status becoming 0
      // Just log the error and let auto-refresh retry
      if (mounted) {
        // Optionally show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: ${e.toString()}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _updateDeviceLocationStatuses() async {
    try {
      // Get all MMT devices from database
      final response = await http.get(
        Uri.parse('http://localhost/monitoring_api/mmt.php?action=getAll'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> mmtList = data['data'];

          // Clear and prepare device statuses map
          deviceStatuses.clear();

          // Ping each MMT device to update status
          for (var mmt in mmtList) {
            final deviceId = mmt['device_id']?.toString() ?? '';
            final ipAddress = mmt['ip_address']?.toString() ?? '';

            if (ipAddress.isNotEmpty) {
              try {
                // Test connectivity to IP
                final testResult = await apiService.testDeviceConnectivity(
                  targetIp: ipAddress,
                );

                if (testResult['success'] == true) {
                  final status = testResult['data']?['status'] ?? 'DOWN';

                  // Update MMT status in database
                  await apiService.reportDeviceStatus(
                    deviceType: 'mmt',
                    deviceId: deviceId,
                    status: status,
                    targetIp: ipAddress,
                  );

                  deviceStatuses[deviceId] = status;
                } else {
                  deviceStatuses[deviceId] = 'DOWN';
                }
              } catch (e) {
                print('Error testing MMT $deviceId: $e');
                deviceStatuses[deviceId] = 'DOWN';
              }
            } else {
              // No IP address, read from database
              final status = mmt['status']?.toString() ?? 'DOWN';
              deviceStatuses[deviceId] = status;
            }

            // Small delay between tests
            await Future.delayed(const Duration(milliseconds: 50));
          }

          // Update status in deviceLocationPoints
          for (var device in deviceLocationPoints) {
            device.status = deviceStatuses[device.id] ?? 'DOWN';
          }

          print('Updated ${deviceStatuses.length} device statuses');
        }
      }
    } catch (e) {
      print('Error updating device location statuses: $e');
    }
  }

  Future<void> _triggerPingCheck() async {
    try {
      const baseUrl = 'http://localhost/monitoring_api/index.php';

      // Call realtime ping endpoint yang update semua towers dan cameras sekaligus
      final response = await http.get(
        Uri.parse('$baseUrl?endpoint=realtime&type=all'),
      );

      // Wait a moment for database to update
      await Future.delayed(const Duration(seconds: 1));

      print('Realtime ping check completed: ${response.statusCode}');
    } catch (e) {
      print('Error triggering ping check: $e');
      rethrow;
    }
  }

  Tower? _findTowerForPoint(TowerPoint point) {
    try {
      return towers.firstWhere((t) => t.towerNumber == point.number);
    } catch (_) {
      final hint = point.towerIdHint ?? point.label;
      if (hint.isEmpty) return null;
      final hintLower = hint.toLowerCase();
      try {
        return towers.firstWhere((t) => t.towerId.toLowerCase() == hintLower);
      } catch (_) {
        return null;
      }
    }
  }

  String _getTowerStatusForPoint(TowerPoint point) {
    final tower = _findTowerForPoint(point);
    return tower?.status.toUpperCase() ?? 'UP';
  }

  // Get tower color based on status
  Color _getTowerColor(TowerPoint point) {
    final status = _getTowerStatusForPoint(point);
    return isDownStatus(status) ? Colors.red : const Color(0xFF2196F3);
  }

  // Detect locations with multiple devices where at least one is DOWN for blinking effect
  void _updateBlinkingLocations() {
    _locationKeysWithDownDevices.clear();

    // Group devices by location
    final Map<String, List<AddedDevice>> devicesByLocation = {};
    for (final device in addedDevices) {
      final key = '${device.latitude}_${device.longitude}';
      if (!devicesByLocation.containsKey(key)) {
        devicesByLocation[key] = [];
      }
      devicesByLocation[key]!.add(device);
    }

    // Check locations with 2+ devices and at least one DOWN
    for (final entry in devicesByLocation.entries) {
      if (entry.value.length >= 2) {
        final hasDownDevice = entry.value.any((d) => d.status == 'DOWN');
        if (hasDownDevice) {
          _locationKeysWithDownDevices.add(entry.key);
        }
      }
    }
  }

  // Get icon untuk added device
  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType) {
      case 'Access Point':
        return Icons.router;
      case 'CCTV':
        return Icons.videocam;
      case 'MMT':
        return Icons.table_chart;
      default:
        return Icons.device_unknown;
    }
  }

  // Get color untuk device berdasarkan tipe
  Color _getDeviceColor(String deviceType) {
    switch (deviceType) {
      case 'Access Point':
        return const Color(0xFF9C27B0); // Purple untuk tower
      case 'CCTV':
        return const Color(0xFF00BCD4); // Cyan untuk CCTV
      case 'MMT':
        return const Color(0xFFFF9800); // Orange untuk MMT
      default:
        return Colors.grey;
    }
  }

  int get totalCameras => totalUpCameras + totalDownCameras;

  void _centerMapToTPK() {
    final points = [
      TPKNilamLocation.coordinate,
      ...containerYards.map((c) => c.coordinate),
      ...deviceLocationPoints.map((d) => d.coordinate),
      ...towerPoints.map((t) => t.coordinate),
      ...specialLocations.map((s) => s.coordinate),
    ];

    if (points.isEmpty) {
      mapController.move(
          TPKNilamLocation.coordinate, TPKNilamLocation.defaultZoom);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Reload devices dan data dashboard
          await _loadDashboardData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Data berhasil diperbarui'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.refresh),
      ),
      body: Column(
        children: [
          // Header
          _buildHeader(context),
          // Content
          Expanded(
            child: _buildContent(context),
          ),
          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isMobile = isMobileScreen(context);

    if (isMobile) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildNetworkStatusCard(context),
              const SizedBox(height: 20),
              _buildCCTVMonitoringCard(context),
              const SizedBox(height: 20),
              _buildActiveAlertsCard(context),
              const SizedBox(height: 20),
              SizedBox(
                height: 500,
                child: _buildLiveTerminalMap(context),
              ),
            ],
          ),
        ),
      );
    }

    // Desktop layout
    return Row(
      children: [
        // Left Panel
        SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildNetworkStatusCard(context),
                  const SizedBox(height: 20),
                  _buildCCTVMonitoringCard(context),
                  const SizedBox(height: 20),
                  _buildActiveAlertsCard(context),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Right Panel - Map
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildLiveTerminalMap(context),
          ),
        ),
      ],
    );
  }

  // Navigate to CCTV page based on Container Yard ID
  void _navigateToCCTV(BuildContext context, String cyId) {
    String route = '/cctv';
    if (cyId == 'CY2') {
      route = '/cctv-cy2';
    } else if (cyId == 'CY3') {
      route = '/cctv-cy3';
    }
    navigateWithLoading(context, route);
  }

  // Navigate to Gate or Parking CCTV
  void _navigateToSpecialLocation(BuildContext context, String locationId) {
    String route = '/cctv-gate';
    if (locationId == 'PARKING') {
      route = '/cctv-parking';
    }
    navigateWithLoading(context, route);
  }

  void _showDevicesAtLocation(
      BuildContext context, double latitude, double longitude) {
    // Find all devices at this location
    final devicesAtLocation = addedDevices
        .where((d) => d.latitude == latitude && d.longitude == longitude)
        .toList();

    if (devicesAtLocation.isEmpty) {
      return;
    }

    if (devicesAtLocation.length == 1) {
      // If only one device, navigate directly
      _navigateAddedDevice(context, devicesAtLocation.first);
      return;
    }

    // Show dialog with list of devices at this location
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: animation,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Devices at this Location',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Latitude: ${latitude.toStringAsFixed(6)}\n'
                      'Longitude: ${longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: devicesAtLocation.length,
                        itemBuilder: (context, index) {
                          final device = devicesAtLocation[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _navigateAddedDevice(context, device);
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: device.status == 'UP'
                                        ? Colors.green
                                        : Colors.red,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getDeviceIcon(device.type),
                                      color: device.status == 'UP'
                                          ? Colors.green
                                          : Colors.red,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            device.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${device.type} • ${device.status}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateAddedDevice(BuildContext context, AddedDevice device) {
    final type = device.type;
    if (type == 'Access Point' || type == 'Tower') {
      String route = '/network';
      if (device.containerYard == 'CY2') {
        route = '/network-cy2';
      } else if (device.containerYard == 'CY3') {
        route = '/network-cy3';
      }
      navigateWithLoading(context, route);
      return;
    }

    if (type == 'CCTV') {
      final location = device.locationName.toLowerCase();
      String route = '/cctv';
      if (location.contains('gate')) {
        route = '/cctv-gate';
      } else if (location.contains('parking')) {
        route = '/cctv-parking';
      } else if (device.containerYard == 'CY2') {
        route = '/cctv-cy2';
      } else if (device.containerYard == 'CY3') {
        route = '/cctv-cy3';
      }
      navigateWithLoading(context, route);
      return;
    }

    // MMT: no dedicated page yet, show detail info
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${device.name} (MMT) - ${device.status}'),
        duration: const Duration(seconds: 2),
        backgroundColor: device.status == 'UP' ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF1976D2),
      child: Row(
        children: [
          const Text(
            'Terminal Nilam',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _buildHeaderOpenButton('+ Add Device', const AddDevicePage()),
          const SizedBox(width: 12),
          _buildHeaderOpenButton('Dashboard', const DashboardPage(),
              isActive: true),
          const SizedBox(width: 12),
          _buildHeaderOpenButton('Access Point', const NetworkPage()),
          const SizedBox(width: 12),
          _buildHeaderOpenButton('CCTV', const CCTVPage()),
          const SizedBox(width: 12),
          _buildHeaderOpenButton('Alerts', const AlertsPage()),
          const SizedBox(width: 12),
          _buildHeaderButton('Logout', () => _showLogoutDialog(context)),
          const SizedBox(width: 12),
          // Profile Icon
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF1976D2),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(String text, VoidCallback onPressed,
      {bool isActive = false}) {
    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withOpacity(0.9)
                  : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderOpenButton(String text, Widget openPage,
      {bool isActive = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => openPage),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withOpacity(0.9)
                  : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkStatusCard(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NetworkPage()),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.language,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Access Point Monitoring',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildTowerStatusTile(
                      count: totalOnlineTowers,
                      label: 'UP',
                      color: Colors.green,
                      icon: Icons.wifi,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTowerStatusTile(
                      count: totalDownTowers,
                      label: 'DOWN',
                      color: Colors.red,
                      icon: Icons.wifi_off,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTowerStatusTile({
    required int count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildCCTVMonitoringCard(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CCTVPage()),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.videocam,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'CCTV Monitoring',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCCTVStatus('$totalUpCameras', 'UP', Colors.green),
                  _buildCCTVStatus('$totalDownCameras', 'DOWN', Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCCTVStatus(String count, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.videocam, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveAlertsCard(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AlertsPage()),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.warning,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Active Alerts',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Critical: $criticalAlertsCount',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total: $totalActiveAlerts',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Warning: $warningAlertsCount',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveTerminalMap(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.map, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Text(
                'Live Terminal Map',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Tombol Check Status Now
              ElevatedButton.icon(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Checking status...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  await _triggerPingCheck();
                  await _loadDashboardData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ Status updated!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Check Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Google Maps Container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: mapController,
                    options: const MapOptions(
                      initialCenter: TPKNilamLocation.coordinate,
                      initialZoom: TPKNilamLocation.defaultZoom,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.monitoring',
                      ),
                      MarkerLayer(
                        markers: [
                          // Container Yards - Marker Besar (Clickable)
                          ...containerYards.map((cy) => Marker(
                                point: cy.coordinate,
                                width: 120,
                                height: 100,
                                child: GestureDetector(
                                  onTap: () {
                                    _navigateToCCTV(context, cy.id);
                                  },
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: cy.color,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.red, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.4),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              )
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                cy.name,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 2),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red
                                                      .withOpacity(0.8),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  cy.id,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )),

                          // Device Locations (CC/RTG/RS)
                          ...deviceLocationPoints.map((location) => Marker(
                                point: location.coordinate,
                                width: 50,
                                height: 70,
                                child: GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${location.name} - ${location.status}'),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: location.status == 'UP'
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    );
                                  },
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        ColorFiltered(
                                          colorFilter: ColorFilter.mode(
                                            location.status == 'UP'
                                                ? Colors.green
                                                : Colors.red,
                                            BlendMode.modulate,
                                          ),
                                          child: Image.asset(
                                            location.iconAsset,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            location.id,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )),

                          // Special Locations - Gate & Parking (Clickable - DRAWN LATER - APPEARS ON TOP)
                          ...specialLocations.map((location) => Marker(
                                point: location.coordinate,
                                width: 60,
                                height: 70,
                                child: GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(location.name),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: location.color,
                                      ),
                                    );
                                  },
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        location.iconAsset != null
                                            ? Image.asset(
                                                location.iconAsset!,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.contain,
                                              )
                                            : Icon(
                                                location.icon,
                                                color: location.color,
                                                size: 40,
                                              ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          decoration: BoxDecoration(
                                            color: location.color,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            location.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )),

                          // Added Devices - User-added devices (DRAWN LAST - APPEARS ON TOP)
                          ...addedDevices.map((device) {
                            final locationKey =
                                '${device.latitude}_${device.longitude}';
                            final isBlinkingLocation =
                                _locationKeysWithDownDevices
                                    .contains(locationKey);

                            // Determine icon color with blinking effect
                            Color iconColor;
                            Color backgroundColor;

                            if (isBlinkingLocation && !_isBlinkVisible) {
                              // Blinking state - show warning color (red)
                              iconColor = Colors.red;
                              backgroundColor = Colors.red;
                            } else {
                              // Normal state
                              iconColor = device.status == 'UP'
                                  ? Colors.green
                                  : Colors.red;
                              backgroundColor = device.status == 'UP'
                                  ? Colors.green
                                  : Colors.red;
                            }

                            return Marker(
                              point: LatLng(device.latitude, device.longitude),
                              width: 60,
                              height: 70,
                              child: GestureDetector(
                                onTap: () {
                                  print(
                                      'DEBUG: Tapped added device at ${device.latitude}, ${device.longitude}');
                                  _showDevicesAtLocation(context,
                                      device.latitude, device.longitude);
                                },
                                behavior: HitTestBehavior.opaque,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Icon(
                                        _getDeviceIcon(device.type),
                                        color: iconColor,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        decoration: BoxDecoration(
                                          color: backgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          device.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),

                          // Tower/Access Points - Tower PNG Image
                          ...towerPoints.map((point) {
                            return Marker(
                              point: point.coordinate,
                              width: 50,
                              height: 70,
                              child: GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(point.name),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: Colors.black87,
                                    ),
                                  );
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Image.asset(
                                        'assets/images/Tower.png',
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          point.label,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ),
                  // Center Map Button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: FloatingActionButton(
                      backgroundColor: const Color(0xFF1976D2),
                      onPressed: _centerMapToTPK,
                      tooltip: 'Center Map',
                      child: const Icon(Icons.my_location, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.timeline, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Text(
                'Activity Timeline',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(50, (index) {
                double height = 20 + (index % 5) * 15.0;
                return Container(
                  width: 4,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '00:00',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              Text(
                '12:00',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              Text(
                '23:59',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.black.withOpacity(0.8),
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '©2026 TPK Nilam Monitoring System',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout', style: TextStyle(color: Colors.black87)),
        content: const Text('Apakah Anda yakin ingin keluar?',
            style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.black87)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
