import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/features/scan/domain/user_vehicle_correction.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motosnap/core/firebase/cloud_sync_availability.dart';
import 'package:motosnap/core/media/camera_capture_service.dart';
import 'package:motosnap/core/permissions/scan_permissions_service.dart';
import 'package:motosnap/core/remote/sync_summary.dart';
import 'package:motosnap/features/scan/domain/pending_scan_sync.dart';
import 'package:motosnap/features/scan/domain/scan_location.dart';
import 'package:motosnap/features/scan/domain/scan_processing_coordinator.dart';
import 'package:motosnap/features/scan/domain/scan_repository.dart';
import 'package:motosnap/features/scan/domain/vehicle_analysis_service.dart';
import 'package:motosnap/features/scan/domain/vehicle_info.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan_status.dart';
import 'package:motosnap/features/scan/domain/vehicle_type.dart';
import 'package:motosnap/features/scan/presentation/cubit/scan_cubit.dart';
import 'package:motosnap/features/scan/presentation/cubit/scan_state.dart';

void main() {
  test(
    'ScanCubit po lokalnym zapisie emituje success bez czekania na AI',
    () async {
      final repo = _FakeScanRepo();
      final sync = _StubSyncForCubit();
      final analysis = _StubAnalysisForCubit();
      final coordinator = ScanProcessingCoordinator(
        repository: repo,
        cloudAvailability: const CloudSyncAvailability(available: true),
        pendingSync: sync,
        analysis: analysis,
      );

      final cubit = ScanCubit(
        scanRepository: repo,
        cameraCapture: _ImmediateCamera(),
        permissions: _AllowAllPermissions(),
        processingCoordinator: coordinator,
      );

      final future = cubit.captureAndSaveScan('pl');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.phase, isNot(ScanFlowPhase.recognizingVehicle));
      expect(cubit.state.phase, isNot(ScanFlowPhase.syncingCloud));

      await future;
      expect(cubit.state.phase, ScanFlowPhase.success);
      expect(cubit.state.backgroundQueued, isTrue);
      expect(
        cubit.state.phase,
        isNot(
          anyOf([ScanFlowPhase.syncingCloud, ScanFlowPhase.recognizingVehicle]),
        ),
      );

      await coordinator.waitUntilIdle();
      expect(sync.calls, 1);
      expect(analysis.calls, 1);

      await cubit.close();
    },
  );

  test(
    'ScanCubit saveScanFromPhoto emituje success bez systemowego aparatu',
    () async {
      final repo = _FakeScanRepo();
      final cubit = ScanCubit(
        scanRepository: repo,
        cameraCapture: _ImmediateCamera(),
        permissions: _AllowAllPermissions(),
      );

      final file = XFile.fromData(
        Uint8List.fromList(List.filled(8, 0)),
        name: 'embedded.jpg',
        mimeType: 'image/jpeg',
      );

      await cubit.saveScanFromPhoto(file, 'en');
      expect(cubit.state.phase, ScanFlowPhase.success);
      expect(repo.lastCreated, isNotNull);

      await cubit.close();
    },
  );
}

final class _ImmediateCamera implements CameraCaptureService {
  @override
  Future<XFile?> capturePhoto({int imageQuality = 85}) async => XFile.fromData(
    Uint8List.fromList(List.filled(8, 0)),
    name: 'test.jpg',
    mimeType: 'image/jpeg',
  );

  @override
  Future<XFile?> pickFromGallery({int imageQuality = 85}) async => null;
}

final class _AllowAllPermissions implements ScanPermissionsService {
  @override
  Future<void> ensureCameraAndWhenInUseLocation() async {}

  @override
  Future<void> ensureWhenInUseLocation() async {}
}

final class _FakeScanRepo implements ScanRepository {
  VehicleScan? lastCreated;

  @override
  Future<VehicleScan> createScan({required XFile capturedPhoto}) async {
    final now = DateTime.utc(2025, 6, 1);
    final scan = VehicleScan(
      id: 'created-1',
      localImagePath: '/tmp/photo.jpg',
      createdAt: now,
      updatedAt: now,
      status: VehicleScanStatus.waitingForRecognition,
      location: const ScanLocation(latitude: 50, longitude: 19),
      pendingSync: true,
    );
    lastCreated = scan;
    return scan;
  }

  @override
  Future<void> deleteScan(String id) async {}

  @override
  Future<List<VehicleScan>> getRecentScans(int limit) async =>
      lastCreated == null ? [] : [lastCreated!];

  @override
  Future<VehicleScan?> getScan(String id) async => lastCreated;

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
  Future<void> updateScan(VehicleScan scan) async {
    lastCreated = scan;
  }

  @override
  Stream<List<VehicleScan>> watchScans() => throw UnimplementedError();
}

final class _StubSyncForCubit implements PendingScanSync {
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
        remoteImageUrl: 'https://example.com/x.jpg',
      ),
    );
  }
}

final class _StubAnalysisForCubit implements VehicleAnalysisService {
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
      confidence: 0.9,
      sourceLanguage: languageCode,
    );
  }
}
