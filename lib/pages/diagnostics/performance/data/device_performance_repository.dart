import 'package:monitoring/models/camera_model.dart';
import 'package:monitoring/models/mmt_model.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/services/api_service.dart';

class DevicePerformanceRepository {
  final ApiService _apiService;

  DevicePerformanceRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<List<Tower>> getAllTowers() => _apiService.getAllTowers();

  Future<List<Camera>> getAllCameras() => _apiService.getAllCameras();

  Future<List<MMT>> getAllMMTs() => _apiService.getAllMMTs();

  Future<Map<String, dynamic>> getDevicePerformance({
    required String deviceType,
    required String deviceId,
  }) {
    return _apiService.getDevicePerformance(
      deviceType: deviceType,
      deviceId: deviceId,
    );
  }
}
