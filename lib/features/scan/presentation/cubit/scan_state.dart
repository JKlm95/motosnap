import 'package:equatable/equatable.dart';

import '../../domain/vehicle_scan.dart';

enum ScanFlowPhase {
  idle,
  requestingPermissions,
  capturing,
  saving,
  syncingCloud,
  recognizingVehicle,
  success,
  error,
}

class ScanState extends Equatable {
  const ScanState({
    this.phase = ScanFlowPhase.idle,
    this.savedScan,
    this.errorMessage,
    this.backgroundQueued = false,
  });

  final ScanFlowPhase phase;
  final VehicleScan? savedScan;
  final String? errorMessage;

  /// Sync + AI zostały dodane do kolejki w aplikacji (nie czekamy na wynik).
  final bool backgroundQueued;

  @override
  List<Object?> get props => [phase, savedScan, errorMessage, backgroundQueued];
}
