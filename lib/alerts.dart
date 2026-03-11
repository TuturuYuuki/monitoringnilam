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
  List<Alert> alerts = [];
  bool isLoading = true;
  Timer? _timer;
  DateTime? _lastRefreshTime = DateTime.now();
  String _selectedDeviceType = 'ALL'; // Filter: ALL, AP, CCTV, MMT

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _loadAlerts();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) _loadAlerts(showLoading: false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAlerts({bool showLoading = true}) async {
    if (showLoading) setState(() => isLoading = true);
    try {
      final results = await apiService.getAllAlerts();
      if (mounted) {
        // Handle paginated response format (getAllAlerts always returns Map<String, dynamic>)
        List<Alert> loadedAlerts = [];

        // Extract alerts list from response map using explicit loop
        final alertListRaw = results['alerts'] as List? ?? [];
        for (var data in alertListRaw) {
          if (data is Alert) {
            loadedAlerts.add(data);
          } else {
            loadedAlerts.add(Alert.fromJson(data as Map<String, dynamic>));
          }
        }

        setState(() {
          alerts = loadedAlerts;
          isLoading = false;
          _lastRefreshTime = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteAlert(Alert alert) async {
    final bool isCurrentStatusOnly = alert.source == 'current' || alert.id <= 0;

    if (isCurrentStatusOnly) {
      final success = await apiService.dismissCurrentAlert(alert.alertKey);

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to delete alert"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          final idx = alerts
              .indexWhere((element) => element.alertKey == alert.alertKey);
          if (idx >= 0) {
            alerts.removeAt(idx);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Alert Deleted"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final success = await apiService.deleteAlert(alert.id);

    if (success && mounted) {
      setState(() {
        final idx =
            alerts.indexWhere((element) => element.alertKey == alert.alertKey);

        if (idx >= 0) {
          alerts.removeAt(idx);
        } else {
          final fallbackIdx = alerts.indexOf(alert);
          if (fallbackIdx >= 0) {
            alerts.removeAt(fallbackIdx);
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Alert deleted"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to delete alert"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== DIALOGS ====================

  void _showDeleteConfirmation(Alert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification',
            style: TextStyle(color: Colors.black87)),
        content: const Text('Are You Sure Want To Delete This Alert?',
            style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.black87, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAlert(alert);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  bool _isDownAlert(Alert alert) {
    final combined =
        '${alert.title} ${alert.description}'.toLowerCase();
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
    final src =
        '${alert.title} ${alert.description} ${alert.lokasi ?? ''}'
            .toUpperCase();
    if (RegExp(r'\bAP\b').hasMatch(src)) return 'AP';
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
    // Format: "DeviceId, IP, Location, Date, Time"
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
                const GlobalSidebarNav(currentRoute: '/alerts'),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 12 : 24.0),
                    child: _buildContent(context),
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

  Widget _buildContent(BuildContext context) {
    final isMobile = isMobileScreen(context);
    final sorted = alerts.toList()
      ..sort((a, b) {
        final at = DateTime.tryParse(a.timestamp);
        final bt = DateTime.tryParse(b.timestamp);
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
    final filtered = _filterByDeviceType(sorted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleSection(isMobile),
        const SizedBox(height: 20),
        _buildDeviceTypeFilter(),
        const SizedBox(height: 16),
        _buildNotificationList(alertsData: filtered, isMobile: isMobile),
      ],
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
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  // ==================== NOTIFICATION LIST ====================

  Widget _buildNotificationList({
    required List<Alert> alertsData,
    required bool isMobile,
  }) {
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
              const Text(
                'Device Notifications',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${alertsData.length} alert',
                style: const TextStyle(
                    color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (alertsData.isEmpty)
            const SizedBox(
              height: 220,
              child: Center(
                child: Text(
                  'No alerts found for selected filter',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alertsData.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) =>
                  _buildNotificationCard(alertsData[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Alert alert) {
    final isDown = _isDownAlert(alert);
    final statusColor =
        isDown ? const Color(0xFFC62828) : const Color(0xFF2E7D32);
    final bgColor =
        isDown ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);
    final statusText = isDown ? 'DOWN' : 'UP';
    final deviceName = _cleanDeviceName(alert.title);
    final ip = _extractIpFromDescription(alert.description);
    final timestamp = '${alert.tanggal ?? '-'}  ${alert.waktu ?? '-'}';

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: statusColor, width: 5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isDown
                ? Icons.cloud_off_rounded
                : Icons.cloud_done_rounded,
            color: statusColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        deviceName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 16,
                  runSpacing: 2,
                  children: [
                    _notifInfoRow(Icons.lan_outlined, 'IP: $ip'),
                    _notifInfoRow(Icons.location_on_outlined,
                        alert.lokasi ?? '-'),
                    _notifInfoRow(
                        Icons.access_time_outlined, timestamp),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notifInfoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.black54),
        const SizedBox(width: 4),
        Text(text,
            style:
                const TextStyle(fontSize: 12, color: Colors.black54)),
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
            'Alert List',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              const Text(
                'Monitoring Real Time',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (_lastRefreshTime != null) ...[
                const SizedBox(width: 8),
                const Text('€¢',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 8),
                Text(
                  'Updated: ${_lastRefreshTime!.hour.toString().padLeft(2, '0')}:${_lastRefreshTime!.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
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
                  'Real Time Device Status Monitoring and Alert History',
                  style:
                      TextStyle(color: Colors.white70, fontSize: 14),
                ),
                if (_lastRefreshTime != null) ...[
                  const SizedBox(width: 8),
                  const Text('€¢',
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
