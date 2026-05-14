import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/shell/main_shell_layout.dart';
import '../../../../core/firebase/cloud_sync_availability.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/locale/app_strings.dart';
import '../../../auth/domain/auth_repository.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../cubit/sync_cubit.dart';
import '../cubit/sync_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final auth = context.read<AuthRepository>();
    final email = auth.currentUserEmail ?? '—';
    final bottomPad = MainShellLayout.paddingOf(context);
    final cloudOk = context.read<CloudSyncAvailability>().available;

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
            children: [
              Text(
                s.settingsAccount,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(s.settingsEmail),
                      subtitle: Text(email),
                    ),
                    ListTile(
                      title: Text(s.settingsSignOut),
                      leading: const Icon(Icons.logout_rounded),
                      onTap: () async {
                        await auth.signOut();
                        if (context.mounted) {
                          context.go(AppRoutes.login);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                s.settingsSyncSection,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        cloudOk
                            ? s.settingsSyncReadyBody
                            : s.settingsSyncOfflineBody,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      BlocConsumer<SyncCubit, SyncState>(
                        listener: (context, syncState) {
                          final loc = AppStrings.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          if (syncState.status == ManualSyncStatus.done &&
                              syncState.summary != null) {
                            final sum = syncState.summary!;
                            if (sum.failed == 0 && sum.uploaded > 0) {
                              AppHaptics.success();
                            } else if (sum.uploaded == 0 && sum.failed > 0) {
                              AppHaptics.error();
                            } else if (sum.failed > 0) {
                              AppHaptics.warning();
                            } else {
                              AppHaptics.success();
                            }
                            messenger.clearSnackBars();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  loc.syncDoneSnack(sum.uploaded, sum.failed),
                                ),
                              ),
                            );
                          } else if (syncState.status ==
                                  ManualSyncStatus.error &&
                              syncState.userError != null) {
                            AppHaptics.error();
                            final msg = switch (syncState.userError!) {
                              SyncUserError.cloudDisabled =>
                                loc.errorSyncCloudUnavailable,
                              SyncUserError.generic => loc.errorSyncGeneric,
                            };
                            messenger.clearSnackBars();
                            messenger.showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          }
                        },
                        builder: (context, syncState) {
                          final busy =
                              syncState.status == ManualSyncStatus.running;
                          return FilledButton.tonal(
                            onPressed: (!cloudOk || busy)
                                ? null
                                : () => context.read<SyncCubit>().syncNow(),
                            child: busy
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(s.settingsSyncNow),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                s.settingsLanguageSection,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: Text(s.settingsLanguageTitle),
                  subtitle: Text(s.settingsLanguageSubtitle),
                  leading: const Icon(Icons.language_rounded),
                  onTap: () {},
                ),
              ),
              const SizedBox(height: 20),
              Text(
                s.settingsAppearance,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        s.settingsTheme,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text(s.themeSystem),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text(s.themeLight),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text(s.themeDark),
                          ),
                        ],
                        selected: {state.themeMode},
                        onSelectionChanged: (selection) {
                          if (selection.isEmpty) {
                            return;
                          }
                          context.read<SettingsCubit>().setThemeMode(
                            selection.first,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
