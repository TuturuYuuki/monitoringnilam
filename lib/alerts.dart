import 'package:flutter/material.dart';
import 'main.dart';

// Alerts & Notification Page
class AlertsPage extends StatefulWidget {
  const AlertsPage({Key? key}) : super(key: key);

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final List<Map<String, dynamic>> alerts = [
    {
      'title': 'CCTV camera offline',
      'description': 'CAM-GATE-A lost connection',
      'severity': 'critical',
      'timestamp': '5 minutes ago',
    },
    {
      'title': 'Container yard near capacity',
      'description': 'Yard 3 at 89% capacity (287/300 slot)',
      'severity': 'warning',
      'timestamp': '12 minutes ago',
    },
    {
      'title': 'High network latency detected',
      'description': 'Tower T3 experiencing latency of 45 ms',
      'severity': 'warning',
      'timestamp': '23 minutes ago',
    },
    {
      'title': 'Camera maintenance schedule',
      'description': 'CAM-Y3-01 schedule for maintenance today at 14:00',
      'severity': 'info',
      'timestamp': '1 hour ago',
    },
    {
      'title': 'CCTV camera offline',
      'description': 'CAM-GATE-B lost connection',
      'severity': 'critical',
      'timestamp': '2 hours ago',
    },
    {
      'title': 'Access switch high CPU',
      'description': 'Switch SW-12 at 92% CPU utilization',
      'severity': 'warning',
      'timestamp': '2 hours ago',
    },
    {
      'title': 'Unauthorized access attempt',
      'description': '3 failed login attempts detected on NMS',
      'severity': 'critical',
      'timestamp': '3 hours ago',
    },
    {
      'title': 'Packet loss detected',
      'description': 'Tower T9 reporting 8% packet loss',
      'severity': 'warning',
      'timestamp': '3 hours ago',
    },
    {
      'title': 'Firmware update available',
      'description': 'CCTV batch Y2 ready for firmware 3.2.1',
      'severity': 'info',
      'timestamp': '4 hours ago',
    },
    {
      'title': 'Power source unstable',
      'description': 'UPS-05 on battery for 12 minutes',
      'severity': 'warning',
      'timestamp': '4 hours ago',
    },
    {
      'title': 'Link down detected',
      'description': 'Fiber link CY2-T4 to core is down',
      'severity': 'critical',
      'timestamp': '4 hours ago',
    },
    {
      'title': 'Storage threshold reached',
      'description': 'NVR-02 storage at 91% usage',
      'severity': 'warning',
      'timestamp': '5 hours ago',
    },
    {
      'title': 'Temperature high',
      'description': 'Rack R3 temperature at 37°C',
      'severity': 'warning',
      'timestamp': '6 hours ago',
    },
  ];

  late int criticalCount;
  late int warningCount;
  late int infoCount;

  @override
  void initState() {
    super.initState();
    _calculateAlertStats();
  }

  void _calculateAlertStats() {
    criticalCount = alerts.where((a) => a['severity'] == 'critical').length;
    warningCount = alerts.where((a) => a['severity'] == 'warning').length;
    infoCount = alerts.where((a) => a['severity'] == 'info').length;
  }

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.all(16.0),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Section
        const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange, size: 32),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerts & Notification',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Monitor and manage system alerts & notification',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Main Content Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Panel - Alerts List
            Expanded(
              flex: 2,
              child: _buildAlertsList(),
            ),
            const SizedBox(width: 20),
            // Right Panel - Statistics
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

  Widget _buildAlertsList() {
    final screenHeight = MediaQuery.of(context).size.height;
    final listHeight = (screenHeight - 280).clamp(360.0, 900.0);

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
          SizedBox(
            height: listHeight,
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  return _buildAlertItem(alerts[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    Color severityColor;
    IconData severityIcon;

    switch (alert['severity']) {
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

    return Container(
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
                  alert['title'],
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert['description'],
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  alert['timestamp'],
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
          _buildCategoryBar('Network', 2, Colors.yellow),
          const SizedBox(height: 12),
          _buildCategoryBar('CCTV', 3, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(String category, int count, Color color) {
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
                  flex: count,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  flex: 5 - count,
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
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
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
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
