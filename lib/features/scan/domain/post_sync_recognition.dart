import '../../../core/remote/sync_summary.dart';
import 'scan_repository.dart';
import 'vehicle_analysis_exception.dart';
import 'vehicle_analysis_service.dart';
import 'vehicle_scan.dart';
import 'vehicle_scan_status.dart';

/// Reguły automatycznego uruchomienia AI po udanym syncu (bez wywołań przed `pendingSync == false`).
abstract final class PostSyncRecognitionPolicy {
  static bool shouldRun(VehicleScan scan) {
    if (scan.pendingSync) {
      return false;
    }
    final url = scan.remoteImageUrl;
    if (url == null || url.isEmpty) {
      return false;
    }
    if (scan.status != VehicleScanStatus.waitingForRecognition) {
      return false;
    }
    if (scan.vehicleInfo != null) {
      return false;
    }
    return true;
  }
}

/// Po sukcesie uploadu woła [VehicleAnalysisService.analyzeScan] dla skanów z [SyncSummary.uploadedScanIds],
/// jeśli spełniają [PostSyncRecognitionPolicy]. Błędy AI nie przerywają pętli — lokalny stan ustala backend + [FirebaseVehicleAnalysisService].
final class PostSyncRecognitionCoordinator {
  PostSyncRecognitionCoordinator({
    required VehicleAnalysisService analysis,
    required ScanRepository repository,
  }) : _analysis = analysis,
       _repository = repository;

  final VehicleAnalysisService _analysis;
  final ScanRepository _repository;

  Future<void> runAfterSyncIfNeeded({
    required SyncSummary summary,
    required String languageCode,
  }) async {
    if (summary.uploadedScanIds.isEmpty) {
      return;
    }
    final lang = languageCode.toLowerCase().startsWith('pl') ? 'pl' : 'en';
    for (final id in summary.uploadedScanIds) {
      final scan = await _repository.getScan(id);
      if (scan == null || !PostSyncRecognitionPolicy.shouldRun(scan)) {
        continue;
      }
      try {
        await _analysis.analyzeScan(scanId: id, languageCode: lang);
      } on VehicleAnalysisException {
        // Stan `failed` / komunikat zapisane lokalnie przez implementację analizy.
      } on Object {
        // Nie blokuj kolejnych skanów; szczegóły po stronie logów usługi analizy.
      }
    }
  }
}
