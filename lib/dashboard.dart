import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'main.dart';
import 'services/api_service.dart';
import 'models/camera_model.dart';
import 'models/tower_model.dart';
import 'models/alert_model.dart';
import 'network.dart';
import 'cctv.dart';
import 'alerts.dart';
import 'profile.dart';
import 'utils/tower_status_override.dart';

// Konstanta lokasi TPK Nilam - sesuai layout gambar
class TPKNilamLocation {
  static const String name = 'Terminal Nilam';
  static const double latitude = -7.2099123;
  static const double longitude = 112.7244489;
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
    latitude: -7.208782,
    longitude: 112.724493,
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

  SpecialLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.color,
    required this.icon,
  });

  LatLng get coordinate => LatLng(latitude, longitude);
}

final List<SpecialLocation> specialLocations = [
  SpecialLocation(
    id: 'GATE',
    name: 'Gate In/Out',
    latitude: -7.2099123,
    longitude: 112.7244489,
    color: const Color(0xFF1976D2),
    icon: Icons.directions_walk,
  ),
  SpecialLocation(
    id: 'PARKING',
    name: 'Parking',
    latitude: -7.209907,
    longitude: 112.724877,
    color: const Color(0xFFD32F2F),
    icon: Icons.local_parking,
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
      latitude: -7.207617,
      longitude: 112.723826,
      containerYard: 'CY1'),
  TowerPoint(
      number: 8,
      name: 'Tower 8',
      label: '8',
      latitude: -7.207563,
      longitude: 112.723950,
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
  int totalUpCameras = 0;
  int totalDownCameras = 0;
  int totalOnlineTowers = 0;
  int totalTowers = 0;

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
  }

  Future<void> _loadDashboardData() async {
    try {
      // Load core data
      final fetchedCameras = await apiService.getAllCameras();
      final fetchedTowers = await apiService.getAllTowers();
      final fetchedAlerts = await apiService.getAllAlerts();

      // Apply forced status overrides before generating alerts
      final updatedTowers = applyForcedTowerStatus(fetchedTowers);

      // Auto-generate DOWN alerts so the dashboard card matches Alerts page
      final generatedAlerts = <Alert>[];

      for (final tower in updatedTowers) {
        if (isDownStatus(tower.status)) {
          String route = '/network';
          if (tower.containerYard == 'CY2') {
            route = '/network-cy2';
          } else if (tower.containerYard == 'CY3') {
            route = '/network-cy3';
          }

          generatedAlerts.add(Alert(
            id: 'tower-${tower.id}',
            title: 'Tower DOWN - ${tower.towerId}',
            description: '${tower.location} tower offline (${tower.towerId})',
            severity: 'critical',
            timestamp: tower.createdAt,
            route: route,
            category: 'Tower',
          ));
        }
      }

      for (final camera in fetchedCameras) {
        if (camera.status == 'DOWN') {
          String route = '/cctv';
          if (camera.containerYard == 'CY2') {
            route = '/cctv-cy2';
          } else if (camera.containerYard == 'CY3') {
            route = '/cctv-cy3';
          }

          generatedAlerts.add(Alert(
            id: 'camera-${camera.id}',
            title: 'CCTV DOWN - ${camera.cameraId}',
            description:
                '${camera.location} camera offline (${camera.cameraId})',
            severity: 'critical',
            timestamp: camera.createdAt,
            route: route,
            category: 'CCTV',
          ));
        }
      }

      setState(() {
        cameras = fetchedCameras;
        totalUpCameras = cameras.where((c) => c.status == 'UP').length;
        totalDownCameras = cameras.where((c) => c.status == 'DOWN').length;

        towers = updatedTowers;
        totalOnlineTowers = towers.where((t) => !isDownStatus(t.status)).length;
        totalTowers = towers.length;

        alerts = [...fetchedAlerts, ...generatedAlerts];
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
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
    if (isForcedDown(point.number)) return 'DOWN';
    final tower = _findTowerForPoint(point);
    return tower?.status.toUpperCase() ?? 'UP';
  }

  // Get tower color based on status
  Color _getTowerColor(TowerPoint point) {
    final status = _getTowerStatusForPoint(point);
    return isDownStatus(status) ? Colors.red : const Color(0xFF2196F3);
  }

  int get totalCameras => totalUpCameras + totalDownCameras;

  void _centerMapToTPK() {
    final points = [
      TPKNilamLocation.coordinate,
      ...containerYards.map((c) => c.coordinate),
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
    String route = '/gate-cctv';
    if (locationId == 'PARKING') {
      route = '/parking-cctv';
    }
    navigateWithLoading(context, route);
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
          _buildHeaderOpenButton('Dashboard', const DashboardPage(),
              isActive: true),
          const SizedBox(width: 12),
          _buildHeaderOpenButton('Network', const NetworkPage()),
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
                  const Text(
                    'Network Status',
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalOnlineTowers/$totalTowers',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Towers Online',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${towerUptimePercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Signal Quality',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

                          // Tower/Access Points - Marker dengan angka (warna berubah sesuai status)
                          ...towerPoints.map((tower) => Marker(
                                point: tower.coordinate,
                                width: 48,
                                height: 48,
                                child: GestureDetector(
                                  onTap: () {
                                    // Navigate to appropriate CY page
                                    String route = '/network';
                                    if (tower.containerYard == 'CY2') {
                                      route = '/network-cy2';
                                    } else if (tower.containerYard == 'CY3') {
                                      route = '/network-cy3';
                                    }

                                    final status =
                                        _getTowerStatusForPoint(tower);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${tower.name} - ${tower.containerYard} - $status'),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: isDownStatus(status)
                                            ? Colors.red
                                            : Colors.blue,
                                      ),
                                    );

                                    navigateWithLoading(context, route);
                                  },
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _getTowerColor(tower),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          tower.label,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )),

                          // Special Locations - Gate & Parking (Clickable)
                          ...specialLocations.map((location) => Marker(
                                point: location.coordinate,
                                width: 60,
                                height: 60,
                                child: GestureDetector(
                                  onTap: () {
                                    _navigateToSpecialLocation(
                                        context, location.id);
                                  },
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: location.color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              )
                                            ],
                                          ),
                                          child: Icon(
                                            location.icon,
                                            color: Colors.white,
                                            size: 24,
                                          ),
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
