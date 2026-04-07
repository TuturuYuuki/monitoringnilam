import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:monitoring/main.dart';
import 'package:monitoring/utils/ui_utils.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/utils/tower_status_override.dart';
import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';
import 'package:monitoring/widgets/global_footer.dart';

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

  void _goBackToCctvOverview() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.pushReplacementNamed(context, '/cctv');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/cctv-fullscreen'),
          Expanded(
            child: GlobalSidebarNav(
                currentRoute: '/cctv-fullscreen',
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Padding(
                        padding: EdgeInsets.all(isMobile ? 8 : 16),
                        child: _buildContent(context, constraints),
                      );
                    },
                  ),
                )),
          ),
          const GlobalFooter(),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    final isMobile = isMobileScreen(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- TITLE SECTION ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1976D2).withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.videocam_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All CCTV Fullscreen View',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitoring All Camera Status Realtime',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (!isMobile)
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: ElevatedButton.icon(
                    onPressed: _goBackToCctvOverview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.12),
                      foregroundColor: Colors.white,
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 14),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text(
                      'BACK',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _goBackToCctvOverview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.14),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Back'),
            ),
          ),
        ],
        const SizedBox(height: 16),

        // --- STATS SECTION (Compact & Readable) ---
        Row(
          children: [
            Expanded(
              child: _buildStatCard('TOTAL CAMERA', totalCameras.toString(),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: indicatorColor.withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 2,
                width: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [indicatorColor, indicatorColor.withOpacity(0)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraGrid(BoxConstraints constraints) {
    // Show loading indicator
    if (isLoading) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3),
                  SizedBox(height: 20),
                  Text(
                    'LOADING CAMERA DATA...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Show empty state if no cameras
    if (allCameras.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam_off_rounded,
                    size: 80,
                    color: Colors.white54,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'NO DATA CAMERA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Show camera grid when data exists
    double spacing = 10;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 1.0,
            ),
            itemCount: allCameras.length,
            itemBuilder: (context, index) {
              return _buildCameraStatusBox(allCameras[index]);
            },
          ),
        ),
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
