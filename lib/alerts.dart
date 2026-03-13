import 'package:flutter/material.dart';
import 'dart:async';
import 'main.dart';
import 'services/api_service.dart';
import 'models/alert_model.dart';
import 'widgets/global_header_bar.dart';
import 'widgets/global_sidebar_nav.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  late ApiService apiService;
  List<Alert> _alerts = [];
  bool _isLoading = true;
  Timer? _timer;
  DateTime? _lastRefreshTime = DateTime.now();
  String _selectedDeviceType = 'ALL';

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _loadAlerts();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) _loadAlerts(showLoading: false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAlerts({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _isLoading = true);
    try {
      final results = await apiService.getAllAlerts(source: 'HISTORY', limit: 200);
      
      if (mounted) {
        final alertListRaw = results['alerts'] as List? ?? [];
        final List<Alert> loaded = [];
        for (var data in alertListRaw) {
          if (data is Alert) {
            loaded.add(data);
          } else {
            loaded.add(Alert.fromJson(data as Map<String, dynamic>));
          }
        }

        setState(() {
          _alerts = loaded;
          _isLoading = false;
          _lastRefreshTime = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isDeviceDown(String status) {
    final s = status.toUpperCase().trim();
    return s == 'DOWN' || s == 'OFFLINE' || s == 'UNREACHABLE' || s == 'WARNING';
  }

  // ==================== HELPERS ====================

  bool _isDownAlert(Alert alert) {
    final combined = '${alert.title} ${alert.description}'.toLowerCase();
    if (combined.contains(' down') ||
        combined.contains('is down') ||
        combined.contains('offline') ||
        combined.contains('unreachable')) {
      return true;
    }
    if (alert.severity.toLowerCase() == 'critical' &&
        !combined.contains(' up') &&
        !combined.contains('is up')) {
      return true;
    }
    return false;
  }

  String _cleanDeviceName(String rawTitle) {
    var s = rawTitle.trim();
    s = s.replaceAll(
        RegExp(r'\s+is\s+now\s+(up|down)\b', caseSensitive: false), '');
    s = s.replaceAll(
        RegExp(r'\s+is\s+(up|down)\b', caseSensitive: false), '');
    return s.trim();
  }

  String _extractDeviceType(Alert alert) {
    if (alert.deviceType != null && alert.deviceType!.isNotEmpty) {
       final dt = alert.deviceType!.toLowerCase();
       if (dt.contains('tower') || dt.contains('ap')) return 'AP';
       if (dt.contains('camera') || dt.contains('cctv')) return 'CCTV';
       if (dt.contains('mmt')) return 'MMT';
    }

    final src =
        '${alert.title} ${alert.description} ${alert.lokasi ?? ''}'
            .toUpperCase();
    if (RegExp(r'\b(AP|TOWER)\b').hasMatch(src)) return 'AP';
    if (RegExp(r'\b(CAM|CCTV)\b').hasMatch(src)) return 'CCTV';
    if (RegExp(r'\bMMT\b').hasMatch(src)) return 'MMT';
    return 'Other';
  }

  List<Alert> _filterByDeviceType(List<Alert> list) {
    if (_selectedDeviceType == 'ALL') return list;
    return list
        .where((a) => _extractDeviceType(a) == _selectedDeviceType)
        .toList();
  }

  String _extractIpFromDescription(String description) {
    final parts = description.split(',');
    if (parts.length >= 2) return parts[1].trim();
    return '-';
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/alerts'),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile) const GlobalSidebarNav(currentRoute: '/alerts'),
                if (!isMobile) const SizedBox(width: 12),
                Expanded(
                  child: _buildContent(isMobile),
                ),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    if (_alerts.isEmpty && !_isLoading) {
      return const Center(
        child: Text(
          'Tidak Ada Alert.',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    final filtered = _filterByDeviceType(_alerts);
    
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          isMobile ? 12 : 24, isMobile ? 12 : 24, isMobile ? 12 : 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleSection(isMobile),
          const SizedBox(height: 16),
          _buildDeviceTypeFilter(),
          const SizedBox(height: 12),
          _buildSummaryBar(filtered),
          const SizedBox(height: 12),
          _buildAlertList(filtered),
        ],
      ),
    );
  }

  // ==================== FILTER CHIPS ====================

  Widget _buildDeviceTypeFilter() {
    final options = ['ALL', 'AP', 'CCTV', 'MMT'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((type) {
        final isSelected = _selectedDeviceType == type;
        return FilterChip(
          label: Text(type),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedDeviceType = type),
          selectedColor: const Color(0xFF1976D2).withOpacity(0.2),
          checkmarkColor: const Color(0xFF1976D2),
          backgroundColor: Colors.white.withOpacity(0.7),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF1976D2) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  // ==================== SUMMARY BAR ====================

  Widget _buildSummaryBar(List<Alert> filtered) {
    // Current Feed Summary (Synchronized with visible list)
    final feedDown = filtered.where((a) => _isDownAlert(a)).length;
    final feedUp = filtered.where((a) => !_isDownAlert(a)).length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _summaryChip(Icons.arrow_downward_rounded, '$feedDown DOWN',
            Colors.red.shade700),
        _summaryChip(Icons.arrow_upward_rounded, '$feedUp UP',
            Colors.green.shade700),
      ],
    );
  }

  Widget _summaryChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ],
      ),
    );
  }

  // ==================== ALERT LIST ====================

  Widget _buildAlertList(List<Alert> filtered) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active,
                  size: 18, color: Color(0xFF1976D2)),
              const SizedBox(width: 6),
              const Text('Live Alert Feed',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${filtered.length} event(s)',
                  style: const TextStyle(
                      color: Colors.black54, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 48),
                    SizedBox(height: 12),
                    Text('No alert events',
                        style: TextStyle(
                            color: Colors.black54, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) =>
                  _buildAlertCard(filtered[index]),
            ),
        ],
      ),
    );
  }

  // ==================== ALERT CARD ====================

  Widget _buildAlertCard(Alert alert) {
    final isDown = _isDownAlert(alert);
    final statusColor =
        isDown ? const Color(0xFFC62828) : const Color(0xFF2E7D32);
    final bgColor =
        isDown ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);
    final deviceName = _cleanDeviceName(alert.title);
    final ip = _extractIpFromDescription(alert.description);
    final date = alert.tanggal ?? '-';
    final time = alert.waktu ?? '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: statusColor, width: 5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status indicator (icon, not text)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDown
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deviceName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 16,
                  runSpacing: 2,
                  children: [
                    _infoRow(
                        Icons.location_on_outlined, alert.lokasi ?? '-'),
                    _infoRow(Icons.lan_outlined, 'IP: $ip'),
                    _infoRow(Icons.calendar_today_outlined, date),
                    _infoRow(Icons.access_time_outlined, time),
                  ],
                ),
              ],
            ),
          ),
          // Status dot indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.black54),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  // ==================== TITLE SECTION ====================

  Widget _buildTitleSection(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.notifications_active,
                size: 24, color: Color(0xFF1976D2)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Alert Monitoring',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Real Time Device Status Monitoring',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      );
    }
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.notifications_active,
              size: 32, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alert Monitoring',
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
                  'Real Time Device Status Monitoring',
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
    );
  }

  // ==================== FOOTER ====================

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
}
