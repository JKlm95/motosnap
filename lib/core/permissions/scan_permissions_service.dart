import 'package:permission_handler/permission_handler.dart';

/// Prosi o uprawnienia potrzebne do lokalnego skanu (kamera + lokalizacja „when in use”).
class ScanPermissionsService {
  Future<void> ensureCameraAndWhenInUseLocation() async {
    final location = await Permission.locationWhenInUse.request();
    if (!location.isGranted) {
      throw const ScanPermissionException(
        'Brak zgody na lokalizację. GPS jest wymagany do zapisu skanu.',
      );
    }

    final camera = await Permission.camera.request();
    if (!camera.isGranted) {
      throw const ScanPermissionException(
        'Brak zgody na aparat. Zdjęcie można zrobić tylko z kamery.',
      );
    }
  }
}

final class ScanPermissionException implements Exception {
  const ScanPermissionException(this.message);

  final String message;

  @override
  String toString() => 'ScanPermissionException($message)';
}
