import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../scan/domain/scan_repository.dart';
import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._repository) : super(const HistoryState()) {
    _subscription = _repository.localScansChanged.listen((_) => load());
    load();
  }

  final ScanRepository _repository;
  StreamSubscription<void>? _subscription;

  Future<void> load() async {
    emit(const HistoryState(isLoading: true, scans: []));
    try {
      final scans = await _repository.loadScansOrdered();
      emit(HistoryState(isLoading: false, scans: scans));
    } catch (_) {
      emit(
        const HistoryState(
          isLoading: false,
          errorMessage: 'Nie udało się wczytać historii.',
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
