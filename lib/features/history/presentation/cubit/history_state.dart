import 'package:equatable/equatable.dart';

import '../../../scan/domain/vehicle_scan.dart';

class HistoryState extends Equatable {
  const HistoryState({
    this.isLoading = true,
    this.scans = const <VehicleScan>[],
    this.errorMessage,
  });

  final bool isLoading;
  final List<VehicleScan> scans;
  final String? errorMessage;

  @override
  List<Object?> get props => [isLoading, scans, errorMessage];
}
