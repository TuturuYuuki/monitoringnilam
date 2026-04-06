import 'package:monitoring/pages/diagnostics/global/data/global_diagnostics_repository.dart';
import 'package:monitoring/pages/diagnostics/global/domain/global_diagnostics_snapshot.dart';

class GlobalDiagnosticsController {
  final GlobalDiagnosticsRepository _repository;

  GlobalDiagnosticsController({GlobalDiagnosticsRepository? repository})
      : _repository = repository ?? GlobalDiagnosticsRepository();

  bool isLoading = false;
  bool didBootstrap = false;
  bool isLiveData = false;
  String? errorMessage;
  GlobalDiagnosticsSnapshot snapshot = GlobalDiagnosticsSnapshot.empty();

  Future<void> bootstrap() async {
    if (didBootstrap) {
      return;
    }
    didBootstrap = true;
    await refresh();
  }

  Future<void> refresh() async {
    isLoading = true;
    final result = await _repository.loadSnapshot();
    snapshot = result.snapshot;
    isLiveData = result.isLiveData;
    errorMessage = result.errorMessage;
    isLoading = false;
  }
}
