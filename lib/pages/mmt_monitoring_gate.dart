import 'package:flutter/material.dart';
import 'package:monitoring/models/mmt_model.dart';
import 'package:monitoring/services/api_service.dart';
import 'dart:async';
import '../main.dart';
import '../widgets/global_header_bar.dart';
import '../widgets/global_sidebar_nav.dart';

class MMTMonitoringGatePage extends StatefulWidget {
  const MMTMonitoringGatePage({super.key});

  @override
  State<MMTMonitoringGatePage> createState() => _MMTMonitoringGatePageState();
}

class _MMTMonitoringGatePageState extends State<MMTMonitoringGatePage> {
  final ApiService _apiService = ApiService();
  static const List<String> _areaOptions = ['CY1', 'CY2', 'CY3', 'GATE', 'PARKING'];

  List<MMT> _mmts = [];
  bool _isLoading = true;
  String selectedCY = 'GATE';
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
  String _getContainerYardValue(String area) {
    switch (area) {
      case 'CY1':
        return 'CY1';
      case 'CY2':
        return 'CY2';
      case 'CY3':
        return 'CY3';
      case 'GATE':
        return 'GATE';
      case 'PARKING':
        return 'PARKING';
      default:
        return area;
    }
  }

  Future<void> _loadMMTs() async {
    try {
      // Fetch MMTs spesifik untuk area yang dipilih
      final containerYardValue = _getContainerYardValue(selectedCY);
      final mmts = await _apiService.getMMTsByContainerYard(containerYardValue);
      
      if (mounted) {
        setState(() {
          _mmts = mmts;
          _isLoading = false;
          _lastRefreshTime = DateTime.now();
        });
        print('✓ Loaded ${mmts.length} MMTs for area: $containerYardValue');
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

  /// Tidak perlu filter lagi karena data sudah di-fetch by container_yard
  List<MMT> get _filteredMMTs => _mmts;

  int get totalMMTs => _filteredMMTs.length;
  int get onlineMMTs => _filteredMMTs.where((m) => m.status == 'UP').length;
  int get downMMTs => _filteredMMTs.where((m) => m.status != 'UP').length;

  List<MMT> get paginatedData {
    final start = currentPage * itemsPerPage;
    final end = (start + itemsPerPage > _filteredMMTs.length)
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
          const GlobalHeaderBar(currentRoute: '/mmt-monitoring-gate'),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlobalSidebarNav(currentRoute: '/mmt-monitoring-gate'),
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
          _buildFooter(),
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
              const Text(
                'Monitoring Real Time',
                style: TextStyle(color: Colors.white70, fontSize: 12),
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
                      _buildMMTDropdown(constraints.maxWidth),
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
                      _buildStatCard('Total MMT', '$totalMMTs', Colors.orange, width: cardWidth),
                      _buildStatCard('UP', '$onlineMMTs', Colors.green, width: cardWidth),
                      _buildStatCard('DOWN', '$downMMTs', Colors.red, width: cardWidth),
                      _buildMMTDropdown(cardWidth),
                      _buildContainerYardButton(cardWidth),
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
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: indicatorColor, shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  // Tombol label area aktif menampilkan nama area saja.
  Widget _buildContainerYardButton(double width) {
    const Color buttonColor = Color(0xFF4A5F7F);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1.0),
        boxShadow: [
          BoxShadow(color: buttonColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 2),
        ],
      ),
      child: const Center(
        child: Text(
          'GATE',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMMTDropdown(double width) {
    return Container(
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
          const Text('AREA',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Flexible(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: null,
                hint: const Text('Select Area',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                dropdownColor: const Color(0xFF4A5F7F),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                items: _areaOptions
                    .map((v) => DropdownMenuItem<String>(
                          value: v,
                          child: Text(v, style: const TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedCY = newValue;
                      currentPage = 0;
                      _isLoading = true;
                    });
                    _loadMMTs();
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
                  }
                },
              ),
            ),
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
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Checking Status...')));
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
              BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 8, spreadRadius: 1),
            ],
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Check Status',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
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
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
              SizedBox(height: 10),
              Text('Loading MMT Data...', style: TextStyle(fontSize: 14, color: Colors.black87)),
            ],
          ),
        ),
      );
    }

    if (_filteredMMTs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.router, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No Data MMT',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
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
    final locationController = TextEditingController(text: mmt.location);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${mmt.mmtId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: ipController,
                decoration: const InputDecoration(labelText: 'IP Address')),
            TextField(
              controller: locationController,
              readOnly: true,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Location (Locked)',
                helperText: 'Pindah lokasi wajib delete MMT lalu tambah lagi di lokasi tujuan.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final response = await _apiService.updateMMT(mmt.id, {'ip_address': ipController.text});
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black.withOpacity(0.8),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('©2026 TPK Nilam Monitoring System',
              style: TextStyle(color: Colors.white, fontSize: 12)),
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