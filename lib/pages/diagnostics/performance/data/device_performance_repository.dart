import 'package:monitoring/models/camera_model.dart';
import 'package:monitoring/models/mmt_model.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/models/nvr_model.dart';
import 'package:monitoring/models/switch_model.dart';
import 'package:monitoring/models/pc_model.dart';
import 'package:monitoring/services/api_service.dart';

class DevicePerformanceRepository {
  final ApiService _apiService;

  DevicePerformanceRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<List<Tower>> getAllTowers() => _apiService.getAllTowers();

  Future<List<Camera>> getAllCameras() => _apiService.getAllCameras();

  Future<List<MMT>> getAllMMTs() => _apiService.getAllMMTs();

  Future<List<Map<String, dynamic>>> getAllMasterLocations() =>
      _apiService.getAllMasterLocations();

  Future<Map<String, dynamic>> getDevicePerformance({
    required String deviceType,
    required String deviceId,
    int? hours,
  }) {
    return _apiService.getDevicePerformance(
      deviceType: deviceType,
      deviceId: deviceId,
      hours: hours,
    );
  }

  Future<Map<String, dynamic>> getGlobalDiagnostics({int? hours}) {
    return _apiService.getGlobalDiagnostics(hours: hours);
  }

  Future<List<NVR>> getAllNVRs() => _apiService.getAllNVRs();

  Future<List<SwitchModel>> getAllSwitches() => _apiService.getAllSwitches();

  Future<List<PCModel>> getAllPCs() => _apiService.getAllPCs();
}