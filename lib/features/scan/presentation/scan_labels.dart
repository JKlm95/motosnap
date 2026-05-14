import '../domain/vehicle_scan_status.dart';

extension VehicleScanStatusUi on VehicleScanStatus {
  String get labelPl {
    return switch (this) {
      VehicleScanStatus.draft => 'Szkic',
      VehicleScanStatus.waitingForRecognition => 'Oczekuje na rozpoznanie',
      VehicleScanStatus.recognized => 'Rozpoznano',
      VehicleScanStatus.failed => 'Błąd',
    };
  }
}
