import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:monitoring/models/camera_model.dart';
import 'package:monitoring/models/mmt_model.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/models/nvr_model.dart';
import 'package:monitoring/models/switch_model.dart';
import 'package:monitoring/models/pc_model.dart';
import 'package:monitoring/pages/diagnostics/performance/data/device_performance_repository.dart';

class DeviceDescriptor {
  final String id;
  final String name;
  final String type; // access_point, camera, mmt, pc
  final String infraType; // TOWER, RTG, RS, CC, OTHER

  DeviceDescriptor({
    required this.id,
    required this.name,
    required this.type,
    required this.infraType,
  });

  @override
  String toString() => '$name ($type)';
}

class DevicePerformanceController extends ChangeNotifier {
  static const int warningThreshold = 80;
  static const Duration refreshInterval = Duration(seconds: 10);

  final DevicePerformanceRepository _repository;

  DevicePerformanceController({DevicePerformanceRepository? repository})
      : _repository = repository ?? DevicePerformanceRepository();

  String _selectedCategory = 'All Devices';
  String _selectedRange = '24h';

  List<DeviceDescriptor> _allDevices = [];
  List<Map<String, dynamic>> _masterLocations = [];
  List<Map<String, dynamic>> _inventoryRows = [];
  Map<String, dynamic>? _overallData;

  bool _isBootLoading = true;
  bool _isRefreshing = false;
  String? _error;
  DateTime? _lastUpdated;

  Map<String, dynamic>? _telemetry;
  final List<Map<String, dynamic>> _telemetryRows = const [];
  Timer? _refreshTimer;

  final List<FlSpot> _rxSpots = [];
  final List<FlSpot> _txSpots = [];
  double _sampleIndex = 0;

  bool _didBootstrap = false;

  String get selectedCategory => _selectedCategory;
  String get selectedRange => _selectedRange;
  
  static const List<String> categories = ['All Devices', 'Access Point', 'CCTV', 'MMT', 'NVR', 'Switch', 'PC'];
  
  int get selectedRangeHours {
    switch (_selectedRange) {
      case '24h':
        return 24;
      case '7d':
        return 24 * 7;
      case '30d':
        return 24 * 30;
      case 'all':
      default:
        return 24 * 30;
    }
  }

  bool get isBootLoading => _isBootLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  Map<String, dynamic>? get telemetry => _telemetry;
  List<Map<String, dynamic>> get telemetryRows =>
      List.unmodifiable(_telemetryRows);
  List<FlSpot> get rxSpots => List.unmodifiable(_rxSpots);
  List<FlSpot> get txSpots => List.unmodifiable(_txSpots);
  bool get didBootstrap => _didBootstrap;
  Map<String, dynamic>? get overallData => _overallData;

  List<Map<String, dynamic>> get categoryTelemetry {
    final rows = _resolvedTelemetryRows();
    if (rows.isEmpty) return [];

    if (_selectedCategory == 'All Devices') {
      return rows;
    }

    final targetType = _mapCategoryToType(_selectedCategory);

    return rows.where((row) {
      final devType = row['device_type']?.toString().toLowerCase().trim() ?? '';
      
      // Sangat permisif: cari keyword dalam string tipe
      if (_selectedCategory == 'Access Point') {
        return devType == 'access_point' || 
               devType == 'tower' || 
               devType == 'ap' || 
               devType.contains('access') || 
               devType.contains('ap') || 
               devType.contains('tower') ||
               devType.contains('wireless');
      }
      
      if (_selectedCategory == 'CCTV') {
        return devType == 'camera' || 
               devType == 'cctv' || 
               devType.contains('cam') || 
               devType.contains('cctv');
      }

      if (_selectedCategory == 'MMT') {
        return devType == 'mmt' || devType.contains('mmt');
      }

      if (_selectedCategory == 'PC') {
        return devType == 'pc' || devType.contains('pc') || devType.contains('computer');
      }

      return devType == targetType;
    }).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  List<Map<String, dynamic>> _resolvedTelemetryRows() {
    final Map<String, Map<String, dynamic>> merged = {};
    
    // 1. Start with all inventory rows (the full list of devices)
    for (var row in _inventoryRows) {
      final id = row['device_id'].toString();
      merged[id] = Map<String, dynamic>.from(row);
    }
    
    // 2. Overlay with telemetry data from API if available
    final apiRows = _overallData?['telemetry_rows'];
    if (apiRows is List) {
      for (var row in apiRows) {
        final id = row['device_id'].toString();
        if (merged.containsKey(id)) {
          merged[id]!.addAll(Map<String, dynamic>.from(row));
        } else {
          merged[id] = Map<String, dynamic>.from(row);
        }
      }
    }
    
    return merged.values.toList();
  }

  String _mapCategoryToType(String cat) {
    switch (cat) {
      case 'All Devices':
        return 'all';
      case 'Access Point':
        return 'access_point';
      case 'CCTV':
        return 'camera';
      case 'MMT':
        return 'mmt';
      case 'NVR':
        return 'nvr';
      case 'Switch':
        return 'switch';
      case 'PC':
        return 'pc';
      default:
        return 'all';
    }
  }

  Future<void> bootstrap(Map<String, dynamic>? args) async {
    if (_didBootstrap) {
      return;
    }
    _didBootstrap = true;

    await _loadAllData();
    
    if (args != null) {
      final candidateType = (args['deviceType'] ?? '').toString().toLowerCase();
      if (candidateType == 'all') {
        _selectedCategory = 'All Devices';
      }
      if (candidateType == 'camera') {
        _selectedCategory = 'CCTV';
      } else if (candidateType == 'mmt') {
        _selectedCategory = 'MMT';
      } else if (candidateType == 'access_point') {
        _selectedCategory = 'Access Point';
      } else if (candidateType == 'pc') {
        _selectedCategory = 'PC';
      }
    }

    await refreshData(force: true);
    _startRefreshTimer();

    _isBootLoading = false;
    notifyListeners();
  }

  Future<void> _loadAllData() async {
    final towers = await _repository.getAllTowers();
    final cameras = await _repository.getAllCameras();
    final mmts = await _repository.getAllMMTs();
    final nvrs = await _repository.getAllNVRs();
    final switches = await _repository.getAllSwitches();
    final pcs = await _repository.getAllPCs();
    _masterLocations = await _repository.getAllMasterLocations();

    final List<DeviceDescriptor> all = [];

    String resolveInfra(String loc) {
      if (loc.isEmpty) return 'OTHER';
      final normalized = loc.trim().toUpperCase();
      final match = _masterLocations.firstWhere(
        (m) =>
            m['location_name'].toString().toUpperCase() == normalized ||
            m['location_code'].toString().toUpperCase() == normalized,
        orElse: () => {},
      );
      if (match.isEmpty) return 'OTHER';
      return (match['location_type'] ?? 'OTHER').toString().toUpperCase();
    }

    for (final t in towers) {
      all.add(DeviceDescriptor(
        id: t.towerId,
        name: t.towerId,
        type: 'access_point',
        infraType: resolveInfra(t.location),
      ));
    }
    for (final c in cameras) {
      all.add(DeviceDescriptor(
        id: c.cameraId,
        name: c.cameraId,
        type: 'camera',
        infraType: resolveInfra(c.location),
      ));
    }
    for (final m in mmts) {
      all.add(DeviceDescriptor(
        id: m.mmtId,
        name: m.mmtId,
        type: 'mmt',
        infraType: resolveInfra(m.location),
      ));
    }
    for (final n in nvrs) {
      all.add(DeviceDescriptor(
        id: n.nvrId,
        name: n.nvrId,
        type: 'nvr',
        infraType: resolveInfra(n.location),
      ));
    }
    for (final s in switches) {
      all.add(DeviceDescriptor(
        id: s.switchId,
        name: s.switchId,
        type: 'switch',
        infraType: resolveInfra(s.location),
      ));
    }
    for (final p in pcs) {
      all.add(DeviceDescriptor(
        id: p.pcId,
        name: p.pcId,
        type: 'pc',
        infraType: resolveInfra(p.location),
      ));
    }

    _allDevices = all;
    _inventoryRows = [
      ...towers.map((t) => _buildTowerRow(t)),
      ...cameras.map((c) => _buildCameraRow(c)),
      ...mmts.map((m) => _buildMmtRow(m)),
      ...nvrs.map((n) => _buildNvrRow(n)),
      ...switches.map((s) => _buildSwitchRow(s)),
      ...pcs.map((p) => _buildPcRow(p)),
    ];
  }

  void updateSelectedCategory(String category) {
    if (category == _selectedCategory) return;
    _selectedCategory = category;
    notifyListeners();
    refreshData(force: true);
  }

  void updateSelectedRange(String range) {
    if (range == _selectedRange) return;
    _selectedRange = range;
    notifyListeners();
    refreshData(force: true);
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(refreshInterval, (_) {
      refreshData();
    });
  }

  Future<void> refreshData({bool force = false}) async {
    if (_isRefreshing && !force) return;

    _isRefreshing = true;
    _error = null;
    notifyListeners();

    try {
      await _loadAllData();
      final response = await _repository.getGlobalDiagnostics(
        hours: selectedRangeHours,
      );

      if (response['success'] == true) {
        final payload = response['data'];
        if (payload is Map<String, dynamic>) {
          _overallData = _normalizeOverallData(payload);
        } else {
          _overallData = null;
        }
      } else {
        _overallData = null;
        _error = (response['message'] ?? 'Failed to fetch performance data').toString();
      }
      
      _lastUpdated = DateTime.now();
    } catch (e) {
      _error = e.toString();
      _overallData = null;
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _normalizeOverallData(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);
    final rows = normalized['telemetry_rows'];
    if (rows is List) {
      normalized['telemetry_rows'] = rows.map((row) {
        final mapped = Map<String, dynamic>.from(row as Map);
        if (!mapped.containsKey('response_time_ms') &&
            mapped.containsKey('latency_ms')) {
          mapped['response_time_ms'] = mapped['latency_ms'];
        }
        return mapped;
      }).toList();
    }
    return normalized;
  }

  void _updateChartSpots() {
    _rxSpots.clear();
    _txSpots.clear();
    _sampleIndex = 0;

    if (_telemetry == null) return;
    final history = _telemetry!['history'] as List?;
    if (history == null) return;

    for (final point in history) {
      final rx = double.tryParse(point['rx_mbps'].toString()) ?? 0;
      final tx = double.tryParse(point['tx_mbps'].toString()) ?? 0;
      _rxSpots.add(FlSpot(_sampleIndex, rx));
      _txSpots.add(FlSpot(_sampleIndex, tx));
      _sampleIndex += 1;
    }
  }

  Map<String, dynamic> _buildTowerRow(Tower tower) {
    return {
      'sampled_at': tower.updatedAt,
      'device_id': tower.towerId,
      'device_type': 'access_point',
      'cpu_load_percent': tower.cpuLoad.toDouble(),
      'ram_usage_percent': tower.ramUsage.toDouble(),
      'response_time_ms': tower.latencyMs.toDouble(),
      'packet_loss_percent': tower.packetLoss,
      'traffic_rx_mbps': tower.bwRx.toDouble(),
      'traffic_tx_mbps': tower.bwTx.toDouble(),
      'uptime_seconds': tower.uptimeSeconds,
    };
  }

  Map<String, dynamic> _buildCameraRow(Camera camera) {
    return {
      'sampled_at': camera.updatedAt,
      'device_id': camera.cameraId,
      'device_type': 'camera',
      'cpu_load_percent': camera.cpuLoad.toDouble(),
      'ram_usage_percent': camera.ramUsage.toDouble(),
      'response_time_ms': camera.latencyMs.toDouble(),
      'packet_loss_percent': camera.packetLoss,
      'traffic_rx_mbps': camera.bwRx.toDouble(),
      'traffic_tx_mbps': camera.bwTx.toDouble(),
      'uptime_seconds': camera.uptimeSeconds,
    };
  }

  Map<String, dynamic> _buildMmtRow(MMT mmt) {
    return {
      'sampled_at': mmt.updatedAt,
      'device_id': mmt.mmtId,
      'device_type': 'mmt',
      'cpu_load_percent': 0,
      'ram_usage_percent': 0,
      'response_time_ms': 0,
      'packet_loss_percent': 0,
      'traffic_rx_mbps': 0,
      'traffic_tx_mbps': 0,
      'uptime_seconds': 0,
    };
  }

  Map<String, dynamic> _buildNvrRow(NVR nvr) {
    return {
      'sampled_at': nvr.updatedAt,
      'device_id': nvr.nvrId,
      'device_type': 'nvr',
      'cpu_load_percent': 0,
      'ram_usage_percent': 0,
      'response_time_ms': 0,
      'packet_loss_percent': 0,
      'traffic_rx_mbps': 0,
      'traffic_tx_mbps': 0,
      'uptime_seconds': 0,
    };
  }

  Map<String, dynamic> _buildSwitchRow(SwitchModel sw) {
    return {
      'sampled_at': sw.updatedAt,
      'device_id': sw.switchId,
      'device_type': 'switch',
      'cpu_load_percent': 0,
      'ram_usage_percent': 0,
      'response_time_ms': 0,
      'packet_loss_percent': 0,
      'traffic_rx_mbps': 0,
      'traffic_tx_mbps': 0,
      'uptime_seconds': 0,
    };
  }

  Map<String, dynamic> _buildPcRow(PCModel pc) {
    return {
      'sampled_at': pc.updatedAt,
      'device_id': pc.pcId,
      'device_type': 'pc',
      'cpu_load_percent': 0,
      'ram_usage_percent': 0,
      'response_time_ms': pc.latencyMs.toDouble(),
      'packet_loss_percent': 0,
      'traffic_rx_mbps': 0,
      'traffic_tx_mbps': 0,
      'uptime_seconds': 0,
    };
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
