import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'services/api_service.dart';
import 'models/tower_model.dart';
import 'route_proxy_page.dart';
import 'utils/tower_status_override.dart';

// Network Page CY 3
class NetworkCY3Page extends StatefulWidget {
  const NetworkCY3Page({super.key});

  @override
  State<NetworkCY3Page> createState() => _NetworkCY3PageState();
}

class _NetworkCY3PageState extends State<NetworkCY3Page> {
  String selectedTower = 'CY 3';
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
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: EdgeInsets.all(isMobile ? 12 : 20.0),
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
                        _buildHeaderOpenButton('+ Add New Device', '/add-device',
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
                      'Real Time Access Point Monitoring And Diagnostics - CY 3',
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
                        'Updated: ${_lastRefreshTime!.hour.toString().padLeft(2, '0')}:${_lastRefreshTime!.minute.toString().padLeft(2, '0')}',
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
                      _buildContainerYardButton(constraints.maxWidth),
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
                      _buildContainerYardButton(cardWidth),
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
    final card = Container(
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: card,
      ),
    );
  }

  Widget _buildNetworkDropdown(double width) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
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
                child: AnimatedDropdownButton(
                value: selectedTower,
                items: const ['CY 1', 'CY 2', 'CY 3'],
                backgroundColor: const Color(0xFF4A5F7F),
                onChanged: (String? newValue) {
                  if (newValue == null) return;
                  setState(() {
                    selectedTower = newValue;
                    currentPage = 0;
                    isLoading = true;
                  });
                  if (newValue == 'CY 1') {
                    Navigator.pushReplacementNamed(context, '/network');
                  } else if (newValue == 'CY 2') {
                    Navigator.pushReplacementNamed(context, '/network-cy2');
                  } else if (newValue == 'CY 3') {
                    Navigator.pushReplacementNamed(context, '/network-cy3');
                  }
                },
              ),
              ),
            ],
          ),
        ),
      ],
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
          'Container\nYard 3',
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

   Widget _buildTowerList() {
  // Show loading indicator
  if (isLoading) {
    return Container(
      // 1. Ubah padding dari .all(20) menjadi symmetric vertical agar lebih tipis
      padding: const EdgeInsets.symmetric(vertical: 16), 
      width: double.infinity, // Memastikan lebar penuh
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 2. Perkecil ukuran loading spinner dengan SizedBox
            SizedBox(
              width: 24, 
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3, // Garis spinner lebih tipis
              ),
            ),
            // 3. Perkecil jarak antara spinner dan teks
            SizedBox(height: 10), 
            Text(
              'Loading Access Point Data...',
              style: TextStyle(
                fontSize: 14, // Ukuran font sedikit diperkecil
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show empty state if no data
    if (towers.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.signal_wifi_off,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No Data Access Point',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'There Are No Registered Access Point For Container Yard 1 Yet',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
  }

    // Show data table when towers exist
    return Container(
        clipBehavior: Clip.antiAlias, 
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Access Point List',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                // Pagination Controls
                    Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      // Tombol Previous
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        onPressed: currentPage > 0 ? () => setState(() => currentPage--) : null,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 8),

                      // LIST ANGKA HALAMAN
                      // Kita generate angka berdasarkan totalPages
                      ...List.generate(totalPages, (index) {
                        bool isCurrentPage = index == currentPage;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              currentPage = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              // Beri warna background jika halaman sedang aktif
                              color: isCurrentPage ? const Color(0xFF1976D2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                // Beri warna teks putih jika aktif, biru jika tidak aktif
                                color: isCurrentPage ? Colors.white : const Color(0xFF1976D2),
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(width: 8),
                      // Tombol Next
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
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
            color: const Color(0xFFC6B430),
            child: Row(
              children: [
                _buildHeaderCell('Access Point ID', flex: 1),
                _buildHeaderCell('Lokasi', flex: 2),
                _buildHeaderCell('IP Address', flex: 2),
                _buildHeaderCell('Status', flex: 1),
                _buildHeaderCell('Action', flex: 1, isLast: true),
              ],
            ),
          ),

          // Table Rows
          ...paginatedData.map((tower) => _buildTableRow(tower)),
        ],
      ),
    );
  }

  Widget _buildTableRow(Tower tower) {
    bool isWarning = isDownStatus(tower.status);
    String statusLabel = isWarning ? 'DOWN' : tower.status;
    Color statusTextColor = isWarning ? Colors.red : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8D5C4),
        border: Border(
          left: BorderSide(color: Colors.grey[500]!, width: 1),
          right: BorderSide(color: Colors.grey[500]!, width: 1),
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          _tableCell(tower.towerId, flex: 1, fontWeight: FontWeight.w800),
          _tableCell(tower.location, flex: 2, fontWeight: FontWeight.w800),
          _tableCell(tower.ipAddress, flex: 2),
          _tableCell(
            statusLabel,
            flex: 1,
            fontWeight: FontWeight.w800,
            color: statusTextColor,
          ),

          // --- KOLOM AKSI KHUSUS CY 3 ---
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => _showEditForm(tower),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _confirmDelete(tower),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildHeaderCell(String label,
      {required int flex, bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: isLast
                ? BorderSide.none
                : BorderSide(color: Colors.white.withOpacity(0.35), width: 1),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _tableCell(String text,
      {required int flex,
      FontWeight fontWeight = FontWeight.w700,
      Color color = Colors.black,
      TextAlign align = TextAlign.center,
      bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: isLast
                ? BorderSide.none
                : BorderSide(color: Colors.grey[500]!, width: 0.8),
          ),
        ),
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            color: color,
            fontWeight: fontWeight,
            fontSize: 14,
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
  void _showEditForm(Tower tower) {
    final ipController = TextEditingController(text: tower.ipAddress);
    final locationController = TextEditingController(text: tower.location);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Tower CY3 - ${tower.towerId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: ipController,
                decoration: const InputDecoration(labelText: 'IP Address')),
            TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location')),
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
                'location': locationController.text,
              });

              if (response['success'] == true) {
                if (mounted) {
                  Navigator.pop(context);
                  _loadTowers(); // Refresh data khusus CY3
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
