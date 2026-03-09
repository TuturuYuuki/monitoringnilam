import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
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
import 'models/device_marker.dart';
import 'network.dart';
import 'cctv.dart';
import 'alerts.dart';
import 'profile.dart';
import 'add_device.dart';
import 'services/device_storage_service.dart';
import 'utils/tower_status_override.dart';
import 'utils/layout_mapper.dart';
import 'utils/device_icon_resolver.dart';
import 'widgets/terminal_layout_static.dart';
import 'widgets/global_header_bar.dart';
import 'report_page.dart';
import 'pages/tower_management.dart';
import 'pages/mmt_monitoring.dart';

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

  // PARKING Towers (P1-P3)
  TowerPoint(
      number: 28,
      name: 'Tower P1',
      label: 'P1',
      towerIdHint: 'P1',
      latitude: -7.209600,
      longitude: 112.725100,
      containerYard: 'PARKING'),
  TowerPoint(
      number: 29,
      name: 'Tower P2',
      label: 'P2',
      towerIdHint: 'P2',
      latitude: -7.209850,
      longitude: 112.724900,
      containerYard: 'PARKING'),
  TowerPoint(
      number: 30,
      name: 'Tower P3',
      label: 'P3',
      towerIdHint: 'P3',
      latitude: -7.209950,
      longitude: 112.725200,
      containerYard: 'PARKING'),

  // GATE Towers (G1-G2)
  TowerPoint(
      number: 31,
      name: 'Tower G1',
      label: 'G1',
      towerIdHint: 'G1',
      latitude: -7.209800,
      longitude: 112.724400,
      containerYard: 'GATE'),
  TowerPoint(
      number: 32,
      name: 'Tower G2',
      label: 'G2',
      towerIdHint: 'G2',
      latitude: -7.210050,
      longitude: 112.724550,
      containerYard: 'GATE'),
];

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with RouteAware {
  late MapController mapController;

  late ApiService apiService;
  List<Camera> cameras = [];
  List<Tower> towers = [];
  List<Alert> alerts = [];
  List<AddedDevice> addedDevices = [];
  List<Map<String, dynamic>> masterLocations = [];
  Map<String, String> deviceStatuses = {};
  Map<String, String> _mmtStatusByIp = {};
  bool _isPickTowerMode = false;
  String? _pickTowerYard;
  int totalUpMMT = 0;
  int totalDownMMT = 0;
  Timer? _refreshTimer;
  Timer? _blinkTimer;
  bool _isLoadingDashboard = false;
  bool _isPingInProgress = false;
  DateTime? _lastPingCheckAt;
  static const Duration _pingCheckInterval = Duration(seconds: 30);
  bool _isRouteSubscribed = false;
  int totalUpCameras = 0;
  int totalDownCameras = 0;
  int totalOnlineTowers = 0;
  int totalTowers = 0;
  int totalWarnings = 0;
  int totalDownTowers = 0;
  bool _isFreeroamEditMode = false;

  // Tracking blinking locations with multiple devices where at least one is DOWN
  final Set<String> _locationKeysWithDownDevices = {};
  bool _isBlinkVisible = true;
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
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
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
    final route = ModalRoute.of(context);
    if (route is PageRoute && !_isRouteSubscribed) {
      routeObserver.subscribe(this, route);
      _isRouteSubscribed = true;
    }
    final args = route?.settings.arguments;
    if (args is Map) {
      if (args['refresh'] == true) {
        _refreshAfterNavigation();
      }

      final pickMode = args['pickTowerPosition'] == true;
      final targetYard = args['yard']?.toString();
      if (pickMode != _isPickTowerMode || targetYard != _pickTowerYard) {
        setState(() {
          _isPickTowerMode = pickMode;
          _pickTowerYard = targetYard;
        });
      }
    } else if (_isPickTowerMode || _pickTowerYard != null) {
      setState(() {
        _isPickTowerMode = false;
        _pickTowerYard = null;
      });
    }
    // Reload data when returning from add device or other pages
    // This ensures added device icons appear immediately on map
    if (mounted) {
      _loadDashboardData();
    }
  }

  @override
  void didPopNext() {
    _refreshAfterNavigation();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _blinkTimer?.cancel();
    if (_isRouteSubscribed) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  void _refreshAfterNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    if (_isLoadingDashboard) {
      return;
    }

    _isLoadingDashboard = true;
    try {
      _triggerPingCheck().catchError((e) => debugPrint('Ping error: $e'));
      await apiService.getDashboardStats();
      // Separate void future from non-void futures
      final results = await Future.wait([
        apiService.getAllCameras(),
        apiService.getAllTowers(),
        apiService.getAllAlerts(),
        apiService.getAllMasterLocations(),
      ]);
      final fetchedCameras = results[0] as List<Camera>;
      final fetchedTowers = results[1] as List<Tower>;

      // Handle new paginated response format (getAllAlerts always returns Map<String, dynamic>)
      List<Alert> fetchedAlerts = [];
      final alertsResponse = results[2] as Map<String, dynamic>;

      // Extract alerts list from response map using explicit loop
      final alertListRaw = alertsResponse['alerts'] as List? ?? [];
      for (var data in alertListRaw) {
        if (data is Alert) {
          fetchedAlerts.add(data);
        } else {
          fetchedAlerts.add(Alert.fromJson(data as Map<String, dynamic>));
        }
      }

      // Extract master locations
      final fetchedMasterLocations = results[3] as List<Map<String, dynamic>>;

      // Run void future separately after other data loads
      await _updateDeviceLocationStatuses();

      final updatedTowers = applyForcedTowerStatus(fetchedTowers);
      final updatedCameras = applyForcedCameraStatus(fetchedCameras);
      final ipStatus = _buildIpStatusMap(updatedTowers, updatedCameras);
      final effectiveTowers = _applyIpStatusToTowers(updatedTowers, ipStatus);
      final effectiveCameras =
          _applyIpStatusToCameras(updatedCameras, ipStatus);
      final List<Alert> generatedAlerts = [];

      for (final tower in effectiveTowers) {
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
            id: int.tryParse(tower.id.toString()) ??
                0, // Ubah ke int agar tidak error
            alertKey: 'generated:${tower.id}:${tower.towerId}:AP_DOWN',
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

      for (final camera in effectiveCameras) {
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
            id: (int.tryParse(camera.id.toString()) ?? 0) + 1000, // ID unik
            alertKey:
                'generated:${camera.id + 1000}:${camera.cameraId}:CCTV_DOWN',
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

      List<AddedDevice> devices = [];
      try {
        devices = await DeviceStorageService.getDevices().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('Warning: Get devices from storage timed out');
            return addedDevices;
          },
        );
      } catch (e) {
        print('Error loading devices from storage: $e');
        devices = addedDevices;
      }

      for (var device in devices) {
        if (device.type == 'MMT') {
          device.status = deviceStatuses[device.name] ??
              deviceStatuses[device.id] ??
              'DOWN';
        } else if (device.type == 'Access Point' || device.type == 'Tower') {
          if (effectiveTowers.isNotEmpty) {
            final tower = effectiveTowers.firstWhere(
              (t) =>
                  t.towerId == device.name || t.ipAddress == device.ipAddress,
              orElse: () => effectiveTowers.first,
            );
            if (tower.towerId == device.name ||
                tower.ipAddress == device.ipAddress) {
              device.status = tower.status;
            }
          }
        } else if (device.type == 'CCTV') {
          if (effectiveCameras.isNotEmpty) {
            final camera = effectiveCameras.firstWhere(
              (c) =>
                  c.cameraId == device.name || c.ipAddress == device.ipAddress,
              orElse: () => effectiveCameras.first,
            );
            if (camera.cameraId == device.name ||
                camera.ipAddress == device.ipAddress) {
              device.status = camera.status;
            }
          }
        }

        final ipKey = device.ipAddress.trim();
        final ipStatusValue = ipStatus[ipKey];
        if (ipStatusValue != null) {
          device.status = ipStatusValue;
        }
      }

      devices.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          // 1. Simpan Data Master ke List (Peta & Detail menggunakan ini)
          cameras = effectiveCameras;
          towers = effectiveTowers;
          masterLocations = fetchedMasterLocations;

          // 2. HITUNG ULANG STATISTIK DARI LIST RIIL (Agar sinkron dengan warna peta)
          // Access Point
          totalTowers = towers.length;
          totalOnlineTowers =
              towers.where((t) => !isDownStatus(t.status)).length;
          totalDownTowers = (totalTowers - totalOnlineTowers).clamp(0, 999);

          // CCTV
          int allCamerasCount = cameras.length;
          totalUpCameras = cameras.where((c) => !isDownStatus(c.status)).length;
          totalDownCameras = (allCamerasCount - totalUpCameras).clamp(0, 999);

          // 3. ALERT: Gabungkan data DB dengan alert yang baru saja terdeteksi (DOWN baru)
          alerts = [...fetchedAlerts, ...generatedAlerts];
          // Hitung total dari gabungan alert tersebut
          totalWarnings = alerts
              .where((a) => a.severity == 'critical' || a.severity == 'warning')
              .length;

          // 4. Update UI lainnya
          addedDevices = devices;
          _syncAddedDevices(ipStatus);
          _updateBlinkingLocations();
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: ${e.toString()}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      _isLoadingDashboard = false;
    }
  }

  Future<void> _syncAddedDevices(Map<String, String> ipStatus) async {
    try {
      List<AddedDevice> storageDevices =
          await DeviceStorageService.getDevices();
      for (var device in storageDevices) {
        final ipKey = device.ipAddress.trim();
        if (ipStatus.containsKey(ipKey)) {
          device.status = ipStatus[ipKey]!;
        }
      }
      if (mounted) {
        setState(() {
          addedDevices = storageDevices;
          addedDevices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
      }
    } catch (e) {
      debugPrint("Error syncing storage devices: $e");
    }
  }

  Future<void> _loadAddedDevices(Map<String, String> ipStatus) async {
    try {
      List<AddedDevice> devices = await DeviceStorageService.getDevices();
      for (var device in devices) {
        final ipKey = device.ipAddress.trim();
        if (ipStatus.containsKey(ipKey)) {
          device.status = ipStatus[ipKey]!;
        }
      }
      if (mounted) {
        setState(() {
          addedDevices = devices;
          addedDevices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
      }
    } catch (e) {
      debugPrint("Error loading added devices: $e");
    }
  }

  Future<void> _updateDeviceLocationStatuses() async {
    try {
      // Get all MMT devices from database
      // The realtime ping check has already updated all statuses in the database
      // So we just read the current status from database without individual pings
      final response = await http.get(
        Uri.parse(
            'http://localhost/monitoring_api/index.php?endpoint=mmt&action=all'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> mmtList = data['data'];

          // Clear and prepare device statuses map
          deviceStatuses.clear();
          final mmtStatusByIp = <String, String>{};
          var upCount = 0;
          var downCount = 0;

          // Update device statuses from database
          for (var mmt in mmtList) {
            final deviceId =
                mmt['id']?.toString() ?? mmt['device_id']?.toString() ?? '';
            final ipAddress = mmt['ip_address']?.toString() ?? '';

            // Read status directly from database (already updated by realtime ping)
            final status = mmt['status']?.toString().toUpperCase() ?? 'DOWN';

            if (status == 'UP') {
              upCount++;
            } else {
              downCount++;
            }

            if (deviceId.isNotEmpty) {
              deviceStatuses[deviceId] = status;
            }
            if (ipAddress.isNotEmpty) {
              _mergeIpStatus(mmtStatusByIp, ipAddress, status);
            }
          }

          _mmtStatusByIp = mmtStatusByIp;
          totalUpMMT = upCount;
          totalDownMMT = downCount;

          // Update status in deviceLocationPoints
          for (var device in deviceLocationPoints) {
            device.status = deviceStatuses[device.id] ?? 'DOWN';
          }

          print(
              'Updated ${deviceStatuses.length} Device Statuses From Database');
        }
      }
    } catch (e) {
      print('Error Updating Device Location Statuses: $e');
    }
  }

  Future<void> _triggerPingCheck({bool force = false}) async {
    final now = DateTime.now();

    if (_isPingInProgress) {
      return;
    }

    if (!force &&
        _lastPingCheckAt != null &&
        now.difference(_lastPingCheckAt!) < _pingCheckInterval) {
      return;
    }

    _isPingInProgress = true;
    _lastPingCheckAt = now;

    try {
      const baseUrl = 'http://localhost/monitoring_api/index.php';

      // Call realtime ping endpoint yang update semua towers dan cameras sekaligus
      final response = await http
          .get(
        Uri.parse('$baseUrl?endpoint=realtime&action=all'),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Realtime Ping Timed Out - Skipping');
          return http.Response('{"success":false,"message":"Timeout"}', 408);
        },
      );

      if (response.statusCode == 200) {
        // Wait a moment for database to update
        await Future.delayed(const Duration(milliseconds: 500));
        print('Realtime Ping Check Completed: ${response.statusCode}');
      } else {
        print('Realtime Ping Failed: ${response.statusCode}');
      }
    } catch (e) {
      // Silent fail - just log, don't throw
      // This prevents error snackbar spam during auto-refresh
      print('Error Triggering Ping Check (Ignored): $e');
    } finally {
      _isPingInProgress = false;
    }
  }

  void _mergeIpStatus(Map<String, String> map, String ip, String status) {
    final normalized = status.toUpperCase();
    if (ip.isEmpty) {
      return;
    }
    final current = map[ip];
    if (normalized == 'UP') {
      map[ip] = 'UP';
      return;
    }
    if (current == null) {
      map[ip] = normalized;
      return;
    }
    if (current != 'UP' && normalized == 'DOWN') {
      map[ip] = 'DOWN';
    }
  }

  Map<String, String> _buildIpStatusMap(
      List<Tower> towers, List<Camera> cameras) {
    final map = <String, String>{};
    for (final tower in towers) {
      _mergeIpStatus(map, tower.ipAddress.trim(), tower.status);
    }
    for (final camera in cameras) {
      _mergeIpStatus(map, camera.ipAddress.trim(), camera.status);
    }
    for (final entry in _mmtStatusByIp.entries) {
      _mergeIpStatus(map, entry.key, entry.value);
    }
    return map;
  }

  List<Tower> _applyIpStatusToTowers(
      List<Tower> towers, Map<String, String> ipStatus) {
    return towers.map((tower) {
      final ip = tower.ipAddress.trim();
      final forced = ipStatus[ip];
      if (forced == null || tower.status.toUpperCase() == forced) {
        return tower;
      }
      return Tower(
        id: tower.id,
        towerId: tower.towerId,
        towerNumber: tower.towerNumber,
        location: tower.location,
        ipAddress: tower.ipAddress,
        status: forced,
        containerYard: tower.containerYard,
        createdAt: tower.createdAt,
        updatedAt: tower.updatedAt,
      );
    }).toList(growable: false);
  }

  List<Camera> _applyIpStatusToCameras(
      List<Camera> cameras, Map<String, String> ipStatus) {
    return cameras.map((camera) {
      final ip = camera.ipAddress.trim();
      final forced = ipStatus[ip];
      if (forced == null || camera.status.toUpperCase() == forced) {
        return camera;
      }
      return Camera(
        id: camera.id,
        cameraId: camera.cameraId,
        location: camera.location,
        ipAddress: camera.ipAddress,
        status: forced,
        type: camera.type,
        containerYard: camera.containerYard,
        areaType: camera.areaType,
        createdAt: camera.createdAt,
        updatedAt: camera.updatedAt,
      );
    }).toList(growable: false);
  }

  LatLng _offsetPoint(double lat, double lng, int index, int total) {
    if (total <= 1) {
      return LatLng(lat, lng);
    }

    const radius = 0.0000225; // ~2,5m - minimal offset to prevent overlap only
    final angle = (2 * math.pi * index) / total;

    return LatLng(
        lat + (radius * math.cos(angle)), lng + (radius * math.sin(angle)));
  }

  List<Marker> _buildAddedDeviceMarkers() {
    final totals = <String, int>{};
    for (final device in addedDevices) {
      final key = '${device.latitude}_${device.longitude}';
      totals[key] = (totals[key] ?? 0) + 1;
    }
    final seen = <String, int>{};

    return addedDevices.map((device) {
      final key = '${device.latitude}_${device.longitude}';
      final index = seen[key] ?? 0;
      seen[key] = index + 1;
      final total = totals[key] ?? 1;
      final offset =
          _offsetPoint(device.latitude, device.longitude, index, total);

      final locationKey = '${device.latitude}_${device.longitude}';
      final isBlinkingLocation =
          _locationKeysWithDownDevices.contains(locationKey);

      Color iconColor;
      Color backgroundColor;

      if (isBlinkingLocation && !_isBlinkVisible) {
        iconColor = Colors.red;
        backgroundColor = Colors.red;
      } else {
        iconColor = device.status == 'UP' ? Colors.green : Colors.red;
        backgroundColor = device.status == 'UP' ? Colors.green : Colors.red;
      }

      return Marker(
        point: offset,
        width: 60,
        height: 70,
        child: GestureDetector(
          onTap: () {
            print(
                'DEBUG: Tapped added device at ${device.latitude}, ${device.longitude}');
            _showDevicesAtLocation(context, device.latitude, device.longitude);
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
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(4),
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
    }).toList(growable: false);
  }

  // Build markers for master locations (RTG, RS, CC, etc) with color-coding
  List<Marker> _buildMasterLocationMarkers() {
    if (masterLocations.isEmpty) {
      return [];
    }

    return masterLocations.map((location) {
      final locType =
          (location['location_type'] ?? '').toString().toUpperCase();
      final locCode = (location['location_code'] ?? '').toString();
      final locName = (location['location_name'] ?? '').toString();
      final lat =
          double.tryParse((location['latitude'] ?? '0').toString()) ?? 0.0;
      final lng =
          double.tryParse((location['longitude'] ?? '0').toString()) ?? 0.0;

      final markerColor = DeviceIconResolver.colorForType(locType);
      final markerIcon = DeviceIconResolver.iconForType(locType);

      return Marker(
        point: LatLng(lat, lng),
        width: 60,
        height: 70,
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Master Location: $locName ($locType)'),
                duration: const Duration(seconds: 2),
                backgroundColor: markerColor,
              ),
            );
          },
          behavior: HitTestBehavior.opaque,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  markerIcon,
                  color: markerColor,
                  size: 35,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: markerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    locCode,
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
    }).toList();
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
    return DeviceIconResolver.iconForType(deviceType);
  }

  // Get color untuk device berdasarkan tipe
  Color _getDeviceColor(String deviceType) {
    return DeviceIconResolver.colorForType(deviceType);
  }

  int get totalCameras => totalUpCameras + totalDownCameras;

  List<AddedDevice> _buildLayoutDevices() {
    final merged = <AddedDevice>[...addedDevices];
    final existingKeys = <String>{};

    for (final device in merged) {
      final key =
          '${device.type.toUpperCase()}|${device.ipAddress.trim().toUpperCase()}|${device.locationName.toUpperCase()}';
      existingKeys.add(key);
    }

    for (final camera in cameras) {
      final locationName = camera.location.trim();
      if (locationName.isEmpty) {
        continue;
      }

      final cameraAsDevice = AddedDevice(
        id: 'camera_${camera.id}',
        type: 'CCTV',
        name: camera.cameraId,
        ipAddress: camera.ipAddress,
        locationName: locationName,
        latitude: camera.latitude ?? 0,
        longitude: camera.longitude ?? 0,
        containerYard: camera.containerYard,
        createdAt: DateTime.tryParse(camera.createdAt) ?? DateTime.now(),
        status: camera.status,
      );

      final key =
          '${cameraAsDevice.type.toUpperCase()}|${cameraAsDevice.ipAddress.trim().toUpperCase()}|${cameraAsDevice.locationName.toUpperCase()}';
      if (existingKeys.add(key)) {
        merged.add(cameraAsDevice);
      }
    }

    return merged;
  }

  // ═══════════════════════════════════════════════════════════════
  // TOWER POSITION UPDATE - FREEROAM CALLBACK
  // ═══════════════════════════════════════════════════════════════
  Future<void> _handleTowerPositionUpdate(
    String towerId,
    double newLatitude,
    double newLongitude,
  ) async {
    try {
      // Find tower
      final towerIndex = towers.indexWhere((t) => t.towerId == towerId);
      if (towerIndex == -1) return;

      final tower = towers[towerIndex];

      // ────────────────────────────────────────────────────────────
      // VALIDATE POSITION
      // ────────────────────────────────────────────────────────────
      final validationResult = await apiService.validateTowerPosition(
        tower.containerYard,
        newLatitude,
        newLongitude,
      );

      if (validationResult['success'] == true &&
          validationResult['valid'] == false) {
        print('⚠️ Position validation failed - outside bounds');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Position outside allowed bounds for this yard'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // ────────────────────────────────────────────────────────────
      // UPDATE UI IMMEDIATELY
      // ────────────────────────────────────────────────────────────
      setState(() {
        towers[towerIndex] = Tower(
          id: tower.id,
          towerId: tower.towerId,
          towerNumber: tower.towerNumber,
          location: tower.location,
          ipAddress: tower.ipAddress,
          status: tower.status,
          containerYard: tower.containerYard,
          createdAt: tower.createdAt,
          updatedAt: tower.updatedAt,
          latitude: newLatitude,
          longitude: newLongitude,
        );

        // Keep master location point in sync immediately so grouped devices follow tower drag in UI.
        final towerCode = tower.towerId.toUpperCase();
        final masterIdx = masterLocations.indexWhere((m) {
          final type = (m['location_type'] ?? '').toString().toUpperCase();
          final code = (m['location_code'] ?? '').toString().toUpperCase();
          final name = (m['location_name'] ?? '').toString().toUpperCase();
          return type == 'TOWER' && (code == towerCode || name == towerCode);
        });

        if (masterIdx >= 0) {
          masterLocations[masterIdx] = {
            ...masterLocations[masterIdx],
            'latitude': newLatitude,
            'longitude': newLongitude,
          };
        }
      });

      // ────────────────────────────────────────────────────────────
      // SAVE TO DATABASE WITH HISTORY
      // ────────────────────────────────────────────────────────────
      final result = await apiService.updateTowerPositionWithHistory(
        tower.id,
        newLatitude,
        newLongitude,
        changedBy: 'freeroam_drag',
        changeReason: 'Position updated via map drag (freeroam mode)',
      );

      if (!result['success']) {
        print(
            '⚠️ Warning: Failed to save position to database: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Position updated locally but DB save failed: ${result['message']}')),
        );
      } else {
        print('✓ Tower position updated and saved to database');
      }
    } catch (e) {
      print('Error handling tower position update: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating tower position: $e')),
      );
    }
  }

  String _normalizeMasterKey(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  Future<void> _handleMasterPositionUpdate(
    Map<String, dynamic> master,
    double newLatitude,
    double newLongitude,
  ) async {
    final itemId = int.tryParse((master['item_id'] ?? '').toString());
    if (itemId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Master location tidak memiliki item_id. Tidak bisa disimpan.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final locType = (master['location_type'] ?? '').toString().toUpperCase();
    final codeKey =
        _normalizeMasterKey((master['location_code'] ?? '').toString());
    final nameKey =
        _normalizeMasterKey((master['location_name'] ?? '').toString());

    setState(() {
      final idx = masterLocations.indexWhere(
        (m) => (m['item_id'] ?? '').toString() == itemId.toString(),
      );

      if (idx >= 0) {
        masterLocations[idx] = {
          ...masterLocations[idx],
          'latitude': newLatitude,
          'longitude': newLongitude,
        };
      }

      if (locType == 'TOWER') {
        for (var i = 0; i < towers.length; i++) {
          final tower = towers[i];
          final towerIdKey = _normalizeMasterKey(tower.towerId);
          final towerLocKey = _normalizeMasterKey(tower.location);
          final isMatch = (codeKey.isNotEmpty &&
                  (towerIdKey.contains(codeKey) ||
                      towerLocKey.contains(codeKey))) ||
              (nameKey.isNotEmpty &&
                  (towerIdKey.contains(nameKey) ||
                      towerLocKey.contains(nameKey)));

          if (!isMatch) continue;

          towers[i] = Tower(
            id: tower.id,
            towerId: tower.towerId,
            towerNumber: tower.towerNumber,
            location: tower.location,
            ipAddress: tower.ipAddress,
            status: tower.status,
            containerYard: tower.containerYard,
            createdAt: tower.createdAt,
            updatedAt: tower.updatedAt,
            latitude: newLatitude,
            longitude: newLongitude,
          );
          break;
        }
      }
    });

    final saveMasterResult = await apiService.updateMasterLocation(itemId, {
      'latitude': newLatitude,
      'longitude': newLongitude,
    });

    if (!saveMasterResult['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Gagal simpan posisi master: ${saveMasterResult['message']}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (locType == 'TOWER') {
      Tower? matchedTower;
      try {
        matchedTower = towers.firstWhere((tower) {
          final towerIdKey = _normalizeMasterKey(tower.towerId);
          final towerLocKey = _normalizeMasterKey(tower.location);
          return (codeKey.isNotEmpty &&
                  (towerIdKey.contains(codeKey) ||
                      towerLocKey.contains(codeKey))) ||
              (nameKey.isNotEmpty &&
                  (towerIdKey.contains(nameKey) ||
                      towerLocKey.contains(nameKey)));
        });
      } catch (_) {
        matchedTower = null;
      }

      if (matchedTower != null) {
        await apiService.updateTowerPositionWithHistory(
          matchedTower.id,
          newLatitude,
          newLongitude,
          changedBy: 'freeroam_drag_master',
          changeReason: 'Master tower position updated via freeroam',
        );
      }
    }
  }

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
      body: Stack(
        children: [
          // LAYER 1: ISI HALAMAN (Paling Belakang)
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 50), // Jarak agar tidak tertutup header
                Expanded(
                  child: _buildContent(context),
                ),
                _buildFooter(),
              ],
            ),
          ),

          // LAYER 2: HEADER (Paling Depan)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlobalHeaderBar(
              currentRoute: '/dashboard',
            ),
          ),
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
              // Mobile: Badges at top
              _buildNavigationBadges(context, isMobile: true),
              const SizedBox(height: 16),
              _buildNetworkStatusCard(context),
              const SizedBox(height: 20),
              _buildCCTVMonitoringCard(context),
              const SizedBox(height: 20),
              _buildMMTMonitoringCard(context),
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

    // Desktop layout with sidebar badges
    return Row(
      children: [
        // Navigation Sidebar (Fixed badges)
        _buildNavigationBadges(context, isMobile: false),
        const SizedBox(width: 12),
        // Left Panel - Info Cards
        SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildNetworkStatusCard(context),
                  const SizedBox(height: 20),
                  _buildCCTVMonitoringCard(context),
                  const SizedBox(height: 20),
                  _buildMMTMonitoringCard(context),
                  const SizedBox(height: 20),
                  _buildActiveAlertsCard(context),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
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

  // Build Navigation Badges Sidebar
  Widget _buildNavigationBadges(BuildContext context,
      {required bool isMobile}) {
    final badges = [
      _BadgeItem(
        icon: Icons.dashboard,
        label: 'Dashboard',
        route: '/dashboard',
        color: const Color(0xFF1976D2),
      ),
      _BadgeItem(
        icon: Icons.storage,
        label: 'Tower Mgmt',
        route: '/tower-management',
        color: const Color(0xFF607D8B),
      ),
      _BadgeItem(
        icon: Icons.add_circle,
        label: 'Add Device',
        route: '/add-device',
        color: const Color(0xFFFB8C00),
      ),
      _BadgeItem(
        icon: Icons.router,
        label: 'Network',
        route: '/network',
        color: const Color(0xFF546E7A),
      ),
      _BadgeItem(
        icon: Icons.videocam,
        label: 'CCTV',
        route: '/cctv',
        color: const Color(0xFF00897B),
      ),
      _BadgeItem(
        icon: Icons.monitor,
        label: 'MMT',
        route: '/mmt-monitoring',
        color: const Color(0xFF43A047),
      ),
      _BadgeItem(
        icon: Icons.warning,
        label: 'Alerts',
        route: '/alerts',
        color: const Color(0xFFE53935),
      ),
      _BadgeItem(
        icon: Icons.assessment,
        label: 'Alert Report',
        route: '/alert-report',
        color: const Color(0xFF8E24AA),
      ),
      _BadgeItem(
        icon: Icons.settings,
        label: 'Settings',
        route: '/profile',
        color: const Color(0xFF607D8B),
      ),
    ];

    if (isMobile) {
      // Mobile: Horizontal scrollable badges
      return SizedBox(
        height: 70,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badge = badges[index];
            final isActive = badge.route == '/dashboard';
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildBadgeButton(badge, isActive),
            );
          },
        ),
      );
    }

    // Desktop: Vertical sidebar
    return Container(
      width: 180,
      margin: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: badges.map((badge) {
            final isActive = badge.route == '/dashboard';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildBadgeButton(badge, isActive),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBadgeButton(_BadgeItem badge, bool isActive) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (badge.route != '/dashboard') {
            Navigator.pushReplacementNamed(context, badge.route);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? badge.color : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? Colors.white38 : const Color(0xFF334155),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                badge.icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  badge.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
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
                                    const Icon(
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

  Widget _buildMinimalHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A237E).withOpacity(0.9),
            const Color(0xFF0D47A1).withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.monitor_heart,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TPK Nilam Monitoring',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Real-time Dashboard',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Status indicators
          _buildHeaderStatusBadge(
            'Towers',
            '$totalOnlineTowers/$totalTowers',
            totalDownTowers > 0 ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 12),
          _buildHeaderStatusBadge(
            'Cameras',
            '$totalUpCameras/$totalCameras',
            totalDownCameras > 0 ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 12),
          _buildHeaderStatusBadge(
            'Alerts',
            '$totalActiveAlerts',
            totalActiveAlerts > 0 ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 16),
          // Profile button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatusBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Keep old header for reference/backup
  Widget _buildHeader(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF1976D2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Terminal Nilam - FIXED
          const Text(
            'Terminal Nilam',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 30),
          // Buttons + Profile - SCROLL HORIZONTAL
          Expanded(
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeaderOpenButton(
                        'Add New Device', const AddDevicePage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton(
                        'Master Data', const TowerManagementPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Dashboard', const DashboardPage(),
                        isActive: true),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Access Point', const NetworkPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('CCTV', const CCTVPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('MMT', const MMTMonitoringPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Alert', const AlertsPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Alert Report', const ReportPage()),
                    const SizedBox(width: 12),
                    _buildHeaderButton(
                        'Logout', () => _showLogoutDialog(context)),
                    const SizedBox(width: 12),
                    // Profile Icon
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfilePage()),
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

  Widget _buildMMTMonitoringCard(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MMTMonitoringPage()),
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
                    child:
                        const Icon(Icons.router, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'MMT Monitoring',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
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
                      count: totalUpMMT,
                      label: 'UP',
                      color: Colors.green,
                      icon: Icons.wifi,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTowerStatusTile(
                      count: totalDownMMT,
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

  void _handleAreaPickedForTower(String areaId, double relX, double relY) {
    if (!_isPickTowerMode) return;

    if (_pickTowerYard != null && _pickTowerYard != areaId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan pilih area $_pickTowerYard.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'containerYard': areaId,
      'lat': relX,
      'lng': relY,
    });
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
              // Header Kartu
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Alerts',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Layout Counter Versi Warning (Seperti CCTV)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAlertStatus(totalWarnings),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Update fungsi agar menerima data jumlah
  Widget _buildAlertStatus(int count) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red, // Background icon orange
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              const Icon(Icons.report_problem, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          '$count', // Menampilkan angka dari database
          style: const TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'DOWN', // Label untuk counter
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  /// ===== Helper Function: Build Device Markers for PNG Layout Map =====
  /// Converts towers and cameras data to DeviceMarker objects
  /// for the NilamLayoutMap widget
  /// Uses coordinates from database if available
  List<DeviceMarker> _buildDeviceMarkersForLayoutMap() {
    List<DeviceMarker> markers = [];

    // Add Towers from database
    for (var tower in towers) {
      if (tower.latitude != null && tower.longitude != null) {
        var pixel =
            LayoutMapper.latLngToPixel(tower.latitude!, tower.longitude!);
        markers.add(DeviceMarker(
          id: tower.towerId,
          name: tower.towerId,
          type: DeviceType.tower,
          status: tower.status,
          ipAddress: tower.ipAddress,
          latitude: tower.latitude!,
          longitude: tower.longitude!,
          pixelX: pixel.x,
          pixelY: pixel.y,
          containerYard: tower.containerYard,
          lastUpdated: DateTime.now(),
        ));
      }
    }

    // Add Cameras (CCTV) from database
    for (var camera in cameras) {
      if (camera.latitude != null && camera.longitude != null) {
        var pixel =
            LayoutMapper.latLngToPixel(camera.latitude!, camera.longitude!);
        markers.add(DeviceMarker(
          id: camera.cameraId,
          name: camera.cameraId,
          type: DeviceType.cctv,
          status: camera.status,
          ipAddress: camera.ipAddress,
          latitude: camera.latitude!,
          longitude: camera.longitude!,
          pixelX: pixel.x,
          pixelY: pixel.y,
          containerYard: camera.containerYard,
          lastUpdated: DateTime.now(),
        ));
      }
    }

    return markers;
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
              if (_isPickTowerMode)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Text(
                    'Pick Mode: ${_pickTowerYard ?? 'Pilih area CY'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
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
                label: Text(
                  _isFreeroamEditMode ? 'Save' : 'Edit',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFreeroamEditMode
                      ? Colors.orange
                      : const Color(0xFF607D8B),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Tombol Check Status Now
              ElevatedButton.icon(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Checking Status...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  await _triggerPingCheck(force: true);
                  await _loadDashboardData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ Status Updated!'),
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
          // Terminal Layout Static
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: TerminalLayoutStatic(
                devices: _buildLayoutDevices(),
                towers: towers,
                masterLocations: masterLocations,
                isPickMode: _isPickTowerMode,
                pickYardFilter: _pickTowerYard,
                onAreaPicked: _handleAreaPickedForTower,
                isFreeroamEditEnabled: _isFreeroamEditMode,
                onTowerMoved: (towerId, latitude, longitude) {
                  _handleTowerPositionUpdate(towerId, latitude, longitude);
                },
                onMasterMoved: (master, latitude, longitude) {
                  _handleMasterPositionUpdate(master, latitude, longitude);
                },
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
        content: const Text('Are You Sure To Logout?',
            style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.black87)),
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

// Helper class for navigation badge items
class _BadgeItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  _BadgeItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}
