import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/core/locale/app_strings.dart';
import 'package:motosnap/features/history/presentation/widgets/premium_history_scan_card.dart';
import 'package:motosnap/features/scan/domain/scan_location.dart';
import 'package:motosnap/features/scan/domain/vehicle_info.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan_status.dart';
import 'package:motosnap/features/scan/domain/vehicle_type.dart';

void main() {
  final s = AppStrings.fromLanguageCode('pl');
  final created = DateTime.utc(2026, 5, 14);

  VehicleScan scan({VehicleInfo? info}) {
    return VehicleScan(
      id: 'card-1',
      localImagePath: '/no/such/file.jpg',
      createdAt: created,
      updatedAt: created,
      status: VehicleScanStatus.recognized,
      location: const ScanLocation(
        latitude: 50,
        longitude: 19,
        displayName: 'Kraków',
      ),
      vehicleInfo: info,
    );
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    required Size size,
    required VehicleScan vehicleScan,
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: PremiumHistoryScanCard(s: s, scan: vehicleScan),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('PremiumHistoryScanCard — brak overflow na wąskim ekranie', (
    tester,
  ) async {
    final info = const VehicleInfo(
      vehicleType: VehicleType.car,
      brand: 'BMW M4 Competition xDrive',
      model: 'Coupe Individual',
      productionYears: '2022–2024',
      confidence: 0.92,
    );

    await pumpCard(
      tester,
      size: const Size(320, 640),
      vehicleScan: scan(info: info),
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
  });
}
