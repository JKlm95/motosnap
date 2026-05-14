import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../scan/domain/pending_scan_sync.dart';
import '../../../scan/domain/scan_repository.dart';
import 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  SyncCubit(this._pendingSync, this._scans) : super(const SyncState());

  final PendingScanSync? _pendingSync;
  final ScanRepository _scans;

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
