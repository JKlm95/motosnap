/// Wspólne promienie i poziomy blur — spójność glass / karty / arkusze bez „magic numbers” w widżetach.
abstract final class AppShape {
  /// Zgodne z [ThemeData.cardTheme] (AppTheme).
  static const double card = 16;

  /// Nagłówek zdjęcia na szczegółach, duży podgląd na skanie.
  static const double headerImage = 22;

  /// Miniatura wiersza historii.
  static const double thumbnail = 12;

  /// Górny róg panelu dolnego (DraggableScrollableSheet).
  static const double sheetTop = 28;

  /// Domyślny róg „pływającego” szkła (nie pill).
  static const double glassPanel = 20;

  /// Blur: dolny pasek shell.
  static const double blurNavBar = 16;

  /// Blur: centralny FAB skanu.
  static const double blurNavFab = 18;

  /// Blur: panel szczegółów skanu.
  static const double blurDetailSheet = 14;
}
