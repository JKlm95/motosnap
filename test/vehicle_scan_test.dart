import 'package:flutter_test/flutter_test.dart';

import 'package:motosnap/features/scan/domain/scan_location.dart';
import 'package:motosnap/features/scan/domain/vehicle_info.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan_status.dart';
import 'package:motosnap/features/scan/domain/vehicle_type.dart';

void main() {
  test('VehicleScan — roundtrip JSON (v2)', () {
    final created = DateTime.utc(2026, 5, 14, 12);
    final original = VehicleScan(
      id: 'abc',
      localImagePath: '/tmp/x.jpg',
      remoteImageUrl: null,
      createdAt: created,
      updatedAt: created,
      status: VehicleScanStatus.waitingForRecognition,
      location: const ScanLocation(
        latitude: 52.1,
        longitude: 21.0,
        city: 'Kraków',
        country: 'PL',
        displayName: 'Kraków, PL',
      ),
      vehicleInfo: const VehicleInfo(
        vehicleType: VehicleType.car,
        brand: 'Test',
        model: 'One',
        confidence: 0.9,
      ),
      isPublic: false,
      recognitionError: null,
      pendingSync: true,
      syncLastError: null,
    );

    final json = original.toJson();
    expect(json['schema_version'], 3);
    final restored = VehicleScan.fromJson(json);

    expect(restored.id, original.id);
    expect(restored.localImagePath, original.localImagePath);
    expect(
      restored.createdAt.toIso8601String(),
      original.createdAt.toIso8601String(),
    );
    expect(
      restored.updatedAt.toIso8601String(),
      original.updatedAt.toIso8601String(),
    );
    expect(restored.status, original.status);
    expect(restored.location.latitude, original.location.latitude);
    expect(restored.location.city, original.location.city);
    expect(restored.vehicleInfo?.brand, original.vehicleInfo?.brand);
    expect(restored.pendingSync, original.pendingSync);
  });

  test('VehicleScan — migracja legacy JSON', () {
    final legacy = <String, dynamic>{
      'id': 'legacy-1',
      'image_path': '/old/path.jpg',
      'latitude': 50.0,
      'longitude': 19.0,
      'captured_at': '2026-01-01T10:00:00.000Z',
      'sync_status': 'pending',
    };
    final scan = VehicleScan.fromJson(legacy);
    expect(scan.localImagePath, '/old/path.jpg');
    expect(scan.status, VehicleScanStatus.waitingForRecognition);
    expect(scan.location.latitude, 50.0);
  });
}
