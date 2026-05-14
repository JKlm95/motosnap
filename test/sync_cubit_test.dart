import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/core/remote/sync_summary.dart';
import 'package:motosnap/features/scan/domain/pending_scan_sync.dart';
import 'package:motosnap/features/scan/domain/scan_repository.dart';
import 'package:motosnap/features/scan/domain/user_vehicle_correction.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan.dart';
import 'package:motosnap/features/settings/presentation/cubit/sync_cubit.dart';
import 'package:motosnap/features/settings/presentation/cubit/sync_state.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('SyncCubit — brak backendu (null) kończy się błędem', () async {
    final cubit = SyncCubit(null, _FakeRepo());
    await cubit.syncNow();
    expect(cubit.state.status, ManualSyncStatus.error);
    expect(cubit.state.errorMessage, isNotNull);
    await cubit.close();
  });

  test('SyncCubit — stub zwraca podsumowanie', () async {
    final cubit = SyncCubit(_StubPendingSync(), _FakeRepo());
    await cubit.syncNow();
    expect(cubit.state.status, ManualSyncStatus.done);
    expect(cubit.state.summary, const SyncSummary(uploaded: 1, failed: 0));
    await cubit.close();
  });
}

final class _StubPendingSync implements PendingScanSync {
  @override
  Future<SyncSummary> syncAllPending(ScanRepository localRepository) async {
    return const SyncSummary(uploaded: 1, failed: 0);
  }
}

final class _FakeRepo implements ScanRepository {
  @override
  Stream<List<VehicleScan>> watchScans() => throw UnimplementedError();

  @override
  Future<List<VehicleScan>> getRecentScans(int limit) async => const [];

  @override
  Future<VehicleScan?> getScan(String id) async => null;

  @override
  Future<VehicleScan> createScan({required XFile capturedPhoto}) =>
      throw UnimplementedError();

  @override
  Future<void> updateScan(VehicleScan scan) async {}

  @override
  Future<void> deleteScan(String id) async {}

  @override
  Future<void> markAsPublic(String id) async {}

  @override
  Future<void> markAsPrivate(String id) async {}

  @override
  Future<void> updateUserCorrection(
    String scanId,
    UserVehicleCorrection correction,
  ) async {}
}
