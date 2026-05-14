import '../../features/scan/domain/scan_location.dart';
import 'location_metadata_enricher.dart';

class PassthroughLocationEnricher implements LocationMetadataEnricher {
  @override
  Future<ScanLocation> enrich(ScanLocation draft) async => draft;
}
