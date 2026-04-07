import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:monitoring/pages/diagnostics/performance/application/device_performance_controller.dart';
import 'package:monitoring/pages/diagnostics/performance/presentation/widgets/radial_gauge_card.dart';
import 'package:monitoring/pages/diagnostics/performance/presentation/widgets/telemetry_info_table.dart';
import 'package:monitoring/pages/diagnostics/performance/presentation/widgets/traffic_chart_card.dart';
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
  void initState() {
    super.initState();
  }

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
        final telemetry = _controller.telemetry;

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
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    Color(0xFF2C3E50).withValues(alpha: 0.24),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.12)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildPageToolbar(),
                                  const SizedBox(height: 12),
                                  _buildControlCard(),
                                  const SizedBox(height: 16),
                                  if (_controller.error != null)
                                    _buildErrorBanner(_controller.error!),
                                  if (telemetry != null) ...[
                                    _buildHeaderMeta(telemetry),
                                    const SizedBox(height: 16),
                                    isMobile
                                        ? Column(
                                            children: [
                                              _buildGaugeGrid(telemetry),
                                              const SizedBox(height: 16),
                                              _buildTrafficCard(),
                                            ],
                                          )
                                        : Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                flex: 5,
                                                child:
                                                    _buildGaugeGrid(telemetry),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                flex: 6,
                                                child: _buildTrafficCard(),
                                              ),
                                            ],
                                          ),
                                    const SizedBox(height: 16),
                                    _buildInfoTable(telemetry),
                                  ],
                                ],
                              ),
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
        Expanded(
          child: Text(
            'Device Performance Monitoring',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
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
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ],
    );
  }

  Widget _buildControlCard() {
    final deviceIds = _controller.deviceOptions(_controller.selectedType);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: Color(0xFFFFFFFF).withValues(alpha: 0.62)),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF87C5FF).withValues(alpha: 0.12),
                blurRadius: 22,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
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
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('type-${_controller.selectedType}'),
                  initialValue: _controller.selectedType,
                  decoration: _inputDecoration('Jenis'),
                  dropdownColor: const Color(0xFF2C3E50),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(
                        value: 'access_point', child: Text('Access Point')),
                    DropdownMenuItem(value: 'camera', child: Text('CCTV')),
                    DropdownMenuItem(value: 'mmt', child: Text('MMT')),
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
                width: 240,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(
                    'id-${_controller.selectedType}-${_controller.selectedDeviceId}-${deviceIds.length}',
                  ),
                  initialValue: deviceIds.contains(_controller.selectedDeviceId)
                      ? _controller.selectedDeviceId
                      : null,
                  decoration: _inputDecoration('Device ID'),
                  dropdownColor: const Color(0xFF2C3E50),
                  style: const TextStyle(color: Colors.white),
                  items: deviceIds
                      .map(
                        (id) => DropdownMenuItem(
                          value: id,
                          child: Text(id),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    _controller.updateSelectedDeviceId(value);
                  },
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Refresh otomatis: ${DevicePerformanceController.refreshInterval.inSeconds} detik',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.92)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        border: Border.all(color: const Color(0xFFFFC107)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(
            color: Color(0xFF9A6700),
            fontWeight: FontWeight.w700,
            fontSize: 12),
      ),
    );
  }

  Widget _buildHeaderMeta(Map<String, dynamic> telemetry) {
    final status = telemetry['status']?.toString().toUpperCase() ?? 'UNKNOWN';
    final isUp = status == 'UP';
    final updated = _controller.lastUpdated;
    final updatedLabel = updated == null
        ? '-'
        : '${updated.hour.toString().padLeft(2, '0')}:${updated.minute.toString().padLeft(2, '0')}:${updated.second.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _metaChip('Status', status,
              chipColor:
                  isUp ? const Color(0xFF219653) : const Color(0xFFEB5757)),
          _metaChip('CPU/RAM Warning',
              '${DevicePerformanceController.warningThreshold}%',
              chipColor: const Color(0xFF2D9CDB)),
          _metaChip('Last Update', updatedLabel,
              chipColor: const Color(0xFFF2994A)),
          _metaChip('Device',
              '${telemetry['device_type']} / ${telemetry['device_id']}',
              chipColor: const Color(0xFF27AE60)),
        ],
      ),
    );
  }

  Widget _metaChip(String label, String value,
      {Color chipColor = const Color(0xFF2D9CDB)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.22),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: chipColor.withOpacity(0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: chipColor.withValues(alpha: 0.95),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeGrid(Map<String, dynamic> telemetry) {
    final cpu = _controller.toInt(telemetry['cpu_load']);
    final ram = _controller.toInt(telemetry['ram_usage']);
    final latency = _controller.toInt(telemetry['latency_ms']);
    final packetLoss = _controller.toDouble(telemetry['packet_loss']);

    final cards = [
      RadialGaugeCard(
        title: 'CPU Load',
        value: cpu.toDouble(),
        maxValue: 100,
        suffix: '%',
        threshold: DevicePerformanceController.warningThreshold.toDouble(),
      ),
      RadialGaugeCard(
        title: 'RAM Usage',
        value: ram.toDouble(),
        maxValue: 100,
        suffix: '%',
        threshold: DevicePerformanceController.warningThreshold.toDouble(),
      ),
      RadialGaugeCard(
        title: 'Latency',
        value: latency.toDouble(),
        maxValue: 250,
        suffix: 'ms',
        threshold: 160,
      ),
      RadialGaugeCard(
        title: 'Packet Loss',
        value: packetLoss,
        maxValue: 12,
        suffix: '%',
        threshold: 3,
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }

  Widget _buildTrafficCard() {
    return TrafficChartCard(
      rxSpots: _controller.rxSpots,
      txSpots: _controller.txSpots,
      maxSamples: DevicePerformanceController.maxSamples,
      refreshSeconds: DevicePerformanceController.refreshInterval.inSeconds,
    );
  }

  Widget _buildInfoTable(Map<String, dynamic> telemetry) {
    final rows = [
      [
        'Uptime',
        _formatDuration(_controller.toInt(telemetry['uptime_seconds']))
      ],
      [
        'Bandwidth RX',
        '${_controller.toDouble(telemetry['traffic_rx_mbps']).toStringAsFixed(2)} Mbps'
      ],
      [
        'Bandwidth TX',
        '${_controller.toDouble(telemetry['traffic_tx_mbps']).toStringAsFixed(2)} Mbps'
      ],
      ['Latency', '${_controller.toInt(telemetry['latency_ms'])} ms'],
      [
        'Packet Loss',
        '${_controller.toDouble(telemetry['packet_loss']).toStringAsFixed(2)} %'
      ],
    ];

    return TelemetryInfoTable(rows: rows);
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) {
      return '0s';
    }
    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return '${days}d ${hours}h ${minutes}m';
  }
}
