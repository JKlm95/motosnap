import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/forgot_password/forgot_password_screen.dart';
import '../../features/auth/presentation/login/login_screen.dart';
import '../../features/auth/presentation/register/register_screen.dart';
import '../../features/history/presentation/cubit/history_cubit.dart';
import '../../features/history/presentation/view/history_screen.dart';
import '../../features/scan/domain/scan_repository.dart';
import '../../features/scan/presentation/cubit/scan_cubit.dart';
import '../../features/scan/presentation/view/scan_screen.dart';
import '../../features/settings/presentation/view/settings_screen.dart';
import '../../features/splash/presentation/cubit/splash_cubit.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../core/media/camera_capture_service.dart';
import 'app_routes.dart';
import 'main_shell_scaffold.dart';

abstract final class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => BlocProvider(
            create: (_) => SplashCubit()..runSequence(),
            child: const SplashScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShellScaffold(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.scanRelative,
                  builder: (context, state) => BlocProvider(
                    create: (_) => ScanCubit(
                      scanRepository: context.read<ScanRepository>(),
                      cameraCapture: context.read<CameraCaptureService>(),
                    ),
                    child: const ScanScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.historyRelative,
                  builder: (context, state) => BlocProvider(
                    create: (_) => HistoryCubit(context.read<ScanRepository>()),
                    child: const HistoryScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.settingsRelative,
                  builder: (context, state) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
