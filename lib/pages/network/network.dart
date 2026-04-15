import 'dart:async';
import 'package:flutter/material.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/services/device_storage_service.dart';
import 'dart:ui';
import 'package:monitoring/main.dart';
import 'package:monitoring/utils/ui_utils.dart';
import 'package:monitoring/utils/tower_status_override.dart';
import 'package:monitoring/utils/location_label_utils.dart';
import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';
import 'package:monitoring/widgets/global_footer.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';

// Network Page
class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  String selectedArea = 'CY 1';
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
  bool _isConnected = true;
  int globalTotalDevices = 0;
  int globalUpDevices = 0;
  int globalDownDevices = 0;
  bool _isLoadingGlobalSummary = true;
  bool _isGlobalSummaryRequestInFlight = false;

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _checkConnection();
    _loadTowers();
    _loadGlobalSummary(initialLoad: true);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    final result = await apiService.testConnection();
    if (mounted) {
      setState(() {
        _isConnected = result['success'] == true;
      });
    }
  }

  String _selectedAreaId() {
    final normalized = selectedArea.toUpperCase().replaceAll(' ', '');
    if (normalized == 'CY1') return 'CY1';
    if (normalized == 'CY2') return 'CY2';
    if (normalized == 'CY3') return 'CY3';
    if (normalized == 'GATE') return 'GATE';
    if (normalized == 'PARKING') return 'PARKING';
    return 'CY1';
  }

  Future<void> _loadTowers() async {
    try {
      final fetchedTowers =
          await apiService.getValidatedTowersByYard(_selectedAreaId());

      if (mounted) {
        setState(() {
          towers = fetchedTowers;
          isLoading = false;
          _lastRefreshTime = DateTime.now();
        });
      }

      _triggerRealtimePing();
    } catch (e) {
      print('Error Loading Towers: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _triggerRealtimePing() async {
    try {
      print('=== Starting Realtime Ping For All Towers ===');

      // Trigger backend realtime ping untuk semua devices
      final pingResult = await apiService.triggerRealtimePing();

      if (pingResult['success'] == true) {
        print('Realtime Ping Completed: ${pingResult['message']}');
        print('IP Checked: ${pingResult['ips_checked']}');
      }

      print('=== Realtime Ping Completed ===');
    } catch (e) {
      print('Error Triggering Realtime Ping: $e');
    }
  }

  Future<void> _triggerPingCheck() async {
    // This method is used by the refresh button manually
    await _triggerRealtimePing();
  }

  Future<void> _loadGlobalSummary({bool initialLoad = false}) async {
    if (_isGlobalSummaryRequestInFlight) {
      return;
    }

    _isGlobalSummaryRequestInFlight = true;
    try {
      // Show loading only on first load to avoid flicker on periodic refresh.
      if (mounted && initialLoad) {
        setState(() {
          _isLoadingGlobalSummary = true;
        });
      }

      final allTowers = await apiService.getAllTowers();
      final allCameras = await apiService.getAllCameras();
      final allMMTs = await apiService.getAllMMTs();

      final towerUp = allTowers.where((t) => !isDownStatus(t.status)).length;
      final cameraUp = allCameras.where((c) => c.status == 'UP').length;
      final mmtUp = allMMTs.where((m) => m.status == 'UP').length;

      final total = allTowers.length + allCameras.length + allMMTs.length;
      final up = towerUp + cameraUp + mmtUp;
      final down = (total - up).clamp(0, 999999);

      if (mounted) {
        setState(() {
          globalTotalDevices = total;
          globalUpDevices = up;
          globalDownDevices = down;
          _isLoadingGlobalSummary = false;
        });
      }
    } catch (e) {
      print('Error loading network overview: $e');
      if (mounted) {
        setState(() {
          _isLoadingGlobalSummary = false;
        });
      }
    } finally {
      _isGlobalSummaryRequestInFlight = false;
    }
  }

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
                    'All Towers Are In UP Condition',
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
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
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

  List<Tower> get paginatedData {
    int start = currentPage * itemsPerPage;
    int end = (start + itemsPerPage > towers.length)
        ? towers.length
        : start + itemsPerPage;
    return towers.sublist(start, end);
  }

  int get totalPages => (towers.length / itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Stack(
        children: [
          Column(
            children: [
              const GlobalHeaderBar(currentRoute: '/network'),
              Expanded(
                child: GlobalSidebarNav(
                    currentRoute: '/network',
                    child: SingleChildScrollView(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Padding(
                            padding: EdgeInsets.all(isMobile ? 8 : 20.0),
                            child: _buildContent(context, constraints),
                          );
                        },
                      ),
                    )),
              ),
              const GlobalFooter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    final isMobile = isMobileScreen(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Section
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.language,
                        size: 20, color: Color(0xFF1976D2)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Access Point Monitoring',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Live camera feeds and surveillance status per area',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_lastRefreshTime != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Updated: ${_lastRefreshTime!.hour.toString().padLeft(2, '0')}:${_lastRefreshTime!.minute.toString().padLeft(2, '0')}:${_lastRefreshTime!.second.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
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
                child:
                    const Icon(Icons.language, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
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
                          const Text('•',
                              style: TextStyle(color: Colors.white70)),
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
              ),
              const SizedBox(width: 12),
              _buildHeaderOverviewMini(isMobile: false),
            ],
          ),
        const SizedBox(height: 16),

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
                      Row(
                        children: [
                          Expanded(
                            child: _buildGlobalStatCard(
                              'TOTAL',
                              '$totalTowers',
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildGlobalStatCard(
                              'UP',
                              '$onlineTowers',
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: _showWarningList,
                              child: _buildGlobalStatCard(
                                'DOWN',
                                '$warningTowers',
                                Colors.red,
                              ),
                            ),
                          ),
                        ],
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
        _buildTowerList(constraints),
      ],
    );
  }

  Widget _buildHeaderOverviewMini({required bool isMobile}) {
    if (_isLoadingGlobalSummary) {
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
            const Text(
              'Overview Data',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Loading overview...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final cards = [
      _buildGlobalStatCard('ALL', '$globalTotalDevices', Colors.orange,
          width: isMobile ? null : 86),
      _buildGlobalStatCard('UP', '$globalUpDevices', Colors.green,
          width: isMobile ? null : 86),
      _buildGlobalStatCard('DOWN', '$globalDownDevices', Colors.red,
          width: isMobile ? null : 86),
    ];

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview Data',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 8),
                Expanded(child: cards[1]),
                const SizedBox(width: 8),
                Expanded(child: cards[2]),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview Data',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              cards[0],
              const SizedBox(width: 8),
              cards[1],
              const SizedBox(width: 8),
              cards[2],
            ],
          ),
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
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
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
                  color: Colors.white.withOpacity(0.85),
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
      {VoidCallback? onTap, double? width}) {
    final isMobile = isMobileScreen(context);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: width,
            padding: EdgeInsets.all(isMobile ? 14 : 20),
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
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 32,
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
                        items: _areaOptions.map((String value) {
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
                            Navigator.pushReplacementNamed(context, '/network');
                          } else if (newValue == 'CY 2') {
                            Navigator.pushReplacementNamed(
                                context, '/network-cy2');
                          } else if (newValue == 'CY 3') {
                            Navigator.pushReplacementNamed(
                                context, '/network-cy3');
                          } else if (newValue == 'GATE') {
                            Navigator.pushReplacementNamed(
                                context, '/network-gate');
                          } else if (newValue == 'PARKING') {
                            Navigator.pushReplacementNamed(
                                context, '/network-parking');
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
              content: Text('Memeriksa status...'),
              duration: Duration(seconds: 2),
            ),
          );
          await _triggerPingCheck();
          await _loadTowers();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Status berhasil diperbarui!'),
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
                          'AKSI',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'CEK STATUS',
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

  Widget _buildTowerList(BoxConstraints constraints) {
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

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
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
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left_rounded,
                                      size: 20, color: Colors.white),
                                  onPressed: currentPage > 0
                                      ? () => setState(() => currentPage--)
                                      : null,
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                                const SizedBox(width: 4),
                                ...List.generate(totalPages, (index) {
                                  bool isCurrentPage = index == currentPage;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        currentPage = index;
                                      });
                                    },
                                    child: Container(
                                      margin:
                                          const EdgeInsets.symmetric(horizontal: 2),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isCurrentPage
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                          color: isCurrentPage
                                              ? const Color(0xFF1976D2)
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right_rounded,
                                      size: 20, color: Colors.white),
                                  onPressed: currentPage < totalPages - 1
                                      ? () => setState(() => currentPage++)
                                      : null,
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildTableContent(constraints),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableContent(BoxConstraints constraints) {
    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: isMobileScreen(context) ? 750 : constraints.maxWidth,
          ),
          child: Column(
            children: [
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
                    _buildHeaderCell('Aksi', flex: 1, isLast: true),
                  ],
                ),
              ),
              ...paginatedData.map((tower) => _buildTableRow(tower)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(Tower tower) {
    bool isWarning = isDownStatus(tower.status);
    String statusLabel = isWarning ? 'DOWN' : tower.status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
      child: Row(
        children: [
          _tableCell(tower.towerId,
              flex: 1, fontWeight: FontWeight.w800, color: Colors.white),
          _tableCell(tower.location,
              flex: 2,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.9)),
          _tableCell(tower.ipAddress,
              flex: 2, color: Colors.white.withOpacity(0.7)),
          _tableCell(
            statusLabel,
            flex: 1,
            fontWeight: FontWeight.w800,
            color: isWarning ? Colors.redAccent : Colors.greenAccent,
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit,
                      color: Colors.blueAccent, size: 20),
                  onPressed: () => _showEditForm(tower),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete,
                      color: Colors.redAccent, size: 20),
                  onPressed: () => _confirmDelete(tower),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label,
      {required int flex, bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        decoration: const BoxDecoration(
            // HAPUS DECORATION BORDER DI SINI agar tidak ada garis putih vertikal
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
                : BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
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
                initialValue: selectedLocation,
                isExpanded: true,
                dropdownColor: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: AppDropdownStyle.menuBorderRadius,
                decoration: const InputDecoration(labelText: 'Location'),
                items: locationOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option['label'],
                        child: Text(option['label'] ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final option = locationOptions.firstWhere(
                    (item) => item['label'] == value,
                    orElse: () => locationOptions.first,
                  );
                  setLocalState(() {
                    selectedLocation = value;
                    selectedYard =
                        option['container_yard'] ?? tower.containerYard;
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
                  // Sync local storage after backend success
                  await DeviceStorageService.updateDeviceFields(
                    type: 'Tower',
                    name: tower.towerId,
                    updates: {
                      'ipAddress': ipController.text,
                      'locationName': selectedLocation,
                      'containerYard': selectedYard,
                    },
                  );
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadTowers();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Data berhasil diperbarui'),
                      backgroundColor: Colors.green));
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
        title: const Text('Konfirmasi hapus'),
        content: Text('Hapus ${tower.towerId}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final response = await apiService.deleteTower(tower.id);
              if (response['success'] == true) {
                if (!mounted) return;
                Navigator.pop(context); // Tutup dialog
                _loadTowers(); // REFRESH DATA DARI DATABASE
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Data berhasil dihapus'),
                    backgroundColor: Colors.red));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _isConnected
            ? Colors.greenAccent.withValues(alpha: 0.1)
            : Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isConnected
              ? Colors.greenAccent.withValues(alpha: 0.3)
              : Colors.redAccent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isConnected ? Colors.greenAccent : Colors.redAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isConnected ? 'BACKEND CONNECTED' : 'CONNECTION LOST',
            style: TextStyle(
              color: _isConnected ? Colors.greenAccent : Colors.redAccent,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
