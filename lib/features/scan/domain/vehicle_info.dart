import 'vehicle_type.dart';

/// Wynik rozpoznania pojazdu (null = oczekiwanie / brak danych).
class VehicleInfo {
  const VehicleInfo({
    this.vehicleType,
    this.brand,
    this.model,
    this.generation,
    this.productionYears,
    this.possibleEngines = const <String>[],
    this.shortDescription,
    this.confidence,
    this.sourceLanguage,
    this.wasUserCorrected = false,
  });

  final VehicleType? vehicleType;
  final String? brand;
  final String? model;
  final String? generation;
  final String? productionYears;
  final List<String> possibleEngines;
  final String? shortDescription;
  final double? confidence;
  final String? sourceLanguage;
  final bool wasUserCorrected;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'vehicle_type': vehicleType?.name,
      'brand': brand,
      'model': model,
      'generation': generation,
      'production_years': productionYears,
      'possible_engines': possibleEngines,
      'short_description': shortDescription,
      'confidence': confidence,
      'source_language': sourceLanguage,
      'was_user_corrected': wasUserCorrected,
    };
  }

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
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

    return VehicleInfo(
      vehicleType: parsedType,
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
      confidence: (json['confidence'] as num?)?.toDouble(),
      sourceLanguage:
          json['source_language'] as String? ??
          json['sourceLanguage'] as String?,
      wasUserCorrected:
          json['was_user_corrected'] as bool? ??
          json['wasUserCorrected'] as bool? ??
          false,
    );
  }

  /// Wynik AI / backendu — zawsze `wasUserCorrected: false` (nie używać flag z JSON).
  factory VehicleInfo.fromAiResponseJson(Map<String, dynamic> json) {
    final base = VehicleInfo.fromJson(json);
    return VehicleInfo(
      vehicleType: base.vehicleType,
      brand: base.brand,
      model: base.model,
      generation: base.generation,
      productionYears: base.productionYears,
      possibleEngines: base.possibleEngines,
      shortDescription: base.shortDescription,
      confidence: base.confidence,
      sourceLanguage: base.sourceLanguage,
      wasUserCorrected: false,
    );
  }
}
