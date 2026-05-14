import 'package:equatable/equatable.dart';

import '../../domain/vehicle_scan.dart';

enum ScanDetailPhase { loading, ready, notFound, removed }

/// Czy [busy] dotyczy wyłącznie analizy AI (do skeletonu / stanów UI).
enum ScanDetailAiBusy { no, yes }

class ScanDetailState extends Equatable {
  const ScanDetailState({
    this.phase = ScanDetailPhase.loading,
    this.scan,
    this.errorMessage,
    this.busy = false,
    this.aiBusy = ScanDetailAiBusy.no,
    this.vehicleRevealToken = 0,
  });

  final ScanDetailPhase phase;
  final VehicleScan? scan;
  final String? errorMessage;
  final bool busy;
  final ScanDetailAiBusy aiBusy;

  /// Inkrementacja po udanej analizie AI z „oczekuje” — wyzwala kaskadowy reveal w UI.
  final int vehicleRevealToken;

  ScanDetailState copyWith({
    ScanDetailPhase? phase,
    VehicleScan? scan,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? busy,
    ScanDetailAiBusy? aiBusy,
    int? vehicleRevealToken,
  }) {
    return ScanDetailState(
      phase: phase ?? this.phase,
      scan: scan ?? this.scan,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      busy: busy ?? this.busy,
      aiBusy: aiBusy ?? this.aiBusy,
      vehicleRevealToken: vehicleRevealToken ?? this.vehicleRevealToken,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    scan,
    errorMessage,
    busy,
    aiBusy,
    vehicleRevealToken,
  ];
}
