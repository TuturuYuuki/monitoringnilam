import 'package:monitoring/pages/diagnostics/global/domain/global_diagnostics_snapshot.dart';
import 'package:monitoring/services/api_service.dart';

class GlobalDiagnosticsRepository {
  final ApiService _apiService;

  GlobalDiagnosticsRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<GlobalDiagnosticsLoadResult> loadSnapshot() async {
    final response = await _apiService.getGlobalDiagnostics();

    if (response['success'] == true &&
        response['data'] is Map<String, dynamic>) {
      final data = response['data'] as Map<String, dynamic>;
      return GlobalDiagnosticsLoadResult(
        snapshot: GlobalDiagnosticsSnapshot.fromApi(data),
        isLiveData: true,
      );
    }

    return GlobalDiagnosticsLoadResult(
      snapshot: GlobalDiagnosticsSnapshot.empty(),
      isLiveData: false,
      errorMessage: response['message']?.toString() ??
          'Failed to fetch global diagnostics',
    );
  }
}

class GlobalDiagnosticsLoadResult {
  final GlobalDiagnosticsSnapshot snapshot;
  final bool isLiveData;
  final String? errorMessage;

  const GlobalDiagnosticsLoadResult({
    required this.snapshot,
    required this.isLiveData,
    this.errorMessage,
  });
}
