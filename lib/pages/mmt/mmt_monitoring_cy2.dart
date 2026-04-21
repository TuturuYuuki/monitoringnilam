import 'package:flutter/material.dart';
import 'package:monitoring/models/mmt_model.dart';
import 'package:monitoring/services/api_service.dart';
import 'dart:async';
import 'dart:ui';
import 'package:monitoring/main.dart';
import 'package:monitoring/utils/location_label_utils.dart';
import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';
import 'package:monitoring/widgets/global_footer.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';

class MMTMonitoringCY2Page extends StatefulWidget {
  const MMTMonitoringCY2Page({super.key});

  @override
  State<MMTMonitoringCY2Page> createState() => _MMTMonitoringCY2PageState();
}

class _MMTMonitoringCY2PageState extends State<MMTMonitoringCY2Page> {
  final ApiService _apiService = ApiService();
  static const List<String> _areaOptions = [
    'CY 1',
    'CY 2',
    'CY 3',
    'GATE',
    'PARKING'
  ];

  List<MMT> _mmts = [];
  bool _isLoading = true;
  String selectedArea = 'CY 2';
  int currentPage = 0;
  final int itemsPerPage = 5;
  Timer? _refreshTimer;
  DateTime? _lastRefreshTime;
  int globalTotalMMTs = 0;
  int globalUpMMTs = 0;
  int globalDownMMTs = 0;
  bool _isLoadingGlobalSummary = true;
  bool _isGlobalSummaryRequestInFlight = false;

  @override
  void initState() {
    super.initState();
    _loadMMTs();
    _loadGlobalSummary(initialLoad: true);
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _loadMMTs();
        _loadGlobalSummary();
      }
    });
  }

  Future<void> _triggerPingCheck() async {
    try {
      await _apiService.triggerRealtimePing();
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _loadMMTs();
      }
    } catch (e) {
      // Silent error
    }
  }

  Future<void> _loadMMTs() async {
    try {
      final mmts = await _apiService.getValidatedMMTsByAreaType(selectedArea.replaceAll(' ', ''));
      if (mounted) {
        setState(() {
          _mmts = mmts;
          _isLoading = false;
          _lastRefreshTime = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading MMTs: $e')),
        );
      }
    }
  }

  Future<void> _loadGlobalSummary({bool initialLoad = false}) async {
    if (_isGlobalSummaryRequestInFlight) return;
    _isGlobalSummaryRequestInFlight = true;
    try {
      if (mounted && initialLoad) {
        setState(() => _isLoadingGlobalSummary = true);
      }
      final mmts = await _apiService.getAllMMTs();
      final up = mmts.where((m) => m.status == 'UP').length;
      final down = mmts.length - up;
      if (mounted) {
        setState(() {
          globalTotalMMTs = mmts.length;
          globalUpMMTs = up;
          globalDownMMTs = down;
          _isLoadingGlobalSummary = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading MMT global overview: $e');
      if (mounted) setState(() => _isLoadingGlobalSummary = false);
    } finally {
      _isGlobalSummaryRequestInFlight = false;
    }
  }

  // List<MMT> get _filteredMMTs {
  //   return _mmts.where((mmt) => mmt.containerYard == selectedArea).toList();
  // }
  // Using _mmts directly as it's now filtered by ApiService

  int get totalMMTs => _mmts.length;
  int get onlineMMTs => _mmts.where((m) => m.status == 'UP').length;
  int get downMMTs => _mmts.where((m) => m.status != 'UP').length;

  List<MMT> get paginatedData {
    int start = currentPage * itemsPerPage;
    int end = (start + itemsPerPage > _mmts.length)
        ? _mmts.length
        : start + itemsPerPage;
    return _mmts.sublist(start, end);
  }

  int get totalPages => (_mmts.length / itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      backgroundColor: AppDropdownStyle.standardPageBackground,
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/mmt-cy2'),
          Expanded(
            child: GlobalSidebarNav(
                currentRoute: '/mmt-cy2',
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
        // Title Section
        isMobile ? _buildMobileHeader() : _buildDesktopHeader(),
        const SizedBox(height: 16),

        // Section 2: Stats Cards
        LayoutBuilder(
          builder: (context, constraints) {
            double cardWidth = constraints.maxWidth > 1400
                    ? (constraints.maxWidth - 100) / 5
                    : (constraints.maxWidth - 80) / 3;

            return isMobile
                ? Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total MMT',
                                '$totalMMTs',
                                Colors.blue,
                                compact: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                'UP',
                                '$onlineMMTs',
                                Colors.green,
                                compact: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                'DOWN',
                                '$downMMTs',
                                Colors.red,
                                compact: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildNetworkDropdown(constraints.maxWidth),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCheckStatusButton(constraints.maxWidth),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildAreaButton(constraints.maxWidth),
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
                              child: _buildStatCard('Total MMT', '$totalMMTs',
                                  Colors.blue, width: cardWidth),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                  'UP', '$onlineMMTs', Colors.green,
                                  width: cardWidth),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                  'DOWN', '$downMMTs', Colors.red,
                                  width: cardWidth),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNetworkDropdown(constraints.maxWidth),
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

        // MMT List
        _buildMMTList(context),
        _buildPagination(),
      ],
    );
  }

  Widget _buildHeaderOverviewMini({required bool isMobile}) {
    final cards = [
      _buildGlobalStatCard('ALL', '$globalTotalMMTs', Colors.orange,
          width: isMobile ? null : 86),
      _buildGlobalStatCard('UP', '$globalUpMMTs', Colors.green,
          width: isMobile ? null : 86),
      _buildGlobalStatCard('DOWN', '$globalDownMMTs', Colors.red,
          width: isMobile ? null : 86),
    ];

    final content = isMobile
        ? Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
              const SizedBox(width: 10),
              Expanded(child: cards[2]),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              cards[0],
              const SizedBox(width: 10),
              cards[1],
              const SizedBox(width: 10),
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
          const Text(
            'Overview Data All Area',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
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
      {VoidCallback? onTap, double? width, bool compact = false}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
                SizedBox(height: compact ? 8 : 12),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: compact ? 24 : 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: compact ? 2 : 4),
                Container(
                  height: 2,
                  width: compact ? 30 : 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [indicatorColor, indicatorColor.withValues(alpha: 0)],
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
            Navigator.pushReplacementNamed(context, '/mmt-monitoring');
          } else if (newValue == 'CY 2') {
            Navigator.pushReplacementNamed(context, '/mmt-monitoring-cy2');
          } else if (newValue == 'CY 3') {
            Navigator.pushReplacementNamed(context, '/mmt-monitoring-cy3');
          } else if (newValue == 'GATE') {
            Navigator.pushReplacementNamed(context, '/mmt-monitoring-gate');
          } else if (newValue == 'PARKING') {
            Navigator.pushReplacementNamed(context, '/mmt-monitoring-parking');
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
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      child: MouseRegion(
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
      ),
    );
  }



  Widget _buildMMTList(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Loading MMT data...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_mmts.isEmpty) {
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
                    Icons.router,
                    size: 64,
                    color: Colors.white38,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No MMT data available',
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

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            width: double.infinity,
            color: const Color(0xFF1976D2),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MMT List',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            width: double.infinity,
            color: const Color(0xFFC6B430),
            child: Row(
              children: [
                _buildHeaderCell('MMT ID', flex: 2),
                _buildHeaderCell('Lokasi', flex: 3),
                _buildHeaderCell('Alamat IP', flex: 2),
                _buildHeaderCell('Status', flex: 1),
                _buildHeaderCell('Action', flex: 2, isLast: true),
              ],
            ),
          ),
          ...paginatedData.map((mmt) => _buildMMTTableRow(mmt)),
        ],
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

  Widget _buildMMTTableRow(MMT mmt) {
    final isDown = mmt.status != 'UP';
    final statusColor = isDown ? Colors.red : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8D5C4),
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildTableCell(mmt.mmtId, flex: 2, fontWeight: FontWeight.w800),
          _buildTableCell(mmt.location, flex: 3, fontWeight: FontWeight.w800),
          _buildTableCell(mmt.ipAddress, flex: 2),
          _buildTableCell(
            isDown ? 'DOWN' : mmt.status,
            flex: 1,
            color: statusColor,
            fontWeight: FontWeight.w800,
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => _editMMT(mmt),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _confirmDeleteMMT(mmt),
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

  Future<void> _editMMT(MMT mmt) async {
    final ipController = TextEditingController(text: mmt.ipAddress);
    var locationOptions = buildMasterLocationOptions(
      await _apiService.getAllMasterLocations(),
    );
    if (locationOptions.isEmpty) {
      locationOptions = [
        {
          'label': normalizeLocationLabel(mmt.location),
          'container_yard': mmt.containerYard,
          'location_type': 'MMT',
          'location_code': mmt.mmtId,
          'location_name': mmt.location,
        }
      ];
    }
    final matchedOption = matchMasterLocationOption(
      locationOptions,
      mmt.location,
      currentContainerYard: mmt.containerYard,
    );
    var selectedLocation =
        matchedOption?['label'] ?? normalizeLocationLabel(mmt.location);
    var selectedYard = matchedOption?['container_yard'] ?? mmt.containerYard;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text('Edit ${mmt.mmtId}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: ipController,
                  decoration: const InputDecoration(labelText: 'IP address')),
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
                    selectedYard =
                        option['container_yard'] ?? mmt.containerYard;
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
                final response = await _apiService.updateMMT(mmt.id, {
                  'ip_address': ipController.text,
                  'location': selectedLocation,
                  'container_yard': selectedYard,
                });

                if (!context.mounted) return;
                if (response['success'] == true) {
                  Navigator.pop(context); // Tutup dialog
                  await _loadMMTs(); // REFRESH DATA DARI DATABASE
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Data successfully updated'),
                        backgroundColor: Colors.green));
                  }
                } else {
                  Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Gagal memperbarui data'),
                        backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMMT(MMT mmt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete confirmation'),
        content: Text('Hapus ${mmt.mmtId}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final response = await _apiService.deleteMMT(mmt.id);
              if (!context.mounted) return;
              if (response['success'] == true) {
                Navigator.pop(context); // Tutup dialog
                await _loadMMTs(); // REFRESH DATA DARI DATABASE
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Data successfully deleted'),
                      backgroundColor: Colors.red));
                }
              } else {
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Failed to delete'),
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
                  onTap: (currentPage != index)
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
                onTap: currentPage < displayPages - 1
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
              color: onTap == null ? Colors.white38 : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
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
              ),
              child: const Icon(Icons.tablet_mac,
                  size: 30, color: Color(0xFF1976D2)),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'MMT Monitoring',
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
          'Monitoring View of MMT',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        if (_lastRefreshTime != null)
          Row(
            children: [
              const Text('•', style: TextStyle(color: Colors.greenAccent)),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.tablet_mac,
            size: 32,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MMT Monitoring',
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
                  'Monitoring View of MMT',
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
}



