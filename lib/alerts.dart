import 'package:flutter/material.dart';
import 'dart:async';
import 'main.dart';
import 'services/api_service.dart';
import 'models/alert_model.dart';
import 'dashboard.dart';
import 'network.dart';
import 'cctv.dart';
import 'add_device.dart';
import 'profile.dart';
import 'report_page.dart';
import 'pages/tower_management.dart';
import 'pages/mmt_monitoring.dart';
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
  String _selectedDeviceType = 'All'; // Filter: All, AP, CCTV, MMT

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

  Future<void> _deleteAllAlerts() async {
    // 1. Tampilkan dialog konfirmasi dan simpan hasilnya di variabel 'isConfirmed'
    final bool isConfirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            // Gunakan nama variabel yang jelas
            return AlertDialog(
              title: const Text('Delete All Alert'),
              content:
                  const Text('Are You Sure Want To Delete All Notification?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop(false);
                  },
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.black87)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Delete All',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        ) ??
        false; // Jika dialog ditutup paksa (klik luar), beri nilai false

    // 2. Jalankan logika HANYA jika user menekan 'Delete All'
    if (isConfirmed) {
      setState(() => isLoading = true);

      try {
        final success = await apiService.deleteAllAlerts();

        if (success && mounted) {
          setState(() {
            alerts.clear(); // Bersihkan list di UI
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("All Alert Deleted Successfully"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Failed To Delete Alert"),
                backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) setState(() => isLoading = false);
        debugPrint("Error: $e");
      }
    }
  }
  // ==================== HEADER FUNCTIONS ====================

  Widget _buildHeader(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF1976D2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Terminal Nilam - FIXED
          const Text(
            'Terminal Nilam',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 30),
          // Buttons + Profile - SCROLL HORIZONTAL
          Expanded(
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeaderOpenButton(
                        'Add New Device', const AddDevicePage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton(
                        'Master Data', const TowerManagementPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Dashboard', const DashboardPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Access Point', const NetworkPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('CCTV', const CCTVPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('MMT', const MMTMonitoringPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Alert', const AlertsPage(),
                        isActive: true),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Alert Report', const ReportPage()),
                    const SizedBox(width: 12),
                    _buildHeaderButton(
                        'Logout', () => _showLogoutDialog(context)),
                    const SizedBox(width: 12),
                    _buildProfileIcon(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderOpenButton(String text, Widget openPage,
      {bool isActive = false}) {
    return buildLiquidGlassButton(text, () {
      // JIKA SUDAH AKTIF (berada di halaman Alert), JANGAN PINDAH KE MANA-MANA
      if (isActive) return;

      // Gunakan push biasa, JANGAN pushReplacement agar tidak merusak stack navigasi
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => openPage));
    }, isActive: isActive);
  }

  Widget _buildHeaderButton(String text, VoidCallback onPressed) {
    return buildLiquidGlassButton(text, onPressed);
  }

  void _showLogoutDialog(BuildContext context) {
    showLogoutDialog(context); // Memanggil fungsi global dari main.dart
  }

  void _showDeleteConfirmation(Alert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification',
            style: TextStyle(color: Colors.black87)),
        content: const Text('Are You Sure Want To Delete This Alert?',
            style: TextStyle(color: Colors.black87)),
        actions: [
          // Tombol Cancel (Flat)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.black87, fontSize: 16)),
          ),
          // Tombol Delete (Merah Lonjong/Stadium)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog dulu
              _deleteAlert(alert); // Langsung eksekusi hapus
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape:
                  const StadiumBorder(), // Membuat bentuk lonjong seperti tombol Logout
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileIcon() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ProfilePage()));
      },
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
                  spreadRadius: 1)
            ],
          ),
          child: const Icon(Icons.person, color: Color(0xFF1976D2), size: 24),
        ),
      ),
    );
  }

  // ==================== BODY & CONTENT ====================

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Stack(
        children: [
          Column(
            children: [
              const GlobalHeaderBar(currentRoute: '/alerts'),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sidebar (Kiri)
                    const GlobalSidebarNav(currentRoute: '/alerts'),
                    const SizedBox(width: 12),
                    // Content (Kanan)
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
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isMobile = isMobileScreen(context);
    final listHeight =
        (MediaQuery.of(context).size.height - 300).clamp(320.0, 3000.0);
    // Sort by timestamp (newest first)
    final sortedAlerts = alerts.toList()
      ..sort((a, b) {
        final aTime = DateTime.tryParse(a.timestamp);
        final bTime = DateTime.tryParse(b.timestamp);
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // Descending (newest first)
      });

    // Keep latest alert per device only to prevent repeated notifications.
    final latestPerDevice = <String, Alert>{};
    for (final alert in sortedAlerts) {
      final identity = _deviceIdentity(alert);
      latestPerDevice.putIfAbsent(identity, () => alert);
    }

    // Filter by device type, then split into UP/DOWN
    final filteredAlerts =
        _filterByDeviceType(latestPerDevice.values.toList(growable: false));
    final downAlerts =
        filteredAlerts.where((a) => _isDownAlert(a)).toList(growable: false);
    final upAlerts =
        filteredAlerts.where((a) => !_isDownAlert(a)).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleSection(isMobile),
        const SizedBox(height: 20),
        // Device Type Filter Buttons
        _buildDeviceTypeFilter(),
        const SizedBox(height: 16),
        if (alerts.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _deleteAllAlerts,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Delete All'),
            ),
          ),
        if (alerts.isNotEmpty) const SizedBox(height: 12),
        isMobile
            ? Column(
                children: [
                  _buildAlertStatusBox(
                    title: 'Device UP',
                    alertsData: upAlerts,
                    isDownBox: false,
                    listHeight: listHeight / 2,
                  ),
                  const SizedBox(height: 12),
                  _buildAlertStatusBox(
                    title: 'Device DOWN',
                    alertsData: downAlerts,
                    isDownBox: true,
                    listHeight: listHeight / 2,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildAlertStatusBox(
                      title: 'Device UP',
                      alertsData: upAlerts,
                      isDownBox: false,
                      listHeight: listHeight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAlertStatusBox(
                      title: 'Device DOWN',
                      alertsData: downAlerts,
                      isDownBox: true,
                      listHeight: listHeight,
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  bool _isDownAlert(Alert alert) {
    final titleLower = alert.title.toLowerCase();
    final descLower = alert.description.toLowerCase();
    final combinedText = '$titleLower $descLower';

    // Check if explicitly mentions DOWN or offline
    if (combinedText.contains(' down') ||
        combinedText.contains('is down') ||
        combinedText.contains('offline') ||
        combinedText.contains('unreachable')) {
      return true;
    }

    // Critical severity with no explicit UP mention
    if (alert.severity.toLowerCase() == 'critical' &&
        !combinedText.contains(' up') &&
        !combinedText.contains('is up')) {
      return true;
    }

    return false;
  }

  String _cleanDeviceName(String rawTitle) {
    var cleaned = rawTitle.trim();
    cleaned = cleaned.replaceAll(
        RegExp(r'\s+is\s+now\s+(up|down)\b', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(
        RegExp(r'\s+is\s+(up|down)\b', caseSensitive: false), '');
    return cleaned.trim();
  }

  String _deviceIdentity(Alert alert) {
    final fromTitle = _cleanDeviceName(alert.title).toUpperCase();
    if (fromTitle.isNotEmpty) return fromTitle;
    return alert.alertKey.toUpperCase();
  }

  String _resolveDeviceType(Alert alert) {
    final source = '${alert.title} ${alert.description} ${alert.lokasi ?? ''}'
        .toUpperCase();
    if (RegExp(r'\bAP\b').hasMatch(source)) return 'AP';
    if (RegExp(r'\b(CAM|CCTV)\b').hasMatch(source)) return 'CCTV';
    if (RegExp(r'\bMMT\b').hasMatch(source)) return 'MMT';
    return 'Other';
  }

  String _extractDeviceType(Alert alert) {
    return _resolveDeviceType(alert);
  }

  List<Alert> _filterByDeviceType(List<Alert> alertsList) {
    if (_selectedDeviceType == 'All') return alertsList;
    return alertsList
        .where((a) => _extractDeviceType(a) == _selectedDeviceType)
        .toList();
  }

  Widget _buildDeviceTypeFilter() {
    final filterOptions = ['All', 'AP', 'CCTV', 'MMT'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filterOptions.map((type) {
        final isSelected = _selectedDeviceType == type;
        return FilterChip(
          label: Text(type),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedDeviceType = type;
            });
          },
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

  Widget _buildAlertStatusBox({
    required String title,
    required List<Alert> alertsData,
    required bool isDownBox,
    required double listHeight,
  }) {
    final accent = isDownBox ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '${alertsData.length} device',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const Divider(height: 30),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(
              height: listHeight,
              child: ListView.separated(
                itemCount: alertsData.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _buildAlertItem(alertsData[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Alert alert) {
    // Gunakan fungsi yang sama dengan logika filter untuk konsistensi
    bool isDown = _isDownAlert(alert);
    Color statusColor = isDown ? Colors.red : Colors.green;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Container(
        decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 6))),
        child: ListTile(
          title: Text(_cleanDeviceName(alert.title),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle:
              Text("${alert.description}\n${alert.lokasi} - ${alert.tanggal}"),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              _showDeleteConfirmation(alert);
            },
          ),
        ),
      ),
    );
  }

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
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              if (_lastRefreshTime != null) ...[
                const SizedBox(width: 8),
                const Text('•', style: TextStyle(color: Colors.white70)),
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
    } else {
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
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
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
  }

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
