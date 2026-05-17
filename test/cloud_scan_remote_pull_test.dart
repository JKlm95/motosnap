import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/features/scan/data/cloud_scan_remote_pull.dart';
import 'package:motosnap/features/scan/data/vehicle_scan_firestore_mapper.dart';
import 'package:motosnap/features/scan/data/vehicle_scan_remote_merger.dart';
import 'package:motosnap/features/scan/domain/scan_location.dart';
import 'package:motosnap/features/scan/domain/scan_repository.dart';
import 'package:motosnap/features/scan/domain/user_vehicle_correction.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan_status.dart';
import 'package:motosnap/features/scan/domain/vehicle_type.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  final t0 = DateTime.utc(2026, 5, 1, 12);

  VehicleScan localWaiting({bool pendingSync = false}) {
    return VehicleScan(
      id: 's1',
      localImagePath: '/tmp/a.jpg',
      remoteImageUrl: pendingSync ? null : 'https://cdn.example/old.jpg',
      createdAt: t0,
      updatedAt: t0,
      status: VehicleScanStatus.waitingForRecognition,
      location: const ScanLocation(latitude: 1, longitude: 2),
      pendingSync: pendingSync,
    );
  }

  Map<String, dynamic> remoteRecognized() {
    return <String, dynamic>{
      'status': 'recognized',
      'remote_image_url': 'https://cdn.example/new.jpg',
      'vehicle_info': <String, dynamic>{
        'vehicle_type': 'car',
        'brand': 'CloudAI',
        'model': 'M3',
        'generation': null,
        'production_years': null,
        'possible_engines': <String>[],
        'short_description': null,
        'confidence': 0.9,
        'source_language': 'pl',
        'was_user_corrected': true,
      },
      'is_public': false,
      'exact_location': <String, dynamic>{'latitude': 1, 'longitude': 2},
    };
  }

  test(
    'pull: lokalny waiting + cloud recognized → updated, status recognized',
    () async {
      final repo = _MemoryRepo([localWaiting()]);
      final result = await CloudScanRemotePull.applyRemoteDocuments(
        localRepository: repo,
        localById: {for (final s in repo.scans) s.id: s},
        remoteDocs: [(id: 's1', data: remoteRecognized())],
      );

      expect(result.updated, 1);
      expect(result.downloaded, 0);
      expect(result.updatedScanIds, ['s1']);
      final saved = await repo.getScan('s1');
      expect(saved!.status, VehicleScanStatus.recognized);
      expect(saved.vehicleInfo?.brand, 'CloudAI');
      expect(saved.pendingSync, isFalse);
    },
  );

  test('pull: cloud scan bez lokalnego → downloaded', () async {
    final repo = _MemoryRepo([]);
    final result = await CloudScanRemotePull.applyRemoteDocuments(
      localRepository: repo,
      localById: {},
      remoteDocs: [(id: 'cloud-1', data: remoteRecognized())],
    );

    expect(result.downloaded, 1);
    expect(result.updated, 0);
    expect(repo.scans, hasLength(1));
    expect(repo.scans.first.id, 'cloud-1');
    expect(repo.scans.first.remoteImageUrl, contains('cdn.example'));
  });

  test(
    'pull: lokalna nowsza korekta nie jest nadpisywana przez starszą chmurę',
    () async {
      final newer = UserVehicleCorrection(
        vehicleType: VehicleType.car,
        brand: 'Lokalna',
        correctedAt: DateTime.utc(2026, 5, 10),
      );
      final local = localWaiting().copyWith(
        userCorrection: newer,
        updateUserCorrection: true,
        pendingSync: false,
        remoteImageUrl: 'https://cdn.example/x.jpg',
      );
      final remote = remoteRecognized()
        ..['user_correction'] = <String, dynamic>{
          'vehicle_type': 'car',
          'brand': 'Stara',
          'corrected_at': '2026-05-01T10:00:00.000Z',
          'possible_engines': <String>[],
          'source': 'user',
        };

      final repo = _MemoryRepo([local]);
      await CloudScanRemotePull.applyRemoteDocuments(
        localRepository: repo,
        localById: {local.id: local},
        remoteDocs: [(id: 's1', data: remote)],
      );

      final saved = await repo.getScan('s1');
      expect(saved!.userCorrection?.brand, 'Lokalna');
      expect(saved.status, VehicleScanStatus.recognized);
    },
  );

  test('mergePull: cloud recognized wygrywa nad lokalnym waiting', () {
    final merged = VehicleScanFirestoreMapper.mergePull(
      local: localWaiting(),
      remote: remoteRecognized(),
    );
    expect(merged.status, VehicleScanStatus.recognized);
    expect(merged.vehicleInfo?.brand, 'CloudAI');
  });

  test(
    'pull: cloud scan bez remote_image_url → metadata-only download',
    () async {
      final repo = _MemoryRepo([]);
      final remote = Map<String, dynamic>.from(remoteRecognized())
        ..remove('remote_image_url');

      final result = await CloudScanRemotePull.applyRemoteDocuments(
        localRepository: repo,
        localById: {},
        remoteDocs: [(id: 'meta-1', data: remote)],
      );

      expect(result.downloaded, 1);
      final saved = await repo.getScan('meta-1');
      expect(saved!.status, VehicleScanStatus.recognized);
      expect(saved.remoteImageUrl, isNull);
      expect(saved.pendingSync, isTrue);
      expect(
        saved.localImagePath,
        VehicleScanFirestoreMapper.remoteOnlyLocalImagePath,
      );
    },
  );

  test('pull: błąd zapisu jednego dokumentu nie blokuje pozostałych', () async {
    final repo = _ThrowOnIdRepo(failId: 'bad');
    final result = await CloudScanRemotePull.applyRemoteDocuments(
      localRepository: repo,
      localById: {},
      remoteDocs: [
        (id: 'bad', data: remoteRecognized()),
        (id: 'good', data: remoteRecognized()),
      ],
    );

    expect(result.downloaded, 1);
    expect(result.skipped, 1);
    expect(repo.scans.map((s) => s.id), ['good']);
  });

  test('cold start: pusta baza + 2 cloud docs → downloaded 2', () async {
    final repo = _MemoryRepo([]);
    final result = await CloudScanRemotePull.applyRemoteDocuments(
      localRepository: repo,
      localById: {},
      remoteDocs: [
        (id: 'c1', data: remoteRecognized()),
        (
          id: 'c2',
          data: <String, dynamic>{
            ...remoteRecognized(),
            'status': 'waitingForRecognition',
            'vehicle_info': null,
          },
        ),
      ],
    );

    expect(result.downloaded, 2);
    expect(repo.scans, hasLength(2));
  });

  test('hasSyncRelevantChanges wykrywa zmianę statusu', () {
    final before = localWaiting();
    final after = VehicleScanRemoteMerger.mergeAfterFirestoreFetch(
      local: before,
      remote: remoteRecognized(),
      remoteImageUrl: 'https://cdn.example/new.jpg',
    );
    expect(
      VehicleScanFirestoreMapper.hasSyncRelevantChanges(before, after),
      isTrue,
    );
  });
}

final class _ThrowOnIdRepo extends _MemoryRepo {
  _ThrowOnIdRepo({required this.failId}) : super([]);

  final String failId;

  @override
  Future<void> updateScan(VehicleScan scan) async {
    if (scan.id == failId) {
      throw StateError('persist failed');
    }
    return super.updateScan(scan);
  }
}

final class _MemoryRepo implements ScanRepository {
  _MemoryRepo(List<VehicleScan> initial) : scans = List.of(initial);

  List<VehicleScan> scans;

  @override
  Stream<List<VehicleScan>> watchScans() async* {
    yield scans;
  }

  @override
  Future<List<VehicleScan>> getRecentScans(int limit) async => scans;

  @override
  Future<VehicleScan?> getScan(String id) async {
    try {
      return scans.firstWhere((s) => s.id == id);
    } on Object {
      return null;
    }
  }

  @override
  Future<VehicleScan> createScan({required XFile capturedPhoto}) =>
      throw UnimplementedError();

  @override
  Future<void> updateScan(VehicleScan scan) async {
    final i = scans.indexWhere((s) => s.id == scan.id);
    if (i >= 0) {
      scans[i] = scan;
    } else {
      scans.add(scan);
    }
  }

  @override
  Future<void> deleteScan(String id) async {
    scans.removeWhere((s) => s.id == id);
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
