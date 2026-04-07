import 'package:flutter/material.dart';
import 'package:monitoring/pages/diagnostics/device/domain/device_chart_sample.dart';
import 'package:monitoring/pages/diagnostics/device/domain/device_diagnostics_event.dart';
import 'package:monitoring/pages/diagnostics/device/domain/device_diagnostics_metric.dart';
import 'package:monitoring/pages/diagnostics/device/domain/device_diagnostics_snapshot.dart';
import 'package:monitoring/services/api_service.dart';

class DeviceDiagnosticsRepository {
  final ApiService _apiService;

  DeviceDiagnosticsRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<DeviceDiagnosticsSnapshot?> getLiveSnapshot({
    required String deviceType,
    required String deviceId,
  }) async {
    final normalizedDeviceType = _normalizeDeviceType(deviceType);
    final isAccessPoint = normalizedDeviceType == 'access_point';
    final isMmt = normalizedDeviceType == 'mmt';
    final response = await _apiService.getDevicePerformance(
      deviceType: normalizedDeviceType,
      deviceId: deviceId,
    );

    if (response['success'] != true ||
        response['data'] is! Map<String, dynamic>) {
      return null;
    }

    final data = response['data'] as Map<String, dynamic>;
    final cpu = _toDouble(data['cpu_load']);
    final ram = _toDouble(data['ram_usage']);
    final latency = _toDouble(data['latency_ms']);
    final packetLoss = _toDouble(data['packet_loss']);
    final uptimeHours = _toInt(data['uptime_seconds']) / 3600.0;

    final metrics = [
      DeviceDiagnosticsMetric(
        title: 'Response Time',
        value: '${latency.toStringAsFixed(1)} ms',
        subtitle: 'Live backend telemetry',
        color: Colors.greenAccent,
      ),
      DeviceDiagnosticsMetric(
        title: 'Packet Loss',
        value: '${packetLoss.toStringAsFixed(2)} %',
        subtitle: 'Live backend telemetry',
        color: Colors.orangeAccent,
      ),
      DeviceDiagnosticsMetric(
        title: (isAccessPoint || isMmt) ? 'CPU Load' : 'Stream CPU Load',
        value: '${cpu.toStringAsFixed(0)} %',
        subtitle: 'Threshold warning >= 80%',
        color: Colors.lightBlueAccent,
      ),
      DeviceDiagnosticsMetric(
        title: (isAccessPoint || isMmt) ? 'RAM Usage' : 'Memory Usage',
        value: '${ram.toStringAsFixed(0)} %',
        subtitle: 'Uptime ${uptimeHours.toStringAsFixed(1)} h',
        color: Colors.purpleAccent,
      ),
    ];

    final series = data['series'] is Map<String, dynamic>
        ? data['series'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final responseTimeSamples = _parseSeries(series['latency_ms']);
    final packetLossSamples = _parseSeries(series['packet_loss_percent']);

    final rawEvents = data['events'];
    final events = rawEvents is List
        ? rawEvents
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .map((row) {
            final rawTime = row['time']?.toString() ?? '';
            final parsedTime = DateTime.tryParse(rawTime);
            final hhmmss = parsedTime == null
                ? rawTime
                : '${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')}:${parsedTime.second.toString().padLeft(2, '0')}';
            final durationSeconds = _toInt(row['duration_seconds']);

            return DeviceDiagnosticsEvent(
              time: hhmmss,
              event: row['message']?.toString() ?? '-',
              duration: durationSeconds > 0 ? '${durationSeconds}s' : '-',
            );
          }).toList(growable: false)
        : const <DeviceDiagnosticsEvent>[];

    return DeviceDiagnosticsSnapshot(
      metrics: metrics,
      responseTimeSamples: responseTimeSamples,
      packetLossSamples: packetLossSamples,
      events: events,
      isLive: true,
    );
  }

  List<DeviceChartSample> _parseSeries(dynamic raw) {
    if (raw is! List) {
      return const <DeviceChartSample>[];
    }

    final parsed = raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(
          (item) => DeviceChartSample(
            x: _toDouble(item['x']),
            y: _toDouble(item['y']),
          ),
        )
        .toList(growable: false);

    return parsed;
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _normalizeDeviceType(String rawType) {
    final t = rawType.trim().toLowerCase();
    if (t.contains('mmt')) {
      return 'mmt';
    }
    if (t.contains('camera') || t.contains('cctv')) {
      return 'camera';
    }
    if (t.contains('ap') || t.contains('tower') || t.contains('access')) {
      return 'access_point';
    }
    return 'camera';
  }
}
