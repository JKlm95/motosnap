import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/locale/app_strings.dart';
import '../../domain/scan_repository.dart';
import '../../domain/user_vehicle_correction.dart';
import '../../domain/vehicle_analysis_exception.dart';
import '../../domain/vehicle_analysis_service.dart';
import '../../domain/vehicle_scan_status.dart';
import 'scan_detail_state.dart';

class ScanDetailCubit extends Cubit<ScanDetailState> {
  ScanDetailCubit(
    this._repository,
    this._analysis,
    this.scanId, {
    required String uiLanguageCode,
  }) : _uiLang = uiLanguageCode,
       super(const ScanDetailState());

  final ScanRepository _repository;
  final VehicleAnalysisService _analysis;
  final String scanId;
  final String _uiLang;

  AppStrings get _s => AppStrings.fromLanguageCode(_uiLang);

  Future<void> load() async {
    emit(const ScanDetailState(phase: ScanDetailPhase.loading));
    final scan = await _repository.getScan(scanId);
    if (scan == null) {
      emit(const ScanDetailState(phase: ScanDetailPhase.notFound));
      return;
    }
    emit(ScanDetailState(phase: ScanDetailPhase.ready, scan: scan));
  }

  Future<void> _reloadReady({
    String? errorMessage,
    bool bumpRevealAfterAi = false,
  }) async {
    final prevToken = state.vehicleRevealToken;
    final scan = await _repository.getScan(scanId);
    if (scan == null) {
      emit(const ScanDetailState(phase: ScanDetailPhase.notFound));
      return;
    }
    var token = prevToken;
    if (bumpRevealAfterAi &&
        scan.status == VehicleScanStatus.recognized &&
        scan.effectiveVehicleInfo != null) {
      token = prevToken + 1;
    }
    emit(
      ScanDetailState(
        phase: ScanDetailPhase.ready,
        scan: scan,
        busy: false,
        aiBusy: ScanDetailAiBusy.no,
        errorMessage: errorMessage,
        vehicleRevealToken: token,
      ),
    );
  }

  Future<void> runAiAnalysis(String languageCode) async {
    final current = state.scan;
    if (current == null) {
      return;
    }
    final wasWaiting =
        current.status == VehicleScanStatus.waitingForRecognition;
    emit(
      state.copyWith(
        busy: true,
        aiBusy: ScanDetailAiBusy.yes,
        clearErrorMessage: true,
      ),
    );
    try {
      await _analysis.analyzeScan(scanId: scanId, languageCode: languageCode);
      await _reloadReady(bumpRevealAfterAi: wasWaiting);
    } on VehicleAnalysisException catch (e) {
      await _reloadReady(errorMessage: _s.aiAnalysisUserMessage(e));
    } on Object catch (e) {
      await _reloadReady(errorMessage: _s.aiAnalysisUserMessage(e));
    }
  }

  Future<void> togglePublic() async {
    final current = state.scan;
    if (current == null) {
      return;
    }
    emit(state.copyWith(busy: true, aiBusy: ScanDetailAiBusy.no));
    try {
      if (current.isPublic) {
        await _repository.markAsPrivate(current.id);
      } else {
        await _repository.markAsPublic(current.id);
      }
      final next = await _repository.getScan(current.id);
      if (next == null) {
        emit(
          state.copyWith(
            busy: false,
            aiBusy: ScanDetailAiBusy.no,
            errorMessage: _s.errorOperationFailed,
          ),
        );
        return;
      }
      emit(
        state.copyWith(scan: next, busy: false, aiBusy: ScanDetailAiBusy.no),
      );
    } on Object catch (_) {
      emit(
        state.copyWith(
          busy: false,
          aiBusy: ScanDetailAiBusy.no,
          errorMessage: _s.errorOperationFailed,
        ),
      );
    }
  }

  Future<void> delete() async {
    final current = state.scan;
    if (current == null) {
      return;
    }
    emit(state.copyWith(busy: true, aiBusy: ScanDetailAiBusy.no));
    try {
      await _repository.deleteScan(scanId);
      emit(const ScanDetailState(phase: ScanDetailPhase.removed));
    } on Object catch (_) {
      emit(
        state.copyWith(
          busy: false,
          aiBusy: ScanDetailAiBusy.no,
          errorMessage: _s.errorDeleteFailed,
        ),
      );
    }
  }

  Future<void> saveUserCorrection(UserVehicleCorrection correction) async {
    final current = state.scan;
    if (current == null) {
      return;
    }
    emit(
      state.copyWith(
        busy: true,
        aiBusy: ScanDetailAiBusy.no,
        clearErrorMessage: true,
      ),
    );
    try {
      await _repository.updateUserCorrection(scanId, correction);
      await _reloadReady();
    } on Object catch (_) {
      await _reloadReady(errorMessage: _s.errorSaveCorrectionFailed);
    }
  }

  void clearError() {
    emit(state.copyWith(clearErrorMessage: true));
  }
}
