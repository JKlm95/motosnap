import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/locale/app_strings.dart';
import '../../domain/scan_repository.dart';
import '../../domain/user_vehicle_correction.dart';
import '../../domain/vehicle_analysis_exception.dart';
import '../../domain/vehicle_analysis_service.dart';
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

  Future<void> _emitReadyFromRepo({String? errorMessage}) async {
    final scan = await _repository.getScan(scanId);
    if (scan == null) {
      emit(const ScanDetailState(phase: ScanDetailPhase.notFound));
      return;
    }
    emit(
      ScanDetailState(
        phase: ScanDetailPhase.ready,
        scan: scan,
        busy: false,
        errorMessage: errorMessage,
      ),
    );
  }

  Future<void> runAiAnalysis(String languageCode) async {
    final current = state.scan;
    if (current == null) {
      return;
    }
    emit(
      ScanDetailState(
        phase: ScanDetailPhase.ready,
        scan: current,
        busy: true,
        errorMessage: null,
      ),
    );
    try {
      await _analysis.analyzeScan(scanId: scanId, languageCode: languageCode);
      await _emitReadyFromRepo();
    } on VehicleAnalysisException catch (e) {
      await _emitReadyFromRepo(errorMessage: _s.aiAnalysisUserMessage(e));
    } on Object catch (e) {
      await _emitReadyFromRepo(errorMessage: _s.aiAnalysisUserMessage(e));
    }
  }

  Future<void> togglePublic() async {
    final current = state.scan;
    if (current == null) {
      return;
    }
    emit(
      ScanDetailState(phase: ScanDetailPhase.ready, scan: current, busy: true),
    );
    try {
      if (current.isPublic) {
        await _repository.markAsPrivate(current.id);
      } else {
        await _repository.markAsPublic(current.id);
      }
      final next = await _repository.getScan(current.id);
      emit(
        ScanDetailState(phase: ScanDetailPhase.ready, scan: next, busy: false),
      );
    } on Object catch (_) {
      emit(
        ScanDetailState(
          phase: ScanDetailPhase.ready,
          scan: current,
          busy: false,
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
    emit(
      ScanDetailState(phase: ScanDetailPhase.ready, scan: current, busy: true),
    );
    try {
      await _repository.deleteScan(scanId);
      emit(const ScanDetailState(phase: ScanDetailPhase.removed));
    } on Object catch (_) {
      emit(
        ScanDetailState(
          phase: ScanDetailPhase.ready,
          scan: current,
          busy: false,
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
      ScanDetailState(
        phase: ScanDetailPhase.ready,
        scan: current,
        busy: true,
        errorMessage: null,
      ),
    );
    try {
      await _repository.updateUserCorrection(scanId, correction);
      await _emitReadyFromRepo();
    } on Object catch (_) {
      await _emitReadyFromRepo(errorMessage: _s.errorSaveCorrectionFailed);
    }
  }

  void clearError() {
    emit(
      ScanDetailState(
        phase: state.phase,
        scan: state.scan,
        busy: state.busy,
        errorMessage: null,
      ),
    );
  }
}
