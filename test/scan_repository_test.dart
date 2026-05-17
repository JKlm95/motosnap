import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motosnap/core/firebase/cloud_sync_availability.dart';
import 'package:motosnap/core/sync/manual_scan_sync_coordinator.dart';
import 'package:motosnap/core/location/current_position_reader.dart';
import 'package:motosnap/core/location/passthrough_location_enricher.dart';
import 'package:motosnap/core/media/image_storage_service.dart';
import 'package:motosnap/core/remote/cloud_scan_sync_service.dart';
import 'package:motosnap/core/storage/scan_local_data_source.dart';
import 'package:motosnap/features/history/presentation/cubit/history_cubit.dart';
import 'package:motosnap/features/history/presentation/view/history_screen.dart';
import 'package:motosnap/features/scan/data/noop_vehicle_analysis_service.dart';
import 'package:motosnap/features/scan/data/scan_repository_impl.dart';
import 'package:motosnap/features/scan/domain/scan_repository.dart';
import 'package:motosnap/features/scan/domain/user_vehicle_correction.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ScanRepository — zapis i odczyt przez Hive', () async {
    final dir = Directory.systemTemp.createTempSync('motosnap_repo_test');
    addTearDown(() async {
      await Hive.close();
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });

    Hive.init(dir.path);
    final local = await ScanLocalDataSource.open();
    final repo = ScanRepositoryImpl(
      localDataSource: local,
      positionReader: _FixedPosition(),
      imageStorage: _TestImageStorage(dir),
      cloudSync: NoOpCloudScanSyncService(),
      analysisService: NoOpVehicleAnalysisService(),
      locationEnricher: PassthroughLocationEnricher(),
    );

    final tmpImg = File('${dir.path}/in.jpg')..writeAsBytesSync([1, 2, 3, 4]);
    final scan = await repo.createScan(capturedPhoto: XFile(tmpImg.path));

    expect(scan.status, VehicleScanStatus.waitingForRecognition);
    final loaded = await repo.getScan(scan.id);
    expect(loaded, isNotNull);
    expect(loaded!.location.latitude, 51.1);
    expect(loaded.localImagePath, isNotEmpty);
  });

  testWidgets('Historia — pusty stan', (tester) async {
    final repo = _EmptyRepo();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pl'),
        supportedLocales: const [Locale('en'), Locale('pl')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: RepositoryProvider<ScanRepository>.value(
          value: repo,
          child: RepositoryProvider<CloudSyncAvailability>.value(
            value: const CloudSyncAvailability(available: true),
            child: BlocProvider(
              create: (_) => HistoryCubit(
                repo,
                NoOpVehicleAnalysisService(),
                ManualScanSyncCoordinator(
                  repository: repo,
                  cloudAvailability: const CloudSyncAvailability(
                    available: false,
                  ),
                ),
                uiLanguageCode: 'pl',
              ),
              child: const HistoryScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Brak zapisanych skanów'), findsOneWidget);
  });
}

final class _FixedPosition implements CurrentPositionReader {
  @override
  Future<Position> getCurrentPosition() async {
    return Position(
      latitude: 51.1,
      longitude: 17.0,
      timestamp: DateTime.now(),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

final class _TestImageStorage extends ImageStorageService {
  _TestImageStorage(this._root);

  final Directory _root;

  @override
  Future<String> persistCameraImage(XFile file) async {
    final target = File('${_root.path}/saved.jpg');
    await File(file.path).copy(target.path);
    return target.path;
  }
}

final class _EmptyRepo implements ScanRepository {
  @override
  Stream<List<VehicleScan>> watchScans() async* {
    yield const <VehicleScan>[];
  }

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
