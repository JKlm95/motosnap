import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/core/firebase/cloud_sync_availability.dart';
import 'package:motosnap/core/remote/sync_summary.dart';
import 'package:motosnap/core/sync/manual_scan_sync_coordinator.dart';
import 'package:motosnap/features/history/presentation/cubit/history_cubit.dart';
import 'package:motosnap/features/map/domain/scan_map_item.dart';
import 'package:motosnap/features/scan/data/cloud_scan_remote_pull.dart';
import 'package:motosnap/features/scan/domain/pending_scan_sync.dart';
import 'package:motosnap/features/scan/domain/scan_repository.dart';
import 'package:motosnap/features/scan/domain/user_vehicle_correction.dart';
import 'package:motosnap/features/scan/domain/vehicle_analysis_service.dart';
import 'package:motosnap/features/scan/domain/vehicle_info.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('mapa po restore widzi skany z GPS', () async {
    final repo = _WatchRepo([]);
    await CloudScanRemotePull.applyRemoteDocuments(
      localRepository: repo,
      localById: {},
      remoteDocs: [
        (
          id: 'gps-1',
          data: <String, dynamic>{
            'status': 'recognized',
            'remote_image_url': 'https://cdn.example/1.jpg',
            'exact_location': <String, dynamic>{
              'latitude': 52.1,
              'longitude': 21.0,
            },
          },
        ),
      ],
    );

    final items = scanMapItemsFromScans(repo.scans);
    expect(items, hasLength(1));
    expect(items.first.scanId, 'gps-1');
  });

  test(
    'History refresh po reinstall — coordinator zwraca downloaded',
    () async {
      final repo = _WatchRepo([]);
      final pending = _RestorePendingSync(repo);
      final coordinator = ManualScanSyncCoordinator(
        repository: repo,
        cloudAvailability: const CloudSyncAvailability(available: true),
        pendingSync: pending,
      );
      final cubit = HistoryCubit(
        repo,
        _NoOpAnalysis(),
        coordinator,
        uiLanguageCode: 'pl',
      );
      addTearDown(cubit.close);

      await Future<void>.delayed(Duration.zero);
      await cubit.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(repo.scans, hasLength(2));
      expect(pending.lastSummary?.downloaded, 2);
      expect(cubit.state.scans, hasLength(2));
    },
  );
}

final class _RestorePendingSync implements PendingScanSync {
  _RestorePendingSync(this.repo);

  final _WatchRepo repo;
  SyncSummary? lastSummary;

  @override
  Future<SyncSummary> syncAllPending(ScanRepository localRepository) async {
    final result = await CloudScanRemotePull.applyRemoteDocuments(
      localRepository: repo,
      localById: {},
      remoteDocs: [
        (
          id: 'r1',
          data: <String, dynamic>{
            'status': 'recognized',
            'remote_image_url': 'https://cdn.example/a.jpg',
            'vehicle_info': <String, dynamic>{
              'vehicle_type': 'car',
              'brand': 'BMW',
              'model': 'M3',
              'possible_engines': <String>[],
            },
            'exact_location': <String, dynamic>{
              'latitude': 50,
              'longitude': 20,
            },
          },
        ),
        (
          id: 'r2',
          data: <String, dynamic>{
            'status': 'waitingForRecognition',
            'remote_image_url': 'https://cdn.example/b.jpg',
            'exact_location': <String, dynamic>{
              'latitude': 51,
              'longitude': 19,
            },
          },
        ),
      ],
    );
    lastSummary = SyncSummary(
      uploaded: 0,
      failed: 0,
      downloaded: result.downloaded,
      updated: result.updated,
      downloadedScanIds: result.downloadedScanIds,
      updatedScanIds: result.updatedScanIds,
    );
    return lastSummary!;
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

  List<VehicleScan> get scans => List.unmodifiable(_scans);

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
    } else {
      _scans.add(scan);
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
