import 'package:geolocator/geolocator.dart';

/// Abstrakcja pozycji GPS (łatwe podstawienie w testach).
abstract class CurrentPositionReader {
  Future<Position> getCurrentPosition();
}
