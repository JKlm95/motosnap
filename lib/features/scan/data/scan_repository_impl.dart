import 'dart:async';

import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/location/current_position_reader.dart';
import '../../../core/location/location_metadata_enricher.dart';
import '../../../core/media/image_storage_service.dart';
import '../../../core/remote/cloud_scan_sync_service.dart';
import '../../../core/storage/scan_local_data_source.dart';
import '../domain/scan_repository.dart';
import '../domain/user_correction_remote_sink.dart';
import '../domain/user_vehicle_correction.dart';
import '../domain/vehicle_analysis_service.dart';
import '../domain/vehicle_scan.dart';
import '../domain/vehicle_scan_status.dart';
import '../domain/scan_location.dart';

class ScanRepositoryImpl implements ScanRepository {
  ScanRepositoryImpl({
    required ScanLocalDataSource localDataSource,
    required CurrentPositionReader positionReader,
    required ImageStorageService imageStorage,
    required CloudScanSyncService cloudSync,
    required VehicleAnalysisService analysisService,
    required LocationMetadataEnricher locationEnricher,
    UserCorrectionRemoteSink? correctionSink,
  }) : _local = localDataSource,
       _position = positionReader,
       _imageStorage = imageStorage,
       _cloudSync = cloudSync,
       _analysis = analysisService,
       _locationEnricher = locationEnricher,
       _correctionSink = correctionSink ?? const NoOpUserCorrectionRemoteSink();

  final ScanLocalDataSource _local;
  final CurrentPositionReader _position;
  final ImageStorageService _imageStorage;
  final CloudScanSyncService _cloudSync;
  final VehicleAnalysisService _analysis;
  final LocationMetadataEnricher _locationEnricher;
  final UserCorrectionRemoteSink _correctionSink;

  final _changes = StreamController<void>.broadcast();

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  @override
  Stream<List<VehicleScan>> watchScans() async* {
    yield await getRecentScans(1 << 20);
    await for (final _ in _changes.stream) {
      yield await getRecentScans(1 << 20);
    }
  }

  @override
  Future<List<VehicleScan>> getRecentScans(int limit) async {
    final all = _local.readAllOrdered();
    if (all.length <= limit) {
      return all;
    }
    return all.sublist(0, limit);
  }

  @override
  Future<VehicleScan?> getScan(String id) async => _local.readById(id);

  @override
  Future<VehicleScan> createScan({required XFile capturedPhoto}) async {
    final now = DateTime.now().toUtc();
    final localPath = await _imageStorage.persistCameraImage(capturedPhoto);
    try {
      final position = await _position.getCurrentPosition();
      final draft = ScanLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final location = await _locationEnricher.enrich(draft);

      final scan = VehicleScan(
        id: const Uuid().v4(),
        localImagePath: localPath,
        createdAt: now,
        updatedAt: now,
        status: VehicleScanStatus.waitingForRecognition,
        location: location,
        pendingSync: true,
      );

      await _local.upsert(scan);
      await _cloudSync.enqueueForUpload(scan);
      await _analysis.scheduleAnalysis(scan.id);
      _emit();
      return scan;
    } on Object catch (_) {
      await _imageStorage.deleteIfExists(localPath);
      rethrow;
    }
  }

  @override
  Future<void> updateScan(VehicleScan scan) async {
    final next = scan.copyWith(updatedAt: DateTime.now().toUtc());
    await _local.upsert(next);
    _emit();
  }

  @override
  Future<void> deleteScan(String id) async {
    final existing = await getScan(id);
    if (existing == null) {
      return;
    }
    await _imageStorage.deleteIfExists(existing.localImagePath);
    await _local.delete(id);
    _emit();
  }

  @override
  Future<void> markAsPublic(String id) async {
    final scan = await getScan(id);
    if (scan == null) {
      return;
    }
    await updateScan(scan.copyWith(isPublic: true));
  }

  @override
  Future<void> markAsPrivate(String id) async {
    final scan = await getScan(id);
    if (scan == null) {
      return;
    }
    await updateScan(scan.copyWith(isPublic: false));
  }

  @override
  Future<void> updateUserCorrection(
    String scanId,
    UserVehicleCorrection correction,
  ) async {
    final scan = await getScan(scanId);
    if (scan == null) {
      return;
    }
    final next = scan.copyWith(
      userCorrection: correction,
      updateUserCorrection: true,
      updatedAt: DateTime.now().toUtc(),
    );
    await updateScan(next);
    final synced =
        !next.pendingSync &&
        (next.remoteImageUrl != null && next.remoteImageUrl!.isNotEmpty);
    if (synced) {
      await _correctionSink.pushUserCorrection(scanId, correction);
    }
  }
}
