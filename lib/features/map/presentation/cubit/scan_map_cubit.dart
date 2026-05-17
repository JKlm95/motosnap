import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../scan/domain/scan_repository.dart';
import '../../../scan/domain/vehicle_scan.dart';
import '../../domain/scan_map_item.dart';
import 'scan_map_state.dart';

class ScanMapCubit extends Cubit<ScanMapState> {
  ScanMapCubit(this._repository) : super(const ScanMapState()) {
    _subscription = _repository.watchScans().listen(
      _onScans,
      onError: (_) {
        emit(state.copyWith(isLoading: false));
      },
    );
  }

  final ScanRepository _repository;
  StreamSubscription<List<VehicleScan>>? _subscription;

  void _onScans(List<VehicleScan> scans) {
    final items = scanMapItemsFromScans(scans);
    final selected = state.selectedScanId;
    final stillVisible =
        selected != null && items.any((i) => i.scanId == selected);
    emit(
      ScanMapState(
        items: items,
        selectedScanId: stillVisible ? selected : null,
        isLoading: false,
      ),
    );
  }

  void selectMarker(String scanId) {
    if (!state.items.any((i) => i.scanId == scanId)) {
      return;
    }
    emit(state.copyWith(selectedScanId: scanId));
  }

  void clearSelection() {
    if (state.selectedScanId == null) {
      return;
    }
    emit(state.copyWith(clearSelection: true));
  }

  @override
  Future<void> close() {
    unawaited(_subscription?.cancel());
    return super.close();
  }
}
