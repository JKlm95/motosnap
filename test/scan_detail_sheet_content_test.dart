import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motosnap/core/locale/app_strings.dart';
import 'package:motosnap/features/scan/domain/scan_location.dart';
import 'package:motosnap/features/scan/domain/user_vehicle_correction.dart';
import 'package:motosnap/features/scan/domain/vehicle_info.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan_status.dart';
import 'package:motosnap/features/scan/domain/vehicle_type.dart';
import 'package:motosnap/features/scan/presentation/detail/scan_detail_sheet_content.dart';

void main() {
  final s = AppStrings.fromLanguageCode('pl');
  final created = DateTime.utc(2026, 5, 14, 12);

  VehicleScan baseScan({
    VehicleScanStatus status = VehicleScanStatus.waitingForRecognition,
    VehicleInfo? vehicleInfo,
    UserVehicleCorrection? userCorrection,
    bool pendingSync = false,
    String? remoteUrl,
  }) {
    return VehicleScan(
      id: 't1',
      localImagePath: '/nope.jpg',
      remoteImageUrl: remoteUrl,
      createdAt: created,
      updatedAt: created,
      status: status,
      location: const ScanLocation(
        latitude: 50.1,
        longitude: 19.9,
        displayName: 'Kraków',
      ),
      vehicleInfo: vehicleInfo,
      userCorrection: userCorrection,
      pendingSync: pendingSync,
    );
  }

  Future<void> pumpSheet(
    WidgetTester tester, {
    required VehicleScan scan,
    required bool synced,
    required bool canAnalyze,
  }) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanDetailSheetContent(
            scan: scan,
            s: s,
            busy: false,
            errorMessage: null,
            synced: synced,
            canAnalyze: canAnalyze,
            scrollController: scroll,
            onAnalyze: () {},
            onOpenCorrection: () {},
            onTogglePublic: () {},
            onDeleteTap: () {},
            onClearError: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('recognized: widać markę z effectiveVehicleInfo', (tester) async {
    final scan = baseScan(
      status: VehicleScanStatus.recognized,
      pendingSync: false,
      remoteUrl: 'https://example.com/x.jpg',
      vehicleInfo: const VehicleInfo(
        vehicleType: VehicleType.car,
        brand: 'Skoda',
        model: 'Octavia',
      ),
    );
    await pumpSheet(tester, scan: scan, synced: true, canAnalyze: false);
    expect(find.text('Skoda'), findsWidgets);
  });

  testWidgets('waiting: przycisk analizy gdy synced', (tester) async {
    final scan = baseScan(
      pendingSync: false,
      remoteUrl: 'https://example.com/x.jpg',
    );
    await pumpSheet(tester, scan: scan, synced: true, canAnalyze: true);
    expect(find.text(s.analyzeWithAi), findsWidgets);
  });

  testWidgets('korekta użytkownika: badge poprawki', (tester) async {
    final scan = baseScan(
      status: VehicleScanStatus.recognized,
      pendingSync: false,
      remoteUrl: 'https://example.com/x.jpg',
      vehicleInfo: const VehicleInfo(
        vehicleType: VehicleType.car,
        brand: 'AI',
        model: 'M',
      ),
      userCorrection: UserVehicleCorrection(
        vehicleType: VehicleType.motorcycle,
        brand: 'User',
        correctedAt: DateTime.utc(2026, 5, 15),
      ),
    );
    await pumpSheet(tester, scan: scan, synced: true, canAnalyze: false);
    expect(find.text(s.correctedByUserLabel), findsOneWidget);
  });
}
