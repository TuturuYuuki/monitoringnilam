import 'package:flutter/material.dart';
import 'package:monitoring/models/mmt_model.dart';
import 'package:monitoring/services/api_service.dart';
import 'dart:async';
import '../dashboard.dart';
import '../network.dart';
import '../cctv.dart';
import '../alerts.dart';
import '../report_page.dart';
import '../add_device.dart';
import '../profile.dart';
import '../main.dart';

class MMTMonitoringPage extends StatefulWidget {
  const MMTMonitoringPage({super.key});

  @override
  State<MMTMonitoringPage> createState() => _MMTMonitoringPageState();
}

class _MMTMonitoringPageState extends State<MMTMonitoringPage> {
  final ApiService _apiService = ApiService();

  List<MMT> _mmts = [];
  bool _isLoading = true;
  String selectedCY = 'CY1';
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
      if (mounted) {
        _loadMMTs();
      }
    });
  }

  Future<void> _loadMMTs() async {
    try {
      final mmts = await _apiService.getAllMMTs();
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

  List<MMT> get _filteredMMTs {
    return _mmts.where((mmt) => mmt.containerYard == selectedCY).toList();
  }

  int get totalMMTs => _filteredMMTs.length;
  int get onlineMMTs => _filteredMMTs.where((m) => m.status == 'UP').length;
  int get downMMTs => _filteredMMTs.where((m) => m.status != 'UP').length;

  List<MMT> get paginatedData {
    int start = currentPage * itemsPerPage;
    int end = (start + itemsPerPage > _filteredMMTs.length)
        ? _filteredMMTs.length
        : start + itemsPerPage;
    return _filteredMMTs.sublist(start, end);
  }

  int get totalPages => (_filteredMMTs.length / itemsPerPage).ceil();

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
                    padding: EdgeInsets.all(isMobile ? 8 : 20.0),
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

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    final isMobile = isMobileScreen(context);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
                child: const Icon(Icons.device_hub,
                    size: 24, color: Color(0xFF1976D2)),
              ),
              const SizedBox(height: 8),
              const Text(
                'MMT Monitoring',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Monitoring Real Time',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
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
                child: const Icon(Icons.device_hub,
                    size: 32, color: Colors.white),
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
                        'Real Time MMT Device Monitoring And Diagnostics',
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
        const SizedBox(height: 16),

        // Stats Cards
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
                            _buildStatCard('Total MMT', '$totalMMTs',
                                Colors.orange,
                                width: cardWidth),
                            SizedBox(width: isMobile ? 8 : 16),
                            _buildStatCard('UP', '$onlineMMTs', Colors.green,
                                width: cardWidth),
                            SizedBox(width: isMobile ? 8 : 16),
                            _buildStatCard(
                                'DOWN', '$downMMTs', Colors.red,
                                width: cardWidth),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCYDropdown(constraints.maxWidth),
                      const SizedBox(height: 12),
                      _buildCheckStatusButton(constraints.maxWidth),
                    ],
                  )
                : Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildStatCard(
                          'Total MMT', '$totalMMTs', Colors.orange,
                          width: cardWidth),
                      _buildStatCard('UP', '$onlineMMTs', Colors.green,
                          width: cardWidth),
                      _buildStatCard('DOWN', '$downMMTs', Colors.red,
                          width: cardWidth),
                      _buildCYDropdown(cardWidth),
                      _buildCheckStatusButton(cardWidth),
                    ],
                  );
          },
        ),
        const SizedBox(height: 16),

        // MMT List
        _buildMMTList(),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color indicatorColor,
      {VoidCallback? onTap, double? width}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
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
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
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
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCYDropdown(double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A5F7F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SELECT CONTAINER YARD',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: selectedCY,
            dropdownColor: const Color(0xFF4A5F7F),
            isExpanded: true,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                  value: 'CY1',
                  child: Text('CY 1',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))),
              DropdownMenuItem(
                  value: 'CY2',
                  child: Text('CY 2',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))),
              DropdownMenuItem(
                  value: 'CY3',
                  child: Text('CY 3',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))),
            ],
            onChanged: (String? newValue) {
              if (newValue != null && newValue != selectedCY) {
                // Navigate to the appropriate page based on CY selection
                String routeName = '/mmt-monitoring';
                if (newValue == 'CY2') {
                  routeName = '/mmt-monitoring-cy2';
                } else if (newValue == 'CY3') {
                  routeName = '/mmt-monitoring-cy3';
                }
                Navigator.pushReplacementNamed(context, routeName);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckStatusButton(double width) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Checking MMT status...')),
          );
          _loadMMTs();
        },
        child: Container(
          width: width,
          height: 80,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[400],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Row(
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF1976D2),
      child: Row(
        children: [
          const Text(
            'Terminal Nilam - MMT Monitoring',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 30),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeaderOpenButton('+ Add New Device', const AddDevicePage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Dashboard', const DashboardPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Access Point', const NetworkPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('CCTV', const CCTVPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Alert', const AlertsPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Alert Report', const ReportPage()),
                    const SizedBox(width: 12),
                    _buildHeaderButton('Tower Mgmt', () => Navigator.pushNamed(context, '/tower-management')),
                    const SizedBox(width: 12),
                    _buildHeaderButton('MMT Monitor', () {}, isActive: true),
                    const SizedBox(width: 12),
                    _buildHeaderButton('Logout', () => showLogoutDialog(context)),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
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

  Widget _buildHeaderOpenButton(String text, Widget page, {bool isActive = false}) {
    return buildLiquidGlassButton(text, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page)), isActive: isActive);
  }

  Widget _buildHeaderButton(String text, VoidCallback onPressed, {bool isActive = false}) {
    return buildLiquidGlassButton(text, onPressed, isActive: isActive);
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMMTList() {
    if (_filteredMMTs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.device_unknown,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text('No MMT devices found',
                style: TextStyle(color: Colors.white)),
          ],
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
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            color: const Color(0xFF37474F),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _buildHeaderCell('MMT ID', flex: 1),
                _buildHeaderCell('Location', flex: 2),
                _buildHeaderCell('IP Address', flex: 2),
                _buildHeaderCell('Container Yard', flex: 1),
                _buildHeaderCell('Type', flex: 1),
                _buildHeaderCell('Status', flex: 1),
                _buildHeaderCell('Action', flex: 1, isLast: true),
              ],
            ),
          ),

          // Table Rows
          ...paginatedData.map((mmt) {
            final statusColor = mmt.status == 'UP' ? Colors.green : Colors.red;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8D5C4),
                border:
                    Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
              ),
              child: Row(
                children: [
                  _buildTableCell(mmt.mmtId, flex: 1),
                  _buildTableCell(mmt.location, flex: 2),
                  _buildTableCell(mmt.ipAddress, flex: 2,
                      color: Colors.grey[700] ?? Colors.grey),
                  _buildTableCell(mmt.containerYard, flex: 1),
                  _buildTableCell(mmt.type, flex: 1),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        mmt.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Text('View'),
                            onTap: () {
                              _showMMTDetails(mmt);
                            },
                          ),
                          PopupMenuItem(
                            child: const Text('Edit'),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Edit feature coming soon')),
                              );
                            },
                          ),
                          PopupMenuItem(
                            child: const Text('Delete'),
                            onTap: () {
                              _confirmDelete(mmt);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          // Table Footer with Pagination
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black.withOpacity(0.8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Page ${currentPage + 1} of $totalPages',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    _buildPagerButton(
                      Icons.chevron_left,
                      currentPage > 0 ? () => setState(() => currentPage--) : null,
                    ),
                    const SizedBox(width: 8),
                    _buildPagerButton(
                      Icons.chevron_right,
                      currentPage < totalPages - 1
                          ? () => setState(() => currentPage++)
                          : null,
                    ),
                  ],
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
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
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
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: fontWeight,
          color: color,
        ),
        textAlign: align,
        overflow: TextOverflow.ellipsis,
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black.withOpacity(0.8),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '©2026 TPK Nilam Monitoring System',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${mmt.mmtId} deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}