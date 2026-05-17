import '../../../core/remote/sync_summary.dart';
import 'scan_repository.dart';

/// Ręczna synchronizacja oczekujących skanów — implementacja Firebase w warstwie data.
abstract interface class PendingScanSync {
  Future<SyncSummary> syncAllPending(ScanRepository localRepository);

  /// Upload i merge pojedynczego skanu (używane przez [ScanProcessingCoordinator]).
  Future<void> syncPendingScan(ScanRepository localRepository, String scanId);
}
