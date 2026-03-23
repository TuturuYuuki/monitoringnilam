import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'services/api_service.dart';
import 'models/tower_model.dart';
import 'route_proxy_page.dart';
import 'utils/tower_status_override.dart';
import 'utils/location_label_utils.dart';
import 'widgets/expandable_fab_nav.dart';
import 'widgets/global_header_bar.dart';
import 'widgets/global_sidebar_nav.dart';

// Network Page CY 3
class NetworkCY3Page extends StatefulWidget {
  const NetworkCY3Page({super.key});

  @override
  State<NetworkCY3Page> createState() => _NetworkCY3PageState();
}

class _NetworkCY3PageState extends State<NetworkCY3Page> {
  String selectedArea = 'CY 3';
  static const List<String> _areaOptions = [
    'CY 1',
    'CY 2',
    'CY 3',
    'GATE',
    'PARKING',
  ];
  int currentPage = 0;
  final int itemsPerPage = 5;
  late ApiService apiService;
  List<Tower> towers = [];
  bool isLoading = true;
  Timer? _refreshTimer;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _loadTowers();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh setiap 2 detik untuk monitoring realtime
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _loadTowers();
      }
    });
  }

  Future<void> _loadTowers() async {
  try {
    // 1. Ambil data database DULU
    final fetchedTowers = await apiService.getTowersByContainerYard('CY3');
    
    if (mounted) {
      setState(() {
        towers = _normalizeAndSortTowers(applyForcedTowerStatus(fetchedTowers));
        isLoading = false;
        _lastRefreshTime = DateTime.now();
      });
    }

    // 2. Jalankan ping di background
    _triggerRealtimePing(); 

  } catch (e) {
    print('Error Loading Tower CY3: $e');
    if (mounted) setState(() => isLoading = false);
  }
}

  Future<void> _triggerRealtimePing() async {
    try {
      print('=== Starting Realtime Ping For All Towers (CY3) ===');

      // Trigger backend realtime ping untuk semua devices
      final pingResult = await apiService.triggerRealtimePing();

      if (pingResult['success'] == true) {
        print('Realtime Ping Completed: ${pingResult['message']}');
        print('IP Checked: ${pingResult['ips_checked']}');
      }

      print('=== Realtime Ping Completed (CY3) ===');
    } catch (e) {
      print('Error Triggering Realtime Ping: $e');
    }
  }

  Future<void> _triggerPingCheck() async {
    try {
      const baseUrl = 'http://localhost/monitoring_api/index.php';

      // Call realtime ping endpoint yang update semua towers sekaligus
      final response = await http
          .get(
        Uri.parse('$baseUrl?endpoint=realtime&action=all'),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Realtime Ping Timed Out');
          return http.Response('{"success":false}', 408);
        },
      );

      if (response.statusCode == 200) {
        // Wait a moment for database to update
        await Future.delayed(const Duration(milliseconds: 500));
        print('Realtime Ping Check Completed');
      }
    } catch (e) {
      print('Error Triggering Ping Check (Ignored): $e');
    }
  }

  List<Tower> _normalizeAndSortTowers(List<Tower> input) {
    final dedup = <String, Tower>{};
    for (final tower in input) {
      dedup[tower.towerId.toLowerCase()] = tower;
    }
    final list = dedup.values.toList();
    list.sort((a, b) => _orderValue(a).compareTo(_orderValue(b)));
    return list;
  }

  double _orderValue(Tower tower) {
    if (tower.towerNumber > 0) {
      return tower.towerNumber.toDouble();
    }

    final regex = RegExp(r'^(\d+)([A-Za-z]?)$');
    final match = regex.firstMatch(tower.towerId.trim());
    if (match != null) {
      final base = double.tryParse(match.group(1) ?? '') ?? 9999;
      final suffix = match.group(2);
      if (suffix != null && suffix.isNotEmpty) {
        final offset = (suffix.codeUnitAt(0) - 'A'.codeUnitAt(0) + 1) / 10;
        return base + offset;
      }
      return base;
    }

    return 9999;
  }

  final List<Map<String, dynamic>> towerData = [
    {
      'id': 'T11',
      'location': 'Container Yard 3',
      'ip': '192.168.30.1',
      'device': '2 CCTV',
      'status': 'UP',
      'traffic': '198 Mbps',
      'uptime': '99.6%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T12',
      'location': 'Container Yard 3',
      'ip': '192.168.30.2',
      'device': '3 CCTV',
      'status': 'UP',
      'traffic': '212 Mbps',
      'uptime': '98.9%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T13',
      'location': 'Container Yard 3',
      'ip': '192.168.30.3',
      'device': '2 CCTV',
      'status': 'UP',
      'traffic': '176 Mbps',
      'uptime': '99.3%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T14',
      'location': 'Container Yard 3',
      'ip': '192.168.30.4',
      'device': '1 CCTV',
      'status': 'Warning',
      'traffic': '85 Mbps',
      'uptime': '95.8%',
      'statusColor': Colors.red,
    },
    {
      'id': 'T15',
      'location': 'Container Yard 3',
      'ip': '192.168.30.5',
      'device': '3 CCTV',
      'status': 'UP',
      'traffic': '205 Mbps',
      'uptime': '99.1%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T16',
      'location': 'Container Yard 3',
      'ip': '192.168.30.6',
      'device': '2 CCTV',
      'status': 'Warning',
      'traffic': '92 Mbps',
      'uptime': '96.3%',
      'statusColor': Colors.red,
    },
    {
      'id': 'T17',
      'location': 'Container Yard 3',
      'ip': '192.168.30.7',
      'device': '2 CCTV',
      'status': 'UP',
      'traffic': '201 Mbps',
      'uptime': '99.0%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T18',
      'location': 'Container Yard 3',
      'ip': '192.168.30.8',
      'device': '3 CCTV',
      'status': 'UP',
      'traffic': '215 Mbps',
      'uptime': '99.2%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T19',
      'location': 'Container Yard 3',
      'ip': '192.168.30.9',
      'device': '2 CCTV',
      'status': 'UP',
      'traffic': '188 Mbps',
      'uptime': '98.8%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T20',
      'location': 'Container Yard 3',
      'ip': '192.168.30.10',
      'device': '1 CCTV',
      'status': 'UP',
      'traffic': '156 Mbps',
      'uptime': '99.4%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T21',
      'location': 'Container Yard 3',
      'ip': '192.168.30.11',
      'device': '3 CCTV',
      'status': 'UP',
      'traffic': '198 Mbps',
      'uptime': '99.1%',
      'statusColor': Colors.green,
    },
  ];

  List<Tower> get paginatedData {
    int start = currentPage * itemsPerPage;
    int end = (start + itemsPerPage > towers.length)
        ? towers.length
        : start + itemsPerPage;
    return towers.sublist(start, end);
  }

  int get totalPages => (towers.length / itemsPerPage).ceil();

  int get totalTowers => towers.length;
  int get onlineTowers => towers.where((t) => !isDownStatus(t.status)).length;
  int get warningTowers => towers.where((t) => isDownStatus(t.status)).length;

  void _showWarningList() {
    final warnings = towers.where((t) => isDownStatus(t.status)).toList();
    showFadeAlertDialog(
      context: context,
      title: 'Access Point DOWN (${warnings.length})',
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 350,
          maxHeight: 400,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (warnings.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'All Towers Are In UP Condition.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...warnings.map((t) {
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
                          t.towerId,
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
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Stack(
        children: [
          Column(
            children: [
              const GlobalHeaderBar(currentRoute: '/network-cy3'),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sidebar (Kiri)
                    const GlobalSidebarNav(currentRoute: '/network-cy3'),
                    const SizedBox(width: 12),
                    // Content (Kanan)
                    Expanded(
                      child: SingleChildScrollView(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Padding(
                              padding: EdgeInsets.all(isMobile ? 8 : 20.0),
                              child: _buildContent(context, constraints),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
          const ExpandableFabNav(currentRoute: '/network-cy3'),
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
                          isActive: true),
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
                         _buildHeaderOpenButton('Master Data', '/tower-management',
                            isActive: false),
                        const SizedBox(width: 12),
                        _buildHeaderOpenButton('Dashboard', '/dashboard',
                            isActive: false),
                        const SizedBox(width: 12),
                        _buildHeaderOpenButton('Access Point', '/network',
                            isActive: true),
                        const SizedBox(width: 12),
                        _buildHeaderOpenButton('CCTV', '/cctv', isActive: false),
                        const SizedBox(width: 12),
                        _buildHeaderOpenButton('MMT', '/mmt-monitoring', isActive: false),
                        const SizedBox(width: 12),
                        _buildHeaderOpenButton('Alert', '/alerts', isActive: false),
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
        // Title Section
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.language,
                  size: 32, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Access Point Monitoring',
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
                      'Real Time Access Point Monitoring And Diagnostics',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    if (_lastRefreshTime != null) ...[
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: Colors.white70)),
                      const SizedBox(width: 8),
                      Text(
                        'Updated: ${_lastRefreshTime!.hour.toString().padLeft(2, '0')}:${_lastRefreshTime!.minute.toString().padLeft(2, '0')}:${_lastRefreshTime!.second.toString().padLeft(2, '0')}',
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
          ],
        ),
        const SizedBox(height: 24),

        // Stats Cards Row with Dropdown
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
                            _buildStatCard('Total Access Point', '$totalTowers',
                                Colors.orange,
                                width: cardWidth),
                            SizedBox(width: isMobile ? 8 : 16),
                            _buildStatCard('UP', '$onlineTowers', Colors.green,
                                width: cardWidth),
                            SizedBox(width: isMobile ? 8 : 16),
                            _buildStatCard(
                                'DOWN', '$warningTowers', Colors.blue,
                                onTap: _showWarningList, width: cardWidth),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildNetworkDropdown(constraints.maxWidth),
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
                      _buildStatCard(
                          'Total Access Point', '$totalTowers', Colors.orange,
                          width: cardWidth),
                      _buildStatCard('UP', '$onlineTowers', Colors.green,
                          width: cardWidth),
                      _buildStatCard('DOWN', '$warningTowers', Colors.red,
                          onTap: _showWarningList, width: cardWidth),
                      _buildNetworkDropdown(cardWidth),
                      _buildAreaButton(cardWidth),
                      _buildCheckStatusButton(cardWidth),
                    ],
                  );
          },
        ),
        const SizedBox(height: 16),

        // Tower List
        _buildTowerList(),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color indicatorColor,
      {VoidCallback? onTap, double? width}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
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
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(-5, -5),
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
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                            color: indicatorColor.withOpacity(0.6),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 0.5,
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
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
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

  Widget _buildNetworkDropdown(double width) {
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
                child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
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
                        dropdownColor: const Color(0xFF0F172A),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
                        items: _areaOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue == null) return;
                          
                          if (newValue == 'CY 1') {
                            Navigator.pushReplacementNamed(context, '/network');
                          } else if (newValue == 'CY 2') {
                            Navigator.pushReplacementNamed(context, '/network-cy2');
                          } else if (newValue == 'CY 3') {
                            Navigator.pushReplacementNamed(context, '/network-cy3');
                          } else if (newValue == 'GATE') {
                            Navigator.pushReplacementNamed(context, '/network-gate');
                          } else if (newValue == 'PARKING') {
                            Navigator.pushReplacementNamed(context, '/network-parking');
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
          await _loadTowers();
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
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
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

   Widget _buildTowerList() {
    // Show loading indicator
    if (isLoading) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            width: double.infinity,
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
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Loading Access Point Data...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Show empty state if no data
    if (towers.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 60),
            width: double.infinity,
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
                    Icons.signal_wifi_off_rounded,
                    size: 64,
                    color: Colors.white38,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'NO DATA ACCESS POINT',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Show data table when towers exist
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1976D2).withOpacity(0.8),
                      const Color(0xFF1976D2).withOpacity(0.4),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Access Point List',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    // Pagination Controls
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, size: 22, color: Colors.white),
                            onPressed: currentPage > 0 ? () => setState(() => currentPage--) : null,
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(width: 8),
                          ...List.generate(totalPages, (index) {
                            bool isCurrentPage = index == currentPage;
                            return GestureDetector(
                              onTap: () => setState(() => currentPage = index),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isCurrentPage ? Colors.white.withOpacity(0.2) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: isCurrentPage ? Colors.white : Colors.white70,
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, size: 22, color: Colors.white),
                            onPressed: currentPage < totalPages - 1 ? () => setState(() => currentPage++) : null,
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFC6B430).withOpacity(0.8), 
                      const Color(0xFFC6B430).withOpacity(0.4), 
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    _buildHeaderCell('Access Point ID', flex: 1),
                    _buildHeaderCell('Location', flex: 2),
                    _buildHeaderCell('IP Address', flex: 2),
                    _buildHeaderCell('Status', flex: 1),
                    _buildHeaderCell('Action', flex: 1, isLast: true),
                  ],
                ),
              ),

              // Table Rows
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paginatedData.length,
                itemBuilder: (context, index) {
                  return _buildTableRow(paginatedData[index]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(Tower tower) {
    bool isWarning = isDownStatus(tower.status);
    String statusLabel = isWarning ? 'DOWN' : tower.status;
    Color statusColor = isWarning ? Colors.redAccent : Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
      child: Row(
        children: [
          _tableCell(tower.towerId, flex: 1, fontWeight: FontWeight.bold),
          _tableCell(tower.location, flex: 2),
          _tableCell(tower.ipAddress, flex: 2),
          _tableCell(
            statusLabel,
            flex: 1,
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(Icons.edit_rounded, Colors.blueAccent, () => _showEditForm(tower)),
                const SizedBox(width: 12),
                _buildActionButton(Icons.delete_rounded, Colors.redAccent, () => _confirmDelete(tower)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _buildPagerIcon(IconData icon, VoidCallback? onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.black87.withOpacity(onPressed == null ? 0.2 : 0.6),
            width: 1.2,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onPressed == null ? Colors.black26 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String label, {required int flex, bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _tableCell(String text,
      {required int flex,
      Color color = Colors.white,
      FontWeight fontWeight = FontWeight.w500}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 13,
            fontWeight: fontWeight,
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
          '©2026 TPK Nilam Monitoring System',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

// --- FUNGSI KHUSUS CY3 ---
  Future<void> _showEditForm(Tower tower) async {
    final ipController = TextEditingController(text: tower.ipAddress);
    var locationOptions = buildMasterLocationOptions(
      await apiService.getAllMasterLocations(),
    );
    if (locationOptions.isEmpty) {
      locationOptions = [
        {
          'label': normalizeLocationLabel(tower.location),
          'container_yard': tower.containerYard,
          'location_type': 'TOWER',
          'location_code': tower.towerId,
          'location_name': tower.location,
        }
      ];
    }
    final matchedOption = matchMasterLocationOption(
      locationOptions,
      tower.location,
      currentContainerYard: tower.containerYard,
    );
    var selectedLocation =
        matchedOption?['label'] ?? normalizeLocationLabel(tower.location);
    var selectedYard = matchedOption?['container_yard'] ?? tower.containerYard;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text('Edit ${tower.towerId}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: ipController,
                  decoration: const InputDecoration(labelText: 'IP Address')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedLocation,
                isExpanded: true,
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
                    selectedYard = option['container_yard'] ?? tower.containerYard;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final response = await apiService.updateTower(tower.id, {
                  'ip_address': ipController.text,
                  'location': selectedLocation,
                  'container_yard': selectedYard,
                });

                if (response['success'] == true) {
                  if (mounted) {
                    Navigator.pop(context);
                    _loadTowers();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('CY3 Updated Successfully'),
                        backgroundColor: Colors.green));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Tower tower) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete ${tower.towerId} from CY3?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final response = await apiService.deleteTower(tower.id);
              if (response['success'] == true) {
                if (mounted) {
                  Navigator.pop(context);
                  _loadTowers(); // Refresh data khusus CY3
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('CY3 Data Deleted Successfully'),
                      backgroundColor: Colors.red));
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

  void _showTowerDetails(Map<String, dynamic> tower) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Access Point ${tower['id']} Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${tower['location']}'),
            const SizedBox(height: 8),
            Text('Status: ${tower['status']}'),
            const SizedBox(height: 8),
            Text('Traffic: ${tower['traffic']}'),
            const SizedBox(height: 8),
            Text('Uptime: ${tower['uptime']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
