import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/location/device_location_service.dart';
import '../core/location/geocoding_location_enricher.dart';
import '../core/media/camera_capture_service.dart';
import '../core/media/image_storage_service.dart';
import '../core/remote/cloud_scan_sync_service.dart';
import '../core/storage/scan_local_data_source.dart';
import '../core/storage/settings_local_data_source.dart';
import '../features/auth/data/stub_auth_repository.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/scan/data/noop_vehicle_analysis_service.dart';
import '../features/scan/data/scan_repository_impl.dart';
import '../features/scan/domain/scan_repository.dart';
import '../features/settings/data/settings_repository_impl.dart';
import '../features/settings/domain/settings_repository.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';
import 'motosnap_app.dart';
import 'router/app_router.dart';

class AppBootstrap {
  /// W testach jednostkowych podaj [hivePath] (np. katalog tymczasowy), żeby uniknąć `initFlutter`.
  static Future<Widget> run({String? hivePath}) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (hivePath != null) {
      Hive.init(hivePath);
    } else {
      await Hive.initFlutter();
    }

    final scanLocal = await ScanLocalDataSource.open();
    final settingsLocal = await SettingsLocalDataSource.open();

    final scanRepository = ScanRepositoryImpl(
      localDataSource: scanLocal,
      positionReader: DeviceLocationService(),
      imageStorage: ImageStorageService(),
      cloudSync: NoOpCloudScanSyncService(),
      analysisService: NoOpVehicleAnalysisService(),
      locationEnricher: GeocodingLocationEnricher(),
    );

    final settingsRepository = SettingsRepositoryImpl(settingsLocal);
    final authRepository = StubAuthRepository();
    final cameraCapture = CameraCaptureService();
    final router = AppRouter.create();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ScanRepository>.value(value: scanRepository),
        RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<CameraCaptureService>.value(value: cameraCapture),
      ],
      child: BlocProvider(
        create: (_) => SettingsCubit(settingsRepository)..load(),
        child: MotosnapApp(routerConfig: router),
      ),
    );
  }
}
