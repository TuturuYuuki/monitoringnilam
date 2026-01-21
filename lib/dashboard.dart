import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'main.dart';
import 'services/api_service.dart';
import 'models/camera_model.dart';
import 'models/tower_model.dart';
import 'models/alert_model.dart';

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
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  TowerPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

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
    latitude: -7.207572,
    longitude: 112.722712,
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

// Tower Points - tersebar di layout sesuai gambar
final List<TowerPoint> towerPoints = [
  // Towers di CY 1
  TowerPoint(
      id: 'T1', name: 'Access Point 1', latitude: -7.2056, longitude: 112.7228),
  TowerPoint(
      id: 'T2', name: 'Access Point 2', latitude: -7.2060, longitude: 112.7235),
  TowerPoint(
      id: 'T3', name: 'Access Point 3', latitude: -7.2063, longitude: 112.7232),

  // Towers di CY 2
  TowerPoint(
      id: 'T4', name: 'Access Point 4', latitude: -7.2085, longitude: 112.7240),
  TowerPoint(
      id: 'T5', name: 'Access Point 5', latitude: -7.2090, longitude: 112.7250),

  // Towers di CY 3
  TowerPoint(
      id: 'T6', name: 'Access Point 6', latitude: -7.2073, longitude: 112.7225),
  TowerPoint(
      id: 'T7', name: 'Access Point 7', latitude: -7.2080, longitude: 112.7230),
  TowerPoint(
      id: 'T8', name: 'Access Point 8', latitude: -7.2078, longitude: 112.7220),
];

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

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
      // Load cameras data
      final fetchedCameras = await apiService.getAllCameras();
      setState(() {
        cameras = fetchedCameras;
        totalUpCameras = cameras.where((c) => c.status == 'UP').length;
        totalDownCameras = cameras.where((c) => c.status == 'DOWN').length;
      });

      // Load towers data
      final fetchedTowers = await apiService.getAllTowers();
      setState(() {
        towers = fetchedTowers;
        totalOnlineTowers = towers.where((t) => t.status == 'UP').length;
        totalTowers = towers.length;
      });

      // Load alerts data
      final fetchedAlerts = await apiService.getAllAlerts();
      setState(() {
        alerts = fetchedAlerts;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
    }
  }

  int get totalCameras => totalUpCameras + totalDownCameras;

  void _centerMapToTPK() {
    mapController.move(
        TPKNilamLocation.coordinate, TPKNilamLocation.defaultZoom);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Column(
        children: [
          // Header
          _buildHeader(context),
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: EdgeInsets.all(isMobile ? 8 : 16.0),
                    child: _buildContent(context, constraints),
                  );
                },
              ),
            ),
          ),
          // Footer
          _buildFooter(),
        ],
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
          _buildHeaderButton('Dashboard', () {
            // Already on Dashboard
          }, isActive: true),
          const SizedBox(width: 12),
          _buildHeaderButton('Network', () {
            navigateWithLoading(context, '/network');
          }),
          const SizedBox(width: 12),
          _buildHeaderButton('CCTV', () {
            navigateWithLoading(context, '/cctv');
          }),
          const SizedBox(width: 12),
          _buildHeaderButton('Alerts', () {
            navigateWithLoading(context, '/alerts');
          }),
          const SizedBox(width: 12),
          _buildHeaderButton('Logout', () {
            _showLogoutDialog(context);
          }),
          const SizedBox(width: 12),
          // Profile Icon
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                navigateWithLoading(context, '/profile');
              },
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
    return buildLiquidGlassButton(text, onPressed, isActive: isActive);
  }

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    double cardWidth =
        constraints.maxWidth > 1200 ? 380 : constraints.maxWidth * 0.3;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Panel
        SizedBox(
          width: cardWidth,
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
        const SizedBox(width: 20),
        // Right Panel
        Expanded(
          child: Column(
            children: [
              _buildLiveTerminalMap(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkStatusCard(BuildContext context) {
    return InkWell(
      onTap: () {
        navigateWithLoading(context, '/network');
      },
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
                  child:
                      const Icon(Icons.language, color: Colors.white, size: 28),
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
    );
  }

  Widget _buildCCTVMonitoringCard(BuildContext context) {
    return InkWell(
      onTap: () {
        navigateWithLoading(context, '/cctv');
      },
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
                  child:
                      const Icon(Icons.videocam, color: Colors.white, size: 28),
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
    return InkWell(
      onTap: () {
        navigateWithLoading(context, '/alerts');
      },
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
                  child:
                      const Icon(Icons.warning, color: Colors.white, size: 28),
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
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
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
          Container(
            height: 700,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
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
                                    mainAxisAlignment: MainAxisAlignment.start,
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
                                              color:
                                                  Colors.black.withOpacity(0.4),
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
                                                color:
                                                    Colors.red.withOpacity(0.8),
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

                        // Tower/Access Points - Marker Kecil
                        ...towerPoints.map((tower) => Marker(
                              point: tower.coordinate,
                              width: 35,
                              height: 35,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: const Icon(
                                  Icons.router,
                                  color: Colors.white,
                                  size: 16,
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
                                    mainAxisAlignment: MainAxisAlignment.start,
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
                                              color:
                                                  Colors.black.withOpacity(0.3),
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
