import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/core/firebase/cloud_sync_availability.dart';
import 'package:motosnap/core/remote/sync_summary.dart';
import 'package:motosnap/features/scan/domain/pending_scan_sync.dart';
import 'package:motosnap/features/scan/domain/scan_processing_coordinator.dart';
import 'package:motosnap/features/scan/domain/scan_location.dart';
import 'package:motosnap/features/scan/domain/scan_repository.dart';
import 'package:motosnap/features/scan/domain/user_vehicle_correction.dart';
import 'package:motosnap/features/scan/domain/vehicle_analysis_exception.dart';
import 'package:motosnap/features/scan/domain/vehicle_analysis_service.dart';
import 'package:motosnap/features/scan/domain/vehicle_info.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan_status.dart';
import 'package:motosnap/features/settings/presentation/cubit/sync_cubit.dart';
import 'package:motosnap/features/settings/presentation/cubit/sync_state.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('SyncCubit — brak backendu (null) kończy się błędem', () async {
    final cubit = SyncCubit(null, _FakeRepo());
    await cubit.syncNow();
    expect(cubit.state.status, ManualSyncStatus.error);
    expect(cubit.state.userError, SyncUserError.cloudDisabled);
    await cubit.close();
  });

  test('SyncCubit — stub zwraca podsumowanie', () async {
    final cubit = SyncCubit(_StubPendingSync(), _FakeRepo());
    await cubit.syncNow();
    expect(cubit.state.status, ManualSyncStatus.done);
    expect(cubit.state.summary, const SyncSummary(uploaded: 1, failed: 0));
    await cubit.close();
  });

  test(
    'SyncCubit — częściowa porażka: status done i poprawne failed',
    () async {
      final cubit = SyncCubit(_StubPendingSyncWithFailures(), _FakeRepo());
      await cubit.syncNow();
      expect(cubit.state.status, ManualSyncStatus.done);
      expect(cubit.state.summary, const SyncSummary(uploaded: 1, failed: 2));
      await cubit.close();
    },
  );

  test('SyncCubit — po syncu kolejka uruchamia AI (upload ids)', () async {
    final repo = _RepoWithOnePendingScan();
    final analysis = _AnalysisCallCounter();
    final queue = ScanProcessingCoordinator(
      repository: repo,
      cloudAvailability: const CloudSyncAvailability(available: true),
      pendingSync: _PendingSyncMarksUploaded(),
      analysis: analysis,
    );
    final cubit = SyncCubit(
      _PendingSyncMarksUploaded(),
      repo,
      processingCoordinator: queue,
    );
    await cubit.syncNow();
    expect(cubit.state.status, ManualSyncStatus.done);
    await queue.waitUntilIdle();
    expect(analysis.calls, 1);
    await cubit.close();
  });

  test('SyncCubit — brak uploadedScanIds nie woła AI', () async {
    final repo = _RepoWithOnePendingScan();
    final analysis = _AnalysisCallCounter();
    final queue = ScanProcessingCoordinator(
      repository: repo,
      cloudAvailability: const CloudSyncAvailability(available: true),
      pendingSync: _PendingSyncNoUploads(),
      analysis: analysis,
    );
    final cubit = SyncCubit(
      _PendingSyncNoUploads(),
      repo,
      processingCoordinator: queue,
    );
    await cubit.syncNow();
    await queue.waitUntilIdle();
    expect(analysis.calls, 0);
    await cubit.close();
  });
}

final class _StubPendingSync implements PendingScanSync {
  @override
  Future<SyncSummary> syncAllPending(ScanRepository localRepository) async {
    return const SyncSummary(uploaded: 1, failed: 0);
  }

  @override
  Future<void> syncPendingScan(
    ScanRepository localRepository,
    String scanId,
  ) async {}
}

final class _StubPendingSyncWithFailures implements PendingScanSync {
  @override
  Future<SyncSummary> syncAllPending(ScanRepository localRepository) async {
    return const SyncSummary(uploaded: 1, failed: 2);
  }

  @override
  Future<void> syncPendingScan(
    ScanRepository localRepository,
    String scanId,
  ) async {}
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

final class _RepoWithOnePendingScan implements ScanRepository {
  _RepoWithOnePendingScan() {
    _scan = VehicleScan(
      id: 's1',
      localImagePath: '/x',
      createdAt: DateTime.utc(2024, 1, 1),
      updatedAt: DateTime.utc(2024, 1, 1),
      status: VehicleScanStatus.waitingForRecognition,
      location: const ScanLocation(latitude: 0, longitude: 0),
      pendingSync: true,
    );
  }

  late VehicleScan _scan;

  @override
  Stream<List<VehicleScan>> watchScans() => throw UnimplementedError();

  @override
  Future<List<VehicleScan>> getRecentScans(int limit) async => [_scan];

  @override
  Future<VehicleScan?> getScan(String id) async =>
      id == _scan.id ? _scan : null;

  @override
  Future<VehicleScan> createScan({required XFile capturedPhoto}) =>
      throw UnimplementedError();

  @override
  Future<void> updateScan(VehicleScan scan) async {
    _scan = scan;
  }

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

final class _PendingSyncMarksUploaded implements PendingScanSync {
  @override
  Future<SyncSummary> syncAllPending(ScanRepository localRepository) async {
    final s = await localRepository.getScan('s1');
    await localRepository.updateScan(
      s!.copyWith(pendingSync: false, remoteImageUrl: 'https://cdn.example/x'),
    );
    return const SyncSummary(uploaded: 1, failed: 0, uploadedScanIds: ['s1']);
  }

  @override
  Future<void> syncPendingScan(
    ScanRepository localRepository,
    String scanId,
  ) async {}
}

final class _PendingSyncNoUploads implements PendingScanSync {
  @override
  Future<SyncSummary> syncAllPending(ScanRepository localRepository) async {
    return const SyncSummary(uploaded: 0, failed: 1, uploadedScanIds: []);
  }

  @override
  Future<void> syncPendingScan(
    ScanRepository localRepository,
    String scanId,
  ) async {}
}

final class _AnalysisCallCounter implements VehicleAnalysisService {
  int calls = 0;

  @override
  Future<void> scheduleAnalysis(String scanId) async {}

  @override
  Future<VehicleInfo> analyzeScan({
    required String scanId,
    required String languageCode,
  }) async {
    calls++;
    throw const VehicleAnalysisException('x');
  }
}
