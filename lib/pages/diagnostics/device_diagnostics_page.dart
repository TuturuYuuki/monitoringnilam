import 'package:flutter/material.dart';
import 'package:monitoring/pages/diagnostics/device/application/device_diagnostics_controller.dart';
import 'package:monitoring/pages/diagnostics/device/presentation/widgets/device_diagnostics_header_card.dart';
import 'package:monitoring/pages/diagnostics/device/presentation/widgets/diagnostics_line_chart_card.dart';
import 'package:monitoring/pages/diagnostics/device/presentation/widgets/metric_summary_grid.dart';
import 'package:monitoring/pages/diagnostics/device/presentation/widgets/recent_events_table.dart';
import 'package:monitoring/widgets/global_footer.dart';
import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';

class DeviceDiagnosticsPage extends StatefulWidget {
  const DeviceDiagnosticsPage({super.key});

  @override
  State<DeviceDiagnosticsPage> createState() => _DeviceDiagnosticsPageState();
}

class _DeviceDiagnosticsPageState extends State<DeviceDiagnosticsPage> {
  final DeviceDiagnosticsController _controller = DeviceDiagnosticsController();
  bool _didStartBootstrap = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartBootstrap) {
      return;
    }
    _didStartBootstrap = true;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    await _controller.bootstrap(args);
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = !_controller.didBootstrap || _controller.isLoading;
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF2C3E50),
        body: Column(
          children: [
            const GlobalHeaderBar(currentRoute: '/device-diagnostics'),
            Expanded(
              child: GlobalSidebarNav(
                currentRoute: '/device-diagnostics',
                enabled: !isMobile,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
            const GlobalFooter(),
          ],
        ),
      );
    }

    final viewModel = _controller.viewModel;
    final responseTimeSpots = _controller.responseTimeSpots;
    final packetLossSpots = _controller.packetLossSpots;

    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/device-diagnostics'),
          Expanded(
            child: GlobalSidebarNav(
                currentRoute: '/device-diagnostics',
                enabled: !isMobile,
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _controller.isLiveData
                                      ? Colors.green.withValues(alpha: 0.18)
                                      : Colors.orange.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _controller.isLiveData
                                        ? Colors.greenAccent
                                            .withValues(alpha: 0.8)
                                        : Colors.orangeAccent
                                            .withValues(alpha: 0.8),
                                  ),
                                ),
                                child: Text(
                                  _controller.isLiveData
                                      ? 'Data Source: Backend'
                                      : 'Data Source: No Data',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildPerformanceButton(
                                context,
                                controller: _controller,
                              ),
                            ],
                          ),
                        ),
                        if (_controller.errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _controller.errorMessage!,
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        DeviceDiagnosticsHeaderCard(viewModel: viewModel),
                        const SizedBox(height: 16),
                        MetricSummaryGrid(
                          isMobile: isMobile,
                          metrics: _controller.metrics,
                        ),
                        const SizedBox(height: 24),
                        if (isMobile)
                          Column(
                            children: [
                              DiagnosticsLineChartCard(
                                title: 'Response Time',
                                subtitle: 'Last 1 hour',
                                spots: responseTimeSpots,
                                color: Colors.lightBlueAccent,
                              ),
                              const SizedBox(height: 16),
                              DiagnosticsLineChartCard(
                                title: 'Packet Loss',
                                subtitle: 'Last 1 hour',
                                spots: packetLossSpots,
                                color: Colors.orangeAccent,
                                showPercentInLeftAxis: true,
                              ),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: DiagnosticsLineChartCard(
                                  title: 'Response Time',
                                  subtitle: 'Last 1 hour',
                                  spots: responseTimeSpots,
                                  color: Colors.lightBlueAccent,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DiagnosticsLineChartCard(
                                  title: 'Packet Loss',
                                  subtitle: 'Last 1 hour',
                                  spots: packetLossSpots,
                                  color: Colors.orangeAccent,
                                  showPercentInLeftAxis: true,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        RecentEventsTable(
                          rows: _controller.events,
                          isLiveData: _controller.isLiveData,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                )),
          ),
          const GlobalFooter(),
        ],
      ),
    );
  }

  Widget _buildPerformanceButton(
    BuildContext context, {
    required DeviceDiagnosticsController controller,
  }) {
    return FilledButton.icon(
      onPressed: () {
        Navigator.pushNamed(
          context,
          '/device-performance',
          arguments: controller.buildPerformanceArguments(),
        );
      },
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      icon: const Icon(Icons.speed),
      label: const Text('Buka Device Performance'),
    );
  }
}
