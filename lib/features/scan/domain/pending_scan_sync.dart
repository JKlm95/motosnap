import '../../../core/remote/sync_summary.dart';
import 'scan_repository.dart';

/// Ręczna synchronizacja — upload pending + pull z Firestore (implementacja Firebase w data).
abstract interface class PendingScanSync {
  /// Wysyła lokalne `pendingSync`, potem scala dokumenty `users/{uid}/scans/{scanId}` do Hive.
  Future<SyncSummary> syncAllPending(ScanRepository localRepository);

  /// Upload i merge pojedynczego skanu (używane przez [ScanProcessingCoordinator]).
  Future<void> syncPendingScan(ScanRepository localRepository, String scanId);
}
