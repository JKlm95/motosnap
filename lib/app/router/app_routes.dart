/// Ścieżki routingu (go_router). Shell używa ścieżek względnych gałęzi.
abstract final class AppRoutes {
  static const splash = '/splash';

  static const login = '/auth/login';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';

  /// Bazowy segment StatefulShell — pełne URL-e to `/scan`, `/history`, `/settings`.
  static const scanRelative = '/scan';
  static const historyRelative = '/history';
  static const settingsRelative = '/settings';
}
