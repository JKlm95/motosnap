import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../scan/domain/pending_scan_sync.dart';
import '../../../scan/domain/post_sync_recognition.dart';
import '../../../scan/domain/scan_repository.dart';
import 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  SyncCubit(
    this._pendingSync,
    this._scans, {
    PostSyncRecognitionCoordinator? postSyncRecognition,
  }) : _postSyncRecognition = postSyncRecognition,
       super(const SyncState());

  final PendingScanSync? _pendingSync;
  final ScanRepository _scans;
  final PostSyncRecognitionCoordinator? _postSyncRecognition;

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
      final coord = _postSyncRecognition;
      if (coord != null && summary.uploadedScanIds.isNotEmpty) {
        await coord.runAfterSyncIfNeeded(
          summary: summary,
          languageCode: PlatformDispatcher.instance.locale.languageCode,
        );
      }
      emit(SyncState(status: ManualSyncStatus.done, summary: summary));
    } on Object catch (e, st) {
      debugPrint('SyncCubit.syncNow failed: $e\n$st');
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
