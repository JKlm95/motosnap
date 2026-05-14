import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/scan_repository.dart';
import 'scan_detail_state.dart';

class ScanDetailCubit extends Cubit<ScanDetailState> {
  ScanDetailCubit(this._repository, this.scanId)
    : super(const ScanDetailState());

  final ScanRepository _repository;
  final String scanId;

  Future<void> load() async {
    emit(const ScanDetailState(phase: ScanDetailPhase.loading));
    final scan = await _repository.getScan(scanId);
    if (scan == null) {
      emit(const ScanDetailState(phase: ScanDetailPhase.notFound));
      return;
    }
    emit(ScanDetailState(phase: ScanDetailPhase.ready, scan: scan));
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
    } on Object catch (e) {
      emit(
        ScanDetailState(
          phase: ScanDetailPhase.ready,
          scan: current,
          busy: false,
          errorMessage: 'Operacja nie powiodła się: $e',
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
    } on Object catch (e) {
      emit(
        ScanDetailState(
          phase: ScanDetailPhase.ready,
          scan: current,
          busy: false,
          errorMessage: 'Usuwanie nie powiodło się: $e',
        ),
      );
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
