import 'package:geocoding/geocoding.dart';

import '../../features/scan/domain/scan_location.dart';
import 'location_metadata_enricher.dart';

class GeocodingLocationEnricher implements LocationMetadataEnricher {
  @override
  Future<ScanLocation> enrich(ScanLocation draft) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        draft.latitude,
        draft.longitude,
      );
      if (placemarks.isEmpty) {
        return draft;
      }
      final p = placemarks.first;
      final city =
          p.locality ?? p.subAdministrativeArea ?? p.administrativeArea;
      final country = p.country;
      final parts = <String>[
        if ((city ?? '').isNotEmpty) city!,
        if ((country ?? '').isNotEmpty) country!,
      ];
      final display = parts.isEmpty ? null : parts.join(', ');
      return draft.copyWith(city: city, country: country, displayName: display);
    } on Object {
      return draft;
    }
  }
}
