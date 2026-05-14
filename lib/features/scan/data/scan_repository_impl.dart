import 'dart:async';

import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/location/device_location_service.dart';
import '../../../core/media/image_storage_service.dart';
import '../../../core/remote/cloud_scan_sync_service.dart';
import '../../../core/storage/scan_local_data_source.dart';
import '../domain/scan_repository.dart';
import '../domain/vehicle_analysis_service.dart';
import '../domain/vehicle_scan.dart';

class ScanRepositoryImpl implements ScanRepository {
  ScanRepositoryImpl({
    required ScanLocalDataSource localDataSource,
    required DeviceLocationService locationService,
    required ImageStorageService imageStorage,
    required CloudScanSyncService cloudSync,
    required VehicleAnalysisService analysisService,
  }) : _local = localDataSource,
       _location = locationService,
       _imageStorage = imageStorage,
       _cloudSync = cloudSync,
       _analysis = analysisService;

  final ScanLocalDataSource _local;
  final DeviceLocationService _location;
  final ImageStorageService _imageStorage;
  final CloudScanSyncService _cloudSync;
  final VehicleAnalysisService _analysis;

  final _changed = StreamController<void>.broadcast();

  @override
  Stream<void> get localScansChanged => _changed.stream;

  void _notifyChanged() {
    if (!_changed.isClosed) {
      _changed.add(null);
    }
  }

  @override
  Future<List<VehicleScan>> loadScansOrdered() async {
    return _local.readAllOrdered();
  }

  @override
  Future<VehicleScan> createScanFromCameraImage(XFile file) async {
    final position = await _location.getCurrentPosition();
    final imagePath = await _imageStorage.persistCameraImage(file);

    final scan = VehicleScan(
      id: const Uuid().v4(),
      imagePath: imagePath,
      latitude: position.latitude,
      longitude: position.longitude,
      capturedAt: DateTime.now().toUtc(),
    );

    await _local.upsert(scan);
    await _cloudSync.enqueueForUpload(scan);
    await _analysis.scheduleAnalysis(scan.id);
    _notifyChanged();
    return scan;
  }
}
