import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/media/camera_capture_service.dart';
import '../../core/permissions/scan_permissions_service.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/presentation/forgot_password/cubit/forgot_password_cubit.dart';
import '../../features/auth/presentation/forgot_password/forgot_password_screen.dart';
import '../../features/auth/presentation/login/cubit/login_cubit.dart';
import '../../features/auth/presentation/login/login_screen.dart';
import '../../features/auth/presentation/register/cubit/register_cubit.dart';
import '../../features/auth/presentation/register/register_screen.dart';
import '../../features/history/presentation/cubit/history_cubit.dart';
import '../../features/history/presentation/view/history_screen.dart';
import '../../features/scan/domain/pending_scan_sync.dart';
import '../../features/scan/domain/scan_repository.dart';
import '../../features/scan/presentation/cubit/scan_cubit.dart';
import '../../features/scan/presentation/detail/scan_detail_cubit.dart';
import '../../features/scan/presentation/detail/scan_detail_screen.dart';
import '../../features/scan/presentation/view/scan_screen.dart';
import '../../features/settings/presentation/cubit/sync_cubit.dart';
import '../../features/settings/presentation/view/settings_screen.dart';
import '../../features/splash/presentation/cubit/splash_cubit.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'app_routes.dart';
import 'auth_route_resolution.dart';
import 'main_shell_scaffold.dart';

abstract final class AppRouter {
  static GoRouter create({required Listenable refreshListenable}) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: refreshListenable,
      redirect: (context, state) {
        final auth = context.read<AuthRepository>();
        return AuthRouteResolution.redirect(
          auth: auth,
          location: state.matchedLocation,
        );
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => BlocProvider(
            create: (_) =>
                SplashCubit(context.read<AuthRepository>())..runSequence(),
            child: const SplashScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => BlocProvider(
            create: (_) => LoginCubit(context.read<AuthRepository>()),
            child: const LoginScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => BlocProvider(
            create: (_) => RegisterCubit(context.read<AuthRepository>()),
            child: const RegisterScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) => BlocProvider(
            create: (_) => ForgotPasswordCubit(context.read<AuthRepository>()),
            child: const ForgotPasswordScreen(),
          ),
        ),
        GoRoute(
          path: '/vehicle-scan/:scanId',
          builder: (context, state) {
            final scanId = state.pathParameters['scanId']!;
            return BlocProvider(
              create: (_) =>
                  ScanDetailCubit(context.read<ScanRepository>(), scanId)
                    ..load(),
              child: ScanDetailScreen(scanId: scanId),
            );
          },
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
                      permissions: ScanPermissionsService(),
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
                  builder: (context, state) => BlocProvider(
                    create: (_) => SyncCubit(
                      context.read<PendingScanSync?>(),
                      context.read<ScanRepository>(),
                    ),
                    child: const SettingsScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
