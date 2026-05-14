import 'package:image_picker/image_picker.dart';

import 'user_vehicle_correction.dart';
import 'vehicle_scan.dart';

abstract class ScanRepository {
  /// Emisja pełnej listy skanów przy każdej zmianie lokalnej bazy.
  Stream<List<VehicleScan>> watchScans();

  Future<List<VehicleScan>> getRecentScans(int limit);

  Future<VehicleScan?> getScan(String id);

  /// Zapisuje skan: wymaga lokalizacji GPS i trwałej kopii zdjęcia na dysku.
  Future<VehicleScan> createScan({required XFile capturedPhoto});

  Future<void> updateScan(VehicleScan scan);

  Future<void> deleteScan(String id);

  Future<void> markAsPublic(String id);

  Future<void> markAsPrivate(String id);

  /// Zapisuje korektę użytkownika (osobno od [VehicleScan.vehicleInfo]); opcjonalnie wypycha do Firestore.
  Future<void> updateUserCorrection(
    String scanId,
    UserVehicleCorrection correction,
  );
}
