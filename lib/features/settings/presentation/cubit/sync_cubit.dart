import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/sync/manual_scan_sync_coordinator.dart';
import '../../../../core/sync/manual_scan_sync_result.dart';
import 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  SyncCubit(this._sync, {required String uiLanguageCode})
    : _uiLang = uiLanguageCode,
      super(const SyncState());

  final ManualScanSyncCoordinator _sync;
  final String _uiLang;

  Future<void> syncNow() async {
    emit(const SyncState(status: ManualSyncStatus.running));
    final result = await _sync.syncNow(languageCode: _uiLang);
    switch (result) {
      case ManualScanSyncSuccess(:final summary):
        emit(SyncState(status: ManualSyncStatus.done, summary: summary));
      case ManualScanSyncCloudUnavailable():
        emit(
          const SyncState(
            status: ManualSyncStatus.error,
            userError: SyncUserError.cloudDisabled,
          ),
        );
      case ManualScanSyncFailure(:final userError):
        emit(SyncState(status: ManualSyncStatus.error, userError: userError));
    }
  }

  void acknowledge() {
    emit(const SyncState());
  }
}
