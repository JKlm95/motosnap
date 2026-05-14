/// Lokalizacja skanu (GPS + opcjonalny reverse geocoding).
class ScanLocation {
  const ScanLocation({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
    this.displayName,
    this.isApproximatePublicLocation = true,
  });

  final double latitude;
  final double longitude;
  final String? city;
  final String? country;
  final String? displayName;
  final bool isApproximatePublicLocation;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
      'display_name': displayName,
      'is_approximate_public_location': isApproximatePublicLocation,
    };
  }

  factory ScanLocation.fromJson(Map<String, dynamic> json) {
    return ScanLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      city: json['city'] as String?,
      country: json['country'] as String?,
      displayName: json['display_name'] as String?,
      isApproximatePublicLocation:
          json['is_approximate_public_location'] as bool? ?? true,
    );
  }

  ScanLocation copyWith({
    double? latitude,
    double? longitude,
    String? city,
    String? country,
    String? displayName,
    bool? isApproximatePublicLocation,
  }) {
    return ScanLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      country: country ?? this.country,
      displayName: displayName ?? this.displayName,
      isApproximatePublicLocation:
          isApproximatePublicLocation ?? this.isApproximatePublicLocation,
    );
  }
}
