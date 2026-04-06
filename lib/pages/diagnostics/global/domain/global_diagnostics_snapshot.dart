class GlobalDiagnosticsSnapshot {
  final String nodeName;
  final int nodeUp;
  final int nodeWarning;
  final int nodeCritical;
  final int nodeUndefined;
  final double cpuLoadPercent;
  final double memoryUsedPercent;
  final double responseTimeMs;
  final double packetLossPercent;
  final List<GlobalDiskVolume> diskVolumes;
  final List<GlobalHighError> highErrors;
  final List<GlobalChartPoint> latencySeries;
  final List<GlobalChartPoint> packetLossSeries;
  final List<GlobalChartPoint> cpuAverageSeries;
  final List<GlobalChartPoint> diskSeriesA;
  final List<GlobalChartPoint> diskSeriesB;
  final List<GlobalCpuSeries> topCpuSeries;

  const GlobalDiagnosticsSnapshot({
    required this.nodeName,
    required this.nodeUp,
    required this.nodeWarning,
    required this.nodeCritical,
    required this.nodeUndefined,
    required this.cpuLoadPercent,
    required this.memoryUsedPercent,
    required this.responseTimeMs,
    required this.packetLossPercent,
    required this.diskVolumes,
    required this.highErrors,
    required this.latencySeries,
    required this.packetLossSeries,
    required this.cpuAverageSeries,
    required this.diskSeriesA,
    required this.diskSeriesB,
    required this.topCpuSeries,
  });

  factory GlobalDiagnosticsSnapshot.fromApi(Map<String, dynamic> data) {
    final node = _asMap(data['node']);
    final health = _asMap(data['health_overview']);
    final vital = _asMap(data['vital']);
    final charts = _asMap(data['charts']);

    return GlobalDiagnosticsSnapshot(
      nodeName: node['name']?.toString() ?? 'WIN-JC6CBES5TOR',
      nodeUp: _toInt(health['up']),
      nodeWarning: _toInt(health['warning']),
      nodeCritical: _toInt(health['critical']),
      nodeUndefined: _toInt(health['undefined']),
      cpuLoadPercent: _toDouble(vital['cpu_load_percent']),
      memoryUsedPercent: _toDouble(vital['memory_used_percent']),
      responseTimeMs: _toDouble(vital['response_time_ms']),
      packetLossPercent: _toDouble(vital['packet_loss_percent']),
      diskVolumes: _asList(data['disk_volumes'])
          .map(GlobalDiskVolume.fromApi)
          .toList(growable: false),
        highErrors: _asList(data['high_errors'])
          .map(GlobalHighError.fromApi)
          .toList(growable: false),
      latencySeries: _parseSeries(charts['latency']),
      packetLossSeries: _parseSeries(charts['packet_loss']),
      cpuAverageSeries: _parseSeries(charts['cpu_avg']),
      diskSeriesA: _parseSeries(charts['disk_a']),
      diskSeriesB: _parseSeries(charts['disk_b']),
      topCpuSeries: _asList(charts['top_cpus'])
          .map(GlobalCpuSeries.fromApi)
          .toList(growable: false),
    );
  }

  factory GlobalDiagnosticsSnapshot.fallback() {
    return GlobalDiagnosticsSnapshot(
      nodeName: 'WIN-JC6CBES5TOR',
      nodeUp: 23,
      nodeWarning: 3,
      nodeCritical: 7,
      nodeUndefined: 4,
      cpuLoadPercent: 33,
      memoryUsedPercent: 92,
      responseTimeMs: 12,
      packetLossPercent: 0.8,
      diskVolumes: const [
        GlobalDiskVolume(
          name: 'C:\\ Label:D6499D61',
          size: '146.0 GB',
          used: '40.6 GB',
          percent: 28,
        ),
        GlobalDiskVolume(
          name: 'D:\\ Label:DataVolAEA2192E',
          size: '3.6 TB',
          used: '51.7 GB',
          percent: 1,
        ),
        GlobalDiskVolume(
          name: 'Physical Memory',
          size: '7.8 GB',
          used: '7.3 GB',
          percent: 93,
        ),
        GlobalDiskVolume(
          name: 'Virtual Memory',
          size: '9.1 GB',
          used: '8.0 GB',
          percent: 88,
        ),
      ],
      highErrors: const [
        GlobalHighError(
          node: 'PERM-TEX-MDS9120',
          interfaceName: 'fc1/5',
          receiveErrors: 0,
          receiveDiscards: 0,
        ),
        GlobalHighError(
          node: 'PERM_AP6511-E6C80C',
          interfaceName: 'fe4',
          receiveErrors: 64088776,
          receiveDiscards: 78073384,
        ),
      ],
      latencySeries: List.generate(
        24,
        (i) => GlobalChartPoint(
          x: i.toDouble(),
          y: (6 + (i % 7) + ((i % 4 == 0) ? 9 : 0)).toDouble(),
        ),
      ),
      packetLossSeries: List.generate(
        24,
        (i) => GlobalChartPoint(
          x: i.toDouble(),
          y: (i % 9 == 0 ? 2.1 : (i % 5 == 0 ? 0.9 : 0.3)).toDouble(),
        ),
      ),
      cpuAverageSeries: List.generate(
        24,
        (i) => GlobalChartPoint(
          x: i.toDouble(),
          y: (8 + (i % 6) * 4 + (i % 8 == 0 ? 28 : 0)).toDouble(),
        ),
      ),
      diskSeriesA: List.generate(
        24,
        (i) => GlobalChartPoint(
          x: i.toDouble(),
          y: (72 + i * 0.35 + (i % 8 == 0 ? 1.2 : 0)).toDouble(),
        ),
      ),
      diskSeriesB: List.generate(
        24,
        (i) => GlobalChartPoint(
          x: i.toDouble(),
          y: (68 + i * 0.28 + (i % 7 == 0 ? 1.0 : 0)).toDouble(),
        ),
      ),
      topCpuSeries: const [
        GlobalCpuSeries(name: 'CPU 1', deviceType: 'access_point', deviceTypeLabel: 'Access Point', value: 26, colorHex: '#1B9FDC'),
        GlobalCpuSeries(name: 'CPU 7', deviceType: 'camera', deviceTypeLabel: 'Camera', value: 45, colorHex: '#E542A3'),
        GlobalCpuSeries(name: 'CPU 4', deviceType: 'camera', deviceTypeLabel: 'Camera', value: 26, colorHex: '#33B1D0'),
        GlobalCpuSeries(name: 'CPU 2', deviceType: 'access_point', deviceTypeLabel: 'Access Point', value: 26, colorHex: '#7C76F2'),
        GlobalCpuSeries(name: 'CPU 8', deviceType: 'mmt', deviceTypeLabel: 'MMT', value: 32, colorHex: '#8FBE34'),
        GlobalCpuSeries(name: 'CPU 5', deviceType: 'camera', deviceTypeLabel: 'Camera', value: 51, colorHex: '#E58E24'),
        GlobalCpuSeries(name: 'CPU 6', deviceType: 'access_point', deviceTypeLabel: 'Access Point', value: 32, colorHex: '#646BD1'),
        GlobalCpuSeries(name: 'CPU 3', deviceType: 'camera', deviceTypeLabel: 'Camera', value: 32, colorHex: '#A74D4B'),
      ],
    );
  }

  factory GlobalDiagnosticsSnapshot.empty() {
    return const GlobalDiagnosticsSnapshot(
      nodeName: 'N/A',
      nodeUp: 0,
      nodeWarning: 0,
      nodeCritical: 0,
      nodeUndefined: 0,
      cpuLoadPercent: 0,
      memoryUsedPercent: 0,
      responseTimeMs: 0,
      packetLossPercent: 0,
      diskVolumes: <GlobalDiskVolume>[],
      highErrors: <GlobalHighError>[],
      latencySeries: <GlobalChartPoint>[],
      packetLossSeries: <GlobalChartPoint>[],
      cpuAverageSeries: <GlobalChartPoint>[],
      diskSeriesA: <GlobalChartPoint>[],
      diskSeriesB: <GlobalChartPoint>[],
      topCpuSeries: <GlobalCpuSeries>[],
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return const <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is List) {
      return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  static List<GlobalChartPoint> _parseSeries(dynamic value) {
    return _asList(value)
        .map((item) => GlobalChartPoint(
              x: _toDouble(item['x']),
              y: _toDouble(item['y']),
            ))
        .toList(growable: false);
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class GlobalDiskVolume {
  final String name;
  final String size;
  final String used;
  final int percent;

  const GlobalDiskVolume({
    required this.name,
    required this.size,
    required this.used,
    required this.percent,
  });

  factory GlobalDiskVolume.fromApi(Map<String, dynamic> json) {
    return GlobalDiskVolume(
      name: json['name']?.toString() ?? '-',
      size: json['size']?.toString() ?? '-',
      used: json['used']?.toString() ?? '-',
      percent: GlobalDiagnosticsSnapshot._toInt(json['percent']),
    );
  }
}

class GlobalChartPoint {
  final double x;
  final double y;

  const GlobalChartPoint({required this.x, required this.y});
}

class GlobalHighError {
  final String node;
  final String interfaceName;
  final int receiveErrors;
  final int receiveDiscards;

  const GlobalHighError({
    required this.node,
    required this.interfaceName,
    required this.receiveErrors,
    required this.receiveDiscards,
  });

  factory GlobalHighError.fromApi(Map<String, dynamic> json) {
    return GlobalHighError(
      node: json['node']?.toString() ?? '-',
      interfaceName: json['interface']?.toString() ?? '-',
      receiveErrors: GlobalDiagnosticsSnapshot._toInt(json['receive_errors']),
      receiveDiscards:
          GlobalDiagnosticsSnapshot._toInt(json['receive_discards']),
    );
  }
}

class GlobalCpuSeries {
  final String name;
  final String deviceType;
  final String deviceTypeLabel;
  final double value;
  final String colorHex;
  final List<GlobalChartPoint> series;

  const GlobalCpuSeries({
    required this.name,
    required this.deviceType,
    required this.deviceTypeLabel,
    required this.value,
    required this.colorHex,
    this.series = const [],
  });

  factory GlobalCpuSeries.fromApi(Map<String, dynamic> json) {
    final rawSeries = json['series'];
    final series = rawSeries is List
        ? rawSeries
            .whereType<Map>()
            .map((item) => GlobalChartPoint(
                  x: GlobalDiagnosticsSnapshot._toDouble(item['x']),
                  y: GlobalDiagnosticsSnapshot._toDouble(item['y']),
                ))
            .toList(growable: false)
        : const <GlobalChartPoint>[];

    return GlobalCpuSeries(
      name: json['name']?.toString() ?? 'CPU',
      deviceType: json['device_type']?.toString() ?? '',
      deviceTypeLabel: json['device_type_label']?.toString() ?? '',
      value: GlobalDiagnosticsSnapshot._toDouble(json['value']),
      colorHex: json['color']?.toString() ?? '#1B9FDC',
      series: series,
    );
  }
}
