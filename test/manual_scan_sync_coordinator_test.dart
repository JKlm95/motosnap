import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/core/firebase/cloud_sync_availability.dart';
import 'package:motosnap/core/remote/sync_summary.dart';
import 'package:motosnap/core/sync/manual_scan_sync_coordinator.dart';
import 'package:motosnap/core/sync/manual_scan_sync_result.dart';
import 'package:motosnap/core/sync/sync_user_error.dart';
import 'package:motosnap/features/scan/domain/pending_scan_sync.dart';
import 'package:motosnap/features/scan/domain/scan_repository.dart';
import 'package:motosnap/features/scan/domain/user_vehicle_correction.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('cloud unavailable → ManualScanSyncCloudUnavailable', () async {
    final coord = ManualScanSyncCoordinator(
      repository: _FakeRepo(),
      cloudAvailability: const CloudSyncAvailability(available: false),
      pendingSync: _RecordingPendingSync(),
    );
    final r = await coord.syncNow(languageCode: 'pl');
    expect(r, isA<ManualScanSyncCloudUnavailable>());
  });

  test('wywołuje syncAllPending i zwraca summary', () async {
    final pending = _RecordingPendingSync(
      summary: const SyncSummary(
        uploaded: 0,
        failed: 0,
        updated: 1,
        updatedScanIds: ['s1'],
      ),
    );
    final coord = ManualScanSyncCoordinator(
      repository: _FakeRepo(),
      cloudAvailability: const CloudSyncAvailability(available: true),
      pendingSync: pending,
    );
    final r = await coord.syncNow(languageCode: 'pl');
    expect(r, isA<ManualScanSyncSuccess>());
    expect(pending.syncCalls, 1);
    final success = r as ManualScanSyncSuccess;
    expect(success.summary.updated, 1);
  });

  test('wyjątek z syncAllPending → ManualScanSyncFailure', () async {
    final coord = ManualScanSyncCoordinator(
      repository: _FakeRepo(),
      cloudAvailability: const CloudSyncAvailability(available: true),
      pendingSync: _ThrowingPendingSync(),
    );
    final r = await coord.syncNow(languageCode: 'pl');
    expect(r, isA<ManualScanSyncFailure>());
    expect((r as ManualScanSyncFailure).userError, SyncUserError.notSignedIn);
  });
}

final class _RecordingPendingSync implements PendingScanSync {
  _RecordingPendingSync({
    this.summary = const SyncSummary(uploaded: 0, failed: 0),
  });

  final SyncSummary summary;
  int syncCalls = 0;

  @override
  Future<SyncSummary> syncAllPending(ScanRepository localRepository) async {
    syncCalls++;
    return summary;
  }

  @override
  Future<void> syncPendingScan(
    ScanRepository localRepository,
    String scanId,
  ) async {}
}

final class _ThrowingPendingSync implements PendingScanSync {
  @override
  Future<SyncSummary> syncAllPending(ScanRepository localRepository) async {
    throw StateError('Brak zalogowanego użytkownika.');
  }

  @override
  Future<void> syncPendingScan(
    ScanRepository localRepository,
    String scanId,
  ) async {}
}

final class _FakeRepo implements ScanRepository {
  @override
  Stream<List<VehicleScan>> watchScans() => Stream.value(const []);

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
