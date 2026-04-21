import 'package:flutter/material.dart';
import 'dart:async';
import 'package:monitoring/main.dart';
import 'package:monitoring/utils/ui_utils.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/models/alert_model.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';
import 'package:monitoring/widgets/global_footer.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';

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
      final results =
          await apiService.getAllAlerts(source: 'HISTORY', limit: 200);

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

        // Sync alerts with current device/master data
        final synced = await _syncAlertsWithDeviceData(loaded);

        setState(() {
          _alerts = synced;
          _isLoading = false;
          _lastRefreshTime = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Sync alert data with current device/master type information
  /// Returns alerts with updated lokasi and deviceType if changed
  Future<List<Alert>> _syncAlertsWithDeviceData(List<Alert> alerts) async {
    try {
      // Fetch current device master data
      final towers = await apiService.getAllTowers();
      final cameras = await apiService.getAllCameras();
      final mmts = await apiService.getAllMMTs();
      // Build lookup maps using model fields that actually exist.
      final Map<String, Tower> towerMap = {};
      for (final t in towers) {
        towerMap[_deviceKey(t.towerId)] = t;
        towerMap[_deviceKey('AP ${t.towerNumber}')] = t;
        towerMap[_deviceKey('AP${t.towerNumber}')] = t;
      }
      final cameraMap = {for (var c in cameras) _deviceKey(c.cameraId): c};
      final mmtMap = {for (var m in mmts) _deviceKey(m.mmtId): m};

      // Sync each alert
      return alerts.map((alert) {
        String? newLocation = alert.lokasi;
        String? newDeviceType = alert.deviceType;
        var isDeletedDevice = alert.isDeviceDeleted;

        // Try to match device name to find current location and type
        final searchName = _deviceKey(alert.title.split(' is ')[0]);

        // Check towers
        if (towerMap.containsKey(searchName)) {
          final tower = towerMap[searchName]!;
          newLocation = tower.location;
          newDeviceType = 'Tower';
          isDeletedDevice = false;
        }
        // Check cameras
        else if (cameraMap.containsKey(searchName)) {
          final camera = cameraMap[searchName]!;
          newLocation = camera.location;
          newDeviceType = 'CCTV';
          isDeletedDevice = false;
        }
        // Check MMTs
        else if (mmtMap.containsKey(searchName)) {
          final mmt = mmtMap[searchName]!;
          newLocation = mmt.location;
          newDeviceType = 'MMT';
          isDeletedDevice = false;
        } else {
          // Keep alert row visible but mark as deleted device in UI.
          isDeletedDevice = true;
        }

        // Sync with new data if found
        return alert.syncWithCurrentDeviceData(
          newLocation: newLocation,
          newDeviceType: newDeviceType,
          isDeviceDeleted: isDeletedDevice,
        );
      }).toList();
    } catch (e) {
      // If sync fails, return original alerts
      print('Alert sync error: $e');
      return alerts;
    }
  }

  String _deviceKey(String raw) {
    final s = raw.trim().toLowerCase();
    return s.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  bool _isDeviceDown(String status) {
    final s = status.toUpperCase().trim();
    return s == 'DOWN' ||
        s == 'OFFLINE' ||
        s == 'UNREACHABLE' ||
        s == 'WARNING';
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
    s = s.replaceAll(RegExp(r'\s+is\s+(up|down)\b', caseSensitive: false), '');
    return s.trim();
  }

  String _extractDeviceType(Alert alert) {
    if (alert.deviceType != null && alert.deviceType!.isNotEmpty) {
      final dt = alert.deviceType!.toLowerCase();
      if (dt.contains('tower') || dt.contains('ap')) return 'AP';
      if (dt.contains('camera') || dt.contains('cctv')) return 'CCTV';
      if (dt.contains('mmt')) return 'MMT';
    }

    final src = '${alert.title} ${alert.description} ${alert.lokasi ?? ''}'
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
      backgroundColor: AppDropdownStyle.standardPageBackground,
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/alerts'),
          Expanded(
            child: GlobalSidebarNav(
                currentRoute: '/alerts',
                enabled: !isMobile,
                child: _buildContent(isMobile)),
          ),
          const GlobalFooter(),
        ],
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    // We remove the early return for empty alerts so the layout always shows.
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
          selectedColor: const Color(0xFF1976D2).withValues(alpha: 0.45),
          checkmarkColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.12),
          side: BorderSide(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.22),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.88),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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
            const Color(0xFFFF1744)),
        _summaryChip(
            Icons.arrow_upward_rounded, '$feedUp UP', const Color(0xFF00E676)),
      ],
    );
  }

  Widget _summaryChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.75), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }

  // ==================== ALERT LIST ====================

  Widget _buildAlertList(List<Alert> filtered) {
    return liquidGlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Alert',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              _isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ))
                  : Text(
                      '${filtered.length} Alerts detected',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const SizedBox(
                height: 200,
                child: Center(
                    child: CircularProgressIndicator(color: Colors.white70)))
          else if (filtered.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.lightGreenAccent.shade200, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'No alerts available',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75), fontSize: 16),
                    ),
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
              itemBuilder: (context, index) => _buildAlertCard(filtered[index]),
            ),
        ],
      ),
    );
  }

  // ==================== ALERT CARD ====================

  Widget _buildAlertCard(Alert alert) {
    final isDown = _isDownAlert(alert);
    final statusColor =
        isDown ? const Color(0xFFFF1744) : const Color(0xFF00E676);
    final bgColor = isDown
        ? const Color(0xFFFF1744).withValues(alpha: 0.22)
        : const Color(0xFF00E676).withValues(alpha: 0.18);
    final deviceName = _cleanDeviceName(alert.title);
    final ip = _extractIpFromDescription(alert.description);
    final date = alert.tanggal ?? '-';
    final time = alert.waktu ?? '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: statusColor, width: 6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status indicator (icon, not text)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.35),
              shape: BoxShape.circle,
              border:
                  Border.all(color: statusColor.withValues(alpha: 0.9), width: 1.5),
            ),
            child: Icon(
              isDown
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deviceName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white),
                    overflow: TextOverflow.ellipsis),
                if (alert.isDeviceDeleted) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.75),
                        width: 1,
                      ),
                    ),
                                        child: const Text(
                                          'Deleted Device',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Wrap(
                  spacing: 16,
                  runSpacing: 2,
                  children: [
                    _infoRow(Icons.location_on_outlined, alert.lokasi ?? '-'),
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
                  color: statusColor.withValues(alpha: 0.4),
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
        Icon(icon, size: 13, color: Colors.white54),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.white60)),
      ],
    );
  }

  // ==================== TITLE SECTION ====================

  Widget _buildTitleSection(bool isMobile) {
    if (isMobile) {
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
                  Icons.notifications_active,
                  size: 30,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Alert Monitoring',
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
            'Monitoring View of Alert',
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
                  'Monitoring View of Alert',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
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
      ],
    );
  }

  // ==================== FOOTER ====================
}
