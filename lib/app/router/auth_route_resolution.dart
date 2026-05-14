import '../../features/auth/domain/auth_repository.dart';
import 'app_routes.dart';

/// Logika redirectów auth — czysta funkcja, łatwa do testów bez `BuildContext`.
abstract final class AuthRouteResolution {
  static String? redirect({
    required AuthRepository auth,
    required String location,
  }) {
    final session = auth.readSessionSync();
    final isSplash = location == AppRoutes.splash;
    final isAuthPath =
        location == AppRoutes.login ||
        location == AppRoutes.register ||
        location == AppRoutes.forgotPassword;
    final isShellPath =
        location == AppRoutes.scanRelative ||
        location == AppRoutes.historyRelative ||
        location == AppRoutes.settingsRelative;
    final isVehicleScan = location.startsWith('/vehicle-scan/');

    if (session == AuthSessionState.signedOut) {
      if (isSplash || isAuthPath) {
        return null;
      }
      if (isShellPath || isVehicleScan) {
        return AppRoutes.login;
      }
      return null;
    }

    // signed in
    if (isSplash) {
      return null;
    }
    if (isAuthPath) {
      return AppRoutes.scanRelative;
    }
    return null;
  }
}
