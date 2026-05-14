import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../scan/domain/vehicle_scan.dart';
import '../../../scan/domain/scan_repository.dart';
import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._repository) : super(const HistoryState()) {
    _subscription = _repository.watchScans().listen(
      (scans) => emit(HistoryState(isLoading: false, scans: scans)),
      onError: (_) => emit(
        const HistoryState(
          isLoading: false,
          errorMessage: 'Nie udało się wczytać historii.',
        ),
      ),
    );
  }

  final ScanRepository _repository;
  StreamSubscription<List<VehicleScan>>? _subscription;

  Future<void> refresh() async {
    emit(const HistoryState(isLoading: true, scans: []));
    try {
      final scans = await _repository.getRecentScans(1 << 20);
      emit(HistoryState(isLoading: false, scans: scans));
    } catch (_) {
      emit(
        const HistoryState(
          isLoading: false,
          errorMessage: 'Nie udało się odświeżyć listy.',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
