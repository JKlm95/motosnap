import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/core/locale/app_strings.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan_status.dart';
import 'package:motosnap/features/scan/domain/vehicle_type.dart';

void main() {
  group('AppStrings PL', () {
    final s = AppStrings.fromLanguageCode('pl');

    test('vehicleType — przykładowe mapowanie', () {
      expect(s.vehicleType(VehicleType.car), 'Samochód');
      expect(s.vehicleType(VehicleType.aircraft), 'Samolot');
      expect(s.vehicleType(VehicleType.emergency), 'Pojazd uprzywilejowany');
    });

    test('scanStatus', () {
      expect(s.scanStatus(VehicleScanStatus.draft), 'Szkic');
      expect(
        s.scanStatus(VehicleScanStatus.waitingForRecognition),
        'Oczekuje na rozpoznanie',
      );
      expect(s.scanStatus(VehicleScanStatus.recognized), 'Rozpoznano');
      expect(s.scanStatus(VehicleScanStatus.failed), 'Rozpoznanie nieudane');
    });

    test('errorSyncScanConnection', () {
      expect(
        s.errorSyncScanConnection,
        'Nie udało się zsynchronizować skanu. Sprawdź połączenie internetowe i spróbuj ponownie.',
      );
    });
  });

  group('AppStrings EN', () {
    final s = AppStrings.fromLanguageCode('en');

    test('vehicleType', () {
      expect(s.vehicleType(VehicleType.car), 'Car');
      expect(s.vehicleType(VehicleType.boat), 'Boat / vessel');
    });

    test('scanStatus', () {
      expect(s.scanStatus(VehicleScanStatus.failed), 'Recognition failed');
    });

    test('errorSyncScanConnection', () {
      expect(
        s.errorSyncScanConnection,
        'Could not sync the scan. Check your internet connection and try again.',
      );
    });
  });
}
