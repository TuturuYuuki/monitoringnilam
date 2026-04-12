import 'package:flutter/material.dart';
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
    final isMobile = MediaQuery.of(context).size.width < 900;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF2C3E50),
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
                                _buildPageToolbar(),
                                const SizedBox(height: 12),
                                _buildControlCard(),
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

  Widget _buildPageToolbar() {
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
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pushNamed('/global-diagnostics');
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
          ),
          icon: const Icon(Icons.analytics_outlined),
          label: const Text('Global Diagnostics'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _controller.isRefreshing
              ? null
              : () => _controller.refreshTelemetry(force: true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
          ),
          icon: _controller.isRefreshing
              ? const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ],
    );
  }

  Widget _buildControlCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2631),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Target Device',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<String>(
              key: ValueKey('type-${_controller.selectedType}'),
              initialValue: _controller.selectedType,
              decoration: _inputDecoration('Jenis'),
              dropdownColor: AppDropdownStyle.menuBackground,
              borderRadius: AppDropdownStyle.menuBorderRadius,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              iconEnabledColor: Colors.white,
              items: const [
                DropdownMenuItem(
                  value: 'access_point',
                  child: Text(
                    'Access Point',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                DropdownMenuItem(
                  value: 'camera',
                  child: Text('CCTV', style: TextStyle(color: Colors.white)),
                ),
                DropdownMenuItem(
                  value: 'mmt',
                  child: Text('MMT', style: TextStyle(color: Colors.white)),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                _controller.updateSelectedType(value);
              },
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              key: ValueKey('range-${_controller.selectedRange}'),
              initialValue: _controller.selectedRange,
              decoration: _inputDecoration('Rentang Data'),
              dropdownColor: AppDropdownStyle.menuBackground,
              borderRadius: AppDropdownStyle.menuBorderRadius,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              iconEnabledColor: Colors.white,
              items: const [
                DropdownMenuItem(
                  value: '24h',
                  child: Text('24 Jam', style: TextStyle(color: Colors.white)),
                ),
                DropdownMenuItem(
                  value: 'all',
                  child:
                      Text('Semua Data', style: TextStyle(color: Colors.white)),
                ),
                DropdownMenuItem(
                  value: '7d',
                  child: Text('7 Hari', style: TextStyle(color: Colors.white)),
                ),
                DropdownMenuItem(
                  value: '30d',
                  child: Text('30 Hari', style: TextStyle(color: Colors.white)),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                _controller.updateSelectedRange(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF253645),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            BorderSide(color: Colors.lightBlueAccent.withValues(alpha: 0.8)),
      ),
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
