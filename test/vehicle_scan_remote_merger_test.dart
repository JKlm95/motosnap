import 'package:flutter_test/flutter_test.dart';

import 'package:motosnap/features/scan/data/vehicle_scan_remote_merger.dart';
import 'package:motosnap/features/scan/domain/scan_location.dart';
import 'package:motosnap/features/scan/domain/user_vehicle_correction.dart';
import 'package:motosnap/features/scan/domain/vehicle_info.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan_status.dart';
import 'package:motosnap/features/scan/domain/vehicle_type.dart';

void main() {
  final t0 = DateTime.utc(2026, 5, 1, 12);

  VehicleScan baseLocal({
    VehicleScanStatus status = VehicleScanStatus.waitingForRecognition,
    VehicleInfo? vehicleInfo,
    UserVehicleCorrection? userCorrection,
  }) {
    return VehicleScan(
      id: 's1',
      localImagePath: '/tmp/a.jpg',
      remoteImageUrl: null,
      createdAt: t0,
      updatedAt: t0,
      status: status,
      location: const ScanLocation(latitude: 1, longitude: 2),
      vehicleInfo: vehicleInfo,
      userCorrection: userCorrection,
      recognizedAt: null,
      isPublic: false,
      recognitionError: null,
      pendingSync: true,
      syncLastError: null,
    );
  }

  test(
    'merge: lokalne recognized + pusty vehicle_info w chmurze nie tracą danych AI',
    () {
      final local = baseLocal(
        status: VehicleScanStatus.recognized,
        vehicleInfo: const VehicleInfo(
          vehicleType: VehicleType.car,
          brand: 'LocalAI',
          model: 'X',
        ),
      );
      final remote = <String, dynamic>{
        'status': 'waitingForRecognition',
        'is_public': false,
      };

      final merged = VehicleScanRemoteMerger.mergeAfterFirestoreFetch(
        local: local,
        remote: remote,
        remoteImageUrl: 'https://cdn.example/x.jpg',
      );

      expect(merged.status, VehicleScanStatus.recognized);
      expect(merged.vehicleInfo?.brand, 'LocalAI');
      expect(merged.pendingSync, isFalse);
      expect(merged.remoteImageUrl, 'https://cdn.example/x.jpg');
    },
  );

  test('merge: pełny vehicle_info z Firestore nadpisuje lokalny', () {
    final local = baseLocal(
      status: VehicleScanStatus.waitingForRecognition,
      vehicleInfo: const VehicleInfo(
        vehicleType: VehicleType.car,
        brand: 'Old',
      ),
    );
    final remote = <String, dynamic>{
      'status': 'recognized',
      'vehicle_info': <String, dynamic>{
        'vehicle_type': 'motorcycle',
        'brand': 'Remote',
        'model': 'R1',
        'generation': null,
        'production_years': null,
        'possible_engines': <String>[],
        'short_description': null,
        'confidence': 0.5,
        'source_language': 'pl',
        'was_user_corrected': true,
      },
      'is_public': false,
    };

    final merged = VehicleScanRemoteMerger.mergeAfterFirestoreFetch(
      local: local,
      remote: remote,
      remoteImageUrl: 'https://cdn.example/x.jpg',
    );

    expect(merged.status, VehicleScanStatus.recognized);
    expect(merged.vehicleInfo?.wasUserCorrected, isFalse);
    expect(merged.vehicleInfo?.brand, 'Remote');
    expect(merged.vehicleInfo?.vehicleType, VehicleType.motorcycle);
  });

  test('merge: nowsza korekta lokalna wygrywa nad starszą zdalną', () {
    final newer = UserVehicleCorrection(
      vehicleType: VehicleType.car,
      brand: 'Nowa',
      correctedAt: DateTime.utc(2026, 5, 10),
    );
    final local = baseLocal(userCorrection: newer);
    final remote = <String, dynamic>{
      'status': 'waitingForRecognition',
      'user_correction': <String, dynamic>{
        'vehicle_type': 'car',
        'brand': 'Stara',
        'corrected_at': '2026-05-01T10:00:00.000Z',
        'possible_engines': <String>[],
        'source': 'user',
      },
      'is_public': false,
    };

    final merged = VehicleScanRemoteMerger.mergeAfterFirestoreFetch(
      local: local,
      remote: remote,
      remoteImageUrl: 'https://cdn.example/x.jpg',
    );

    expect(merged.userCorrection?.brand, 'Nowa');
  });
}
