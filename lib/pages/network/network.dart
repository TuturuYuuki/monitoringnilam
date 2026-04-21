import 'dart:async';
import 'package:flutter/material.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/services/device_storage_service.dart';
import 'dart:ui';
import 'package:monitoring/main.dart';
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
    // Check connection but _isConnected is currently not used in UI
    await apiService.testConnection();
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
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _triggerRealtimePing() async {
    try {
      final pingResult = await apiService.triggerRealtimePing();

      if (pingResult['success'] == true) {
      }
    } catch (e) {
      // ignore: empty_catches
    }
  }

  Future<void> _triggerPingCheck() async {
    await _triggerRealtimePing();
  }

  Future<void> _loadGlobalSummary({bool initialLoad = false}) async {
    if (_isGlobalSummaryRequestInFlight) {
      return;
    }

    _isGlobalSummaryRequestInFlight = true;
    try {
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
          onPressed: () {
            if (context.mounted) Navigator.of(context).pop();
          },
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

  Widget _buildPagination() {
    final int displayPages = totalPages > 0 ? totalPages : 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPaginationButton(
                label: 'Previous',
                onTap: currentPage > 0
                    ? () => setState(() => currentPage--)
                    : null,
                color: const Color(0xFFE53935),
                isFirst: true,
              ),

              ...List.generate(displayPages, (index) {
                if (displayPages > 7) {
                  if (index != 0 &&
                      index != displayPages - 1 &&
                      (index < currentPage - 1 || index > currentPage + 1)) {
                    if (index == 1 && currentPage > 3) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('...',
                            style: TextStyle(color: Colors.white70)),
                      );
                    }
                    if (index == displayPages - 2 &&
                        currentPage < displayPages - 4) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('...',
                            style: TextStyle(color: Colors.white70)),
                      );
                    }
                    if (index > 1 && index < displayPages - 2) {
                      return const SizedBox.shrink();
                    }
                  }
                }

                return _buildPaginationButton(
                  label: '${index + 1}',
                  onTap: (towers.isNotEmpty && currentPage != index)
                      ? () => setState(() => currentPage = index)
                      : null,
                  color: currentPage == index
                      ? const Color(0xFF1565C0)
                      : const Color(0xFF2196F3),
                  isSquare: true,
                );
              }),

              _buildPaginationButton(
                label: 'Next',
                onTap: currentPage < displayPages - 1 && towers.isNotEmpty
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

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      backgroundColor: AppDropdownStyle.standardPageBackground,
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/network'),
          Expanded(
            child: GlobalSidebarNav(
              currentRoute: '/network',
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
          ),
          const GlobalFooter(),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    final isMobile = isMobileScreen(context);
    return SizedBox(
      width: constraints.maxWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Section
          isMobile ? _buildMobileHeader() : _buildDesktopHeader(),
          const SizedBox(height: 24),
          if (isMobile) ...[
            _buildHeaderOverviewMini(isMobile: true),
            const SizedBox(height: 16),
          ],
          if (!isMobile)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total AP',
                        '$totalTowers',
                        Colors.blue,
                        compact: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'UP',
                        '$onlineTowers',
                        Colors.green,
                        compact: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'DOWN',
                        '$warningTowers',
                        Colors.red,
                        onTap: warningTowers > 0 ? _showWarningList : null,
                        compact: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAreaButton(constraints.maxWidth),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        title: 'AREA',
                        icon: Icons.map_rounded,
                        iconColor: Colors.blue,
                        content: Text(
                          selectedArea,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        title: 'ACTION',
                        icon: Icons.refresh_rounded,
                        iconColor: Colors.green,
                        onTap: () async {
                          setState(() => isLoading = true);
                          await _triggerPingCheck();
                          await _loadTowers();
                        },
                        content: const Text(
                          "CHECK STATUS",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total AP',
                        '$totalTowers',
                        Colors.blue,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        'UP',
                        '$onlineTowers',
                        Colors.green,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        'DOWN',
                        '$warningTowers',
                        Colors.red,
                        onTap: warningTowers > 0 ? _showWarningList : null,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAreaButton(constraints.maxWidth),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildCheckStatusButton(constraints.maxWidth),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionCard(
                        title: 'AREA',
                        icon: Icons.map_rounded,
                        iconColor: Colors.blue,
                        content: Text(
                          selectedArea,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 16),
          _buildTowerList(constraints),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildHeaderOverviewMini({required bool isMobile}) {
    final Widget content;

    if (_isLoadingGlobalSummary) {
      content = Text(
        'Loading overview...',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.2),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      final cards = [
        _buildGlobalStatCard('ALL', '$globalTotalDevices', Colors.orange,
            width: isMobile ? null : 86),
        _buildGlobalStatCard('UP', '$globalUpDevices', Colors.green,
            width: isMobile ? null : 86),
        _buildGlobalStatCard('DOWN', '$globalDownDevices', Colors.red,
            width: isMobile ? null : 86),
      ];

      content = isMobile
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
    }

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
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
                  boxShadow: [
                    BoxShadow(
                      color: indicatorColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
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
      {VoidCallback? onTap, double? width, bool compact = false}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
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
      ),
    );
  }

  Widget _buildAreaButton(double width) {
    return _buildActionCard(
      title: 'AREA',
      icon: Icons.location_on_rounded,
      iconColor: Colors.white,
      content: AnimatedDropdownButton(
        value: "Select Area",
        items: _areaOptions,
        backgroundColor: AppDropdownStyle.menuBackground,
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
    );
  }

  Widget _buildCheckStatusButton(double width) {
    if (MediaQuery.of(context).size.width >= 600) {
      return const SizedBox.shrink();
    }
    return _buildActionCard(
      title: 'ACTION',
      icon: Icons.refresh_rounded,
      iconColor: Colors.green,
      onTap: () async {
        setState(() => isLoading = true);
        await _triggerPingCheck();
        await _loadTowers();
      },
      content: Text(
        "CHECK STATUS",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: isMobileScreen(context) ? 13 : 15,
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
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      constraints: BoxConstraints(minHeight: isMobile ? 45 : 50),
      child: MouseRegion(
        cursor:
            onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 10 : 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
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
                      child: Icon(icon, color: Colors.white, size: isMobile ? 18 : 20),
                    ),
                    SizedBox(width: isMobile ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: isMobile ? 10 : 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          content,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTowerList(BoxConstraints constraints) {
    if (isLoading) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
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
                    'Loading Access Point data...',
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

    if (towers.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
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
                    Icons.router_outlined,
                    size: 64,
                    color: Colors.white38,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No AP data available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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

    final isMobile = isMobileScreen(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
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
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1976D2).withValues(alpha: 0.8),
                      const Color(0xFF1976D2).withValues(alpha: 0.4),
                    ],
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Access Point List',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Builder(builder: (context) {
                const double minTableWidth = 500;
                final tableContent = Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1976D2).withValues(alpha: 0.8),
                            const Color(0xFF1976D2).withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildHeaderCell('AP ID', flex: 2),
                          _buildHeaderCell('IP Address', flex: 3),
                          _buildHeaderCell('Status', flex: 2, isLast: true),
                        ],
                      ),
                    ),
                    ...paginatedData.map((tower) => _buildTowerTableRow(tower)),
                  ],
                );
                if (isMobile) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(width: minTableWidth, child: tableContent),
                  );
                }
                return tableContent;
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String label,
      {required int flex, bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTowerTableRow(Tower tower) {
    final bool isDown = isDownStatus(tower.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildTableCell(tower.towerId,
              flex: 2, fontWeight: FontWeight.w800, color: Colors.white),
          _buildTableCell(tower.ipAddress,
              flex: 3, color: Colors.white.withValues(alpha: 0.7)),
          _buildTableCell(
            isDown ? 'DOWN' : 'UP',
            flex: 2,
            color: isDown ? Colors.redAccent : Colors.greenAccent,
            fontWeight: FontWeight.w800,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text,
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
                : BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.8),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: fontWeight,
            fontSize: 14,
          ),
          textAlign: align,
        ),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 10,
                  )
                ],
              ),
              child: const Icon(
                Icons.router_rounded,
                size: 30,
                color: Color(0xFF1976D2),
              ),
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
        const SizedBox(height: 8),
        const Text(
          'Monitoring View of Access Point',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        if (_lastRefreshTime != null)
          Row(
            children: [
              const Text('•', style: TextStyle(color: Colors.greenAccent)),
              const SizedBox(width: 6),
              Text(
                'Updated: ${_lastRefreshTime!.hour.toString().padLeft(2, '0')}:${_lastRefreshTime!.minute.toString().padLeft(2, '0')}:${_lastRefreshTime!.second.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.router_rounded,
            size: 32,
            color: Colors.white,
          ),
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
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text(
                  'Monitoring View of Access Point',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                if (_lastRefreshTime != null) ...[
                  const SizedBox(width: 12),
                  const Text('•', style: TextStyle(color: Colors.greenAccent)),
                  const SizedBox(width: 6),
                  Text(
                    'Updated: ${_lastRefreshTime!.hour.toString().padLeft(2, '0')}:${_lastRefreshTime!.minute.toString().padLeft(2, '0')}:${_lastRefreshTime!.second.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const Spacer(),
        _buildHeaderOverviewMini(isMobile: false),
      ],
    );
  }
}
