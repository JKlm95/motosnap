import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motosnap/core/locale/app_strings.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan_status.dart';
import 'package:motosnap/features/scan/presentation/widgets/scan_status_badge.dart';

void main() {
  final s = AppStrings.fromLanguageCode('pl');

  Future<void> pumpBadge(WidgetTester tester, VehicleScanStatus status) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ScanStatusBadge(status: status, label: s.scanStatus(status)),
          ),
        ),
      ),
    );
  }

  testWidgets('ScanStatusBadge: każdy status pokazuje etykietę', (
    tester,
  ) async {
    for (final status in VehicleScanStatus.values) {
      await pumpBadge(tester, status);
      expect(find.text(s.scanStatus(status)), findsOneWidget);
    }
  });

  testWidgets('UserCorrectedBadge pokazuje etykietę PL', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: UserCorrectedBadge(label: s.correctedByUserLabel),
          ),
        ),
      ),
    );
    expect(find.text(s.correctedByUserLabel), findsOneWidget);
  });
}
