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
    final typeRaw = json['vehicle_type'] as String?;
    VehicleType? parsedType;
    if (typeRaw != null) {
      try {
        parsedType = VehicleType.values.byName(typeRaw);
      } on ArgumentError {
        parsedType = VehicleType.unknown;
      }
    }

    final engines =
        (json['possible_engines'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const <String>[];

    return VehicleInfo(
      vehicleType: parsedType,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      generation: json['generation'] as String?,
      productionYears: json['production_years'] as String?,
      possibleEngines: engines,
      shortDescription: json['short_description'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      sourceLanguage: json['source_language'] as String?,
      wasUserCorrected: json['was_user_corrected'] as bool? ?? false,
    );
  }
}
