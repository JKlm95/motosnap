import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/firebase/cloud_sync_availability.dart';
import '../../../auth/domain/auth_repository.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../cubit/sync_cubit.dart';
import '../cubit/sync_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();
    final email = auth.currentUserEmail ?? '—';
    final cloudOk = context.read<CloudSyncAvailability>().available;

    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(
                'Konto',
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
                      title: const Text('E-mail'),
                      subtitle: Text(email),
                    ),
                    ListTile(
                      title: const Text('Wyloguj'),
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
                'Synchronizacja',
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
                            ? 'Firebase gotowy — skany z `pendingSync` możesz wysłać ręcznie.'
                            : 'Tryb bez Firebase (np. brak `flutterfire configure`). Skany zostają lokalnie.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      BlocConsumer<SyncCubit, SyncState>(
                        listener: (context, syncState) {
                          if (syncState.status == ManualSyncStatus.done &&
                              syncState.summary != null) {
                            final s = syncState.summary!;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Synchronizacja: OK ${s.uploaded}, błędy ${s.failed}',
                                ),
                              ),
                            );
                          } else if (syncState.status ==
                                  ManualSyncStatus.error &&
                              syncState.errorMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(syncState.errorMessage!)),
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
                                : const Text('Synchronizuj teraz'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Język',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: const Text('Język aplikacji'),
                  subtitle: const Text('Wkrótce: wybór pl / en'),
                  leading: const Icon(Icons.language_rounded),
                  onTap: () {},
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Wygląd',
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
                        'Motyw',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Jasny'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Ciemny'),
                          ),
                        ],
                        selected: {state.themeMode},
                        onSelectionChanged: (selection) {
                          if (selection.isEmpty) return;
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
