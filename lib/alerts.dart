import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'dart:async';
import 'main.dart';
import 'services/api_service.dart';
import 'models/alert_model.dart';
import 'models/tower_model.dart';
import 'models/camera_model.dart';
import 'utils/tower_status_override.dart';
import 'route_proxy_page.dart';

// Alerts & Notification Page
class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  late ApiService apiService;
  List<Alert> alerts = [];
  List<Tower> towers = [];
  List<Camera> cameras = [];
  bool isLoading = true;
  Timer? _timer;
  Timer? _uiRefreshTimer; // Timer untuk refresh UI waktu real-time
  final Map<String, String> _alertTimestamps = {}; // Track alert timestamps
  final List<Map<String, dynamic>> alertsOld = [
    {
      'title': 'CCTV DOWN - CY1 Cam-12',
      'description': 'Parking Area (CY1) camera offline (Cam-12)',
      'severity': 'critical',
      'timestamp': '5 minutes ago',
      'route': '/cctv',
    },
    {
      'title': 'CCTV DOWN - CY1 Cam-13',
      'description': 'Loading Dock (CY1) camera offline (Cam-13)',
      'severity': 'critical',
      'timestamp': '4 minutes ago',
      'route': '/cctv',
    },
    {
      'title': 'CCTV DOWN - CY1 Cam-15',
      'description': 'Office Area (CY1) camera offline (Cam-15)',
      'severity': 'critical',
      'timestamp': '3 minutes ago',
      'route': '/cctv',
    },
    {
      'title': 'CCTV DOWN - CY2 Cam-31',
      'description': 'Container Yard 2 camera offline (Cam-31)',
      'severity': 'critical',
      'timestamp': '10 minutes ago',
      'route': '/cctv-cy2',
    },
    {
      'title': 'CCTV DOWN - CY3 Cam-16',
      'description': 'Container Yard 3 camera offline (Cam-16)',
      'severity': 'critical',
      'timestamp': '18 minutes ago',
      'route': '/cctv-cy3',
    },
    {
      'title': 'Tower WARNING - CY1 T10',
      'description': 'Tower T10 (CY1) latency/packet loss detected',
      'severity': 'warning',
      'timestamp': '23 minutes ago',
      'route': '/network',
    },
    {
      'title': 'Tower WARNING - CY2 T3',
      'description': 'Tower T3 (CY2) degraded performance',
      'severity': 'warning',
      'timestamp': '45 minutes ago',
      'route': '/network-cy2',
    },
    {
      'title': 'Tower WARNING - CY3 T14',
      'description': 'Tower T14 (CY3) degraded performance',
      'severity': 'warning',
      'timestamp': '1 hour ago',
      'route': '/network-cy3',
    },
    {
      'title': 'Tower WARNING - CY3 T16',
      'description': 'Tower T16 (CY3) degraded performance',
      'severity': 'warning',
      'timestamp': '1 hour ago',
      'route': '/network-cy3',
    },
  ];

  List<Alert> get activeAlerts => alerts
      .where((a) => a.severity == 'critical' || a.severity == 'warning')
      .toList();
  int get criticalCount =>
      activeAlerts.where((a) => a.severity == 'critical').length;
  int get warningCount =>
      activeAlerts.where((a) => a.severity == 'warning').length;
  int get infoCount => alerts.where((a) => a.severity == 'info').length;

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _loadAlerts();
    // Auto-refresh data dari database dan update UI setiap 30 detik
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadAlerts(); // Refresh data dari database secara real-time
      }
    });
    // Refresh UI untuk update timestamp setiap 1 detik
    _uiRefreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // Trigger rebuild untuk update relative time
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _uiRefreshTimer?.cancel();
    super.dispose();
  }

  String _getRelativeTime(String timestamp) {
    try {
      // Parse timestamp dari database
      DateTime alertTime;
      if (timestamp.contains('T')) {
        alertTime = DateTime.parse(timestamp);
      } else {
        // Format: "2025-01-28 10:30:00"
        alertTime = DateTime.parse(timestamp.replaceAll(' ', 'T'));
      }

      // Convert ke local time jika timestamp dalam UTC
      if (alertTime.isUtc) {
        alertTime = alertTime.toLocal();
      }

      final now = DateTime.now();
      final difference = now.difference(alertTime);

      if (difference.inSeconds < 60) {
        return 'Baru saja';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} menit yang lalu';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari yang lalu';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks minggu yang lalu';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months bulan yang lalu';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years tahun yang lalu';
      }
    } catch (e) {
      // Jika parsing gagal, return timestamp asli
      return timestamp;
    }
  }

  String _getFormattedDate(String timestamp) {
    try {
      // Parse timestamp dari database
      DateTime alertTime;
      if (timestamp.contains('T')) {
        alertTime = DateTime.parse(timestamp);
      } else {
        // Format: "2025-01-28 10:30:00"
        alertTime = DateTime.parse(timestamp.replaceAll(' ', 'T'));
      }

      // Convert ke local time jika timestamp dalam UTC
      if (alertTime.isUtc) {
        alertTime = alertTime.toLocal();
      }

      // Daftar nama bulan dalam Bahasa Indonesia
      const months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];

      final day = alertTime.day;
      final month = months[alertTime.month - 1];
      final year = alertTime.year;
      final hour = alertTime.hour.toString().padLeft(2, '0');
      final minute = alertTime.minute.toString().padLeft(2, '0');

      return '$day $month $year, $hour:$minute';
    } catch (e) {
      // Jika parsing gagal, return timestamp asli
      return timestamp;
    }
  }

  Future<void> _loadAlerts() async {
    try {
      // Load all data
      final fetchedAlerts = await apiService.getAllAlerts();
      final fetchedTowers = await apiService.getAllTowers();
      final fetchedCameras = await apiService.getAllCameras();

      // Apply forced tower status
      final updatedTowers = applyForcedTowerStatus(fetchedTowers);

      // Generate alerts from DOWN towers and cameras
      final generatedAlerts = <Alert>[];

      // Tower alerts
      for (final tower in updatedTowers) {
        if (isDownStatus(tower.status)) {
          String route = '/network';
          if (tower.containerYard == 'CY2') {
            route = '/network-cy2';
          } else if (tower.containerYard == 'CY3') {
            route = '/network-cy3';
          }

          final alertId = 'tower-${tower.id}';
          // Gunakan updatedAt dari database sebagai timestamp (fallback ke createdAt)
          // Ini lebih reliable daripada generate di client-side
          final timestamp = tower.updatedAt.isNotEmpty
              ? tower.updatedAt
              : (tower.createdAt.isNotEmpty
                  ? tower.createdAt
                  : DateTime.now().toString());

          generatedAlerts.add(Alert(
            id: alertId,
            title: 'Tower DOWN - ${tower.towerId}',
            description: '${tower.location} tower offline (${tower.towerId})',
            severity: 'critical',
            timestamp: timestamp,
            route: route,
            category: 'Tower',
          ));
        }
      }

      // Camera alerts
      for (final camera in fetchedCameras) {
        if (isDownStatus(camera.status)) {
          String route = '/cctv';

          // Check areaType first for specific areas
          if (camera.areaType == 'Gate') {
            route = '/cctv-gate';
          } else if (camera.areaType == 'Parking') {
            route = '/cctv-parking';
          } else if (camera.containerYard == 'CY2') {
            route = '/cctv-cy2';
          } else if (camera.containerYard == 'CY3') {
            route = '/cctv-cy3';
          }

          final alertId = 'camera-${camera.id}';
          // Gunakan updatedAt dari database sebagai timestamp
          // Ini lebih reliable daripada generate di client-side
          final timestamp = camera.updatedAt.isNotEmpty
              ? camera.updatedAt
              : (camera.createdAt.isNotEmpty
                  ? camera.createdAt
                  : DateTime.now().toString());

          generatedAlerts.add(Alert(
            id: alertId,
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

      // No need for cleanup since we're using database timestamps directly

      setState(() {
        alerts = [...fetchedAlerts, ...generatedAlerts];
        towers = updatedTowers;
        cameras = fetchedCameras;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading alerts: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Column(
        children: [
          _buildHeader(context),
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
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16, vertical: isMobile ? 10 : 12),
      color: const Color(0xFF1976D2),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terminal Nilam',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildHeaderOpenButton('Dashboard', '/dashboard',
                          isActive: false),
                      const SizedBox(width: 8),
                      _buildHeaderOpenButton('Network', '/network',
                          isActive: false),
                      const SizedBox(width: 8),
                      _buildHeaderOpenButton('CCTV', '/cctv', isActive: false),
                      const SizedBox(width: 8),
                      _buildHeaderOpenButton('Alerts', '/alerts',
                          isActive: true),
                      const SizedBox(width: 8),
                      _buildHeaderLogoutButton(),
                      const SizedBox(width: 8),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: OpenContainer(
                          transitionDuration: const Duration(milliseconds: 550),
                          transitionType: ContainerTransitionType.fadeThrough,
                          closedElevation: 0,
                          closedColor: Colors.transparent,
                          closedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          openElevation: 0,
                          openBuilder: (context, _) =>
                              const RouteProxyPage('/profile'),
                          closedBuilder: (context, openContainer) {
                            return GestureDetector(
                              onTap: openContainer,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF1976D2),
                                  size: 16,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    'Terminal Nilam',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildHeaderOpenButton('Dashboard', '/dashboard',
                    isActive: false),
                const SizedBox(width: 12),
                _buildHeaderOpenButton('Network', '/network', isActive: false),
                const SizedBox(width: 12),
                _buildHeaderOpenButton('CCTV', '/cctv', isActive: false),
                const SizedBox(width: 12),
                _buildHeaderOpenButton('Alerts', '/alerts', isActive: true),
                const SizedBox(width: 12),
                _buildHeaderLogoutButton(),
                const SizedBox(width: 12),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: OpenContainer(
                    transitionDuration: const Duration(milliseconds: 550),
                    transitionType: ContainerTransitionType.fadeThrough,
                    closedElevation: 0,
                    closedColor: Colors.transparent,
                    closedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    openElevation: 0,
                    openBuilder: (context, _) =>
                        const RouteProxyPage('/profile'),
                    closedBuilder: (context, openContainer) {
                      return GestureDetector(
                        onTap: openContainer,
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
                            size: 20,
                          ),
                        ),
                      );
                    },
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

  Widget _buildHeaderOpenButton(String text, String route,
      {bool isActive = false}) {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 550),
      transitionType: ContainerTransitionType.fadeThrough,
      closedElevation: 0,
      closedColor: Colors.transparent,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      openElevation: 0,
      openBuilder: (context, _) => RouteProxyPage(route),
      closedBuilder: (context, openContainer) {
        return buildLiquidGlassButton(text, openContainer, isActive: isActive);
      },
    );
  }

  Widget _buildHeaderLogoutButton() {
    return buildLiquidGlassButton('Logout', () => _showLogoutDialog(context),
        isActive: false);
  }

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    final isMobile = isMobileScreen(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final listHeight = (screenHeight - 280).clamp(360.0, 900.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Section
        Row(
          children: [
            Icon(Icons.warning_rounded,
                color: Colors.orange, size: isMobile ? 24 : 32),
            SizedBox(width: isMobile ? 12 : 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 20 : 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isMobile
                      ? 'Notifications'
                      : 'Monitor and manage system alerts & notification',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Main Content Row or Column based on screen size
        if (isMobile)
          Column(
            children: [
              _buildAlertsList(listHeight),
              const SizedBox(height: 20),
              _buildAlertStatistics(),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildAlertsList(listHeight),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: constraints.maxWidth > 1200
                    ? 350
                    : constraints.maxWidth * 0.3,
                child: Column(
                  children: [
                    _buildAlertStatistics(),
                    const SizedBox(height: 20),
                    _buildAlertsByCategory(),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAlertsList(double listHeight) {
    // Sort alerts by timestamp (newest first)
    final sortedActiveAlerts = List<Alert>.from(activeAlerts)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final towerAlerts =
        sortedActiveAlerts.where((a) => a.category == 'Tower').toList();
    final cctvAlerts =
        sortedActiveAlerts.where((a) => a.category == 'CCTV').toList();
    final otherAlerts = sortedActiveAlerts
        .where((a) => a.category != 'Tower' && a.category != 'CCTV')
        .toList();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Alerts',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (activeAlerts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No active alerts right now',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ),
            )
          else
            SizedBox(
              height: listHeight,
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (towerAlerts.isNotEmpty) ...[
                      _buildCategoryHeader(
                          'Tower Alerts', towerAlerts.length, Colors.blue),
                      ...towerAlerts.map((alert) => _buildAlertItem(alert)),
                      const SizedBox(height: 16),
                    ],
                    if (cctvAlerts.isNotEmpty) ...[
                      _buildCategoryHeader(
                          'CCTV Alerts', cctvAlerts.length, Colors.green),
                      ...cctvAlerts.map((alert) => _buildAlertItem(alert)),
                      const SizedBox(height: 16),
                    ],
                    if (otherAlerts.isNotEmpty) ...[
                      _buildCategoryHeader(
                          'Other Alerts', otherAlerts.length, Colors.grey),
                      ...otherAlerts.map((alert) => _buildAlertItem(alert)),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Alert alert) {
    Color severityColor;
    IconData severityIcon;

    switch (alert.severity) {
      case 'critical':
        severityColor = Colors.red;
        severityIcon = Icons.error;
        break;
      case 'warning':
        severityColor = Colors.orange;
        severityIcon = Icons.warning;
        break;
      case 'info':
        severityColor = Colors.blue;
        severityIcon = Icons.info;
        break;
      default:
        severityColor = Colors.grey;
        severityIcon = Icons.info;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          navigateWithLoading(context, alert.route);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: severityColor, width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(severityIcon, color: severityColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.description,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  // Delete alert
                },
                iconSize: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertStatistics() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alerts Statistics',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildStatRow('Critical Alert', criticalCount.toString(), Colors.red),
          const SizedBox(height: 12),
          _buildStatRow(
              'Warning Alert', warningCount.toString(), Colors.orange),
          const SizedBox(height: 12),
          _buildStatRow('Info Alert', infoCount.toString(), Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsByCategory() {
    final categories = _alertsByCategory();
    final total = activeAlerts.length;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alerts by Category',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            const Text(
              'No active alerts by category',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            )
          else ...[
            _buildCategoryBar('Network', categories['Network']!.length, total,
                _categoryColor(categories['Network']!)),
            const SizedBox(height: 12),
            _buildCategoryBar('CCTV', categories['CCTV']!.length, total,
                _categoryColor(categories['CCTV']!)),
            if (categories['Other']!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildCategoryBar('Other', categories['Other']!.length, total,
                  _categoryColor(categories['Other']!)),
            ],
          ],
        ],
      ),
    );
  }

  Map<String, List<Alert>> _alertsByCategory() {
    final categories = {
      'Network': <Alert>[],
      'CCTV': <Alert>[],
      'Other': <Alert>[],
    };

    for (final alert in activeAlerts) {
      final route = alert.route.toLowerCase();
      if (route.contains('network')) {
        categories['Network']!.add(alert);
      } else if (route.contains('cctv')) {
        categories['CCTV']!.add(alert);
      } else {
        categories['Other']!.add(alert);
      }
    }

    return categories;
  }

  Color _categoryColor(List<Alert> list) {
    if (list.any((a) => a.severity == 'critical')) return Colors.red;
    if (list.any((a) => a.severity == 'warning')) return Colors.orange;
    if (list.any((a) => a.severity == 'info')) return Colors.blue;
    return Colors.grey;
  }

  Widget _buildCategoryBar(String category, int count, int total, Color color) {
    final safeTotal = total == 0 ? 1 : total;
    final filledFlex = count == 0 ? 1 : count;
    final emptyFlex = (safeTotal - count) <= 0 ? 1 : safeTotal - count;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$count alerts',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: filledFlex,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  flex: emptyFlex,
                  child: Container(),
                ),
              ],
            ),
          ),
        ),
      ],
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
