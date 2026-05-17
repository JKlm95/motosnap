/// Ścieżki routingu (go_router). Shell używa ścieżek względnych gałęzi.
abstract final class AppRoutes {
  static const splash = '/splash';

  static const login = '/auth/login';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';

  /// Bazowy segment StatefulShell — pełne URL-e: `/scan`, `/history`, `/map`, `/settings`.
  static const scanRelative = '/scan';
  static const historyRelative = '/history';
  static const mapRelative = '/map';
  static const settingsRelative = '/settings';

  /// Pełnoekranowy widok rekordu skanu (poza shell).
  static String vehicleScan(String scanId) => '/vehicle-scan/$scanId';
}
