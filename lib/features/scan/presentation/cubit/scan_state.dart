import 'package:equatable/equatable.dart';

import '../../domain/vehicle_scan.dart';

enum ScanFlowPhase {
  idle,
  requestingPermissions,
  capturing,
  saving,
  success,
  error,
}

class ScanState extends Equatable {
  const ScanState({
    this.phase = ScanFlowPhase.idle,
    this.savedScan,
    this.errorMessage,
  });

  final ScanFlowPhase phase;
  final VehicleScan? savedScan;
  final String? errorMessage;

  @override
  List<Object?> get props => [phase, savedScan, errorMessage];
}
