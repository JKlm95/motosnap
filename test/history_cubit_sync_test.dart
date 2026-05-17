import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/core/firebase/cloud_sync_availability.dart';
import 'package:motosnap/core/remote/sync_summary.dart';
import 'package:motosnap/core/sync/manual_scan_sync_coordinator.dart';
import 'package:motosnap/features/history/presentation/cubit/history_cubit.dart';
import 'package:motosnap/features/scan/data/vehicle_scan_firestore_mapper.dart';
import 'package:motosnap/features/scan/domain/pending_scan_sync.dart';
import 'package:motosnap/features/scan/domain/scan_repository.dart';
import 'package:motosnap/features/scan/domain/user_vehicle_correction.dart';
import 'package:motosnap/features/scan/domain/vehicle_analysis_service.dart';
import 'package:motosnap/features/scan/domain/vehicle_info.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan_status.dart';
import 'package:motosnap/features/scan/domain/scan_location.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  final t0 = DateTime.utc(2026, 5, 1);

  VehicleScan waitingScan() => VehicleScan(
    id: 's1',
    localImagePath: '/tmp/a.jpg',
    remoteImageUrl: 'https://cdn.example/x.jpg',
    createdAt: t0,
    updatedAt: t0,
    status: VehicleScanStatus.waitingForRecognition,
    location: const ScanLocation(latitude: 1, longitude: 2),
    pendingSync: false,
  );

  test('refresh wywołuje pełny sync przez coordinator', () async {
    final repo = _WatchRepo([waitingScan()]);
    final pending = _PullRecognizedPendingSync();
    final coord = ManualScanSyncCoordinator(
      repository: repo,
      cloudAvailability: const CloudSyncAvailability(available: true),
      pendingSync: pending,
    );
    final cubit = HistoryCubit(
      repo,
      _NoOpAnalysis(),
      coord,
      uiLanguageCode: 'pl',
    );
    await Future<void>.delayed(Duration.zero);
    await cubit.refresh();
    expect(pending.syncCalls, 1);
    await cubit.close();
  });

  test('błąd syncu nie czyści listy skanów', () async {
    final repo = _WatchRepo([waitingScan()]);
    final coord = ManualScanSyncCoordinator(
      repository: repo,
      cloudAvailability: const CloudSyncAvailability(available: true),
      pendingSync: _FailingPendingSync(),
    );
    final cubit = HistoryCubit(
      repo,
      _NoOpAnalysis(),
      coord,
      uiLanguageCode: 'pl',
    );
    await Future<void>.delayed(Duration.zero);
    await cubit.refresh();
    expect(cubit.state.scans, hasLength(1));
    expect(cubit.state.scans.first.id, 's1');
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.transientSnackMessage, isNotNull);
    await cubit.close();
  });

  test('remote recognized po sync aktualizuje lokalny rekord w repo', () async {
    final repo = _WatchRepo([waitingScan()]);
    final pending = _PullRecognizedPendingSync();
    final coord = ManualScanSyncCoordinator(
      repository: repo,
      cloudAvailability: const CloudSyncAvailability(available: true),
      pendingSync: pending,
    );
    final cubit = HistoryCubit(
      repo,
      _NoOpAnalysis(),
      coord,
      uiLanguageCode: 'pl',
    );
    await Future<void>.delayed(Duration.zero);
    await cubit.refresh();
    await Future<void>.delayed(Duration.zero);
    final saved = await repo.getScan('s1');
    expect(saved!.status, VehicleScanStatus.recognized);
    expect(saved.vehicleInfo?.brand, 'CloudAI');
    await cubit.close();
  });
}

/// Symuluje syncAllPending: pull merge recognized (jak FirebaseCloudSyncService).
final class _PullRecognizedPendingSync implements PendingScanSync {
  int syncCalls = 0;

  @override
  Future<SyncSummary> syncAllPending(ScanRepository localRepository) async {
    syncCalls++;
    final local = await localRepository.getScan('s1');
    final remote = <String, dynamic>{
      'status': 'recognized',
      'remote_image_url': 'https://cdn.example/x.jpg',
      'vehicle_info': <String, dynamic>{
        'vehicle_type': 'car',
        'brand': 'CloudAI',
        'model': 'M',
        'generation': null,
        'production_years': null,
        'possible_engines': <String>[],
        'short_description': null,
        'confidence': 0.9,
        'source_language': 'pl',
        'was_user_corrected': true,
      },
      'is_public': false,
    };
    final merged = VehicleScanFirestoreMapper.mergePull(
      local: local!,
      remote: remote,
    );
    await localRepository.updateScan(merged);
    return const SyncSummary(
      uploaded: 0,
      failed: 0,
      updated: 1,
      updatedScanIds: ['s1'],
    );
  }

  @override
  Future<void> syncPendingScan(
    ScanRepository localRepository,
    String scanId,
  ) async {}
}

final class _FailingPendingSync implements PendingScanSync {
  @override
  Future<SyncSummary> syncAllPending(ScanRepository localRepository) async {
    throw Exception('network');
  }

  @override
  Future<void> syncPendingScan(
    ScanRepository localRepository,
    String scanId,
  ) async {}
}

final class _WatchRepo implements ScanRepository {
  _WatchRepo(List<VehicleScan> initial) : _scans = List.of(initial) {
    _controller = StreamController<List<VehicleScan>>.broadcast(
      onListen: () => _controller.add(List.unmodifiable(_scans)),
    );
  }

  final List<VehicleScan> _scans;
  late final StreamController<List<VehicleScan>> _controller;

  void _emit() => _controller.add(List.unmodifiable(_scans));

  @override
  Stream<List<VehicleScan>> watchScans() => _controller.stream;

  @override
  Future<List<VehicleScan>> getRecentScans(int limit) async =>
      List.unmodifiable(_scans);

  @override
  Future<VehicleScan?> getScan(String id) async {
    try {
      return _scans.firstWhere((s) => s.id == id);
    } on Object {
      return null;
    }
  }

  @override
  Future<VehicleScan> createScan({required XFile capturedPhoto}) =>
      throw UnimplementedError();

  @override
  Future<void> updateScan(VehicleScan scan) async {
    final i = _scans.indexWhere((s) => s.id == scan.id);
    if (i >= 0) {
      _scans[i] = scan;
    }
    _emit();
  }

  @override
  Future<void> deleteScan(String id) async {
    _scans.removeWhere((s) => s.id == id);
    _emit();
  }

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

final class _NoOpAnalysis implements VehicleAnalysisService {
  @override
  Future<void> scheduleAnalysis(String scanId) async {}

  @override
  Future<VehicleInfo> analyzeScan({
    required String scanId,
    required String languageCode,
  }) async {
    throw UnimplementedError();
  }
}
