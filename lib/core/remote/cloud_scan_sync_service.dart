import '../../features/scan/domain/vehicle_scan.dart';

/// Abstrakcja wysyłki skanów do chmury (Firebase Storage + Firestore itd.) — implementacja później.
abstract class CloudScanSyncService {
  Future<void> enqueueForUpload(VehicleScan scan);
}

class NoOpCloudScanSyncService implements CloudScanSyncService {
  @override
  Future<void> enqueueForUpload(VehicleScan scan) async {}
}
