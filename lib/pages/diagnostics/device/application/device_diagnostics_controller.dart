import 'package:fl_chart/fl_chart.dart';
import 'package:monitoring/pages/diagnostics/device/application/device_diagnostics_view_model.dart';
import 'package:monitoring/pages/diagnostics/device/data/device_diagnostics_repository.dart';
import 'package:monitoring/pages/diagnostics/device/domain/device_diagnostics_event.dart';
import 'package:monitoring/pages/diagnostics/device/domain/device_diagnostics_metric.dart';

class DeviceDiagnosticsController {
  final DeviceDiagnosticsRepository _repository;

  DeviceDiagnosticsController({DeviceDiagnosticsRepository? repository})
      : _repository = repository ?? DeviceDiagnosticsRepository();

  late final DeviceDiagnosticsViewModel viewModel;
  List<DeviceDiagnosticsMetric> metrics = const [];
  List<DeviceDiagnosticsEvent> events = const [];
  List<FlSpot> responseTimeSpots = const [];
  List<FlSpot> packetLossSpots = const [];

  bool didBootstrap = false;
  bool isLoading = false;
  bool isLiveData = false;
  String? errorMessage;

  Future<void> bootstrap(Map<String, dynamic>? args) async {
    if (didBootstrap) {
      return;
    }
    didBootstrap = true;
    isLoading = true;
    viewModel = DeviceDiagnosticsViewModel.fromRouteArgs(args);

    final liveSnapshot = await _repository.getLiveSnapshot(
      deviceType: viewModel.deviceType,
      deviceId: viewModel.deviceId,
    );

    if (liveSnapshot != null) {
      metrics = liveSnapshot.metrics;
      events = liveSnapshot.events;
      responseTimeSpots = liveSnapshot.responseTimeSamples
          .map((sample) => FlSpot(sample.x, sample.y))
          .toList(growable: false);
      packetLossSpots = liveSnapshot.packetLossSamples
          .map((sample) => FlSpot(sample.x, sample.y))
          .toList(growable: false);
      isLiveData = true;
      isLoading = false;
      return;
    }

    metrics = const [];
    events = const [];
    responseTimeSpots = const [];
    packetLossSpots = const [];
    isLiveData = false;
    errorMessage = 'Data historis backend belum tersedia untuk perangkat ini.';
    isLoading = false;
  }

  Map<String, String> buildPerformanceArguments() {
    final normalizedType = viewModel.isMmt
        ? 'mmt'
        : (viewModel.isAccessPoint ? 'access_point' : 'camera');

    return {
      'deviceType': normalizedType,
      'deviceId': viewModel.deviceId,
      'deviceName': viewModel.deviceName,
    };
  }
}
