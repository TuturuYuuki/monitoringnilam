import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'main.dart';
import 'route_proxy_page.dart';
import 'services/api_service.dart';

// Fullscreen CCTV Page - All Areas
class CCTVFullscreenPage extends StatefulWidget {
  const CCTVFullscreenPage({super.key});

  @override
  State<CCTVFullscreenPage> createState() => _CCTVFullscreenPageState();
}

class _CCTVFullscreenPageState extends State<CCTVFullscreenPage> {
  bool isLoading = false;
  final List<Map<String, dynamic>> allCameras = [];

  int get upCameras => allCameras.where((c) => c['status'] == 'UP').length;
  int get downCameras => allCameras.where((c) => c['status'] == 'DOWN').length;
  int get totalCameras => allCameras.length;

  @override
  void initState() {
    super.initState();
    _loadAllCameras();
  }

  Future<void> _loadAllCameras() async {
    try {
      setState(() {
        isLoading = true;
      });

      final apiService = ApiService();
      final cameras = await apiService.getAllCameras();

      setState(() {
        allCameras.clear();
        final camerasMap = cameras
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
    } catch (e) {
      print('Error loading cameras: $e');
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
                    padding: EdgeInsets.all(isMobile ? 12 : 24),
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
          horizontal: isMobile ? 12 : 24, vertical: isMobile ? 12 : 16),
      color: const Color(0xFF1976D2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Terminal Nilam - All CCTV Fullscreen',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18 : 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildHeaderOpenButton('Dashboard', '/dashboard', isActive: false),
          const SizedBox(width: 12),
          _buildHeaderOpenButton('Network', '/network', isActive: false),
          const SizedBox(width: 12),
          _buildHeaderOpenButton('CCTV', '/cctv', isActive: false),
          const SizedBox(width: 12),
          _buildHeaderOpenButton('Alerts', '/alerts', isActive: false),
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
              openBuilder: (context, _) => const RouteProxyPage('/profile'),
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
        // Title Section
        Row(
          children: [
            Icon(Icons.videocam_rounded, color: Colors.blue, size: 32),
            const SizedBox(width: 16),
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
                  'Melihat semua status CCTV di semua area',
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

        // Stats Section (Compact)
        Row(
          children: [
            Expanded(
              child: _buildStatCard('TOTAL CCTV', totalCameras.toString(),
                  Colors.blue, double.infinity),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                  'UP', upCameras.toString(), Colors.green, double.infinity),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                  'DOWN', downCameras.toString(), Colors.red, double.infinity),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Camera Grid - Full Screen
        _buildCameraGrid(constraints),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, Color indicatorColor, double width) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
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
        padding: const EdgeInsets.all(40),
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
                'Loading CCTV data...',
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
        padding: const EdgeInsets.all(40),
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
                'No CCTV cameras found',
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
    int crossAxisCount =
        (constraints.maxWidth / 50).floor().clamp(8, 30).toInt();
    double spacing = 6;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.4),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Text(
              camera['id'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
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
        content: const Text('Apakah Anda yakin ingin keluar?',
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
