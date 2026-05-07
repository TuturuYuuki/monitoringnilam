import 'package:flutter/material.dart';
import 'package:monitoring/main.dart';
import 'package:monitoring/pages/diagnostics/performance/application/device_performance_controller.dart';
import 'package:monitoring/pages/diagnostics/performance/presentation/widgets/overall_performance_table_card.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';
import 'package:monitoring/widgets/global_footer.dart';
import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';

class DevicePerformancePage extends StatefulWidget {
  const DevicePerformancePage({super.key});

  @override
  State<DevicePerformancePage> createState() => _DevicePerformancePageState();
}

class _DevicePerformancePageState extends State<DevicePerformancePage> {
  final DevicePerformanceController _controller = DevicePerformanceController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _controller.bootstrap(args);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    final screenWidth = MediaQuery.of(context).size.width; 

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppDropdownStyle.standardPageBackground,
          body: Column(
            children: [
              const GlobalHeaderBar(currentRoute: '/device-performance'),
              Expanded(
                child: GlobalSidebarNav(
                  currentRoute: '/device-performance',
                  enabled: !isMobile,
                  child: _controller.isBootLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SafeArea(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPageToolbar(isMobile, screenWidth),
                                const SizedBox(height: 12),
                                _buildControlCard(screenWidth),
                                const SizedBox(height: 16),
                                if (_controller.overallData != null) ...[
                                  OverallPerformanceTableCard(
                                    overallData: _controller.overallData,
                                    title: 'Performance: ${_controller.selectedCategory}',
                                    selectedRange: _controller.selectedRange,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (_controller.error != null)
                                  _buildErrorBanner(_controller.error!),
                                const SizedBox(height: 16),
                                _buildCategoryStatusTable(),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              const GlobalFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageToolbar(bool isMobile, double screenWidth) {
    final globalButton = FilledButton.icon(
      onPressed: () => Navigator.of(context).pushNamed('/global-diagnostics'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF00D9FF),
        foregroundColor: Colors.black87,
      ),
      icon: const Icon(Icons.analytics_outlined),
      label: const Text('Global Diagnostic'),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data List',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: globalButton),
        ],
      );
    }

    return Row(
      children: [
        const Expanded(
          child: Text(
            'Data List',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        globalButton,
      ],
    );
  }

  Widget _buildControlCard(double screenWidth) {
    final isMobile = screenWidth < 900;
    final isNarrowMobile = screenWidth < 430;
    
    String getDisplayRange(String val) {
      if (val == '24h') return '24 Hour';
      if (val == 'all') return 'All Data';
      if (val == '7d') return '7 Day';
      if (val == '30d') return '30 Day';
      return val;
    }
    String getRawRange(String val) {
      if (val == '24 Hour') return '24h';
      if (val == 'All Data') return 'all';
      if (val == '7 Day') return '7d';
      if (val == '30 Day') return '30d';
      return val;
    }

    final deviceDropdown = _buildDropdownContainer(
      label: 'Select Category',
      child: AnimatedDropdownButton(
        value: _controller.selectedCategory,
        items: DevicePerformanceController.categories,
        backgroundColor: AppDropdownStyle.menuBackground,
        onChanged: (value) {
          if (value != null) {
            _controller.updateSelectedCategory(value);
          }
        },
      ),
    );

    final rangeDropdown = _buildDropdownContainer(
      label: 'Data Range',
      child: AnimatedDropdownButton(
        value: getDisplayRange(_controller.selectedRange),
        items: const ['All Data', '24 Hour', '7 Day', '30 Day'],
        backgroundColor: AppDropdownStyle.menuBackground,
        onChanged: (value) {
          if (value != null) {
            _controller.updateSelectedRange(getRawRange(value));
          }
        },
      ),
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: IntrinsicWidth(
        child: liquidGlassCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Target Device',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),
              if (isMobile && isNarrowMobile)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: MediaQuery.of(context).size.width * 0.8, child: deviceDropdown),
                    const SizedBox(height: 0),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.8, child: rangeDropdown),
                  ],
                )
              else if (isMobile)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: MediaQuery.of(context).size.width * 0.35, child: deviceDropdown),
                    const SizedBox(width: 0),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.35, child: rangeDropdown),
                  ],
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 140, child: deviceDropdown),
                    const SizedBox(width: 0),
                    SizedBox(width: 110, child: rangeDropdown),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownContainer({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: appGlassFieldDecoration(radius: 12),
          child: child,
        ),
      ],
    );
  }

  Widget _buildCategoryStatusTable() {
    final rows = _controller.categoryTelemetry;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        liquidGlassCard(
          padding: const EdgeInsets.all(0),
          child: rows.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, color: Colors.white.withValues(alpha: 0.3), size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'No devices found for this category',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildCustomCategoryTable(rows),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withValues(alpha: 0.18),
        border:
            Border.all(color: const Color(0xFFD32F2F).withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: const TextStyle(color: Colors.white)),
    );
  }
  Widget _buildCustomCategoryTable(List<Map<String, dynamic>> rows) {
    const headers = ['Device ID', 'CPU %', 'RAM %', 'Resp Time', 'Loss %', 'Uptime'];
    final isMobile = MediaQuery.of(context).size.width < 900;
    final columnFlex = [1, 1, 1, 1, 1, 1]; 
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2C3A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          // Blue Title Header (as requested in screenshot style)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withValues(alpha: 0.8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Text(
              'Device Performance List',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Yellow/Olive Column Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF9E9D24).withValues(alpha: 0.7),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                for (int i = 0; i < headers.length; i++)
                  _buildCategoryTableCellFlex(
                    text: headers[i],
                    flex: columnFlex[i],
                    isHeader: true,
                    isNumeric: false, // Center everything as in screenshot
                    showDivider: i < headers.length - 1,
                  ),
              ],
            ),
          ),
          // Table Rows
          ...rows.asMap().entries.map((entry) {
            final row = entry.value;
            final index = entry.key;
            final isLast = index == rows.length - 1;
            
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF263238).withValues(alpha: 0.4),
                border: Border(
                  bottom: isLast
                      ? BorderSide.none
                      : BorderSide(
                          color: Colors.white.withValues(alpha: 0.04),
                          width: 1.0,
                        ),
                ),
              ),
              child: Row(
                children: [
                  _buildCategoryTableCellFlex(
                    text: row['device_id'].toString(),
                    flex: columnFlex[0],
                    showDivider: true,
                  ),
                  _buildCategoryTableCellFlex(
                    text: '${_toDouble(row['cpu_load_percent']).toStringAsFixed(2)}%',
                    flex: columnFlex[1],
                    value: _toDouble(row['cpu_load_percent']),
                    metricType: 'cpu',
                    showDivider: true,
                  ),
                  _buildCategoryTableCellFlex(
                    text: '${_toDouble(row['ram_usage_percent']).toStringAsFixed(2)}%',
                    flex: columnFlex[2],
                    value: _toDouble(row['ram_usage_percent']),
                    metricType: 'ram',
                    showDivider: true,
                  ),
                  _buildCategoryTableCellFlex(
                    text: '${_toDouble(row['response_time_ms']).toStringAsFixed(2)}ms',
                    flex: columnFlex[3],
                    showDivider: true,
                  ),
                  _buildCategoryTableCellFlex(
                    text: '${_toDouble(row['packet_loss_percent']).toStringAsFixed(2)}%',
                    flex: columnFlex[4],
                    value: _toDouble(row['packet_loss_percent']),
                    metricType: 'loss',
                    showDivider: true,
                  ),
                  _buildCategoryTableCellFlex(
                    text: _formatUptime(row['uptime_seconds'] ?? 0),
                    flex: columnFlex[5],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryTableCellFlex({
    required String text,
    required int flex,
    bool isHeader = false,
    bool isNumeric = false,
    double? value,
    String? metricType,
    bool showDivider = false,
  }) {
    final alignment = isNumeric ? TextAlign.right : TextAlign.center;
    Color textColor = Colors.white.withValues(alpha: 0.9);

    if (!isHeader && value != null) {
      if (metricType == 'cpu' || metricType == 'ram') {
        if (value >= 90) {
          textColor = const Color(0xFFFF5252);
        } else if (value >= 75) textColor = const Color(0xFFFFAB40);
      } else if (metricType == 'loss' && value > 0) {
        textColor = const Color(0xFFFFAB40);
      }
    }

    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider 
            ? Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1))
            : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          text,
          textAlign: alignment,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
            fontSize: isHeader ? 11 : 12,
            fontFamily: isNumeric ? 'monospace' : null,
          ),
        ),
      ),
    );
  }

  String _formatUptime(dynamic seconds) {
    try {
      final secs = int.parse(seconds.toString());
      if (secs < 60) return '$secs s';
      if (secs < 3600) return '${(secs / 60).toStringAsFixed(1)} m';
      if (secs < 86400) return '${(secs / 3600).toStringAsFixed(1)} h';
      return '${(secs / 86400).toStringAsFixed(1)} d';
    } catch (_) {
      return '$seconds s';
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value == null) {
      return 0.0;
    }
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
