import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:http/http.dart' as http;
import 'package:monitoring/main.dart';
import 'package:monitoring/utils/ui_utils.dart';
import 'package:monitoring/route_proxy_page.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/utils/location_label_utils.dart';
import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';
import 'package:monitoring/widgets/global_footer.dart';
import 'package:monitoring/models/camera_model.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';

// CCTV Page CY 3
class CCTVCy3Page extends StatefulWidget {
  const CCTVCy3Page({super.key});

  @override
  State<CCTVCy3Page> createState() => _CCTVCy3PageState();
}

class _CCTVCy3PageState extends State<CCTVCy3Page> {
  String selectedArea = 'CY 3';
  int currentPage = 0;
  int camerasPerPage = 6;
  bool isLoading = true;
  List<Camera> allCameras = [];
  DateTime? lastUpdated;
  Timer? _refreshTimer;

  List<Camera> get paginatedCameras {
    int start = currentPage * camerasPerPage;
    int end = (start + camerasPerPage > allCameras.length)
        ? allCameras.length
        : start + camerasPerPage;
    return allCameras.sublist(start, end);
  }

  int get totalPages => (allCameras.length / camerasPerPage).ceil();
  int get upCameras => allCameras.where((c) => c.status == 'UP').length;
  int get downCameras => allCameras.where((c) => c.status == 'DOWN').length;

  int _resolveCamerasPerPage() => 6;

  void _showOfflineList() {
    final offlines = allCameras.where((c) => c.status == 'DOWN').toList();
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
                          c.cameraId,
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
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) _loadCameras();
    });
  }

  Future<void> _triggerRealtimePing() async {
    try {
      await ApiService().triggerRealtimePing();
    } catch (e) {
      print('Error Triggering Realtime Ping: $e');
    }
  }

  Future<void> _loadCameras() async {
    try {
      if (allCameras.isEmpty) {
        setState(() => isLoading = true);
      }

      final apiService = ApiService();
      final validatedCameras =
          await apiService.getValidatedCamerasByYard('CY3');

      if (mounted) {
        setState(() {
          allCameras = validatedCameras;
          isLoading = false;
          lastUpdated = DateTime.now();
          if (currentPage >= totalPages && totalPages > 0) {
            currentPage = totalPages - 1;
          }
        });
      }

      _triggerRealtimePing();
    } catch (e) {
      print('Error Loading Camera: $e');
      if (mounted) setState(() => isLoading = false);
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
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/cctv-cy3'),
          Expanded(
            child: GlobalSidebarNav(
                currentRoute: '/cctv-cy3',
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Padding(
                        padding: EdgeInsets.all(isMobile ? 12 : 24),
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
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeaderOpenButton(
                            '+ Add New Device', '/add-device',
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
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeaderOpenButton(
                              'Add New Device', '/add-device',
                              isActive: false),
                          const SizedBox(width: 12),
                          _buildHeaderOpenButton(
                              'Master Data', '/tower-management',
                              isActive: false),
                          const SizedBox(width: 12),
                          _buildHeaderOpenButton('Dashboard', '/dashboard',
                              isActive: false),
                          const SizedBox(width: 12),
                          _buildHeaderOpenButton('Access Point', '/network',
                              isActive: false),
                          const SizedBox(width: 12),
                          _buildHeaderOpenButton('CCTV', '/cctv',
                              isActive: true),
                          const SizedBox(width: 12),
                          _buildHeaderOpenButton('MMT', '/mmt-monitoring',
                              isActive: false),
                          const SizedBox(width: 12),
                          _buildHeaderOpenButton('Alert', '/alerts',
                              isActive: false),
                          const SizedBox(width: 12),
                          _buildHeaderOpenButton('Alert Report', '/report',
                              isActive: false),
                          const SizedBox(width: 12),
                          _buildHeaderLogoutButton(),
                          const SizedBox(width: 12),
                          // Profile Icon - SCROLL dengan buttons
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: OpenContainer(
                              transitionDuration:
                                  const Duration(milliseconds: 550),
                              transitionType:
                                  ContainerTransitionType.fadeThrough,
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
                          'Updated: ${lastUpdated!.hour.toString().padLeft(2, '0')}:${lastUpdated!.minute.toString().padLeft(2, '0')}:${lastUpdated!.second.toString().padLeft(2, '0')}',
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
                            _buildStatCard(
                                'Total Camera',
                                '${allCameras.length}',
                                Colors.orange,
                                cardWidth),
                            const SizedBox(width: 8),
                            _buildStatCard(
                                'UP', '$upCameras', Colors.green, cardWidth),
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
                      _buildAreaButton(constraints.maxWidth),
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
                      _buildStatCard(
                          'UP', '$upCameras', Colors.green, cardWidth),
                      GestureDetector(
                        onTap: _showOfflineList,
                        child: _buildStatCard(
                            'DOWN', '$downCameras', Colors.red, cardWidth),
                      ),
                      _buildCCTVDropdown(cardWidth),
                      _buildAreaButton(cardWidth),
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
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: indicatorColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: indicatorColor.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildCCTVDropdown(double width) {
    final List<String> areaOptions = [
      'CY 1',
      'CY 2',
      'CY 3',
      'GATE',
      'PARKING'
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'AREA',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: null,
                        hint: const Text(
                          "SELECT AREA",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        dropdownColor: AppDropdownStyle.menuBackground,
                        borderRadius: AppDropdownStyle.menuBorderRadius,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.white, size: 20),
                        items: areaOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue == null) return;

                          if (newValue == 'CY 1') {
                            Navigator.pushReplacementNamed(context, '/cctv');
                          } else if (newValue == 'CY 2') {
                            Navigator.pushReplacementNamed(
                                context, '/cctv-cy2');
                          } else if (newValue == 'CY 3') {
                            Navigator.pushReplacementNamed(
                                context, '/cctv-cy3');
                          } else if (newValue == 'GATE') {
                            Navigator.pushReplacementNamed(
                                context, '/cctv-gate');
                          } else if (newValue == 'PARKING') {
                            Navigator.pushReplacementNamed(
                                context, '/cctv-parking');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAreaButton(double width) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1976D2).withOpacity(0.12),
                const Color(0xFF1976D2).withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF1976D2).withOpacity(0.25),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.business_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'YARD',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedArea,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                content: Text('✓ Status updated!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: width,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4CAF50).withOpacity(0.12),
                    const Color(0xFF4CAF50).withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ACTION',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'CHECK STATUS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
    final isMobile = isMobileScreen(context);
    double childAspectRatio = isMobile ? 2.4 : 2.4;
    double spacing = isMobile ? 12 : 20;

    return SizedBox(
      width: double.infinity,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: isMobile ? 320 : 420,
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

  Widget _buildCameraCard(Camera camera) {
    bool isUp = camera.status == 'UP';
    Color statusColor = isUp ? Colors.green : Colors.red;

    return Stack(
      // 1. Tambahkan Stack agar tombol bisa melayang di atas kartu
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
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.videocam,
                          color: Colors.white, size: 18),
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
                    camera.cameraId,
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
              color:
                  Colors.white.withOpacity(0.8), // Background putih transparan
              shape: BoxShape.circle,
            ),
            child: PopupMenuButton<String>(
              icon:
                  const Icon(Icons.more_vert, size: 20, color: Colors.black54),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${(currentPage * camerasPerPage) + 1}-${(currentPage * camerasPerPage) + paginatedCameras.length} Of ${allCameras.length} Camera',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: currentPage > 0
                        ? () {
                            setState(() {
                              currentPage--;
                            });
                          }
                        : null,
                  ),
                  ...List.generate(totalPages, (index) {
                    final isCurrent = currentPage == index;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            currentPage = index;
                          });
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFF1976D2).withOpacity(0.8)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrent
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
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
      ),
    );
  }

  Future<void> _showEditCameraForm(Camera camera) async {
    final ipController = TextEditingController(text: camera.ipAddress);
    var locationOptions = buildMasterLocationOptions(
      await ApiService().getAllMasterLocations(),
    );
    if (locationOptions.isEmpty) {
      locationOptions = [
        {
          'label': normalizeLocationLabel(camera.location),
          'container_yard': camera.containerYard,
          'location_type': 'CCTV',
          'location_code': camera.cameraId,
          'location_name': camera.location,
        }
      ];
    }
    final matchedOption = matchMasterLocationOption(
      locationOptions,
      camera.location,
      currentContainerYard: camera.containerYard,
    );
    var selectedLocation =
        matchedOption?['label'] ?? normalizeLocationLabel(camera.location);
    var selectedArea = matchedOption?['container_yard'] ?? camera.containerYard;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text('Edit ${camera.cameraId}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ipController,
                decoration: const InputDecoration(labelText: 'IP Address'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedLocation,
                isExpanded: true,
                dropdownColor: AppDropdownStyle.menuBackground,
                borderRadius: AppDropdownStyle.menuBorderRadius,
                decoration: const InputDecoration(labelText: 'Location'),
                items: locationOptions
                    .map((option) => DropdownMenuItem<String>(
                          value: option['label'],
                          child: Text(option['label'] ?? ''),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final option = locationOptions.firstWhere(
                    (item) => item['label'] == value,
                    orElse: () => locationOptions.first,
                  );
                  setLocalState(() {
                    selectedLocation = value;
                    selectedArea = option['container_yard'] ?? selectedArea;
                  });
                },
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
                final response = await ApiService().updateCamera(
                  camera.cameraId,
                  {
                    'ip_address': ipController.text,
                    'location': selectedLocation,
                    'container_yard': selectedArea,
                  },
                );

                if (response['success'] == true) {
                  if (mounted) {
                    Navigator.pop(context); // Menutup dialog
                    _loadCameras(); // Refresh data
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Updated Successfully'),
                        backgroundColor: Colors.green));
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCamera(Camera camera) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Camera'),
        content: Text('Are You Sure Want To Delete Camera ${camera.cameraId}?'),
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
              final response = await ApiService().deleteCamera(camera.cameraId);

              if (response['success'] == true) {
                if (mounted) {
                  Navigator.pop(context);
                  _loadCameras();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Deleted Successfully'),
                      backgroundColor: Colors.green));
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
