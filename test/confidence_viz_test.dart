import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/core/locale/app_strings.dart';
import 'package:motosnap/features/scan/presentation/widgets/confidence_viz.dart';

void main() {
  testWidgets('ConfidenceViz — wysoka etykieta PL', (tester) async {
    final s = AppStrings.fromLanguageCode('pl');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ConfidenceViz(s: s, confidence: 0.82)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(s.confidenceHigh), findsOneWidget);
    expect(find.textContaining('%'), findsWidgets);
  });
}
