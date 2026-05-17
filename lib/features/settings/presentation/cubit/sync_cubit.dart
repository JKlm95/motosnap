import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../scan/domain/pending_scan_sync.dart';
import '../../../scan/domain/scan_processing_coordinator.dart';
import '../../../scan/domain/scan_repository.dart';
import 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  SyncCubit(
    this._pendingSync,
    this._scans, {
    ScanProcessingCoordinator? processingCoordinator,
  }) : _processing = processingCoordinator,
       super(const SyncState());

  final PendingScanSync? _pendingSync;
  final ScanRepository _scans;
  final ScanProcessingCoordinator? _processing;

  Future<void> syncNow() async {
    final cloud = _pendingSync;
    if (cloud == null) {
      emit(
        const SyncState(
          status: ManualSyncStatus.error,
          userError: SyncUserError.cloudDisabled,
        ),
      );
      return;
    }

    emit(const SyncState(status: ManualSyncStatus.running));
    try {
      final summary = await cloud.syncAllPending(_scans);
      final queue = _processing;
      if (queue != null) {
        final lang = PlatformDispatcher.instance.locale.languageCode;
        for (final id in summary.uploadedScanIds) {
          queue.enqueue(id, lang);
        }
        await queue.enqueuePendingScans(languageCode: lang);
      }
      emit(SyncState(status: ManualSyncStatus.done, summary: summary));
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('SyncCubit.syncNow failed: $e\n$st');
      }
      emit(
        const SyncState(
          status: ManualSyncStatus.error,
          userError: SyncUserError.generic,
        ),
      );
    }
  }

  void acknowledge() {
    emit(const SyncState());
  }
}
