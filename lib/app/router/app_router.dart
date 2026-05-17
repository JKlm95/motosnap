import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/media/camera_capture_service.dart';
import '../../core/sync/manual_scan_sync_coordinator.dart';
import '../../core/ui/app_motion.dart';
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
import '../../features/map/presentation/cubit/scan_map_cubit.dart';
import '../../features/map/presentation/view/scan_map_screen.dart';
import '../../features/scan/domain/scan_processing_coordinator.dart';
import '../../features/scan/domain/scan_repository.dart';
import '../../features/scan/domain/vehicle_analysis_service.dart';
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
          pageBuilder: (context, state) {
            final scanId = state.pathParameters['scanId']!;
            return CustomTransitionPage<void>(
              key: state.pageKey,
              transitionDuration: const Duration(milliseconds: 250),
              reverseTransitionDuration: AppMotion.fast,
              child: BlocProvider(
                create: (_) => ScanDetailCubit(
                  context.read<ScanRepository>(),
                  context.read<VehicleAnalysisService>(),
                  scanId,
                  uiLanguageCode: Localizations.localeOf(context).languageCode,
                )..load(),
                child: ScanDetailScreen(scanId: scanId),
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    final curved = CurvedAnimation(
                      parent: animation,
                      curve: AppMotion.emphasizedDecelerate,
                      reverseCurve: AppMotion.standard,
                    );
                    return FadeTransition(
                      opacity: curved,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.02, 0.008),
                          end: Offset.zero,
                        ).animate(curved),
                        child: child,
                      ),
                    );
                  },
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
                      processingCoordinator: context
                          .read<ScanProcessingCoordinator?>(),
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
                    create: (_) => HistoryCubit(
                      context.read<ScanRepository>(),
                      context.read<VehicleAnalysisService>(),
                      context.read<ManualScanSyncCoordinator>(),
                      uiLanguageCode: Localizations.localeOf(
                        context,
                      ).languageCode,
                    ),
                    child: const HistoryScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.mapRelative,
                  builder: (context, state) => BlocProvider(
                    create: (_) => ScanMapCubit(context.read<ScanRepository>()),
                    child: const ScanMapScreen(),
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
                      context.read<ManualScanSyncCoordinator>(),
                      uiLanguageCode: Localizations.localeOf(
                        context,
                      ).languageCode,
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
