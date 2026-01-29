import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'main.dart';
import 'route_proxy_page.dart';
import 'services/api_service.dart';

// CCTV Page CY 3
class CCTVCy3Page extends StatefulWidget {
  const CCTVCy3Page({super.key});

  @override
  State<CCTVCy3Page> createState() => _CCTVCy3PageState();
}

class _CCTVCy3PageState extends State<CCTVCy3Page> {
  String selectedYard = 'CY 3';
  int currentPage = 0;
  final int camerasPerPage = 8;
  bool isLoading = false;

  final List<Map<String, dynamic>> allCameras = [];

  List<Map<String, dynamic>> get paginatedCameras {
    int start = currentPage * camerasPerPage;
    int end = (start + camerasPerPage > allCameras.length)
        ? allCameras.length
        : start + camerasPerPage;
    return allCameras.sublist(start, end);
  }

  int get totalPages => (allCameras.length / camerasPerPage).ceil();
  int get upCameras => allCameras.where((c) => c['status'] == 'UP').length;
  int get downCameras => allCameras.where((c) => c['status'] == 'DOWN').length;

  void _showOfflineList() {
    final offlines = allCameras.where((c) => c['status'] == 'DOWN').toList();
    showFadeAlertDialog(
      context: context,
      title: 'Cameras DOWN (${offlines.length})',
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 350,
          maxHeight: 400,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (offlines.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Semua kamera dalam kondisi UP.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...offlines.map((c) {
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
                          c['id'],
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
                }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    try {
      setState(() {
        isLoading = true;
      });

      final apiService = ApiService();
      final cameras = await apiService.getCamerasByContainerYard('CY3');

      setState(() {
        allCameras.clear();
        final camerasMap = cameras
            .map((c) => {
                  'id': c.cameraId,
                  'location': c.location,
                  'status': c.status,
                  'type': c.type,
                })
            .toList();
        camerasMap
            .sort((a, b) => a['id'].toString().compareTo(b['id'].toString()));
        allCameras.addAll(camerasMap);
        isLoading = false;
        currentPage = 0;
      });
    } catch (e) {
      print('Error loading cameras: $e');
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
                    padding: EdgeInsets.all(isMobile ? 12 : 20.0),
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
                      child: OpenContainer(
                        transitionDuration: const Duration(milliseconds: 550),
                        transitionType: ContainerTransitionType.fadeThrough,
                        closedElevation: 0,
                        closedColor: Colors.transparent,
                        closedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        openElevation: 0,
                        openBuilder: (context, _) =>
                            const RouteProxyPage('/profile'),
                        closedBuilder: (context, openContainer) {
                          return GestureDetector(
                            onTap: openContainer,
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
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _buildHeaderOpenButton('Dashboard', '/dashboard',
                        isActive: false),
                    _buildHeaderOpenButton('Network', '/network',
                        isActive: false),
                    _buildHeaderOpenButton('CCTV', '/cctv', isActive: true),
                    _buildHeaderOpenButton('Alerts', '/alerts',
                        isActive: false),
                    _buildHeaderLogoutButton(),
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
                _buildHeaderOpenButton('Dashboard', '/dashboard'),
                const SizedBox(width: 12),
                _buildHeaderOpenButton('Network', '/network'),
                const SizedBox(width: 12),
                _buildHeaderOpenButton('CCTV', '/cctv', isActive: true),
                const SizedBox(width: 12),
                _buildHeaderOpenButton('Alerts', '/alerts'),
                const SizedBox(width: 12),
                _buildHeaderLogoutButton(),
                const SizedBox(width: 12),
                // Profile icon shortcut to profile page
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: OpenContainer(
                    transitionDuration: const Duration(milliseconds: 550),
                    transitionType: ContainerTransitionType.fadeThrough,
                    closedElevation: 0,
                    closedColor: Colors.transparent,
                    closedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    openElevation: 0,
                    openBuilder: (context, _) =>
                        const RouteProxyPage('/profile'),
                    closedBuilder: (context, openContainer) {
                      return GestureDetector(
                        onTap: openContainer,
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
                      );
                    },
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

  Widget _buildHeaderOpenButton(String text, String route,
      {bool isActive = false}) {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 550),
      transitionType: ContainerTransitionType.fadeThrough,
      closedElevation: 0,
      closedColor: Colors.transparent,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      openElevation: 0,
      openBuilder: (context, _) => RouteProxyPage(route),
      closedBuilder: (context, openContainer) {
        return buildLiquidGlassButton(text, openContainer, isActive: isActive);
      },
    );
  }

  Widget _buildHeaderLogoutButton() {
    return buildLiquidGlassButton('Logout', () => _showLogoutDialog(context),
        isActive: false);
  }

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.videocam, size: 40, color: Colors.white),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CCTV Monitoring',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Live camera feeds and surveillance system status',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Spacer(),
            // Fullscreen Button
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => navigateWithLoading(context, '/cctv-fullscreen'),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            double cardWidth = constraints.maxWidth > 1400
                ? (constraints.maxWidth - 100) / 5
                : (constraints.maxWidth - 80) / 3;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatCard('Total Camera', '${allCameras.length}',
                    Colors.orange, cardWidth),
                _buildStatCard('UP', '$upCameras', Colors.green, cardWidth),
                GestureDetector(
                  onTap: _showOfflineList,
                  child: _buildStatCard(
                      'DOWN', '$downCameras', Colors.red, cardWidth),
                ),
                _buildCCTVDropdown(cardWidth),
                _buildContainerYardButton(cardWidth),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _buildCameraGrid(constraints),
        const SizedBox(height: 24),
        _buildPagination(),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, Color indicatorColor, double width) {
    return Container(
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
  }

  Widget _buildCCTVDropdown(double width) {
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
                value: selectedYard,
                items: const ['CY 1', 'CY 2', 'CY 3', 'Parking', 'Gate'],
                backgroundColor: const Color(0xFF4A5F7F),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedYard = newValue;
                    });
                    if (newValue == 'CY 1') {
                      navigateWithLoading(context, '/cctv');
                    } else if (newValue == 'CY 2') {
                      navigateWithLoading(context, '/cctv-cy2');
                    } else if (newValue == 'CY 3') {
                      // Already on CY 3
                    } else if (newValue == 'Parking') {
                      navigateWithLoading(context, '/parking-cctv');
                    } else if (newValue == 'Gate') {
                      navigateWithLoading(context, '/gate-cctv');
                    }
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
          'Container\nYard 3',
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

  Widget _buildCameraGrid(BoxConstraints constraints) {
    // Show loading indicator
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Memuat data kamera...',
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

    // Show empty state if no cameras
    if (allCameras.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Tidak ada kamera',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Belum ada kamera yang terdaftar untuk Container Yard 3',
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

    // Show camera grid when data exists
    final isMobile = isMobileScreen(context);
    int crossAxisCount = isMobile
        ? 1
        : constraints.maxWidth > 1400
            ? 4
            : constraints.maxWidth > 1000
                ? 3
                : 2;

    double childAspectRatio = isMobile ? 1.0 : 1.2;
    double spacing = isMobile ? 12 : 20;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: paginatedCameras.length,
      itemBuilder: (context, index) {
        return _buildCameraCard(paginatedCameras[index]);
      },
    );
  }

  Widget _buildCameraCard(Map<String, dynamic> camera) {
    bool isUp = camera['status'] == 'UP';
    Color statusColor = isUp ? Colors.green : Colors.red;

    return Container(
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
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.videocam, color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Text(
                camera['id'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${(currentPage * camerasPerPage) + 1}-${(currentPage * camerasPerPage) + paginatedCameras.length} of ${allCameras.length} cameras',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 0
                    ? () {
                        setState(() {
                          currentPage--;
                        });
                      }
                    : null,
              ),
              ...List.generate(totalPages, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        currentPage = index;
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: currentPage == index
                            ? const Color(0xFF1976D2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: currentPage == index
                              ? const Color(0xFF1976D2)
                              : Colors.grey,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: currentPage == index
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages - 1
                    ? () {
                        setState(() {
                          currentPage++;
                        });
                      }
                    : null,
              ),
            ],
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
