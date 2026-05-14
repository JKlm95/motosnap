import 'package:image_picker/image_picker.dart';

import 'vehicle_scan.dart';

abstract class ScanRepository {
  Stream<void> get localScansChanged;

  Future<List<VehicleScan>> loadScansOrdered();

  /// Tworzy skan: wymaga lokalizacji GPS i trwałej kopii zdjęcia na dysku.
  Future<VehicleScan> createScanFromCameraImage(XFile file);
}
