import 'package:flutter/material.dart';
import 'main.dart';
import 'services/api_service.dart';
import 'models/tower_model.dart';

// Network Page
class NetworkPage extends StatefulWidget {
  const NetworkPage({Key? key}) : super(key: key);

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  String selectedTower = 'CY 1';
  int currentPage = 0;
  final int itemsPerPage = 5;
  late ApiService apiService;
  List<Tower> towers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _loadTowers();
  }

  Future<void> _loadTowers() async {
    try {
      final fetchedTowers = await apiService.getTowersByContainerYard('CY1');
      setState(() {
        towers = fetchedTowers;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading towers: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  final List<Map<String, dynamic>> towerData = [
    {
      'id': 'T7',
      'location': 'Container Yard 1',
      'ip': '192.168.10.1',
      'device': '3 CCTV',
      'status': 'UP',
      'traffic': '156 Mbps',
      'uptime': '99.8%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T8',
      'location': 'Container Yard 1',
      'ip': '192.168.10.2',
      'device': '1 CCTV',
      'status': 'UP',
      'traffic': '231 Mbps',
      'uptime': '99.9%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T9',
      'location': 'Container Yard 1',
      'ip': '192.168.10.3',
      'device': '2 CCTV',
      'status': 'UP',
      'traffic': '187 Mbps',
      'uptime': '97.2%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T10',
      'location': 'Container Yard 1',
      'ip': '192.168.10.4',
      'device': '2 CCTV',
      'status': 'Warning',
      'traffic': '98 Mbps',
      'uptime': '99.5%',
      'statusColor': Colors.red,
    },
    {
      'id': 'T11',
      'location': 'Container Yard 1',
      'ip': '192.168.10.5',
      'device': '3 CCTV',
      'status': 'UP',
      'traffic': '180 Mbps',
      'uptime': '80%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T12',
      'location': 'Container Yard 1',
      'ip': '192.168.10.6',
      'device': '2 CCTV',
      'status': 'UP',
      'traffic': '145 Mbps',
      'uptime': '98.5%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T12A',
      'location': 'Container Yard 1',
      'ip': '192.168.10.7',
      'device': '2 CCTV',
      'status': 'UP',
      'traffic': '165 Mbps',
      'uptime': '99.2%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T13',
      'location': 'Container Yard 1',
      'ip': '192.168.10.8',
      'device': '1 CCTV',
      'status': 'Warning',
      'traffic': '67 Mbps',
      'uptime': '95.2%',
      'statusColor': Colors.red,
    },
    {
      'id': 'T14',
      'location': 'Container Yard 1',
      'ip': '192.168.10.9',
      'device': '2 CCTV',
      'status': 'UP',
      'traffic': '203 Mbps',
      'uptime': '99.1%',
      'statusColor': Colors.green,
    },
    {
      'id': 'T15',
      'location': 'Container Yard 1',
      'ip': '192.168.10.10',
      'device': '3 CCTV',
      'status': 'UP',
      'traffic': '189 Mbps',
      'uptime': '98.8%',
      'statusColor': Colors.green,
    },
  ];

  int get totalTowers => towers.length;
  int get onlineTowers => towers.where((t) => t.status == 'UP').length;
  int get warningTowers => towers.where((t) => t.status == 'Warning').length;

  void _showWarningList() {
    final warnings = towers.where((t) => t.status == 'Warning').toList();
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
                            t.towerId,
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

  List<Tower> get paginatedData {
    int start = currentPage * itemsPerPage;
    int end = (start + itemsPerPage > towers.length)
        ? towers.length
        : start + itemsPerPage;
    return towers.sublist(start, end);
  }

  int get totalPages => (towers.length / itemsPerPage).ceil();

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

  Widget _buildHeader(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24, vertical: isMobile ? 12 : 16),
      color: const Color(0xFF1976D2),
      child: isMobile
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Terminal Nilam',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 18 : 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          navigateWithLoading(context, '/profile');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF1976D2),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _buildHeaderButton('Dashboard', () {
                      navigateWithLoading(context, '/dashboard');
                    }, isActive: false),
                    _buildHeaderButton('Network', () {}, isActive: true),
                    _buildHeaderButton('CCTV', () {
                      navigateWithLoading(context, '/cctv');
                    }, isActive: false),
                    _buildHeaderButton('Alerts', () {
                      navigateWithLoading(context, '/alerts');
                    }, isActive: false),
                    _buildHeaderButton('Logout', () {
                      _showLogoutDialog(context);
                    }, isActive: false),
                  ],
                )
              ],
            )
          : Row(
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
                const SizedBox(width: 12),
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
                child: const Icon(Icons.language,
                    size: 24, color: Color(0xFF1976D2)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Network',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Monitoring real-time',
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
        const SizedBox(height: 16),

        // Stats Cards Row with Dropdown
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
                            _buildStatCard(
                                'Total Tower', '$totalTowers', Colors.orange,
                                width: cardWidth),
                            SizedBox(width: isMobile ? 8 : 16),
                            _buildStatCard('UP', '$onlineTowers', Colors.green,
                                width: cardWidth),
                            SizedBox(width: isMobile ? 8 : 16),
                            _buildStatCard(
                                'DOWN', '$warningTowers', Colors.blue,
                                onTap: _showWarningList, width: cardWidth),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildNetworkDropdown(constraints.maxWidth),
                      const SizedBox(height: 12),
                      _buildContainerYardButton(constraints.maxWidth),
                    ],
                  )
                : Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildStatCard(
                          'Total Tower', '$totalTowers', Colors.orange,
                          width: cardWidth),
                      _buildStatCard('UP', '$onlineTowers', Colors.green,
                          width: cardWidth),
                      _buildStatCard('DOWN', '$warningTowers', Colors.red,
                          onTap: _showWarningList, width: cardWidth),
                      _buildNetworkDropdown(cardWidth),
                      _buildContainerYardButton(cardWidth),
                    ],
                  );
          },
        ),
        const SizedBox(height: 16),

        // Tower List
        _buildTowerList(),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color indicatorColor,
      {VoidCallback? onTap, double? width}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = isMobileScreen(context);
        final card = Container(
          width: width,
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: isMobile ? 10 : 12,
                    height: isMobile ? 10 : 12,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 8 : 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 20 : 28,
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
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: card,
          ),
        );
      },
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
          'Container\nYard 1',
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
    // Show loading indicator
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
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
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Memuat data tower...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state if no data
    if (towers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
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
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.signal_wifi_off,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Tidak ada data tower',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Belum ada tower yang terdaftar untuk Container Yard 1',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Show data table when towers exist
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
            decoration: const BoxDecoration(
              color: Color(0xFFC6B430),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                left: BorderSide(color: Color(0xFF9C8F2B), width: 1),
                right: BorderSide(color: Color(0xFF9C8F2B), width: 1),
                bottom: BorderSide(color: Color(0xFF9C8F2B), width: 1),
              ),
            ),
            child: Row(
              children: [
                _buildHeaderCell('Tower ID', flex: 1),
                _buildHeaderCell('Lokasi', flex: 2),
                _buildHeaderCell('IP Address', flex: 2),
                _buildHeaderCell('Device', flex: 2),
                _buildHeaderCell('Status', flex: 1, isLast: true),
              ],
            ),
          ),

          // Table Rows
          ...paginatedData.map((tower) => _buildTableRow(tower)).toList(),
        ],
      ),
    );
  }

  Widget _buildTableRow(Tower tower) {
    bool isWarning = tower.status == 'Warning';
    String statusLabel = isWarning ? 'DOWN' : tower.status;
    Color statusTextColor = isWarning ? Colors.red : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8D5C4),
        border: Border(
          left: BorderSide(color: Colors.grey[500]!, width: 1),
          right: BorderSide(color: Colors.grey[500]!, width: 1),
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          _tableCell(tower.towerId, flex: 1, fontWeight: FontWeight.w800),
          _tableCell(tower.location, flex: 2, fontWeight: FontWeight.w800),
          _tableCell(tower.ipAddress, flex: 2),
          _tableCell('${tower.deviceCount} CCTV', flex: 2),
          _tableCell(statusLabel,
              flex: 1,
              fontWeight: FontWeight.w800,
              color: statusTextColor,
              isLast: true),
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

  Widget _buildHeaderCell(String label,
      {required int flex, bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: isLast
                ? BorderSide.none
                : BorderSide(color: Colors.white.withOpacity(0.35), width: 1),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _tableCell(String text,
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
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            color: color,
            fontWeight: fontWeight,
            fontSize: 14,
          ),
        ),
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
          Text(
            'Last Update: 2 Minutes Ago',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
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
