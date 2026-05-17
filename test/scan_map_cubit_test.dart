import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motosnap/features/map/presentation/cubit/scan_map_cubit.dart';
import 'package:motosnap/features/scan/domain/scan_location.dart';
import 'package:motosnap/features/scan/domain/scan_repository.dart';
import 'package:motosnap/features/scan/domain/user_vehicle_correction.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan_status.dart';

VehicleScan _scan({required String id, double lat = 52, double lng = 21}) {
  final now = DateTime.utc(2026, 2, 1);
  return VehicleScan(
    id: id,
    localImagePath: '/tmp/$id.jpg',
    createdAt: now,
    updatedAt: now,
    status: VehicleScanStatus.recognized,
    location: ScanLocation(latitude: lat, longitude: lng),
    pendingSync: false,
  );
}

void main() {
  late _FakeRepo repo;

  setUp(() {
    repo = _FakeRepo();
  });

  test('emituje tylko skany z poprawnym GPS', () async {
    final cubit = ScanMapCubit(repo);
    addTearDown(cubit.close);

    repo.emit([_scan(id: 'ok'), _scan(id: 'bad', lat: 0, lng: 0)]);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.items.length, 1);
    expect(cubit.state.items.first.scanId, 'ok');
    expect(cubit.state.isLoading, isFalse);
  });

  test('selectMarker ustawia selectedScanId', () async {
    final cubit = ScanMapCubit(repo);
    addTearDown(cubit.close);

    repo.emit([_scan(id: 'x')]);
    await Future<void>.delayed(Duration.zero);

    cubit.selectMarker('x');
    expect(cubit.state.selectedScanId, 'x');

    cubit.clearSelection();
    expect(cubit.state.selectedScanId, isNull);
  });

  test('empty state gdy brak skanów z lokalizacją', () async {
    final cubit = ScanMapCubit(repo);
    addTearDown(cubit.close);

    repo.emit([_scan(id: 'z', lat: 0, lng: 0)]);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.isEmpty, isTrue);
    expect(cubit.state.items, isEmpty);
  });
}

final class _FakeRepo implements ScanRepository {
  final _controller = StreamController<List<VehicleScan>>.broadcast();

  void emit(List<VehicleScan> scans) => _controller.add(scans);

  @override
  Stream<List<VehicleScan>> watchScans() => _controller.stream;

  @override
  Future<List<VehicleScan>> getRecentScans(int limit) async => [];

  @override
  Future<VehicleScan?> getScan(String id) async => null;

  @override
  Future<VehicleScan> createScan({required XFile capturedPhoto}) =>
      throw UnimplementedError();

  @override
  Future<void> updateScan(VehicleScan scan) => throw UnimplementedError();

  @override
  Future<void> deleteScan(String id) => throw UnimplementedError();

  @override
  Future<void> markAsPublic(String id) => throw UnimplementedError();

  @override
  Future<void> markAsPrivate(String id) => throw UnimplementedError();

  @override
  Future<void> updateUserCorrection(
    String scanId,
    UserVehicleCorrection correction,
  ) => throw UnimplementedError();
}
