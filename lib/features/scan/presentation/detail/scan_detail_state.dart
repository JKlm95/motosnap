import 'package:equatable/equatable.dart';

import '../../domain/vehicle_scan.dart';

enum ScanDetailPhase { loading, ready, notFound, removed }

class ScanDetailState extends Equatable {
  const ScanDetailState({
    this.phase = ScanDetailPhase.loading,
    this.scan,
    this.errorMessage,
    this.busy = false,
  });

  final ScanDetailPhase phase;
  final VehicleScan? scan;
  final String? errorMessage;
  final bool busy;

  @override
  List<Object?> get props => [phase, scan, errorMessage, busy];
}
