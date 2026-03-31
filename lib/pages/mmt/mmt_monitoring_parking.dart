import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:monitoring/main.dart';
import 'package:monitoring/utils/ui_utils.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/utils/location_label_utils.dart';
import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';
import 'package:monitoring/widgets/global_footer.dart';
import 'package:monitoring/models/mmt_model.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';

class MMTMonitoringParkingPage extends StatefulWidget {
  const MMTMonitoringParkingPage({super.key});

  @override
  State<MMTMonitoringParkingPage> createState() => _MMTMonitoringParkingPageState();
}

class _MMTMonitoringParkingPageState extends State<MMTMonitoringParkingPage> {
  final ApiService _apiService = ApiService();
  static const List<String> _areaOptions = ['CY1', 'CY2', 'CY3', 'GATE', 'PARKING'];

  List<MMT> _mmts = [];
  bool _isLoading = true;
  String selectedArea = 'PARKING';
  int currentPage = 0;
  final int itemsPerPage = 5;
  Timer? _refreshTimer;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _loadMMTs();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) _loadMMTs();
    });
  }

  /// Map UI seleksi area ke container_yard nilai di database
  // REMOVED: _getContainerYardValue as selectedArea now maps directly via ApiService

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
      // Fetch MMTs specifically for the selected area
      final mmts = await _apiService.getValidatedMMTsByAreaType(selectedArea);
      
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
        print('❌ Error loading MMTs: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading MMTs: $e')),
        );
      }
    }
  }

  // List<MMT> get _filteredMMTs => _mmts;

  int get totalMMTs => _mmts.length;
  int get onlineMMTs => _mmts.where((m) => m.status == 'UP').length;
  int get downMMTs => _mmts.where((m) => m.status != 'UP').length;

  List<MMT> get paginatedData {
    final start = currentPage * itemsPerPage;
    final end = (start + itemsPerPage > _mmts.length)
        ? _mmts.length
        : start + itemsPerPage;
    return _mmts.sublist(start, end);
  }

  int get totalPages => (_mmts.length / itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/mmt-monitoring-parking'),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlobalSidebarNav(currentRoute: '/mmt-monitoring-parking'),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) => Padding(
                        padding: EdgeInsets.all(isMobile ? 8 : 20.0),
                        child: _buildContent(context, constraints),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                child: const Icon(Icons.device_hub, size: 24, color: Color(0xFF1976D2)),
              ),
              const SizedBox(height: 8),
              const Text(
                'MMT Monitoring',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Text(
                    'Monitoring Real Time',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (_lastRefreshTime != null) ...[
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Colors.white70)),
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
                child: const Icon(Icons.device_hub, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MMT Monitoring',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Real Time MMT Device Monitoring And Diagnostics',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
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
        const SizedBox(height: 16),

        // Stats Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = isMobile
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
                            _buildStatCard('Total MMT', '$totalMMTs', Colors.orange, width: cardWidth),
                            SizedBox(width: isMobile ? 8 : 16),
                            _buildStatCard('UP', '$onlineMMTs', Colors.green, width: cardWidth),
                            SizedBox(width: isMobile ? 8 : 16),
                            _buildStatCard('DOWN', '$downMMTs', Colors.red, width: cardWidth),
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
                      _buildStatCard('Total MMT', '$totalMMTs', Colors.orange, width: cardWidth),
                      _buildStatCard('UP', '$onlineMMTs', Colors.green, width: cardWidth),
                      _buildStatCard('DOWN', '$downMMTs', Colors.red, width: cardWidth),
                      _buildNetworkDropdown(cardWidth),
                      _buildAreaButton(cardWidth),
                      _buildCheckStatusButton(cardWidth),
                    ],
                  );
          },
        ),
        const SizedBox(height: 16),

        _buildMMTList(),
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
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: 2,
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
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: indicatorColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: indicatorColor.withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
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
                        dropdownColor: AppDropdownStyle.menuBackground,
                        borderRadius: AppDropdownStyle.menuBorderRadius,
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
                          
                          if (newValue == 'CY1') {
                            Navigator.pushReplacementNamed(context, '/mmt-monitoring');
                          } else if (newValue == 'CY2') {
                            Navigator.pushReplacementNamed(context, '/mmt-monitoring-cy2');
                          } else if (newValue == 'CY3') {
                            Navigator.pushReplacementNamed(context, '/mmt-monitoring-cy3');
                          } else if (newValue == 'GATE') {
                            Navigator.pushReplacementNamed(context, '/mmt-monitoring-gate');
                          } else if (newValue == 'PARKING') {
                            Navigator.pushReplacementNamed(context, '/mmt-monitoring-parking');
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMMTList() {
    if (_isLoading) {
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
                    'Loading MMT Data...',
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

    if (_mmts.isEmpty) {
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
                    Icons.router,
                    size: 64,
                    color: Colors.white38,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'NO DATA MMT',
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header biru — MMT List + pagination
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            width: double.infinity,
            color: const Color(0xFF1976D2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('MMT List',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        onPressed: currentPage > 0 ? () => setState(() => currentPage--) : null,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(totalPages, (index) {
                        final isCurrentPage = index == currentPage;
                        return GestureDetector(
                          onTap: () => setState(() => currentPage = index),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCurrentPage ? const Color(0xFF1976D2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isCurrentPage ? Colors.white : const Color(0xFF1976D2),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
                        onPressed:
                            currentPage < totalPages - 1 ? () => setState(() => currentPage++) : null,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Header kolom kuning
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            width: double.infinity,
            color: const Color(0xFFC6B430),
            child: Row(
              children: [
                _buildHeaderCell('MMT ID', flex: 2),
                _buildHeaderCell('Location', flex: 3),
                _buildHeaderCell('IP Address', flex: 2),
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

  Widget _buildHeaderCell(String label, {required int flex, bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
    );
  }

  Widget _buildMMTTableRow(MMT mmt) {
    final isDown = mmt.status != 'UP';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8D5C4),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        children: [
          _buildTableCell(mmt.mmtId, flex: 2, fontWeight: FontWeight.w800),
          _buildTableCell(mmt.location, flex: 3, fontWeight: FontWeight.w800),
          _buildTableCell(mmt.ipAddress, flex: 2),
          _buildTableCell(
            isDown ? 'DOWN' : mmt.status,
            flex: 1,
            color: isDown ? Colors.red : Colors.black87,
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
        child: Text(text,
            style: TextStyle(color: color, fontWeight: fontWeight, fontSize: 14),
            textAlign: align),
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
                decoration: const InputDecoration(labelText: 'IP Address')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedLocation,
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
                  selectedYard = option['container_yard'] ?? mmt.containerYard;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final response = await _apiService.updateMMT(mmt.id, {
                'ip_address': ipController.text,
                'location': selectedLocation,
                'container_yard': selectedYard,
              });
              if (response['success'] == true) {
                if (mounted) {
                  Navigator.pop(context);
                  await _loadMMTs();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Successfully Updated'), backgroundColor: Colors.green));
                  }
                }
              } else {
                if (mounted) {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to update'), backgroundColor: Colors.red));
                  }
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

  void _confirmDeleteMMT(MMT mmt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are You Sure Want To Delete ${mmt.mmtId}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final response = await _apiService.deleteMMT(mmt.id);
              if (response['success'] == true) {
                if (mounted) {
                  Navigator.pop(context);
                  await _loadMMTs();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Data Has Been Successfully Deleted'),
                        backgroundColor: Colors.red));
                  }
                }
              } else {
                if (mounted) {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to delete'), backgroundColor: Colors.red));
                  }
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPagerButton(IconData icon, VoidCallback? onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onPressed != null ? Colors.blue : Colors.grey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }


  void _showMMTDetails(MMT mmt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('MMT Details - ${mmt.mmtId}'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Location', mmt.location, Icons.location_on),
            const SizedBox(height: 12),
            _buildDetailRow('IP Address', mmt.ipAddress, Icons.router),
            const SizedBox(height: 12),
            _buildDetailRow('Container Yard', mmt.containerYard, Icons.domain),
            const SizedBox(height: 12),
            _buildDetailRow('Type', mmt.type, Icons.category),
            const SizedBox(height: 12),
            _buildDetailRow('Status', mmt.status, Icons.info),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _confirmDelete(MMT mmt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete MMT?'),
        content: Text('Are you sure you want to delete ${mmt.mmtId}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('${mmt.mmtId} deleted')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

