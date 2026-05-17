import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motosnap/app/shell/glass_shell_bottom_nav.dart';
import 'package:motosnap/core/locale/app_strings.dart';

void main() {
  testWidgets('GlassShellBottomNav: cztery etykiety z AppStrings (PL)', (
    tester,
  ) async {
    final s = AppStrings.fromLanguageCode('pl');
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pl'),
        supportedLocales: const [Locale('en'), Locale('pl')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Center(
            child: GlassShellBottomNav(
              currentBranchIndex: 0,
              onBranchSelected: (_) {},
              historyLabel: s.historyTitle,
              mapLabel: s.mapTitle,
              scanLabel: s.scanTabTitle,
              settingsLabel: s.settingsTitle,
            ),
          ),
        ),
      ),
    );

    expect(find.text(s.historyTitle), findsOneWidget);
    expect(find.text(s.mapTitle), findsOneWidget);
    expect(find.text(s.scanTabTitle), findsOneWidget);
    expect(find.text(s.settingsTitle), findsOneWidget);
  });
}
