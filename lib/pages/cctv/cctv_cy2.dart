import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';
import 'package:monitoring/main.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/services/device_storage_service.dart';
import 'package:monitoring/utils/location_label_utils.dart';
import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';
import 'package:monitoring/widgets/global_footer.dart';
import 'package:monitoring/models/camera_model.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';

// CCTV Page CY 2
class CCTVCy2Page extends StatefulWidget {
  const CCTVCy2Page({super.key});

  @override
  State<CCTVCy2Page> createState() => _CCTVCy2PageState();
}

class _CCTVCy2PageState extends State<CCTVCy2Page> {
  String selectedArea = 'CY 2';
  int currentPage = 0;
  int camerasPerPage = 6;
  bool isLoading = true;
  List<Camera> allCameras = [];
  DateTime? lastUpdated;
  Timer? _refreshTimer;
  int globalTotalCameras = 0;
  int globalUpCameras = 0;
  int globalDownCameras = 0;
  bool _isLoadingGlobalSummary = true;
  bool _isGlobalSummaryRequestInFlight = false;

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

  int _resolveCamerasPerPage() {
    return 6;
  }

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
                    'All cameras are in UP condition',
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
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
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
    _loadGlobalSummary(initialLoad: true);
    // Refresh setiap 2 detik untuk monitoring realtime
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _loadCameras();
        _loadGlobalSummary();
      }
    });
  }

  Future<void> _triggerRealtimePing() async {
    try {
      debugPrint('=== Starting Realtime Ping For All Cameras (CY2) ===');

      final apiService = ApiService();
      final pingResult = await apiService.triggerRealtimePing();

      if (pingResult['success'] == true) {
        debugPrint('Realtime Ping Completed: ${pingResult['message']}');
        debugPrint('IP Checked: ${pingResult['ips_checked']}');
      }

      debugPrint('=== Realtime Ping Completed (CY2) ===');
    } catch (e) {
      debugPrint('Error Triggering Realtime Ping: $e');
    }
  }

  Future<void> _loadCameras() async {
    try {
      if (allCameras.isEmpty) {
        setState(() => isLoading = true);
      }

      final apiService = ApiService();
      final validatedCameras =
          await apiService.getValidatedCamerasByYard('CY2');

      final resolvedPerPage = _resolveCamerasPerPage();

      if (mounted) {
        setState(() {
          allCameras = validatedCameras;
          camerasPerPage = resolvedPerPage;
          isLoading = false;
          lastUpdated = DateTime.now();
          if (currentPage >= totalPages && totalPages > 0) {
            currentPage = totalPages - 1;
          }
        });
      }

      _triggerRealtimePing();
    } catch (e) {
      debugPrint('Error Loading Camera: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }
  
  Future<void> _loadGlobalSummary({bool initialLoad = false}) async {
    if (_isGlobalSummaryRequestInFlight) return;
    _isGlobalSummaryRequestInFlight = true;
    try {
      if (mounted && initialLoad) {
        setState(() => _isLoadingGlobalSummary = true);
      }
      final cameras = await ApiService().getAllCameras();
      final up = cameras.where((c) => c.status == 'UP').length;
      final down = cameras.length - up;
      if (mounted) {
        setState(() {
          globalTotalCameras = cameras.length;
          globalUpCameras = up;
          globalDownCameras = down;
          _isLoadingGlobalSummary = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading CCTV global overview: $e');
      if (mounted) setState(() => _isLoadingGlobalSummary = false);
    } finally {
      _isGlobalSummaryRequestInFlight = false;
    }
  }

  Future<void> _triggerPingCheck() async {
    try {
      final baseUrl = ApiService.baseUrl;
      await http
          .get(
        Uri.parse('$baseUrl?endpoint=realtime&action=all'),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Realtime Ping Timed Out');
          return http.Response('{"Success":False}', 408);
        },
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _loadCameras();
      }
    } catch (e) {
      debugPrint('Error Triggering Ping Check (Ignored): $e');
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
      backgroundColor: AppDropdownStyle.standardPageBackground,
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/cctv-cy2'),
          Expanded(
            child: GlobalSidebarNav(
                currentRoute: '/cctv-cy2',
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

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    final isMobile = isMobileScreen(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- TITLE SECTION ---
        isMobile ? _buildMobileHeader() : _buildDesktopHeader(),
        const SizedBox(height: 16),

        // --- STATS CARDS ROW ---
        LayoutBuilder(
          builder: (context, constraints) {
            return isMobile
                ? Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total CCTV',
                              '${allCameras.length}',
                              Colors.blue,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'UP',
                              '$upCameras',
                              Colors.green,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: downCameras > 0 ? _showOfflineList : null,
                              child: _buildStatCard(
                                'DOWN',
                                '$downCameras',
                                Colors.red,
                                compact: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: _buildCCTVDropdown(double.infinity)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                  child:
                                      _buildCheckStatusButton(double.infinity)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _buildAreaButton(double.infinity)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                                child: _buildStatCard('Total CCTV',
                                    '${allCameras.length}', Colors.blue)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildStatCard(
                                    'UP', '$upCameras', Colors.green)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: downCameras > 0 ? _showOfflineList : null,
                                child: _buildStatCard(
                                    'DOWN', '$downCameras', Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCCTVDropdown(constraints.maxWidth),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildAreaButton(constraints.maxWidth),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCheckStatusButton(constraints.maxWidth),
                          ),
                        ],
                      ),
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

  Widget _buildHeaderOverviewMini({required bool isMobile}) {
    final cards = [
      _buildGlobalStatCard('ALL', '$globalTotalCameras', Colors.orange,
          width: isMobile ? null : 86),
      _buildGlobalStatCard('UP', '$globalUpCameras', Colors.green,
          width: isMobile ? null : 86),
      _buildGlobalStatCard('DOWN', '$globalDownCameras', Colors.red,
          width: isMobile ? null : 86),
    ];

    final content = isMobile
        ? Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 8),
              Expanded(child: cards[1]),
              const SizedBox(width: 8),
              Expanded(child: cards[2]),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              cards[0],
              const SizedBox(width: 8),
              cards[1],
              const SizedBox(width: 8),
              cards[2],
            ],
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview Data All Area',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          content,
        ],
      ),
    );
  }

  Widget _buildGlobalStatCard(String title, String value, Color indicatorColor,
      {double? width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color indicatorColor,
      {double? width, bool compact = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width,
          padding: EdgeInsets.all(compact ? 12 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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
                    child: SizedBox(
                      height: compact ? 32 : 20,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 11 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: compact ? 10 : 12,
                    height: compact ? 10 : 12,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: indicatorColor.withValues(alpha: 0.5),
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
                style: TextStyle(
                  fontSize: compact ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 2,
                width: compact ? 30 : 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      indicatorColor,
                      indicatorColor.withValues(alpha: 0)
                    ],
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



  Widget _buildCCTVDropdown(double width) {
    final List<String> areaOptions = [
      'CY 1',
      'CY 2',
      'CY 3',
      'GATE',
      'PARKING'
    ];

    return _buildActionCard(
      title: 'AREA',
      icon: Icons.location_on_rounded,
      iconColor: Colors.white,
      content: AnimatedDropdownButton(
        value: "Select Area",
        items: areaOptions,
        backgroundColor: AppDropdownStyle.menuBackground,
        onChanged: (String? newValue) {
          if (newValue == null) return;
          if (newValue == 'CY 1') {
            Navigator.pushReplacementNamed(context, '/cctv');
          } else if (newValue == 'CY 2') {
            Navigator.pushReplacementNamed(context, '/cctv-cy2');
          } else if (newValue == 'CY 3') {
            Navigator.pushReplacementNamed(context, '/cctv-cy3');
          } else if (newValue == 'GATE') {
            Navigator.pushReplacementNamed(context, '/cctv-gate');
          } else if (newValue == 'PARKING') {
            Navigator.pushReplacementNamed(context, '/cctv-parking');
          }
        },
      ),
    );
  }

  Widget _buildAreaButton(double width) {
    return _buildActionCard(
      title: 'AREA',
      icon: Icons.location_on_rounded,
      iconColor: const Color(0xFF1976D2),
      content: Text(
        selectedArea,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 15,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCheckStatusButton(double width) {
    return _buildActionCard(
      title: 'ACTION',
      icon: Icons.refresh_rounded,
      iconColor: const Color(0xFF4CAF50),
      onTap: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checking status...'),
            duration: Duration(seconds: 2),
          ),
        );
        await _triggerPingCheck();
        await _loadCameras();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Status successfully updated!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      content: const Text(
        'CHECK STATUS',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 15,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget content,
    VoidCallback? onTap,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return MouseRegion(
      cursor:
          onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon,
                        color: Colors.white, size: isMobile ? 18 : 20),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: content is Text
                              ? FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: content,
                                )
                              : content,
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
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
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
                    'Loading CCTV data...',
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
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
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
                    'No CCTV data available',
                    textAlign: TextAlign.center,
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
    double childAspectRatio = isMobile ? 1.0 : 1.0;
    double spacing = isMobile ? 8 : 20;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isMobile ? 180 : 240,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: paginatedCameras.length,
      itemBuilder: (context, index) {
        return _buildCameraCard(paginatedCameras[index]);
      },
    );
  }

  Widget _buildCameraCard(Camera camera) {
    bool isUp = camera.status == 'UP';
    Color statusColor =
        isUp ? const Color(0xFF4CAF50) : const Color(0xFFE53935);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                statusColor.withValues(alpha: 0.3),
                                statusColor.withValues(alpha: 0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.6),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.4),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.3),
                                blurRadius: 4,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.videocam_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        camera.cameraId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      size: 20, color: Colors.white70),
                  color: const Color(0xFF1B2631),
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
                          Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    // Ensure at least 1 page is shown even if data is empty
    final int displayPages = totalPages > 0 ? totalPages : 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous Button
              _buildPaginationButton(
                label: 'Previous',
                onTap: currentPage > 0
                    ? () => setState(() => currentPage--)
                    : null,
                color: const Color(0xFFE53935),
                isFirst: true,
              ),

              // Page Numbers
              ...List.generate(displayPages, (index) {
                // Logic to show limited page numbers with ellipsis
                if (displayPages > 7) {
                  if (index != 0 &&
                      index != displayPages - 1 &&
                      (index < currentPage - 1 || index > currentPage + 1)) {
                    if (index == 1 && currentPage > 3) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('...', style: TextStyle(color: Colors.white70)),
                      );
                    }
                    if (index == displayPages - 2 && currentPage < displayPages - 4) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('...', style: TextStyle(color: Colors.white70)),
                      );
                    }
                    if (index > 1 && index < displayPages - 2) return const SizedBox.shrink();
                  }
                }

                return _buildPaginationButton(
                  label: '${index + 1}',
                  onTap: (allCameras.isNotEmpty && currentPage != index)
                      ? () => setState(() => currentPage = index)
                      : null,
                  color: currentPage == index
                      ? const Color(0xFF1565C0)
                      : const Color(0xFF2196F3),
                  isSquare: true,
                );
              }),

              // Next Button
              _buildPaginationButton(
                label: 'Next',
                onTap: currentPage < displayPages - 1 && allCameras.isNotEmpty
                    ? () => setState(() => currentPage++)
                    : null,
                color: const Color(0xFFE53935),
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationButton({
    required String label,
    VoidCallback? onTap,
    required Color color,
    bool isFirst = false,
    bool isLast = false,
    bool isSquare = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSquare ? 12 : 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: onTap == null ? color.withValues(alpha: 0.3) : color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              if (onTap != null)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: onTap == null ? Colors.white54 : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
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

    if (!mounted) return;

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
                decoration: const InputDecoration(labelText: 'IP address'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedLocation,
                isExpanded: true,
                dropdownColor: AppDropdownStyle.menuBackground,
                borderRadius: AppDropdownStyle.menuBorderRadius,
                decoration: const InputDecoration(labelText: 'Location'),
                items: locationOptions
                    .map((option) => DropdownMenuItem<String>(value: option['label'],
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
                  // Sync local storage after backend success
                  await DeviceStorageService.updateDeviceFields(
                    type: 'CCTV',
                    name: camera.cameraId,
                    updates: {
                      'ipAddress': ipController.text,
                      'locationName': selectedLocation,
                      'containerYard': selectedArea,
                    },
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _loadCameras();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Berhasil diperbarui'),
                      backgroundColor: Colors.green));
                }
              },
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
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
        title: const Text('Delete confirmation'),
        content: Text('Delete kamera ${camera.cameraId}?'),
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
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadCameras();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Data successfully deleted'),
                    backgroundColor: Colors.green));
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
        content: const Text('Are you sure you want to exit?',
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
  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.videocam,
                  size: 30, color: Color(0xFF1976D2)),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'CCTV Monitoring',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/cctv-fullscreen'),
              child: Icon(
                Icons.fullscreen_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 28,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Monitoring View of CCTV',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        if (lastUpdated != null)
          Row(
            children: [
              const Text('•', style: TextStyle(color: Colors.greenAccent)),
              const SizedBox(width: 4),
              Text(
                'Updated: ${lastUpdated!.hour.toString().padLeft(2, '0')}:${lastUpdated!.minute.toString().padLeft(2, '0')}:${lastUpdated!.second.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        const SizedBox(height: 10),
        _buildHeaderOverviewMini(isMobile: true),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.videocam,
            size: 30,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
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
                  'Monitoring View of CCTV',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                if (lastUpdated != null) ...[
                  const SizedBox(width: 12),
                  const Text('•', style: TextStyle(color: Colors.greenAccent)),
                  const SizedBox(width: 6),
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
        _buildHeaderOverviewMini(isMobile: false),
        const SizedBox(width: 16),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/cctv-fullscreen'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.fullscreen_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
