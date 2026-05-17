import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/features/map/domain/scan_map_location_filter.dart';
import 'package:motosnap/features/scan/domain/scan_location.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan_status.dart';

VehicleScan _scan({
  required String id,
  required ScanLocation location,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime.utc(2026, 1, 1);
  return VehicleScan(
    id: id,
    localImagePath: '/tmp/$id.jpg',
    createdAt: now,
    updatedAt: now,
    status: VehicleScanStatus.waitingForRecognition,
    location: location,
    pendingSync: false,
  );
}

void main() {
  test('hasMapEligibleLocation — poprawne współrzędne', () {
    expect(
      hasMapEligibleLocation(
        const ScanLocation(latitude: 52.1, longitude: 21.0),
      ),
      isTrue,
    );
  });

  test('hasMapEligibleLocation — odrzuca 0,0', () {
    expect(
      hasMapEligibleLocation(const ScanLocation(latitude: 0, longitude: 0)),
      isFalse,
    );
  });

  test('hasMapEligibleLocation — odrzuca poza zakresem', () {
    expect(
      hasMapEligibleLocation(const ScanLocation(latitude: 95, longitude: 21)),
      isFalse,
    );
  });

  test('scansWithMapEligibleLocation — tylko skany z GPS', () {
    final result = scansWithMapEligibleLocation([
      _scan(
        id: 'a',
        location: const ScanLocation(latitude: 50, longitude: 20),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      _scan(id: 'b', location: const ScanLocation(latitude: 0, longitude: 0)),
      _scan(
        id: 'c',
        location: const ScanLocation(latitude: 51, longitude: 19),
        createdAt: DateTime.utc(2026, 1, 2),
      ),
    ]);
    expect(result.map((s) => s.id), ['c', 'a']);
  });

  test('scansWithMapEligibleLocation — limit 500', () {
    final scans = List.generate(
      600,
      (i) => _scan(
        id: 's$i',
        location: ScanLocation(latitude: 50 + i * 0.0001, longitude: 20),
      ),
    );
    expect(scansWithMapEligibleLocation(scans).length, kScanMapMaxMarkers);
  });
}
