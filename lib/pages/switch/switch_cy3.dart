import 'dart:async';
import 'package:flutter/material.dart';
import 'package:monitoring/models/switch_model.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/utils/location_label_utils.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';
import 'dart:ui';
import 'package:monitoring/main.dart';
import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';
import 'package:monitoring/widgets/global_footer.dart';

class SwitchPageCY3 extends StatefulWidget {
  const SwitchPageCY3({super.key});

  @override
  State<SwitchPageCY3> createState() => _SwitchPageCY3State();
}

class _SwitchPageCY3State extends State<SwitchPageCY3> {
  String selectedArea = 'CY 3';
  static const List<String> _areaOptions = ['CY 1', 'CY 2', 'CY 3', 'GATE', 'PARKING'];
  int currentPage = 0;
  final int itemsPerPage = 5;
  late ApiService apiService;
  List<SwitchModel> switchList = [];
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
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
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
      _loadSwitches(),
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
    final normalized = selectedArea.toUpperCase().replaceAll(' ', '');
    if (normalized == 'CY3') return 'CY3';
    if (normalized == 'CY2') return 'CY2';
    if (normalized == 'CY3') return 'CY3';
    if (normalized == 'GATE') return 'GATE';
    if (normalized == 'PARKING') return 'PARKING';
    return 'CY3';
  }

  Future<void> _loadSwitches() async {
    try {
      final fetched = await apiService.getValidatedSwitchesByYard(_selectedAreaId());
      if (mounted) {
        setState(() {
          switchList = fetched;
          _lastRefreshTime = DateTime.now();
        });
      }
      _triggerRealtimePing();
    } catch (e) {
      // error handling
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

  Future<void> _triggerRealtimePing() async {
    try {
      await apiService.triggerRealtimePing();
    } catch (e) {
      // ignore
    }
  }

  Future<void> _handleCheckStatus() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking status...'), duration: Duration(seconds: 2)),
    );
    await apiService.triggerRealtimePing();
    if (mounted) {
      await _loadSwitches();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('âœ“ Status successfully updated!'),
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
      final allNVRs = await apiService.getAllSwitches();
      final upCount = allNVRs.where((n) => n.status == 'UP').length;
      final total = allNVRs.length;
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

  int get totalSwitches => switchList.length;
  int get onlineSwitches => switchList.where((n) => n.status == 'UP').length;
  int get downSwitches => switchList.where((n) => n.status == 'DOWN').length;

  List<SwitchModel> get paginatedData {
    int start = currentPage * itemsPerPage;
    int end = (start + itemsPerPage > switchList.length) ? switchList.length : start + itemsPerPage;
    return switchList.sublist(start, end);
  }

  int get totalPages => (switchList.length / itemsPerPage).ceil();

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
          const GlobalHeaderBar(currentRoute: '/switch-monitoring-cy3'),
          Expanded(
            child: GlobalSidebarNav(
              currentRoute: '/switch-monitoring-cy3',
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
                  Expanded(flex: 1, child: _buildStatCard('Total Switch', '$totalSwitches', Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: _buildStatCard('UP', '$onlineSwitches', Colors.green)),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: _buildStatCard('DOWN', '$downSwitches', Colors.red)),
                ],
              )
            else
              Column(
                children: [
                  _buildStatCard('Total Switch', '$totalSwitches', Colors.blue),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('UP', '$onlineSwitches', Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('DOWN', '$downSwitches', Colors.red)),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 16),
            if (!isMobile)
              Row(
                children: [
                  Expanded(child: _buildAreaButton(0)),
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
                  Expanded(child: _buildCheckStatusButton(0)),
                ],
              )
            else
              Column(
                children: [
                  _buildAreaButton(0),
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
                  _buildCheckStatusButton(0),
                ],
              ),
            const SizedBox(height: 24),
            _buildSwitchList(constraints),
            _buildPagination(),
          ],
        ),
      ),
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

  Widget _buildAreaButton(double width) {
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
          items: const [
            DropdownMenuItem(value: 'CY 1', child: Text('CY 1')),
            DropdownMenuItem(value: 'CY 2', child: Text('CY 2')),
            DropdownMenuItem(value: 'CY 3', child: Text('CY 3')),
            DropdownMenuItem(value: 'GATE', child: Text('GATE')),
            DropdownMenuItem(value: 'PARKING', child: Text('PARKING')),
          ],
          onChanged: (String? v) {
            if (v == null) return;
            final routeMap = {
              'CY 1': '/switch-monitoring-cy1',
              'CY 2': '/switch-monitoring-cy2',
              'CY 3': '/switch-monitoring-cy3',
              'GATE': '/switch-monitoring-gate',
              'PARKING': '/switch-monitoring-parking',
            };
            Navigator.pushReplacementNamed(context, routeMap[v]!);
          },
        ),
      ),
    );
  }

  Widget _buildCheckStatusButton(double width) {
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

  Widget _buildSwitchList(BoxConstraints constraints) {
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
                    'Loading Switch data...',
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

    if (switchList.isEmpty) {
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
                    Icons.device_hub,
                    size: 64,
                    color: Colors.white38,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No Switch data available',
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
            'Switch List',
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
                  if (!isMobileScreen(context))
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B8B3E),
                        border: Border(
                            bottom: BorderSide(color: Colors.white24, width: 1)),
                      ),
                      child: Row(
                        children: [
                          _buildHeaderCell('SWITCH ID', flex: 2),
                          _buildHeaderCell('Location', flex: 3),
                          _buildHeaderCell('IP Address', flex: 2),
                          _buildHeaderCell('Status', flex: 1),
                          _buildHeaderCell('Action', flex: 2, isLast: true),
                        ],
                      ),
                    ),
                  ...paginatedData.map((nvr) => _buildSwitchTableRow(nvr)),
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

  Widget _buildSwitchTableRow(SwitchModel sw) {
    final bool isDown = sw.status != 'UP';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: const Border(
            bottom: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Row(
        children: [
          _buildTableCell(sw.switchId, flex: 2, fontWeight: FontWeight.w800),
          _buildTableCell(
            resolveFullLocationLabel(
              _masterOptions,
              sw.location,
              currentContainerYard: sw.containerYard,
            ),
            flex: 3,
          ),
          _buildTableCell(sw.ipAddress, flex: 2),
          _buildTableCell(isDown ? 'DOWN' : sw.status,
              flex: 1,
              color: isDown ? Colors.redAccent : Colors.greenAccent,
              fontWeight: FontWeight.w800),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => _editSwitch(sw),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _confirmDeleteSwitch(sw),
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
                : const Border(
                    right: BorderSide(color: Colors.white10, width: 1))),
        child: Text(text,
            style: TextStyle(
                color: color ?? Colors.white.withValues(alpha: 0.9),
                fontWeight: fontWeight,
                fontSize: 14),
            textAlign: align),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF1976D2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.settings_ethernet, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text('Switch Monitoring', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)), Text('Location: CY 3', style: TextStyle(color: Colors.white70, fontSize: 13))],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Monitoring View of Switch', style: TextStyle(color: Colors.white70, fontSize: 13)),
        if (_lastRefreshTime != null)
          Row(
            children: [
              const Text('•', style: TextStyle(color: Colors.greenAccent)),
              const SizedBox(width: 6),
              Text('Updated: ${_lastRefreshTime!.hour.toString().padLeft(2, '0')}:${_lastRefreshTime!.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
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
          decoration: BoxDecoration(color: const Color(0xFF1976D2), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.settings_ethernet, size: 32, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Switch Monitoring', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('Monitoring View of Switch', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(width: 20),
                if (_lastRefreshTime != null)
                  Row(
                    children: [
                      const Text('•', style: TextStyle(color: Colors.greenAccent)),
                      const SizedBox(width: 6),
                      Text('Updated: ${_lastRefreshTime!.hour.toString().padLeft(2, '0')}:${_lastRefreshTime!.minute.toString().padLeft(2, '0')}:${_lastRefreshTime!.second.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                    ],
                  ),
              ],
            ),
          ],
        ),
        const Spacer(),
        _buildHeaderOverviewMini(isMobile: false),
      ],
    );
  }

  Future<void> _editSwitch(SwitchModel sw) async {
    final ipController = TextEditingController(text: sw.ipAddress);
    final nameController = TextEditingController(text: sw.switchId);
    var locationOptions = buildMasterLocationOptions(
      await apiService.getAllMasterLocations(),
    );
    if (locationOptions.isEmpty) {
      locationOptions = [
        {
          'label': normalizeLocationLabel(sw.location),
          'container_yard': sw.containerYard,
          'location_type': 'SWITCH',
          'location_code': sw.switchId,
          'location_name': sw.location,
        }
      ];
    }
    final matchedOption = matchMasterLocationOption(
      locationOptions,
      sw.location,
      currentContainerYard: sw.containerYard,
    );
    var selectedLocation =
        matchedOption?['label'] ?? normalizeLocationLabel(sw.location);
    var selectedYard = matchedOption?['container_yard'] ?? sw.containerYard;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          backgroundColor: const Color(0xFFF5F5F7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit ${sw.switchId}',
              style: const TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.black54),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ipController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: const InputDecoration(
                    labelText: 'IP Address',
                    labelStyle: TextStyle(color: Colors.black54),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black12)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedLocation,
                  isExpanded: true,
                  isDense: true,
                  dropdownColor: Colors.white,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    labelStyle: TextStyle(color: Colors.black54),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black12)),
                  ),
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                  items: locationOptions
                      .map((option) => DropdownMenuItem<String>(
                            value: option['label'],
                            child: Text(
                              option['label'] ?? '',
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 13),
                            ),
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
                      selectedYard =
                          option['container_yard'] ?? sw.containerYard;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.black54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2)),
              child: const Text('Save Changes',
                  style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final response = await apiService.updateSwitch(sw.id, {
                  'switch_id': nameController.text,
                  'ip_address': ipController.text,
                  'location': locationOptions.firstWhere((o) => o['label'] == selectedLocation, orElse: () => locationOptions.first)['location_code'] ?? selectedLocation,
                  'container_yard': selectedYard,
                });

                if (!context.mounted) return;
                if (response['success'] == true) {
                  Navigator.pop(context);
                  _loadSwitches();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Successfully updated'),
                      backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed to update: ${response['message']}'),
                      backgroundColor: Colors.red));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSwitch(SwitchModel sw) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5F5F7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete confirmation',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete ${sw.switchId}?',
            style: const TextStyle(color: Colors.black54)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.black54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              final response = await apiService.deleteSwitch(sw.id);
              if (!context.mounted) return;
              if (response['success'] == true) {
                Navigator.pop(context);
                _loadSwitches();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Successfully deleted'),
                    backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed to delete: ${response['message']}'),
                    backgroundColor: Colors.red));
              }
            },
          ),
        ],
      ),
    );
  }



}
