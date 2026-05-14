import 'package:flutter/material.dart';

/// Szacunkowa wysokość treści pod pływającą nawigację (pill + wystający przycisk Skan).
const double kShellGlassNavContentPadding = 100;

/// Przekazuje rezerwę miejsca pod pływającą nawigację szklaną (żeby treść nie chowała się pod bar).
class MainShellLayout extends InheritedWidget {
  const MainShellLayout({
    super.key,
    required this.bottomContentPadding,
    required super.child,
  });

  final double bottomContentPadding;

  static double paddingOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<MainShellLayout>()
            ?.bottomContentPadding ??
        kShellGlassNavContentPadding;
  }

  @override
  bool updateShouldNotify(MainShellLayout oldWidget) {
    return oldWidget.bottomContentPadding != bottomContentPadding;
  }
}
