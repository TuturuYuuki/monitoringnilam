import 'package:monitoring/pages/diagnostics/device/domain/device_chart_sample.dart';
import 'package:monitoring/pages/diagnostics/device/domain/device_diagnostics_event.dart';
import 'package:monitoring/pages/diagnostics/device/domain/device_diagnostics_metric.dart';

class DeviceDiagnosticsSnapshot {
  final List<DeviceDiagnosticsMetric> metrics;
  final List<DeviceChartSample> responseTimeSamples;
  final List<DeviceChartSample> packetLossSamples;
  final List<DeviceDiagnosticsEvent> events;
  final bool isLive;

  const DeviceDiagnosticsSnapshot({
    required this.metrics,
    required this.responseTimeSamples,
    required this.packetLossSamples,
    required this.events,
    required this.isLive,
  });
}
