import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'route_proxy_page.dart';
import 'services/api_service.dart';
import 'utils/tower_status_override.dart';
import 'widgets/expandable_fab_nav.dart';
import 'widgets/global_header_bar.dart';

// CCTV Page CY 2
class CCTVCy2Page extends StatefulWidget {
  const CCTVCy2Page({super.key});

  @override
  State<CCTVCy2Page> createState() => _CCTVCy2PageState();
}

class _CCTVCy2PageState extends State<CCTVCy2Page> {
  String selectedYard = 'CY 2';
  int currentPage = 0;
  int camerasPerPage = 8;
  bool isLoading = true;
  final List<Map<String, dynamic>> allCameras = [];
  DateTime? lastUpdated;
  Timer? _refreshTimer;

  List<Map<String, dynamic>> get paginatedCameras {
    int start = currentPage * camerasPerPage;
    int end = (start + camerasPerPage > allCameras.length)
        ? allCameras.length
        : start + camerasPerPage;
    return allCameras.sublist(start, end);
  }

  int get totalPages => (allCameras.length / camerasPerPage).ceil();
  int get upCameras => allCameras.where((c) => c['status'] == 'UP').length;
  int get downCameras => allCameras.where((c) => c['status'] == 'DOWN').length;

  int _resolveCamerasPerPage() {
    final isMobile = isMobileScreen(context);
    if (isMobile) return 4;  // Mobile: 1 column layout
    
    // Desktop layouts
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1400) return 8;  // 4 columns
    if (screenWidth > 1000) return 9;  // 3 columns (3x3 = 9 full)
    return 8;  // 2 columns (2x4 = 8)
  }

  void _showOfflineList() {
    final offlines = allCameras.where((c) => c['status'] == 'DOWN').toList();
    showFadeAlertDialog(
      context: context,
      title: 'Cameras DOWN (${offlines.length})',
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 350,
          maxHeight: 400,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (offlines.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'All Cameras Are In UP Condition',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...offlines.map((c) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          c['id'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DOWN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCameras();
    // Refresh setiap 2 detik untuk monitoring realtime
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _loadCameras();
      }
    });
  }

  Future<void> _triggerRealtimePing() async {
    try {
      print('=== Starting Realtime Ping For All Camera (CY2) ===');

      final apiService = ApiService();
      final pingResult = await apiService.triggerRealtimePing();

      if (pingResult['success'] == true) {
        print('Realtime Ping Completed: ${pingResult['message']}');
        print('IP Checked: ${pingResult['ips_checked']}');
      }

      print('=== Realtime Ping Completed (CY2) ===');
    } catch (e) {
      print('Error Triggering Realtime Ping: $e');
    }
  }

  Future<void> _loadCameras() async {
    try {
      // Don't show loading if already have data (prevents flickering)
      if (allCameras.isEmpty) {
        setState(() {
          isLoading = true;
        });
      }

      final apiService = ApiService();
      final cameras = await apiService.getCamerasByContainerYard('CY2');
      final updatedCameras = applyForcedCameraStatus(cameras);

      // Resolve adaptive page size before loading data
      final resolvedPerPage = _resolveCamerasPerPage();
      if (resolvedPerPage != camerasPerPage) {
        setState(() {
          camerasPerPage = resolvedPerPage;
          if (currentPage >= totalPages && totalPages > 0) {
            currentPage = totalPages - 1;
          }
        });
      }

      if (mounted) {
        setState(() {
          allCameras.clear();
          final camerasMap = updatedCameras
              .map((c) => {
                    'id': c.cameraId,
                    'location': c.location,
                    'status': c.status,
                    'type': c.type,
                    'ip_address': c.ipAddress,
                  })
              .toList();
          camerasMap
              .sort((a, b) => a['id'].toString().compareTo(b['id'].toString()));
          allCameras.addAll(camerasMap);
          isLoading = false;
          // Only reset page if current page exceeds available pages
          if (currentPage >= totalPages && totalPages > 0) {
            currentPage = totalPages - 1;
          }
          lastUpdated = DateTime.now();
        });
      }

      // Trigger realtime ping in background after UI loads
      _triggerRealtimePing();
    } catch (e) {
      print('Error Loading Camera: $e');
      setState(() {
        isLoading = false;
      });
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
        await _loadCameras();
      }
    } catch (e) {
      print('Error Triggering Ping Check (Ignored): $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Stack(
        children: [
          Column(
            children: [
              const GlobalHeaderBar(currentRoute: '/cctv-cy2'),
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
          const ExpandableFabNav(currentRoute: '/cctv-cy2'),
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
                      _buildHeaderOpenButton('CCTV', '/cctv', isActive: true),
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
              // Terminal Nilam - TETAP FIXED
              const Text(
                'Terminal Nilam',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 30),
              // Buttons - SCROLL HORIZONTAL
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeaderOpenButton('Add New Device', '/add-device',
                            isActive: false),
                        const SizedBox(width: 12),
                         _buildHeaderOpenButton('Master Data', '/tower-management', isActive: false),
                        const SizedBox(width: 12),
                        _buildHeaderOpenButton('Dashboard', '/dashboard',
                            isActive: false),
                        const SizedBox(width: 12),
                        _buildHeaderOpenButton('Access Point', '/network',
                            isActive: false),
                        const SizedBox(width: 12),
                        _buildHeaderOpenButton('CCTV', '/cctv', isActive: true),
                        const SizedBox(width: 12),
                        _buildHeaderOpenButton('MMT', '/mmt-monitoring', isActive: false),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- TITLE SECTION ---
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.videocam,
                  size: 24,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'CCTV',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Live Monitoring',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.videocam,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CCTV Monitoring',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Live Camera Feeds And Surveillance System Status',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      if (lastUpdated != null) ...[
                        const SizedBox(width: 8),
                        const Text('•',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(width: 8),
                        Text(
                          'Updated: ${lastUpdated!.hour.toString().padLeft(2, '0')}:${lastUpdated!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Fullscreen Button
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/cctv-fullscreen'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),

        // --- STATS CARDS ROW ---
        LayoutBuilder(
          builder: (context, constraints) {
            double cardWidth = isMobile
                ? (constraints.maxWidth - 16) / 1.5
                : constraints.maxWidth > 1400
                    ? (constraints.maxWidth - 100) / 5
                    : (constraints.maxWidth - 80) / 3;

            return isMobile
                ? Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatCard('Total Camera', '${allCameras.length}',
                                Colors.orange, cardWidth),
                            const SizedBox(width: 8),
                            _buildStatCard('UP', '$upCameras', Colors.green, cardWidth),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _showOfflineList,
                              child: _buildStatCard('DOWN', '$downCameras',
                                  Colors.red, cardWidth),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCCTVDropdown(constraints.maxWidth),
                      const SizedBox(height: 12),
                      _buildContainerYardButton(constraints.maxWidth),
                      const SizedBox(height: 12),
                      _buildCheckStatusButton(constraints.maxWidth),
                    ],
                  )
                : Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildStatCard('Total Camera', '${allCameras.length}',
                          Colors.orange, cardWidth),
                      _buildStatCard('UP', '$upCameras', Colors.green, cardWidth),
                      GestureDetector(
                        onTap: _showOfflineList,
                        child: _buildStatCard('DOWN', '$downCameras', Colors.red, cardWidth),
                      ),
                      _buildCCTVDropdown(cardWidth),
                      _buildContainerYardButton(cardWidth),
                      _buildCheckStatusButton(cardWidth),
                    ],
                  );
          },
        ),
        const SizedBox(height: 16),

        // --- CAMERA GRID ---
        _buildCameraGrid(constraints),
        const SizedBox(height: 24),

        // --- PAGINATION ---
        _buildPagination(),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, Color indicatorColor, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCCTVDropdown(double width) {
    return Container(
      width: width,
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A5F7F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AREA',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                // --- FIX: TAMPILAN "SELECT AREA" ---
                value: null, // Set null agar value lama tidak tampil di kotak utama
                hint: const Text(
                  "Select Area", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                ),
                dropdownColor: const Color(0xFF4A5F7F),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                items: const ['CY 1', 'CY 2', 'CY 3', 'Parking', 'Gate']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedYard = newValue;
                      isLoading = true;
                    });
                    if (newValue == 'CY 1') {
                      Navigator.pushReplacementNamed(context, '/cctv');
                    } else if (newValue == 'CY 2') Navigator.pushReplacementNamed(context, '/cctv-cy2');
                    else if (newValue == 'CY 3') Navigator.pushReplacementNamed(context, '/cctv-cy3');
                    else if (newValue == 'Parking') Navigator.pushReplacementNamed(context, '/cctv-parking');
                    else if (newValue == 'Gate') Navigator.pushReplacementNamed(context, '/cctv-gate');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildContainerYardButton(double width) {
    return Container(
      width: width,
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF5D6D7E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1.0),
      ),
      child: const Center(
        child: Text(
          'Container\nYard 2',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckStatusButton(double width) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Checking Status...'),
              duration: Duration(seconds: 2),
            ),
          );
          await _triggerPingCheck();
          await _loadCameras();
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
        child: Container(
          width: width,
          height: 80,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24, width: 1.0),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Check Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading Camera Data...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No Data Camera',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show camera grid when data exists
    final isMobile = isMobileScreen(context);
    int crossAxisCount = isMobile
        ? 1
        : constraints.maxWidth > 1400
            ? 4
            : constraints.maxWidth > 1000
                ? 3
                : 2;

    double childAspectRatio = isMobile ? 1.0 : 1.2;
    double spacing = isMobile ? 12 : 20;

    return SizedBox(
      width: double.infinity,
      child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: paginatedCameras.length,
      itemBuilder: (context, index) {
        return _buildCameraCard(paginatedCameras[index]);
      },
      ),
    );
  }

   Widget _buildCameraCard(Map<String, dynamic> camera) {
    bool isUp = camera['status'] == 'UP';
    Color statusColor = isUp ? Colors.green : Colors.red;

    return Stack( // 1. Tambahkan Stack agar tombol bisa melayang di atas kartu
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.videocam,
                          color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF1976D2),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Text(
                    camera['id'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // 2. Tambahkan tombol aksi melayang di pojok kanan atas
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8), // Background putih transparan
              shape: BoxShape.circle,
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20, color: Colors.black54),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditCameraForm(camera);
                } else if (value == 'delete') {
                  _confirmDeleteCamera(camera);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${(currentPage * camerasPerPage) + 1}-${(currentPage * camerasPerPage) + paginatedCameras.length} Of ${allCameras.length} Camera',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 0
                    ? () {
                        setState(() {
                          currentPage--;
                        });
                      }
                    : null,
              ),
              ...List.generate(totalPages, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        currentPage = index;
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: currentPage == index
                            ? const Color(0xFF1976D2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: currentPage == index
                              ? const Color(0xFF1976D2)
                              : Colors.grey,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: currentPage == index
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages - 1
                    ? () {
                        setState(() {
                          currentPage++;
                        });
                      }
                    : null,
              ),
            ],
          ),
        ],
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
          '©2026 TPK Nilam Monitoring System',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

void _showEditCameraForm(Map<String, dynamic> camera) {
    // Controller otomatis terisi data lama (Initial Value)
    final ipController = TextEditingController(text: camera['ip_address'] ?? '');
    final locationController = TextEditingController(text: camera['location'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${camera['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(labelText: 'IP Address'),
            ),
            TextField(
              controller: locationController,
              readOnly: true,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Location (Locked)',
                helperText: 'Pindah lokasi wajib delete camera lalu add ulang di lokasi tujuan.',
              ),
            ),
          ],
        ),
        actions: [
          // Tombol Cancel
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          // Tombol Save
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // PERBAIKAN: Kirim 2 argumen (ID dan Map Data)
              final response = await ApiService().updateCamera(
                camera['id'], // Argumen 1: ID Kamera
                {              // Argumen 2: Map Data yang diubah
                  'ip_address': ipController.text,
                },
              );

              if (response['success'] == true) {
                if (mounted) {
                  Navigator.pop(context); // Menutup dialog
                  _loadCameras(); // Refresh data
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Updated Successfully'), 
                      backgroundColor: Colors.green
                    )
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCamera(Map<String, dynamic> camera) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Camera'),
        content: Text('Are You Sure Want To Delete Camera ${camera['id']}?'),
        actions: [
          // Tombol Cancel
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          // Tombol Delete
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final response = await ApiService().deleteCamera(camera['id']);
              
              if (response['success'] == true) {
                if (mounted) {
                  Navigator.pop(context); // Menutup dialog
                  _loadCameras(); // Refresh data
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deleted Successfully'), backgroundColor: Colors.red)
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
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
            child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
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
