import 'dart:async';
import 'package:flutter/material.dart';
import 'package:monitoring/main.dart'; // For AnimatedDropdownButton
import 'package:monitoring/pages/diagnostics/performance/application/device_performance_controller.dart';
import 'package:monitoring/pages/diagnostics/performance/presentation/widgets/device_telemetry_data_table_card.dart';
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
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _controller.bootstrap(args);
    
    _timer ??= Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_controller.isRefreshing) {
        _controller.refreshTelemetry(force: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
                                if (_controller.error != null)
                                  _buildErrorBanner(_controller.error!),
                                const SizedBox(height: 16),
                                DeviceTelemetryDataTableCard(
                                  rows: _controller.telemetryRows,
                                ),
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
      label: const Text('Global Diagnostics'),
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
    final deviceOptions = _controller.deviceOptions(_controller.selectedType);
    final selectedDeviceId = deviceOptions.contains(_controller.selectedDeviceId)
        ? _controller.selectedDeviceId
        : null;

    final String deviceLabel;
    if (_controller.selectedType == 'camera') {
      deviceLabel = 'CCTV Device';
    } else if (_controller.selectedType == 'mmt') {
      deviceLabel = 'MMT Device';
    } else {
      deviceLabel = 'AP Device';
    }

    String getDisplayType(String val) {
      if (val == 'access_point') return 'Access Point';
      if (val == 'camera') return 'CCTV';
      if (val == 'mmt') return 'MMT';
      return val;
    }
    String getRawType(String val) {
      if (val == 'Access Point') return 'access_point';
      if (val == 'CCTV') return 'camera';
      if (val == 'MMT') return 'mmt';
      return val;
    }
    
    String getDisplayRange(String val) {
      if (val == '24h') return '24 Hours';
      if (val == 'all') return 'All Data';
      if (val == '7d') return '7 Days';
      if (val == '30d') return '30 Days';
      return val;
    }
    String getRawRange(String val) {
      if (val == '24 Hours') return '24h';
      if (val == 'All Data') return 'all';
      if (val == '7 Days') return '7d';
      if (val == '30 Days') return '30d';
      return val;
    }

    final typeDropdown = _buildDropdownContainer(
      label: 'Type',
      child: AnimatedDropdownButton(
        value: getDisplayType(_controller.selectedType),
        items: const ['Access Point', 'CCTV', 'MMT'],
        backgroundColor: AppDropdownStyle.menuBackground,
        onChanged: (value) {
          if (value != null) {
            _controller.updateSelectedType(getRawType(value));
          }
        },
      ),
    );

    final rangeDropdown = _buildDropdownContainer(
      label: 'Data Range',
      child: AnimatedDropdownButton(
        value: getDisplayRange(_controller.selectedRange),
        items: const ['24 Hours', 'All Data', '7 Days', '30 Days'],
        backgroundColor: AppDropdownStyle.menuBackground,
        onChanged: (value) {
          if (value != null) {
            _controller.updateSelectedRange(getRawRange(value));
          }
        },
      ),
    );

    final deviceDropdown = _buildDropdownContainer(
      label: deviceLabel,
      child: AnimatedDropdownButton(
        value: selectedDeviceId ?? 'Select Device',
        items: deviceOptions.isEmpty ? ['Select Device'] : deviceOptions,
        backgroundColor: AppDropdownStyle.menuBackground,
        onChanged: (value) {
          if (value != null && value != 'Select Device') {
            _controller.updateSelectedDeviceId(value);
          }
        },
      ),
    );

    return liquidGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              children: [
                typeDropdown,
                const SizedBox(height: 12),
                deviceDropdown,
                const SizedBox(height: 12),
                rangeDropdown,
              ],
            )
          else if (isMobile)
            Row(
              children: [
                Expanded(child: typeDropdown),
                const SizedBox(width: 12),
                Expanded(child: deviceDropdown),
                const SizedBox(width: 12),
                Expanded(child: rangeDropdown),
              ],
            )
          else
            Row(
              children: [
                SizedBox(width: 200, child: typeDropdown),
                const SizedBox(width: 16),
                SizedBox(width: 200, child: deviceDropdown),
                const SizedBox(width: 16),
                SizedBox(width: 200, child: rangeDropdown),
              ],
            ),
        ],
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
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: appGlassFieldDecoration(radius: 12),
          child: child,
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
}
