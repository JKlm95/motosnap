import 'package:flutter_test/flutter_test.dart';

import 'package:motosnap/features/scan/domain/vehicle_scan.dart';

void main() {
  test('VehicleScan — roundtrip JSON', () {
    final original = VehicleScan(
      id: 'abc',
      imagePath: '/tmp/x.jpg',
      latitude: 52.1,
      longitude: 21.0,
      capturedAt: DateTime.utc(2026, 5, 14, 12),
      syncStatus: ScanSyncStatus.pending,
    );

    final json = original.toJson();
    final restored = VehicleScan.fromJson(json);

    expect(restored.id, original.id);
    expect(restored.imagePath, original.imagePath);
    expect(restored.latitude, original.latitude);
    expect(restored.longitude, original.longitude);
    expect(
      restored.capturedAt.toIso8601String(),
      original.capturedAt.toIso8601String(),
    );
    expect(restored.syncStatus, original.syncStatus);
  });
}
