import 'vehicle_info.dart';
import 'vehicle_type.dart';

/// Korekta użytkownika względem wyniku AI — osobny dokument (`user_correction` w Firestore / Hive).
///
/// Pole `source` jest zawsze `"user"` (zgodnie ze schematem produktowym).
class UserVehicleCorrection {
  const UserVehicleCorrection({
    required this.vehicleType,
    this.brand,
    this.model,
    this.generation,
    this.productionYears,
    this.possibleEngines = const <String>[],
    this.shortDescription,
    required this.correctedAt,
    this.source = 'user',
  });

  final VehicleType vehicleType;
  final String? brand;
  final String? model;
  final String? generation;
  final String? productionYears;
  final List<String> possibleEngines;
  final String? shortDescription;
  final DateTime correctedAt;
  final String source;

  /// Do wyświetlania jako [VehicleInfo] z flagą `wasUserCorrected`.
  VehicleInfo toEffectiveVehicleInfo({VehicleInfo? aiBaseline}) {
    return VehicleInfo(
      vehicleType: vehicleType,
      brand: brand ?? aiBaseline?.brand,
      model: model ?? aiBaseline?.model,
      generation: generation ?? aiBaseline?.generation,
      productionYears: productionYears ?? aiBaseline?.productionYears,
      possibleEngines: possibleEngines.isNotEmpty
          ? possibleEngines
          : (aiBaseline?.possibleEngines ?? const []),
      shortDescription: shortDescription ?? aiBaseline?.shortDescription,
      confidence: aiBaseline?.confidence,
      sourceLanguage: aiBaseline?.sourceLanguage,
      wasUserCorrected: true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'vehicle_type': vehicleType.name,
      'brand': brand,
      'model': model,
      'generation': generation,
      'production_years': productionYears,
      'possible_engines': possibleEngines,
      'short_description': shortDescription,
      'corrected_at': correctedAt.toIso8601String(),
      'source': source,
    };
  }

  factory UserVehicleCorrection.fromJson(Map<String, dynamic> json) {
    final typeRaw =
        json['vehicle_type'] as String? ?? json['vehicleType'] as String?;
    VehicleType? parsedType;
    if (typeRaw != null) {
      try {
        parsedType = VehicleType.values.byName(typeRaw);
      } on ArgumentError {
        parsedType = VehicleType.unknown;
      }
    }

    final enginesRaw = json['possible_engines'] ?? json['possibleEngines'];
    var engines = const <String>[];
    if (enginesRaw is List<dynamic>) {
      engines = enginesRaw.map((e) => e as String).toList();
    }

    final correctedRaw =
        json['corrected_at'] as String? ?? json['correctedAt'] as String?;
    final correctedAt = correctedRaw != null
        ? DateTime.parse(correctedRaw).toUtc()
        : DateTime.now().toUtc();

    return UserVehicleCorrection(
      vehicleType: parsedType ?? VehicleType.unknown,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      generation: json['generation'] as String?,
      productionYears:
          json['production_years'] as String? ??
          json['productionYears'] as String?,
      possibleEngines: engines,
      shortDescription:
          json['short_description'] as String? ??
          json['shortDescription'] as String?,
      correctedAt: correctedAt,
      source: json['source'] as String? ?? 'user',
    );
  }
}
