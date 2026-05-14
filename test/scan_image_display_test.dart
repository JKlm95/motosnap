import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motosnap/features/scan/presentation/widgets/scan_image_display.dart';

void main() {
  test('ScanImageDisplay.heroTagFor jest stabilny', () {
    expect(
      ScanImageDisplay.heroTagFor('abc-123'),
      'motosnap-scan-photo-abc-123',
    );
    expect(
      ScanImageDisplay.heroTagFor('abc-123'),
      ScanImageDisplay.heroTagFor('abc-123'),
    );
  });

  testWidgets('brak pliku i brak URL — placeholder', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 120,
            child: ScanImageDisplay(
              localImagePath: '__no_such_file_motosnap__.jpg',
              remoteImageUrl: null,
            ),
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  });

  testWidgets('ScanImageDisplay z heroTag tworzy Hero', (tester) async {
    const tag = 'motosnap-scan-photo-x';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 50,
            height: 50,
            child: ScanImageDisplay(
              heroTag: tag,
              localImagePath: '__missing__',
              remoteImageUrl: null,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(Hero), findsOneWidget);
  });
}
