import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/locale/app_strings.dart';
import '../../../../core/sync/manual_scan_sync_coordinator.dart';
import '../../../../core/sync/manual_scan_sync_result.dart';
import '../../../../core/sync/sync_messages.dart';
import '../../../scan/domain/scan_repository.dart';
import '../../../scan/domain/vehicle_analysis_exception.dart';
import '../../../scan/domain/vehicle_analysis_service.dart';
import '../../../scan/domain/vehicle_scan.dart';
import '../../domain/history_list_query.dart';
import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(
    this._repository,
    this._analysis,
    this._sync, {
    required String uiLanguageCode,
  }) : _uiLang = uiLanguageCode,
       super(const HistoryState()) {
    _subscription = _repository.watchScans().listen(
      (scans) {
        final wasEmpty = state.scans.isEmpty;
        final nowHas = scans.isNotEmpty;
        final bumpInitial = wasEmpty && nowHas;
        emit(
          state.copyWith(
            isLoading: false,
            scans: scans,
            clearErrorMessage: true,
            listAnimationEpoch: bumpInitial
                ? state.listAnimationEpoch + 1
                : state.listAnimationEpoch,
          ),
        );
      },
      onError: (_) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: AppStrings.fromLanguageCode(_uiLang).historyLoadError,
          ),
        );
      },
    );
  }

  final ScanRepository _repository;
  final VehicleAnalysisService _analysis;
  final ManualScanSyncCoordinator _sync;
  final String _uiLang;

  StreamSubscription<List<VehicleScan>>? _subscription;

  void setFilter(HistoryFilter filter) {
    if (filter == state.filter) {
      return;
    }
    emit(state.copyWith(filter: filter));
  }

  void setSort(HistorySort sort) {
    if (sort == state.sort) {
      return;
    }
    emit(state.copyWith(sort: sort));
  }

  /// Pełny sync z chmurą (upload + pull), potem lista z [watchScans].
  Future<void> refresh() async {
    final previousScans = state.scans;
    emit(
      state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
        clearTransientSnack: true,
      ),
    );

    final strings = AppStrings.fromLanguageCode(_uiLang);
    final result = await _sync.syncNow(languageCode: _uiLang);

    switch (result) {
      case ManualScanSyncSuccess(:final summary):
        emit(
          state.copyWith(
            isLoading: false,
            listAnimationEpoch: summary.hasActivity
                ? state.listAnimationEpoch + 1
                : state.listAnimationEpoch,
            transientSnackMessage: SyncMessages.historyRefreshSnack(
              strings,
              summary,
            ),
          ),
        );
      case ManualScanSyncCloudUnavailable():
        await _reloadLocalOnly(previousScans);
      case ManualScanSyncFailure(:final userError):
        emit(
          state.copyWith(
            isLoading: false,
            scans: previousScans.isNotEmpty ? previousScans : state.scans,
            transientSnackMessage: SyncMessages.userError(strings, userError),
          ),
        );
    }
  }

  Future<void> _reloadLocalOnly(List<VehicleScan> fallbackScans) async {
    try {
      final scans = await _repository.getRecentScans(1 << 20);
      emit(
        state.copyWith(
          isLoading: false,
          scans: scans,
          listAnimationEpoch: state.listAnimationEpoch + 1,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          isLoading: false,
          scans: fallbackScans,
          errorMessage: fallbackScans.isEmpty
              ? AppStrings.fromLanguageCode(_uiLang).historyRefreshError
              : null,
          transientSnackMessage: fallbackScans.isNotEmpty
              ? AppStrings.fromLanguageCode(_uiLang).errorSyncCloudUnavailable
              : null,
        ),
      );
    }
  }

  Future<void> deleteScan(String id) async {
    await _repository.deleteScan(id);
  }

  Future<void> togglePublic(VehicleScan scan) async {
    if (scan.isPublic) {
      await _repository.markAsPrivate(scan.id);
    } else {
      await _repository.markAsPublic(scan.id);
    }
  }

  Future<void> retryAiAnalysis(String scanId) async {
    emit(state.copyWith(retryingScanId: scanId, clearTransientSnack: true));
    try {
      await _analysis.analyzeScan(scanId: scanId, languageCode: _uiLang);
      emit(state.copyWith(clearRetryingScanId: true));
    } on VehicleAnalysisException catch (e) {
      emit(
        state.copyWith(
          clearRetryingScanId: true,
          transientSnackMessage: AppStrings.fromLanguageCode(
            _uiLang,
          ).aiAnalysisUserMessage(e),
        ),
      );
    } on Object catch (e) {
      emit(
        state.copyWith(
          clearRetryingScanId: true,
          transientSnackMessage: AppStrings.fromLanguageCode(
            _uiLang,
          ).aiAnalysisUserMessage(e),
        ),
      );
    }
  }

  void clearTransientSnack() {
    emit(state.copyWith(clearTransientSnack: true));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
