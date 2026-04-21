import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:monitoring/main.dart';
import 'package:monitoring/utils/ui_utils.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/utils/tower_status_override.dart';
import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';
import 'package:monitoring/widgets/global_footer.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';

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
    // Refresh UI setiap 5 detik untuk status monitoring realtime (dikurangi frekuensinya agar tidak berat)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
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
        int cmpYard = a['containerYard'].toString().compareTo(b['containerYard'].toString());
        if (cmpYard != 0) return cmpYard;
        int cmpArea = a['areaType'].toString().compareTo(b['areaType'].toString());
        if (cmpArea != 0) return cmpArea;
        return a['id'].toString().compareTo(b['id'].toString());
      });

      if (mounted) {
        setState(() {
          allCameras.clear();
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
      final baseUrl = ApiService.baseUrl;
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
      backgroundColor: AppDropdownStyle.standardPageBackground,
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/cctv-fullscreen'),
          Expanded(
            child: isMobile
                ? _buildScrollingContent(context)
                : GlobalSidebarNav(
                    currentRoute: '/cctv-fullscreen',
                    child: _buildScrollingContent(context),
                  ),
          ),
          const GlobalFooter(),
        ],
      ),
    );
  }

  Widget _buildScrollingContent(BuildContext context) {
    final isMobile = isMobileScreen(context);
    final spacing = isMobile ? 8.0 : 10.0;
    
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 12 : 24,
              isMobile ? 8 : 16,
              isMobile ? 12 : 24,
              16,
            ),
            child: _buildHeaderSection(isMobile),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
          ),
          sliver: SliverToBoxAdapter(
            child: _buildStatsSection(isMobile),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.all(isMobile ? 12 : 24),
          sliver: isLoading
              ? SliverToBoxAdapter(child: _buildLoadingIndicator())
              : allCameras.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState())
                  : SliverGrid(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: isMobile ? 120 : 140,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: 1.0,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildCameraStatusBox(allCameras[index]);
                        },
                        childCount: allCameras.length,
                      ),
                    ),
        ),
        // Add some bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildHeaderSection(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: Color(0xFF1976D2),
                  size: 30,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All CCTV Fullscreen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 18 : 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Monitoring View of All CCTV',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: isMobile ? 10 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isMobile)
          ElevatedButton.icon(
            onPressed: _goBackToCctvOverview,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('BACK'),
          ),
      ],
    );
  }

  Widget _buildStatsSection(bool isMobile) {
    return Column(
      children: [
        if (isMobile) 
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: _goBackToCctvOverview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back'),
              ),
            ),
          ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStatCard('Total CCTV', totalCameras.toString(),
                    Colors.blue, isMobile: isMobile),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                    'UP', upCameras.toString(), Colors.green, isMobile: isMobile),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                    'DOWN', downCameras.toString(), Colors.red, isMobile: isMobile),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildStatCard(String title, String value, Color indicatorColor, {required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: indicatorColor.withValues(alpha: 0.5),
                      blurRadius: 6,
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
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [indicatorColor, indicatorColor.withValues(alpha: 0)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLoadingIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_rounded, size: 80, color: Colors.white54),
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
              color: statusColor.withValues(alpha: 0.4),
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
        content: const Text('Are you sure you want to exit?',
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

