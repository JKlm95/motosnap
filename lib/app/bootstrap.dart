import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/firebase/cloud_sync_availability.dart';
import '../core/firebase/firebase_initializer.dart';
import '../core/location/device_location_service.dart';
import '../core/location/geocoding_location_enricher.dart';
import '../core/media/camera_capture_service.dart';
import '../core/media/image_storage_service.dart';
import '../core/remote/cloud_scan_sync_service.dart';
import '../core/storage/scan_local_data_source.dart';
import '../core/storage/settings_local_data_source.dart';
import '../features/auth/data/firebase_auth_repository.dart';
import '../features/auth/data/offline_auth_repository.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/scan/data/firebase_cloud_sync_service.dart';
import '../features/scan/data/firebase_vehicle_analysis_service.dart';
import '../features/scan/data/noop_vehicle_analysis_service.dart';
import '../features/scan/data/scan_repository_impl.dart';
import '../features/scan/domain/pending_scan_sync.dart';
import '../features/scan/domain/post_sync_recognition.dart';
import '../features/scan/domain/scan_repository.dart';
import '../features/scan/domain/user_correction_remote_sink.dart';
import '../features/scan/domain/vehicle_analysis_service.dart';
import '../features/settings/data/settings_repository_impl.dart';
import '../features/settings/domain/settings_repository.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';
import 'motosnap_app.dart';
import 'router/app_router.dart';
import 'router/router_refresh_bridge.dart';

class AppBootstrap {
  /// W testach jednostkowych podaj [hivePath] (np. katalog tymczasowy), żeby uniknąć `initFlutter`.
  static Future<Widget> run({String? hivePath}) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (hivePath != null) {
      Hive.init(hivePath);
    } else {
      await Hive.initFlutter();
    }

    final FirebaseInitStatus? firebaseStatus;
    if (hivePath == null) {
      firebaseStatus = await FirebaseInitializer.initialize();
    } else {
      firebaseStatus = null;
    }

    final firebaseReady = firebaseStatus == FirebaseInitStatus.ready;

    final AuthRepository authRepository = firebaseReady
        ? FirebaseAuthRepository()
        : OfflineAuthRepository();

    final FirebaseCloudSyncService? firebaseCloudSync = firebaseReady
        ? FirebaseCloudSyncService()
        : null;

    final CloudScanSyncService cloudScanService =
        firebaseCloudSync ?? NoOpCloudScanSyncService();

    final UserCorrectionRemoteSink correctionRemoteSink =
        firebaseCloudSync ?? const NoOpUserCorrectionRemoteSink();

    final scanLocal = await ScanLocalDataSource.open();
    final settingsLocal = await SettingsLocalDataSource.open();

    final scanRepository = ScanRepositoryImpl(
      localDataSource: scanLocal,
      positionReader: DeviceLocationService(),
      imageStorage: ImageStorageService(),
      cloudSync: cloudScanService,
      analysisService: NoOpVehicleAnalysisService(),
      locationEnricher: GeocodingLocationEnricher(),
      correctionSink: correctionRemoteSink,
    );

    final VehicleAnalysisService vehicleAnalysis = firebaseReady
        ? FirebaseVehicleAnalysisService(scanRepository: scanRepository)
        : NoOpVehicleAnalysisService();

    final PostSyncRecognitionCoordinator? postSyncRecognition = firebaseReady
        ? PostSyncRecognitionCoordinator(
            analysis: vehicleAnalysis,
            repository: scanRepository,
          )
        : null;

    final settingsRepository = SettingsRepositoryImpl(settingsLocal);
    final cameraCapture = CameraCaptureService();

    final refreshBridge = RouterRefreshBridge(authRepository.watchSession());
    final router = AppRouter.create(refreshListenable: refreshBridge);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ScanRepository>.value(value: scanRepository),
        RepositoryProvider<VehicleAnalysisService>.value(
          value: vehicleAnalysis,
        ),
        RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<CameraCaptureService>.value(value: cameraCapture),
        RepositoryProvider<PendingScanSync?>.value(value: firebaseCloudSync),
        RepositoryProvider<PostSyncRecognitionCoordinator?>.value(
          value: postSyncRecognition,
        ),
        RepositoryProvider<CloudSyncAvailability>.value(
          value: CloudSyncAvailability(available: firebaseReady),
        ),
      ],
      child: BlocProvider(
        create: (_) => SettingsCubit(settingsRepository)..load(),
        child: _RouterLifecycle(
          refreshBridge: refreshBridge,
          child: MotosnapApp(routerConfig: router),
        ),
      ),
    );
  }
}

final class _RouterLifecycle extends StatefulWidget {
  const _RouterLifecycle({required this.refreshBridge, required this.child});

  final RouterRefreshBridge refreshBridge;
  final Widget child;

  @override
  State<_RouterLifecycle> createState() => _RouterLifecycleState();
}

final class _RouterLifecycleState extends State<_RouterLifecycle> {
  @override
  void dispose() {
    widget.refreshBridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
