import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/locale/app_strings.dart';
import '../../../scan/domain/scan_repository.dart';
import '../../../scan/domain/vehicle_analysis_exception.dart';
import '../../../scan/domain/vehicle_analysis_service.dart';
import '../../../scan/domain/vehicle_scan.dart';
import '../../domain/history_list_query.dart';
import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(
    this._repository,
    this._analysis, {
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

  Future<void> refresh() async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));
    try {
      final scans = await _repository.getRecentScans(1 << 20);
      emit(
        state.copyWith(
          isLoading: false,
          scans: scans,
          listAnimationEpoch: state.listAnimationEpoch + 1,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: AppStrings.fromLanguageCode(
            _uiLang,
          ).historyRefreshError,
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
