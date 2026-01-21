import 'package:flutter/material.dart';
import 'main.dart';
import 'services/api_service.dart';
import 'models/alert_model.dart';

// Alerts & Notification Page
class AlertsPage extends StatefulWidget {
  const AlertsPage({Key? key}) : super(key: key);

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  late ApiService apiService;
  List<Alert> alerts = [];
  bool isLoading = true;
  final List<Map<String, dynamic>> alertsOld = [
    {
      'title': 'CCTV DOWN - CY1 Cam-12',
      'description': 'Parking Area (CY1) camera offline (Cam-12)',
      'severity': 'critical',
      'timestamp': '5 minutes ago',
      'route': '/cctv',
    },
    {
      'title': 'CCTV DOWN - CY1 Cam-13',
      'description': 'Loading Dock (CY1) camera offline (Cam-13)',
      'severity': 'critical',
      'timestamp': '4 minutes ago',
      'route': '/cctv',
    },
    {
      'title': 'CCTV DOWN - CY1 Cam-15',
      'description': 'Office Area (CY1) camera offline (Cam-15)',
      'severity': 'critical',
      'timestamp': '3 minutes ago',
      'route': '/cctv',
    },
    {
      'title': 'CCTV DOWN - CY2 Cam-31',
      'description': 'Container Yard 2 camera offline (Cam-31)',
      'severity': 'critical',
      'timestamp': '10 minutes ago',
      'route': '/cctv-cy2',
    },
    {
      'title': 'CCTV DOWN - CY3 Cam-16',
      'description': 'Container Yard 3 camera offline (Cam-16)',
      'severity': 'critical',
      'timestamp': '18 minutes ago',
      'route': '/cctv-cy3',
    },
    {
      'title': 'Tower WARNING - CY1 T10',
      'description': 'Tower T10 (CY1) latency/packet loss detected',
      'severity': 'warning',
      'timestamp': '23 minutes ago',
      'route': '/network',
    },
    {
      'title': 'Tower WARNING - CY2 T3',
      'description': 'Tower T3 (CY2) degraded performance',
      'severity': 'warning',
      'timestamp': '45 minutes ago',
      'route': '/network-cy2',
    },
    {
      'title': 'Tower WARNING - CY3 T14',
      'description': 'Tower T14 (CY3) degraded performance',
      'severity': 'warning',
      'timestamp': '1 hour ago',
      'route': '/network-cy3',
    },
    {
      'title': 'Tower WARNING - CY3 T16',
      'description': 'Tower T16 (CY3) degraded performance',
      'severity': 'warning',
      'timestamp': '1 hour ago',
      'route': '/network-cy3',
    },
  ];

  List<Alert> get activeAlerts => alerts
      .where((a) => a.severity == 'critical' || a.severity == 'warning')
      .toList();
  int get criticalCount =>
      activeAlerts.where((a) => a.severity == 'critical').length;
  int get warningCount =>
      activeAlerts.where((a) => a.severity == 'warning').length;
  int get infoCount => alerts.where((a) => a.severity == 'info').length;

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final fetchedAlerts = await apiService.getAllAlerts();
      setState(() {
        alerts = fetchedAlerts;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading alerts: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

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
                    padding: EdgeInsets.all(isMobile ? 8 : 16.0),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF1976D2),
      child: Row(
        children: [
          const Text(
            'Terminal Nilam',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _buildHeaderButton('Dashboard', () {
            navigateWithLoading(context, '/dashboard');
          }, isActive: false),
          const SizedBox(width: 12),
          _buildHeaderButton('Network', () {
            navigateWithLoading(context, '/network');
          }, isActive: false),
          const SizedBox(width: 12),
          _buildHeaderButton('CCTV', () {
            navigateWithLoading(context, '/cctv');
          }, isActive: false),
          const SizedBox(width: 12),
          _buildHeaderButton('Alerts', () {
            // Already on Alerts
          }, isActive: true),
          const SizedBox(width: 12),
          _buildHeaderButton('Logout', () {
            _showLogoutDialog(context);
          }, isActive: false),
          const SizedBox(width: 12),
          // Profile Icon
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                navigateWithLoading(context, '/profile');
              },
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
    );
  }

  Widget _buildHeaderButton(String text, VoidCallback onPressed,
      {bool isActive = false}) {
    return buildLiquidGlassButton(text, onPressed, isActive: isActive);
  }

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    final isMobile = isMobileScreen(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final listHeight = (screenHeight - 280).clamp(360.0, 900.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Section
        Row(
          children: [
            Icon(Icons.warning_rounded,
                color: Colors.orange, size: isMobile ? 24 : 32),
            SizedBox(width: isMobile ? 12 : 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 20 : 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isMobile
                      ? 'Notifications'
                      : 'Monitor and manage system alerts & notification',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Main Content Row or Column based on screen size
        if (isMobile)
          Column(
            children: [
              _buildAlertsList(listHeight),
              const SizedBox(height: 20),
              _buildAlertStatistics(),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildAlertsList(listHeight),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: constraints.maxWidth > 1200
                    ? 350
                    : constraints.maxWidth * 0.3,
                child: Column(
                  children: [
                    _buildAlertStatistics(),
                    const SizedBox(height: 20),
                    _buildAlertsByCategory(),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAlertsList(double listHeight) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Alerts',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (activeAlerts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No active alerts right now',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ),
            )
          else
            SizedBox(
              height: listHeight,
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  itemCount: activeAlerts.length,
                  itemBuilder: (context, index) {
                    return _buildAlertItem(activeAlerts[index]);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Alert alert) {
    Color severityColor;
    IconData severityIcon;

    switch (alert.severity) {
      case 'critical':
        severityColor = Colors.red;
        severityIcon = Icons.error;
        break;
      case 'warning':
        severityColor = Colors.orange;
        severityIcon = Icons.warning;
        break;
      case 'info':
        severityColor = Colors.blue;
        severityIcon = Icons.info;
        break;
      default:
        severityColor = Colors.grey;
        severityIcon = Icons.info;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          navigateWithLoading(context, alert.route);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: severityColor, width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(severityIcon, color: severityColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.description,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alert.timestamp,
                      style: const TextStyle(
                        color: Colors.black38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  // Delete alert
                },
                iconSize: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertStatistics() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alerts Statistics',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildStatRow('Critical Alert', criticalCount.toString(), Colors.red),
          const SizedBox(height: 12),
          _buildStatRow(
              'Warning Alert', warningCount.toString(), Colors.orange),
          const SizedBox(height: 12),
          _buildStatRow('Info Alert', infoCount.toString(), Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsByCategory() {
    final categories = _alertsByCategory();
    final total = activeAlerts.length;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alerts by Category',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            const Text(
              'No active alerts by category',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            )
          else ...[
            _buildCategoryBar('Network', categories['Network']!.length, total,
                _categoryColor(categories['Network']!)),
            const SizedBox(height: 12),
            _buildCategoryBar('CCTV', categories['CCTV']!.length, total,
                _categoryColor(categories['CCTV']!)),
            if (categories['Other']!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildCategoryBar('Other', categories['Other']!.length, total,
                  _categoryColor(categories['Other']!)),
            ],
          ],
        ],
      ),
    );
  }

  Map<String, List<Alert>> _alertsByCategory() {
    final categories = {
      'Network': <Alert>[],
      'CCTV': <Alert>[],
      'Other': <Alert>[],
    };

    for (final alert in activeAlerts) {
      final route = alert.route.toLowerCase();
      if (route.contains('network')) {
        categories['Network']!.add(alert);
      } else if (route.contains('cctv')) {
        categories['CCTV']!.add(alert);
      } else {
        categories['Other']!.add(alert);
      }
    }

    return categories;
  }

  Color _categoryColor(List<Alert> list) {
    if (list.any((a) => a.severity == 'critical')) return Colors.red;
    if (list.any((a) => a.severity == 'warning')) return Colors.orange;
    if (list.any((a) => a.severity == 'info')) return Colors.blue;
    return Colors.grey;
  }

  Widget _buildCategoryBar(String category, int count, int total, Color color) {
    final safeTotal = total == 0 ? 1 : total;
    final filledFlex = count == 0 ? 1 : count;
    final emptyFlex = (safeTotal - count) <= 0 ? 1 : safeTotal - count;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$count alerts',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: filledFlex,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  flex: emptyFlex,
                  child: Container(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout', style: TextStyle(color: Colors.black87)),
        content: const Text('Apakah Anda yakin ingin keluar?',
            style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.black87)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
