import 'package:flutter_test/flutter_test.dart';

import 'package:motosnap/features/scan/domain/vehicle_info.dart';
import 'package:motosnap/features/scan/domain/vehicle_type.dart';

void main() {
  test('VehicleInfo — fromJson akceptuje camelCase (odpowiedź serwera)', () {
    final info = VehicleInfo.fromJson(<String, dynamic>{
      'vehicleType': 'motorcycle',
      'brand': 'Yamaha',
      'model': 'MT-07',
      'generation': null,
      'productionYears': '2014–2025',
      'possibleEngines': ['689 cm³'],
      'shortDescription': 'Naked bike.',
      'confidence': 0.81,
      'sourceLanguage': 'en',
    });
    expect(info.vehicleType, VehicleType.motorcycle);
    expect(info.brand, 'Yamaha');
    expect(info.productionYears, '2014–2025');
    expect(info.possibleEngines, ['689 cm³']);
    expect(info.sourceLanguage, 'en');
  });
}
