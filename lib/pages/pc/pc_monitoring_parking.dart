import 'dart:async';
import 'package:flutter/material.dart';
import 'package:monitoring/models/pc_model.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/utils/location_label_utils.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';
import 'dart:ui';
import 'package:monitoring/main.dart';
import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';
import 'package:monitoring/widgets/global_footer.dart';
import 'package:monitoring/utils/device_icon_resolver.dart';

class PCMonitoringParkingPage extends StatefulWidget {
  const PCMonitoringParkingPage({super.key});

  @override
  State<PCMonitoringParkingPage> createState() => _PCMonitoringParkingPageState();
}

class _PCMonitoringParkingPageState extends State<PCMonitoringParkingPage> {
  String selectedArea = 'PARKING';
  static const List<String> _areaOptions = ['CY 1', 'CY 2', 'CY 3', 'GATE', 'PARKING'];
  int currentPage = 0;
  final int itemsPerPage = 5;
  late ApiService apiService;
  List<PCModel> pcList = [];
  bool isLoading = true;
  Timer? _refreshTimer;
  DateTime? _lastRefreshTime;
  int globalTotalDevices = 0;
  int globalUpDevices = 0;
  int globalDownDevices = 0;
  bool _isLoadingGlobalSummary = true;
  bool _isGlobalSummaryRequestInFlight = false;
  List<Map<String, String>> _masterOptions = [];

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _loadMasterLocations();
    _refreshData(initial: true);
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _loadMasterLocations();
        _refreshData();
      }
    });
  }

  Future<void> _refreshData({bool initial = false}) async {
    if (initial && mounted) {
      setState(() => isLoading = true);
    }
    await Future.wait([
      _loadPCs(),
      _loadGlobalSummary(),
    ]);
    if (initial && mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _selectedAreaId() {
    return 'PARKING';
  }

  Future<void> _loadPCs() async {
    try {
      final fetched = await apiService.getPCsByYard(_selectedAreaId());
      if (mounted) {
        setState(() {
          pcList = fetched;
          _lastRefreshTime = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('Error loading PCs: $e');
    }
  }

  Future<void> _loadMasterLocations() async {
    try {
      final locs = await apiService.getAllMasterLocations();
      if (mounted) {
        setState(() {
          _masterOptions = buildMasterLocationOptions(locs);
        });
      }
    } catch (_) {}
  }

  Future<void> _handleCheckStatus() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking status...'), duration: Duration(seconds: 2)),
    );
    await apiService.triggerRealtimePing();
    if (mounted) {
      await _loadPCs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Status successfully updated!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadGlobalSummary({bool initialLoad = false}) async {
    if (_isGlobalSummaryRequestInFlight) return;
    _isGlobalSummaryRequestInFlight = true;
    try {
      if (mounted && initialLoad) {
        setState(() => _isLoadingGlobalSummary = true);
      }
      final allPCs = await apiService.getAllPCs();
      final upCount = allPCs.where((n) => n.status.trim().toUpperCase() == 'UP').length;
      final total = allPCs.length;
      final downCount = (total - upCount).clamp(0, 999999);

      if (mounted) {
        setState(() {
          globalTotalDevices = total;
          globalUpDevices = upCount;
          globalDownDevices = downCount;
          _isLoadingGlobalSummary = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingGlobalSummary = false);
    } finally {
      _isGlobalSummaryRequestInFlight = false;
    }
  }

  int get totalPCs => pcList.length;
  int get onlinePCs => pcList.where((n) => n.status.trim().toUpperCase() == 'UP').length;
  int get downPCs => pcList.where((n) => n.status.trim().toUpperCase() != 'UP').length;

  List<PCModel> get paginatedData {
    int start = currentPage * itemsPerPage;
    int end = (start + itemsPerPage > pcList.length) ? pcList.length : start + itemsPerPage;
    if (start >= pcList.length) return [];
    return pcList.sublist(start, end);
  }

  int get totalPages => (pcList.length / itemsPerPage).ceil();

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
                onTap: currentPage > 0 ? () => setState(() => currentPage--) : null,
                color: Colors.red.withValues(alpha: 0.3),
                isFirst: true,
              ),
              ...List.generate(displayPages, (index) {
                return _buildPaginationButton(
                  label: '${index + 1}',
                  onTap: () => setState(() => currentPage = index),
                  color: currentPage == index ? const Color(0xFF1A3B5D) : Colors.blue,
                  isSquare: true,
                );
              }),
              _buildPaginationButton(
                label: 'Next',
                onTap: currentPage < displayPages - 1 ? () => setState(() => currentPage++) : null,
                color: Colors.red,
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
          padding: EdgeInsets.symmetric(horizontal: isSquare ? 12 : 16, vertical: 8),
          decoration: BoxDecoration(
            color: onTap == null ? color.withValues(alpha: 0.3) : color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              if (onTap != null)
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2),
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
    return Scaffold(
      backgroundColor: AppDropdownStyle.standardPageBackground,
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/pc-monitoring-parking'),
          Expanded(
            child: GlobalSidebarNav(
              currentRoute: '/pc-monitoring-parking',
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) => _buildContent(context, constraints),
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
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isMobile ? _buildMobileHeader() : _buildDesktopHeader(),
            const SizedBox(height: 24),
            if (isMobile) ...[
              _buildHeaderOverviewMini(isMobile: true),
              const SizedBox(height: 16),
            ],
            if (!isMobile)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _buildStatCard('Total PC', '$totalPCs', Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: _buildStatCard('UP', '$onlinePCs', Colors.green)),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: _buildStatCard('DOWN', '$downPCs', Colors.red)),
                ],
              )
            else
              Column(
                children: [
                  _buildStatCard('Total PC', '$totalPCs', Colors.blue),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('UP', '$onlinePCs', Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('DOWN', '$downPCs', Colors.red)),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 16),
            if (!isMobile)
              Row(
                children: [
                  Expanded(child: _buildAreaButton()),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      title: 'AREA',
                      icon: Icons.location_on,
                      iconColor: Colors.blue,
                      showArrow: false,
                      content: Text(
                        selectedArea,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCheckStatusButton()),
                ],
              )
            else
              Column(
                children: [
                  _buildAreaButton(),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    title: 'AREA',
                    icon: Icons.location_on,
                    iconColor: Colors.blue,
                    showArrow: false,
                    content: Text(
                      selectedArea,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCheckStatusButton(),
                ],
              ),
            const SizedBox(height: 24),
            _buildPCList(constraints),
            _buildPagination(),
          ],
        ),
      ),
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
          child: Icon(DeviceIconResolver.iconForType('PC'), size: 32, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PC Monitoring',
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
                  'Monitoring View of PC',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
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
      ],
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
                color: const Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(DeviceIconResolver.iconForType('PC'), size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'PC Monitoring',
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
        Row(
          children: [
            const Text(
              'Monitoring View of PC',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            if (_lastRefreshTime != null) ...[
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
              const SizedBox(width: 4),
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
        child: Text(
          'Loading overview...',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 10),
        ),
      );
    }

    final cards = [
      _buildGlobalStatCard('ALL', '$globalTotalDevices', Colors.orange, width: isMobile ? null : 86),
      _buildGlobalStatCard('UP', '$globalUpDevices', Colors.green, width: isMobile ? null : 86),
      _buildGlobalStatCard('DOWN', '$globalDownDevices', Colors.red, width: isMobile ? null : 86),
    ];

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
          isMobile
              ? Row(children: [Expanded(child: cards[0]), const SizedBox(width: 8), Expanded(child: cards[1]), const SizedBox(width: 8), Expanded(child: cards[2])])
              : Row(mainAxisSize: MainAxisSize.min, children: [cards[0], const SizedBox(width: 8), cards[1], const SizedBox(width: 8), cards[2]]),
        ],
      ),
    );
  }

  Widget _buildGlobalStatCard(String title, String value, Color indicatorColor, {double? width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600)),
              Container(width: 6, height: 6, decoration: BoxDecoration(color: indicatorColor, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color indicatorColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w700))),
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: indicatorColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: indicatorColor.withValues(alpha: 0.45), blurRadius: 8, spreadRadius: 1)])),
                ],
              ),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Container(height: 2.5, width: 42, decoration: BoxDecoration(gradient: LinearGradient(colors: [indicatorColor, indicatorColor.withValues(alpha: 0)]), borderRadius: BorderRadius.circular(2))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAreaButton() {
    return _buildActionCard(
      title: 'AREA',
      icon: Icons.map_rounded,
      iconColor: Colors.orange,
      showArrow: false,
      content: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedArea,
          isExpanded: true,
          isDense: true,
          dropdownColor: const Color(0xFF1B2631),
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          items: _areaOptions.map((area) => DropdownMenuItem(value: area, child: Text(area))).toList(),
          onChanged: (String? v) {
            if (v == null || v == selectedArea) return;
            final routeMap = {
              'CY 1': '/pc-monitoring-cy1',
              'CY 2': '/pc-monitoring-cy2',
              'CY 3': '/pc-monitoring-cy3',
              'GATE': '/pc-monitoring-gate',
              'PARKING': '/pc-monitoring-parking',
            };
            Navigator.pushReplacementNamed(context, routeMap[v]!);
          },
        ),
      ),
    );
  }

  Widget _buildCheckStatusButton() {
    return _buildActionCard(
      title: 'ACTION',
      icon: Icons.refresh_rounded,
      iconColor: Colors.green,
      content: const Text(
        'CHECK STATUS',
        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      onTap: _handleCheckStatus,
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget content,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0.05)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        content,
                      ],
                    ),
                  ),
                  if (onTap == null && showArrow) Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPCList(BoxConstraints constraints) {
    final isMobile = isMobileScreen(context);
    
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
                    'Loading PC data...',
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

    if (pcList.isEmpty) {
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
                    Icons.desktop_windows,
                    size: 64,
                    color: Colors.white38,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No PC data available',
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

    return Column(
      children: [
        // Blue Header Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF1E5BB4),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: const Text(
            'PC List',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Table Container
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.white.withValues(alpha: 0.16),
                  Colors.white.withValues(alpha: 0.05)
                ]),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18), width: 1.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  if (!isMobile)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B8B3E),
                        border: Border(
                            bottom: BorderSide(color: Colors.white24, width: 1)),
                      ),
                      child: Row(
                        children: [
                          _buildHeaderCell('PC ID', flex: 2),
                          _buildHeaderCell('Location', flex: 3),
                          _buildHeaderCell('IP Address', flex: 2),
                          _buildHeaderCell('Status', flex: 1),
                          _buildHeaderCell('Action', flex: 2, isLast: true),
                        ],
                      ),
                    ),
                  ...paginatedData.map((pc) => _buildPCTableRow(pc)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String label, {required int flex, bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(right: BorderSide(color: Colors.white24, width: 1))),
        child: Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    );
  }

  Widget _buildPCTableRow(PCModel pc) {
    final bool isUp = pc.status.trim().toUpperCase() == 'UP';
    final isMobile = isMobileScreen(context);
    
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isUp ? Colors.green : Colors.red).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.desktop_windows, color: isUp ? Colors.green : Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pc.pcId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(pc.location, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                ],
              ),
            ),
            _buildStatusBadge(isUp),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
              onPressed: () => _showEditPCForm(pc),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
              onPressed: () => _confirmDeletePC(pc),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: const Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Row(
        children: [
          _buildTableCell(pc.pcId, flex: 2, fontWeight: FontWeight.w800),
          _buildTableCell(
            resolveFullLocationLabel(
              _masterOptions,
              pc.location,
              currentContainerYard: pc.containerYard,
            ),
            flex: 3,
          ),
          _buildTableCell(pc.ipAddress, flex: 2),
          _buildTableCell(isUp ? 'UP' : 'DOWN',
              flex: 1,
              color: isUp ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.w800),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                  onPressed: () => _showEditPCForm(pc),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _confirmDeletePC(pc),
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

  Widget _buildTableCell(String text,
      {required int flex,
      FontWeight fontWeight = FontWeight.w700,
      Color? color,
      TextAlign align = TextAlign.center,
      bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(right: BorderSide(color: Colors.white10, width: 1))),
        child: Text(text,
            style: TextStyle(
                color: color ?? Colors.white.withValues(alpha: 0.9),
                fontWeight: fontWeight,
                fontSize: 14),
            textAlign: align),
      ),
    );
  }

  Widget _buildStatusBadge(bool isUp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isUp ? Colors.green : Colors.red).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: (isUp ? Colors.green : Colors.red).withValues(alpha: 0.3)),
      ),
      child: Text(
        isUp ? 'UP' : 'DOWN',
        style: TextStyle(color: isUp ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _showEditPCForm(PCModel pc) async {
    final ipController = TextEditingController(text: pc.ipAddress);
    final nameController = TextEditingController(text: pc.pcId);
    
    var locationOptions = buildMasterLocationOptions(_masterOptions);
    if (locationOptions.isEmpty) {
      locationOptions = [
        {
          'label': normalizeLocationLabel(pc.location),
          'container_yard': pc.containerYard,
          'location_type': 'PC',
          'location_code': pc.pcId,
          'location_name': pc.location,
        }
      ];
    }

    final matchedOption = matchMasterLocationOption(
      locationOptions,
      pc.location,
      currentContainerYard: pc.containerYard,
    );
    
    var selectedLocation = matchedOption?['label'] ?? normalizeLocationLabel(pc.location);
    var selectedArea = matchedOption?['container_yard'] ?? pc.containerYard;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit ${pc.pcId}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 22)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEditTextField(nameController, 'Name'),
                const SizedBox(height: 20),
                _buildEditTextField(ipController, 'IP Address'),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: selectedLocation,
                  isExpanded: true,
                  isDense: true,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    labelStyle: TextStyle(color: Colors.black54, fontSize: 12),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E88E5))),
                  ),
                  items: locationOptions.map((opt) => DropdownMenuItem(
                    value: opt['label'],
                    child: Text(opt['label'] ?? '', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    final opt = locationOptions.firstWhere((i) => i['label'] == val);
                    setLocalState(() {
                      selectedLocation = val;
                      selectedArea = opt['container_yard'] ?? selectedArea;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
              ),
              onPressed: () async {
                final result = await apiService.updatePC(pc.id!, {
                  'pc_id': nameController.text,
                  'ip_address': ipController.text,
                  'location': selectedLocation,
                  'container_yard': selectedArea,
                });

                if (result['success'] == true && mounted) {
                  Navigator.pop(context);
                  _refreshData(initial: true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PC updated successfully'), backgroundColor: Colors.green),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Update failed: ${result['message']}'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEditTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E88E5))),
      ),
    );
  }

  void _confirmDeletePC(PCModel pc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2631),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete PC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete PC ${pc.pcId}?', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: TextStyle(color: Colors.white.withValues(alpha: 0.54)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              final result = await apiService.deletePC(pc.id!);
              if (!mounted) return;
              if (result['success'] == true) {
                Navigator.pop(context);
                _refreshData(initial: true);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PC deleted successfully'), backgroundColor: Colors.red));
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
