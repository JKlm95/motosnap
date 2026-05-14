import 'package:permission_handler/permission_handler.dart';

import 'scan_permission_denied_kind.dart';
import 'scan_permission_exception.dart';

export 'scan_permission_denied_kind.dart';
export 'scan_permission_exception.dart';

/// Prosi o uprawnienia potrzebne do lokalnego skanu (kamera + lokalizacja „when in use”).
class ScanPermissionsService {
  Future<void> ensureCameraAndWhenInUseLocation() async {
    final location = await Permission.locationWhenInUse.request();
    if (!location.isGranted) {
      throw const ScanPermissionException(
        ScanPermissionDeniedKind.locationWhenInUse,
      );
    }

    final camera = await Permission.camera.request();
    if (!camera.isGranted) {
      throw const ScanPermissionException(ScanPermissionDeniedKind.camera);
    }
  }
}
