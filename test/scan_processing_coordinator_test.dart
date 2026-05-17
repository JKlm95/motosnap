import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/features/scan/domain/user_vehicle_correction.dart';
import 'package:motosnap/core/firebase/cloud_sync_availability.dart';
import 'package:motosnap/core/remote/sync_summary.dart';
import 'package:motosnap/features/scan/domain/pending_scan_sync.dart';
import 'package:motosnap/features/scan/domain/scan_processing_coordinator.dart';
import 'package:motosnap/features/scan/domain/scan_repository.dart';
import 'package:motosnap/features/scan/domain/vehicle_analysis_service.dart';
import 'package:motosnap/features/scan/domain/scan_location.dart';
import 'package:motosnap/features/scan/domain/vehicle_info.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan_status.dart';
import 'package:motosnap/features/scan/domain/vehicle_type.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('kolejka nie dubluje tego samego scanId', () async {
    final sync = _RecordingSync();
    final analysis = _RecordingAnalysis();
    final repo = _InMemoryRepo();
    final scan = _pendingScan();
    await repo.upsert(scan);

    final coordinator = ScanProcessingCoordinator(
      repository: repo,
      cloudAvailability: const CloudSyncAvailability(available: true),
      pendingSync: sync,
      analysis: analysis,
    );

    coordinator.enqueue(scan.id, 'pl');
    coordinator.enqueue(scan.id, 'pl');
    await coordinator.waitUntilIdle();

    expect(sync.calls, 1);
    expect(analysis.calls, 1);
  });

  test('enqueue uruchamia sync potem AI asynchronicznie', () async {
    final sync = _RecordingSync();
    final analysis = _RecordingAnalysis();
    final repo = _InMemoryRepo();
    final scan = _pendingScan();
    await repo.upsert(scan);

    final coordinator = ScanProcessingCoordinator(
      repository: repo,
      cloudAvailability: const CloudSyncAvailability(available: true),
      pendingSync: sync,
      analysis: analysis,
    );

    coordinator.enqueue(scan.id, 'en');
    expect(sync.calls, 0);
    expect(analysis.calls, 0);

    await coordinator.waitUntilIdle();
    expect(sync.calls, 1);
    expect(analysis.calls, 1);
  });

  test('AI nie startuje gdy sync się nie uda', () async {
    final sync = _FailingSync();
    final analysis = _RecordingAnalysis();
    final repo = _InMemoryRepo();
    final scan = _pendingScan();
    await repo.upsert(scan);

    final coordinator = ScanProcessingCoordinator(
      repository: repo,
      cloudAvailability: const CloudSyncAvailability(available: true),
      pendingSync: sync,
      analysis: analysis,
    );

    coordinator.enqueue(scan.id, 'pl');
    await coordinator.waitUntilIdle();

    expect(sync.calls, 1);
    expect(analysis.calls, 0);
  });
}

VehicleScan _pendingScan() {
  final now = DateTime.utc(2025, 1, 1);
  return VehicleScan(
    id: 'scan-queue-1',
    localImagePath: '/tmp/x.jpg',
    createdAt: now,
    updatedAt: now,
    status: VehicleScanStatus.waitingForRecognition,
    location: const ScanLocation(latitude: 1, longitude: 2),
    pendingSync: true,
  );
}

final class _InMemoryRepo implements ScanRepository {
  final Map<String, VehicleScan> _store = {};

  @override
  Future<VehicleScan> createScan({required XFile capturedPhoto}) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteScan(String id) async => _store.remove(id);

  @override
  Future<List<VehicleScan>> getRecentScans(int limit) async =>
      _store.values.toList();

  @override
  Future<VehicleScan?> getScan(String id) async => _store[id];

  @override
  Future<void> markAsPrivate(String id) async {}

  @override
  Future<void> markAsPublic(String id) async {}

  @override
  Future<void> updateUserCorrection(
    String scanId,
    UserVehicleCorrection correction,
  ) async {}

  @override
  Future<void> updateScan(VehicleScan scan) async => _store[scan.id] = scan;

  @override
  Stream<List<VehicleScan>> watchScans() => throw UnimplementedError();

  Future<void> upsert(VehicleScan scan) async => _store[scan.id] = scan;
}

final class _RecordingSync implements PendingScanSync {
  int calls = 0;

  @override
  Future<SyncSummary> syncAllPending(ScanRepository localRepository) async =>
      const SyncSummary(uploaded: 0, failed: 0);

  @override
  Future<void> syncPendingScan(
    ScanRepository localRepository,
    String scanId,
  ) async {
    calls++;
    final scan = await localRepository.getScan(scanId);
    if (scan == null) {
      return;
    }
    await localRepository.updateScan(
      scan.copyWith(
        pendingSync: false,
        remoteImageUrl: 'https://example.com/$scanId.jpg',
      ),
    );
  }
}

final class _FailingSync implements PendingScanSync {
  int calls = 0;

  @override
  Future<SyncSummary> syncAllPending(ScanRepository localRepository) async =>
      const SyncSummary(uploaded: 0, failed: 0);

  @override
  Future<void> syncPendingScan(
    ScanRepository localRepository,
    String scanId,
  ) async {
    calls++;
    throw StateError('sync failed');
  }
}

final class _RecordingAnalysis implements VehicleAnalysisService {
  int calls = 0;

  @override
  Future<void> scheduleAnalysis(String scanId) async {}

  @override
  Future<VehicleInfo> analyzeScan({
    required String scanId,
    required String languageCode,
  }) async {
    calls++;
    return VehicleInfo(
      vehicleType: VehicleType.car,
      confidence: 0.5,
      sourceLanguage: languageCode,
    );
  }
}
