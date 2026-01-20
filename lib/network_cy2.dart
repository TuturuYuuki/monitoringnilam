import 'package:flutter/material.dart';
import 'main.dart';

// Network Page CY 2
class NetworkCY2Page extends StatefulWidget {
  const NetworkCY2Page({Key? key}) : super(key: key);

  @override
  State<NetworkCY2Page> createState() => _NetworkCY2PageState();
}

class _NetworkCY2PageState extends State<NetworkCY2Page> {
  String selectedTower = 'CY 2';
  int currentPage = 0;
  final int itemsPerPage = 5;

  final List<Map<String, dynamic>> towerData = [
    {
      'id': 'T1',
      'location': 'Container Yard 2',
      'ip': '192.168.20.1',
      'device': '2 CCTV',
      'status': 'UP',
      'traffic': '178 Mbps',
      'uptime': '99.5%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T2',
      'location': 'Container Yard 2',
      'ip': '192.168.20.2',
      'device': '3 CCTV',
      'status': 'UP',
      'traffic': '205 Mbps',
      'uptime': '98.8%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T3',
      'location': 'Container Yard 2',
      'ip': '192.168.20.3',
      'device': '1 CCTV',
      'status': 'Warning',
      'traffic': '89 Mbps',
      'uptime': '96.5%',
      'statusColor': Colors.red,
    },
    {
      'id': 'T4',
      'location': 'Container Yard 2',
      'ip': '192.168.20.4',
      'device': '2 CCTV',
      'status': 'UP',
      'traffic': '192 Mbps',
      'uptime': '99.2%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T5',
      'location': 'Container Yard 2',
      'ip': '192.168.20.5',
      'device': '3 CCTV',
      'status': 'UP',
      'traffic': '167 Mbps',
      'uptime': '97.8%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T6',
      'location': 'Container Yard 2',
      'ip': '192.168.20.6',
      'device': '2 CCTV',
      'status': 'UP',
      'traffic': '215 Mbps',
      'uptime': '99.7%',
      'statusColor': Colors.green,
    },
  ];

  List<Map<String, dynamic>> get paginatedData {
    int start = currentPage * itemsPerPage;
    int end = (start + itemsPerPage > towerData.length)
        ? towerData.length
        : start + itemsPerPage;
    return towerData.sublist(start, end);
  }

  int get totalPages => (towerData.length / itemsPerPage).ceil();

  int get totalTowers => towerData.length;
  int get onlineTowers => towerData.where((t) => t['status'] == 'UP').length;
  int get warningTowers =>
      towerData.where((t) => t['status'] == 'Warning').length;

  void _showWarningList() {
    final warnings = towerData.where((t) => t['status'] == 'Warning').toList();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_rounded, color: Colors.red, size: 22),
              const SizedBox(width: 8),
              Text(
                'Towers DOWN (${warnings.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 350,
              maxHeight: 300,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (warnings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Semua tower dalam kondisi UP.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...warnings.map((t) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t['id'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DOWN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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
                    padding: const EdgeInsets.all(20.0),
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
          _buildHeaderButton('Network', () {}, isActive: true),
          const SizedBox(width: 12),
          _buildHeaderButton('CCTV', () {
            navigateWithLoading(context, '/cctv');
          }, isActive: false),
          const SizedBox(width: 12),
          _buildHeaderButton('Alerts', () {
            navigateWithLoading(context, '/alerts');
          }, isActive: false),
          const SizedBox(width: 12),
          _buildHeaderButton('Logout', () {
            _showLogoutDialog(context);
          }, isActive: false),
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.language,
                  size: 32, color: Color(0xFF1976D2)),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Network Monitoring',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Real time network infrastructure monitoring and diagnostics',
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

        // Stats Cards Row
        LayoutBuilder(
          builder: (context, constraints) {
            double cardWidth = constraints.maxWidth > 1400
                ? (constraints.maxWidth - 100) / 5
                : (constraints.maxWidth - 80) / 3;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatCard('Total Tower', '$totalTowers', Colors.orange,
                    width: cardWidth),
                _buildStatCard('UP', '$onlineTowers', Colors.green,
                    width: cardWidth),
                _buildStatCard(
                    'DOWN',
                    '${towerData.where((t) => t['status'] == 'Warning').length}',
                    Colors.blue,
                    onTap: _showWarningList,
                    width: cardWidth),
                _buildNetworkDropdown(cardWidth),
                _buildContainerYardButton(cardWidth),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Main Content Row
        LayoutBuilder(
          builder: (context, constraints) {
            bool isWideScreen = constraints.maxWidth > 1200;

            if (isWideScreen) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildTowerList(),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 5,
                    child: _buildNetworkTrafficChart(),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildTowerList(),
                  const SizedBox(height: 20),
                  _buildNetworkTrafficChart(),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color indicatorColor,
      {VoidCallback? onTap, double? width}) {
    final card = Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: card,
      ),
    );
  }

  Widget _buildNetworkDropdown(double width) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF4A5F7F),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CCTV',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedDropdownButton(
                value: selectedTower,
                items: const ['CY 1', 'CY 2', 'CY 3'],
                backgroundColor: const Color(0xFF4A5F7F),
                onChanged: (String? newValue) {
                  if (newValue == null) return;
                  setState(() {
                    selectedTower = newValue;
                    currentPage = 0;
                  });
                  if (newValue == 'CY 1') {
                    navigateWithLoading(context, '/network');
                  } else if (newValue == 'CY 2') {
                    navigateWithLoading(context, '/network-cy2');
                  } else if (newValue == 'CY 3') {
                    navigateWithLoading(context, '/network-cy3');
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContainerYardButton(double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF5D6D7E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'Container\nYard 2',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTowerList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tower List',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black54, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      _buildPagerIcon(
                        Icons.chevron_left,
                        currentPage > 0
                            ? () {
                                setState(() {
                                  currentPage--;
                                });
                              }
                            : null,
                      ),
                      const SizedBox(width: 12),
                      ...List.generate(totalPages, (index) {
                        bool isActive = index == currentPage;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? const Color(0xFF1976D2)
                                  : Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 12),
                      _buildPagerIcon(
                        Icons.chevron_right,
                        currentPage < totalPages - 1
                            ? () {
                                setState(() {
                                  currentPage++;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFC6B430),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _buildHeaderCell('Tower ID', flex: 1),
                _buildHeaderCell('Lokasi', flex: 2),
                _buildHeaderCell('IP Address', flex: 2),
                _buildHeaderCell('Device', flex: 2),
                _buildHeaderCell('Status', flex: 1),
              ],
            ),
          ),

          // Table Rows
          ...paginatedData.map((tower) => _buildTableRow(tower)).toList(),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> tower) {
    bool isWarning = tower['status'] == 'Warning';
    String statusLabel = isWarning ? 'DOWN' : tower['status'];
    Color statusTextColor = isWarning ? Colors.red : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8D5C4),
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          _tableCell(tower['id'], flex: 1, fontWeight: FontWeight.w800),
          _tableCell(tower['location'], flex: 2, fontWeight: FontWeight.w800),
          _tableCell(tower['ip'], flex: 2),
          _tableCell(tower['device'], flex: 2),
          _tableCell(statusLabel,
              flex: 1, fontWeight: FontWeight.w800, color: statusTextColor),
        ],
      ),
    );
  }

  Widget _buildPagerIcon(IconData icon, VoidCallback? onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.black87.withOpacity(onPressed == null ? 0.2 : 0.6),
            width: 1.2,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onPressed == null ? Colors.black26 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String label, {required int flex}) {
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

  Widget _tableCell(String text,
      {required int flex,
      FontWeight fontWeight = FontWeight.w700,
      Color color = Colors.black,
      TextAlign align = TextAlign.center}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          color: color,
          fontWeight: fontWeight,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildNetworkTrafficChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: const Center(
              child: Text(
                'Network Traffic',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Chart Area
          Container(
            height: 400,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Chart visualization
                CustomPaint(
                  size: const Size(double.infinity, 400),
                  painter: NetworkTrafficPainter(),
                ),
                // Time labels
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('00:00',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black54)),
                      Text('12:00',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black54)),
                      Text('23:59',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  void _showTowerDetails(Map<String, dynamic> tower) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tower ${tower['id']} Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${tower['location']}'),
            const SizedBox(height: 8),
            Text('Status: ${tower['status']}'),
            const SizedBox(height: 8),
            Text('Traffic: ${tower['traffic']}'),
            const SizedBox(height: 8),
            Text('Uptime: ${tower['uptime']}'),
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
}

// Custom Painter for Network Traffic Chart
class NetworkTrafficPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF5C6BC0).withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = const Color(0xFF42A5F5).withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final paint3 = Paint()
      ..color = const Color(0xFFEC407A).withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Generate random mountain-like shapes
    final path1 = Path();
    final path2 = Path();
    final path3 = Path();

    path1.moveTo(0, size.height);
    path2.moveTo(0, size.height);
    path3.moveTo(0, size.height);

    for (int i = 0; i <= 50; i++) {
      double x = (size.width / 50) * i;
      double y1 = size.height - (size.height * 0.3) - ((i % 7) * 30);
      double y2 = size.height - (size.height * 0.5) - ((i % 5) * 25);
      double y3 = size.height - (size.height * 0.2) - ((i % 6) * 20);

      if (i == 0) {
        path1.lineTo(x, y1);
        path2.lineTo(x, y2);
        path3.lineTo(x, y3);
      } else {
        path1.lineTo(x, y1);
        path2.lineTo(x, y2);
        path3.lineTo(x, y3);
      }
    }

    path1.lineTo(size.width, size.height);
    path2.lineTo(size.width, size.height);
    path3.lineTo(size.width, size.height);

    path1.close();
    path2.close();
    path3.close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
