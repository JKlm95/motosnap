import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/core/remote/sync_summary.dart';
import 'package:motosnap/features/scan/domain/post_sync_recognition.dart';
import 'package:motosnap/features/scan/domain/scan_repository.dart';
import 'package:motosnap/features/scan/domain/vehicle_analysis_exception.dart';
import 'package:motosnap/features/scan/domain/vehicle_analysis_service.dart';
import 'package:motosnap/features/scan/domain/vehicle_info.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan_status.dart';
import 'package:motosnap/features/scan/domain/vehicle_type.dart';
import 'package:motosnap/features/scan/domain/user_vehicle_correction.dart';
import 'package:motosnap/features/scan/domain/scan_location.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('PostSyncRecognitionPolicy', () {
    test('shouldRun gdy sync zakończony, URL, waiting, brak vehicleInfo', () {
      final scan = _baseScan().copyWith(
        pendingSync: false,
        remoteImageUrl: 'https://x',
        status: VehicleScanStatus.waitingForRecognition,
        vehicleInfo: null,
        updateVehicleInfo: true,
      );
      expect(PostSyncRecognitionPolicy.shouldRun(scan), isTrue);
    });

    test('nie shouldRun gdy pendingSync', () {
      final scan = _baseScan().copyWith(
        pendingSync: true,
        remoteImageUrl: 'https://x',
        status: VehicleScanStatus.waitingForRecognition,
      );
      expect(PostSyncRecognitionPolicy.shouldRun(scan), isFalse);
    });

    test('nie shouldRun gdy recognized', () {
      final scan = _baseScan().copyWith(
        pendingSync: false,
        remoteImageUrl: 'https://x',
        status: VehicleScanStatus.recognized,
        vehicleInfo: _dummyInfo(),
        updateVehicleInfo: true,
      );
      expect(PostSyncRecognitionPolicy.shouldRun(scan), isFalse);
    });

    test('nie shouldRun gdy vehicleInfo już jest', () {
      final scan = _baseScan().copyWith(
        pendingSync: false,
        remoteImageUrl: 'https://x',
        status: VehicleScanStatus.waitingForRecognition,
        vehicleInfo: _dummyInfo(),
        updateVehicleInfo: true,
      );
      expect(PostSyncRecognitionPolicy.shouldRun(scan), isFalse);
    });
  });

  group('PostSyncRecognitionCoordinator', () {
    test('woła analyzeScan dla id z podsumowania gdy shouldRun', () async {
      final id = 'scan-a';
      final repo = _MemoryRepo();
      await repo.seed(
        VehicleScan(
          id: id,
          localImagePath: '/x',
          createdAt: DateTime.utc(2024),
          updatedAt: DateTime.utc(2024),
          status: VehicleScanStatus.waitingForRecognition,
          location: const ScanLocation(latitude: 1, longitude: 2),
          pendingSync: false,
          remoteImageUrl: 'https://x',
        ),
      );
      final analysis = _CountingAnalysis();
      final coord = PostSyncRecognitionCoordinator(
        analysis: analysis,
        repository: repo,
      );
      await coord.runAfterSyncIfNeeded(
        summary: const SyncSummary(
          uploaded: 1,
          failed: 0,
          uploadedScanIds: ['scan-a'],
        ),
        languageCode: 'pl',
      );
      expect(analysis.calls, 1);
    });

    test('nie woła analyzeScan gdy uploadedScanIds puste', () async {
      final repo = _MemoryRepo();
      final analysis = _CountingAnalysis();
      final coord = PostSyncRecognitionCoordinator(
        analysis: analysis,
        repository: repo,
      );
      await coord.runAfterSyncIfNeeded(
        summary: const SyncSummary(uploaded: 0, failed: 1),
        languageCode: 'pl',
      );
      expect(analysis.calls, 0);
    });

    test('błąd AI nie przerywa kolejnych id', () async {
      final repo = _MemoryRepo();
      await repo.seed(
        VehicleScan(
          id: '1',
          localImagePath: '/a',
          createdAt: DateTime.utc(2024),
          updatedAt: DateTime.utc(2024),
          status: VehicleScanStatus.waitingForRecognition,
          location: const ScanLocation(latitude: 1, longitude: 2),
          pendingSync: false,
          remoteImageUrl: 'https://a',
        ),
      );
      await repo.seed(
        VehicleScan(
          id: '2',
          localImagePath: '/b',
          createdAt: DateTime.utc(2024),
          updatedAt: DateTime.utc(2024),
          status: VehicleScanStatus.waitingForRecognition,
          location: const ScanLocation(latitude: 1, longitude: 2),
          pendingSync: false,
          remoteImageUrl: 'https://b',
        ),
      );
      final analysis = _CountingAnalysis(fail: true);
      final coord = PostSyncRecognitionCoordinator(
        analysis: analysis,
        repository: repo,
      );
      await coord.runAfterSyncIfNeeded(
        summary: const SyncSummary(
          uploaded: 2,
          failed: 0,
          uploadedScanIds: ['1', '2'],
        ),
        languageCode: 'en',
      );
      expect(analysis.calls, 2);
    });

    test('pomija skan już rozpoznany (recognized + vehicleInfo)', () async {
      final repo = _MemoryRepo();
      await repo.seed(
        VehicleScan(
          id: 'r',
          localImagePath: '/a',
          createdAt: DateTime.utc(2024),
          updatedAt: DateTime.utc(2024),
          status: VehicleScanStatus.recognized,
          location: const ScanLocation(latitude: 1, longitude: 2),
          pendingSync: false,
          remoteImageUrl: 'https://a',
          vehicleInfo: _dummyInfo(),
        ),
      );
      final analysis = _CountingAnalysis();
      final coord = PostSyncRecognitionCoordinator(
        analysis: analysis,
        repository: repo,
      );
      await coord.runAfterSyncIfNeeded(
        summary: const SyncSummary(
          uploaded: 1,
          failed: 0,
          uploadedScanIds: ['r'],
        ),
        languageCode: 'pl',
      );
      expect(analysis.calls, 0);
    });
  });
}

VehicleScan _baseScan() {
  return VehicleScan(
    id: 'id',
    localImagePath: '/p',
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
    status: VehicleScanStatus.waitingForRecognition,
    location: const ScanLocation(latitude: 0, longitude: 0),
    pendingSync: true,
  );
}

VehicleInfo _dummyInfo() {
  return const VehicleInfo(
    vehicleType: VehicleType.car,
    brand: 'X',
    model: 'Y',
    confidence: 0.9,
    sourceLanguage: 'pl',
  );
}

final class _MemoryRepo implements ScanRepository {
  final Map<String, VehicleScan> _byId = {};

  Future<void> seed(VehicleScan s) async {
    _byId[s.id] = s;
  }

  @override
  Future<VehicleScan> createScan({required XFile capturedPhoto}) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteScan(String id) async {}

  @override
  Future<VehicleScan?> getScan(String id) async => _byId[id];

  @override
  Future<List<VehicleScan>> getRecentScans(int limit) async =>
      _byId.values.toList();

  @override
  Future<void> markAsPrivate(String id) async {}

  @override
  Future<void> markAsPublic(String id) async {}

  @override
  Stream<List<VehicleScan>> watchScans() => throw UnimplementedError();

  @override
  Future<void> updateScan(VehicleScan scan) async {
    _byId[scan.id] = scan;
  }

  @override
  Future<void> updateUserCorrection(
    String scanId,
    UserVehicleCorrection correction,
  ) async {}
}

final class _CountingAnalysis implements VehicleAnalysisService {
  _CountingAnalysis({this.fail = false});

  final bool fail;
  int calls = 0;

  @override
  Future<void> scheduleAnalysis(String scanId) async {}

  @override
  Future<VehicleInfo> analyzeScan({
    required String scanId,
    required String languageCode,
  }) async {
    calls++;
    if (fail) {
      throw const VehicleAnalysisException('fail');
    }
    return _dummyInfo();
  }
}
