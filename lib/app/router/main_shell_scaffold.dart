import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/locale/app_strings.dart';
import '../shell/glass_shell_bottom_nav.dart';
import '../shell/main_shell_layout.dart';

class MainShellScaffold extends StatelessWidget {
  const MainShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final bottomPad =
        MediaQuery.paddingOf(context).bottom + kShellGlassNavContentPadding;

    return MainShellLayout(
      bottomContentPadding: bottomPad,
      isScanTabActive: navigationShell.currentIndex == 0,
      child: Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: GlassShellBottomNav(
          currentBranchIndex: navigationShell.currentIndex,
          historyLabel: s.historyTitle,
          mapLabel: s.mapTitle,
          scanLabel: s.scanTabTitle,
          settingsLabel: s.settingsTitle,
          onBranchSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }
}
