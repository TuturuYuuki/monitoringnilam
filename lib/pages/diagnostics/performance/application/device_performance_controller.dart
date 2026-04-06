import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:monitoring/models/camera_model.dart';
import 'package:monitoring/models/mmt_model.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/pages/diagnostics/performance/data/device_performance_repository.dart';

class DevicePerformanceController extends ChangeNotifier {
  static const int warningThreshold = 80;
  static const Duration refreshInterval = Duration(seconds: 10);
  static const int maxSamples = 24;

  final DevicePerformanceRepository _repository;

  DevicePerformanceController({DevicePerformanceRepository? repository})
      : _repository = repository ?? DevicePerformanceRepository();

  String _selectedType = 'access_point';
  String _selectedDeviceId = '';

  List<Tower> _towers = [];
  List<Camera> _cameras = [];
  List<MMT> _mmts = [];

  bool _isBootLoading = true;
  bool _isRefreshing = false;
  String? _error;
  DateTime? _lastUpdated;

  Map<String, dynamic>? _telemetry;
  Timer? _refreshTimer;

  final List<FlSpot> _rxSpots = [];
  final List<FlSpot> _txSpots = [];
  double _sampleIndex = 0;

  bool _didBootstrap = false;

  String get selectedType => _selectedType;
  String get selectedDeviceId => _selectedDeviceId;
  List<Tower> get towers => _towers;
  List<Camera> get cameras => _cameras;
  List<MMT> get mmts => _mmts;
  bool get isBootLoading => _isBootLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  Map<String, dynamic>? get telemetry => _telemetry;
  List<FlSpot> get rxSpots => List.unmodifiable(_rxSpots);
  List<FlSpot> get txSpots => List.unmodifiable(_txSpots);
  bool get didBootstrap => _didBootstrap;

  List<String> deviceOptions(String type) {
    if (type == 'camera') {
      return _cameras.map((e) => e.cameraId).where((e) => e.isNotEmpty).toList();
    }
    if (type == 'mmt') {
      return _mmts.map((e) => e.mmtId).where((e) => e.isNotEmpty).toList();
    }
    return _towers.map((e) => e.towerId).where((e) => e.isNotEmpty).toList();
  }

  String resolveInitialDeviceId(String type, String preferredId) {
    final options = deviceOptions(type);
    if (preferredId.isNotEmpty && options.any((e) => e == preferredId)) {
      return preferredId;
    }
    return options.isNotEmpty ? options.first : preferredId;
  }

  Future<void> bootstrap(Map<String, dynamic>? args) async {
    if (_didBootstrap) {
      return;
    }
    _didBootstrap = true;

    if (args != null) {
      final rawType = (args['deviceType']?.toString() ?? '').toLowerCase();
      if (rawType.contains('camera') || rawType.contains('cctv')) {
        _selectedType = 'camera';
      } else if (rawType.contains('mmt')) {
        _selectedType = 'mmt';
      } else if (rawType.contains('tower') || rawType.contains('ap') || rawType.contains('access')) {
        _selectedType = 'access_point';
      }

      final candidateId =
          args['deviceId']?.toString() ?? args['deviceName']?.toString() ?? '';
      _selectedDeviceId = candidateId.trim();
    }

    await _loadDeviceOptions();
    await refreshTelemetry(force: true);
    _startRefreshTimer();

    _isBootLoading = false;
    notifyListeners();
  }

  Future<void> _loadDeviceOptions() async {
    final towers = await _repository.getAllTowers();
    final cameras = await _repository.getAllCameras();
    final mmts = await _repository.getAllMMTs();

    _towers = towers;
    _cameras = cameras;
    _mmts = mmts;
    _selectedDeviceId = resolveInitialDeviceId(_selectedType, _selectedDeviceId);
    notifyListeners();
  }

  void updateSelectedType(String type) {
    final nextId = resolveInitialDeviceId(type, '');
    _selectedType = type;
    _selectedDeviceId = nextId;
    notifyListeners();
    refreshTelemetry(force: true);
  }

  void updateSelectedDeviceId(String deviceId) {
    _selectedDeviceId = deviceId;
    notifyListeners();
    refreshTelemetry(force: true);
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(refreshInterval, (_) {
      refreshTelemetry();
    });
  }

  Future<void> refreshTelemetry({bool force = false}) async {
    if (_selectedDeviceId.isEmpty) {
      _telemetry = null;
      _error = 'Pilih device Access Point, CCTV, atau MMT terlebih dahulu.';
      notifyListeners();
      return;
    }

    if (_isRefreshing && !force) {
      return;
    }

    _isRefreshing = true;
    _error = null;
    notifyListeners();

    final response = await _repository.getDevicePerformance(
      deviceType: _selectedType,
      deviceId: _selectedDeviceId,
    );

    if (response['success'] == true && response['data'] is Map<String, dynamic>) {
      final data = response['data'] as Map<String, dynamic>;
      _pushTrafficSample(
        rx: toDouble(data['traffic_rx_mbps']),
        tx: toDouble(data['traffic_tx_mbps']),
      );

      _telemetry = data;
      _lastUpdated = DateTime.now();
      _isRefreshing = false;
      notifyListeners();
      return;
    }

    _isRefreshing = false;
    _error = response['message']?.toString() ?? 'Gagal mengambil data telemetry.';
    notifyListeners();
  }

  void _pushTrafficSample({required double rx, required double tx}) {
    _rxSpots.add(FlSpot(_sampleIndex, rx));
    _txSpots.add(FlSpot(_sampleIndex, tx));
    _sampleIndex += 1;

    if (_rxSpots.length > maxSamples) {
      _rxSpots.removeAt(0);
    }
    if (_txSpots.length > maxSamples) {
      _txSpots.removeAt(0);
    }
  }

  double toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int toInt(dynamic value) {
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
