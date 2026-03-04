import 'dart:async';

import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'route_proxy_page.dart';
import 'services/api_service.dart';
import 'utils/tower_status_override.dart';

// Fullscreen CCTV Page - All Areas
class CCTVFullscreenPage extends StatefulWidget {
  const CCTVFullscreenPage({super.key});

  @override
  State<CCTVFullscreenPage> createState() => _CCTVFullscreenPageState();
}

class _CCTVFullscreenPageState extends State<CCTVFullscreenPage> {
  bool isLoading = true;
  final List<Map<String, dynamic>> allCameras = [];
  Timer? _refreshTimer;
  Timer? _continuousPingTimer;

  int get upCameras => allCameras.where((c) => c['status'] == 'UP').length;
  int get downCameras => allCameras.where((c) => c['status'] == 'DOWN').length;
  int get totalCameras => allCameras.length;

  @override
  void initState() {
    super.initState();
    _loadAllCameras();
    // Refresh UI setiap 1 detik untuk status monitoring realtime
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _loadAllCameras();
      }
    });

    // Trigger continuous PING every 2 seconds independent of UI refresh
    // This ensures devices are pinged even while UI is loading
    _continuousPingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _triggerRealtimePing();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _continuousPingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllCameras() async {
    try {
      // Don't show loading if already have data (prevents flickering)
      if (allCameras.isEmpty) {
        setState(() {
          isLoading = true;
        });
      }

      final apiService = ApiService();
      final cameras = await apiService.getAllCameras();
      final updatedCameras = applyForcedCameraStatus(cameras);

      if (mounted) {
        setState(() {
          allCameras.clear();
          final camerasMap = updatedCameras
              .map((c) => {
                    'id': c.cameraId,
                    'location': c.location,
                    'status': c.status,
                    'type': c.type,
                    'containerYard': c.containerYard,
                    'areaType': c.areaType,
                  })
              .toList();
          // Sort by container yard, then area type, then camera id
          camerasMap.sort((a, b) {
            int cmpYard = a['containerYard']
                .toString()
                .compareTo(b['containerYard'].toString());
            if (cmpYard != 0) return cmpYard;
            int cmpArea =
                a['areaType'].toString().compareTo(b['areaType'].toString());
            if (cmpArea != 0) return cmpArea;
            return a['id'].toString().compareTo(b['id'].toString());
          });
          allCameras.addAll(camerasMap);
          isLoading = false;
        });
      }

      // Trigger realtime ping in background after UI loads
      _triggerRealtimePing();
    } catch (e) {
      print('Error Loading Camera: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _triggerRealtimePing() async {
    try {
      print('=== Starting Realtime Ping For All Camera (Fullscreen) ===');

      final apiService = ApiService();
      final pingResult = await apiService.triggerRealtimePing();

      if (pingResult['success'] == true) {
        print('Realtime Ping Completed: ${pingResult['message']}');
        print('IP Checked: ${pingResult['ips_checked']}');
      }

      print('=== Realtime Ping Completed (Fullscreen) ===');
    } catch (e) {
      print('Error Triggering Realtime Ping: $e');
    }
  }

  Future<void> _triggerPingCheck() async {
    try {
      const baseUrl = 'http://localhost/monitoring_api/index.php';
      await http
          .get(
        Uri.parse('$baseUrl?endpoint=realtime&action=all'),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Realtime Ping Timed Out');
          return http.Response('{"Success":False}', 408);
        },
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _loadAllCameras();
      }
    } catch (e) {
      print('Error Triggering Ping Check (Ignored): $e');
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
                    padding: EdgeInsets.all(isMobile ? 8 : 16),
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
  double screenWidth = MediaQuery.of(context).size.width;
  return Container(
    width: screenWidth,
    padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24, vertical: isMobile ? 12 : 16),
    color: const Color(0xFF1976D2),
    child: isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Terminal Nilam',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 28 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeaderOpenButton('+ Add New Device', '/add-device',
                          isActive: false),
                      const SizedBox(width: 4),
                      _buildHeaderOpenButton('Dashboard', '/dashboard',
                          isActive: false),
                      const SizedBox(width: 4),
                      _buildHeaderOpenButton('Access Point', '/network',
                          isActive: false),
                      const SizedBox(width: 4),
                      _buildHeaderOpenButton('CCTV', '/cctv', isActive: false),
                      const SizedBox(width: 4),
                      _buildHeaderOpenButton('Alert', '/alerts',
                          isActive: false),
                      const SizedBox(width: 4),
                      _buildHeaderOpenButton('Alert Report', '/report',
                          isActive: false),
                      const SizedBox(width: 4),
                      _buildHeaderLogoutButton(),
                    ],
                  ),
                ),
              ),
            ],
          )
        : Row(
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
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeaderOpenButton('+ Add New Device', '/add-device',
                            isActive: false),
                        const SizedBox(width: 12),
                        _buildHeaderOpenButton('Dashboard', '/dashboard',
                            isActive: false),
                        const SizedBox(width: 12),
                        _buildHeaderOpenButton('Access Point', '/network',
                            isActive: false),
                        const SizedBox(width: 12),
                        _buildHeaderOpenButton('CCTV', '/cctv', isActive: false),
                        const SizedBox(width: 12),
                        _buildHeaderOpenButton('Alert', '/alerts', isActive: false),
                        const SizedBox(width: 12),
                        _buildHeaderOpenButton('Alert Report', '/report', isActive: false),
                        const SizedBox(width: 12),
                        _buildHeaderLogoutButton(),
                        const SizedBox(width: 12),
                        // Profile Icon - SCROLL dengan buttons
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
                                    size: 24,
                                  ),
                                ),
                              );
                            },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- TITLE SECTION ---
        Row(
          children: [
            // Container putih untuk icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.videocam_rounded,
                color: Colors.white, 
                size: 28,
              ),
            ),
            const SizedBox(width: 16), // Jarak antara icon dan teks
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All CCTV Fullscreen View',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'View All CCTV Status In All Area',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- STATS SECTION (Compact & Readable) ---
        Row(
          children: [
            Expanded(
              child: _buildStatCard('TOTAL CCTV', totalCameras.toString(),
                  Colors.blue, double.infinity),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                  'UP', upCameras.toString(), Colors.green, double.infinity),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                  'DOWN', downCameras.toString(), Colors.red, double.infinity),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- CAMERA GRID - FULL SCREEN ---
        _buildCameraGrid(constraints),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, Color indicatorColor, double width) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraGrid(BoxConstraints constraints) {
    // Show loading indicator
    if (isLoading) {
      return Container(
       padding: const EdgeInsets.symmetric(vertical: 24), // Diperkecil dari 40
      width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading CCTV Data...',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state if no cameras
    if (allCameras.isEmpty) {
      return Container(
       padding: const EdgeInsets.symmetric(vertical: 30),
      width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off_rounded, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No Data CCTV',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show camera grid when data exists
    // Perbesarkan kotak: 120px untuk tampilan lebih besar dan jelas
    int crossAxisCount =
        (constraints.maxWidth / 120).floor().clamp(4, 12).toInt();
    double spacing = 10;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 1.0,
        ),
        itemCount: allCameras.length,
        itemBuilder: (context, index) {
          return _buildCameraStatusBox(allCameras[index]);
        },
      ),
    );
  }

  Widget _buildCameraStatusBox(Map<String, dynamic> camera) {
    bool isUp = camera['status'] == 'UP';
    Color statusColor = isUp ? Colors.green : Colors.red;

    return Tooltip(
      message: '${camera['id']}\n${camera['location']}',
      child: Container(
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              camera['id'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
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
          '© 2025 Terminal Nilam. All rights reserved.',
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              navigateWithLoading(context, '/login');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}