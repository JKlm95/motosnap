import 'package:geolocator/geolocator.dart';

/// Pobiera pozycję GPS urządzenia. Logika uprawnień i błędów poza widgetami.
class DeviceLocationService {
  Future<Position> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedException(permission);
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}

final class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException(this.permission);

  final LocationPermission permission;

  @override
  String toString() => 'LocationPermissionDeniedException($permission)';
}
