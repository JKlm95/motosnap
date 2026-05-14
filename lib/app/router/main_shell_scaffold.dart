import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/locale/app_strings.dart';

class MainShellScaffold extends StatelessWidget {
  const MainShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.photo_camera_outlined),
        selectedIcon: const Icon(Icons.photo_camera),
        label: s.scanTabTitle,
      ),
      NavigationDestination(
        icon: const Icon(Icons.history_outlined),
        selectedIcon: const Icon(Icons.history),
        label: s.historyTitle,
      ),
      NavigationDestination(
        icon: const Icon(Icons.tune_outlined),
        selectedIcon: const Icon(Icons.tune),
        label: s.settingsTitle,
      ),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: destinations,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
