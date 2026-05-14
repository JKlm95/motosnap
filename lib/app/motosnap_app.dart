import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/settings/presentation/cubit/settings_cubit.dart';
import '../features/settings/presentation/cubit/settings_state.dart';
import 'theme/app_theme.dart';

class MotosnapApp extends StatelessWidget {
  const MotosnapApp({required this.routerConfig, super.key});

  final GoRouter routerConfig;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (prev, next) => prev.themeMode != next.themeMode,
      builder: (context, settings) {
        return MaterialApp.router(
          title: 'MotoSnap',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.themeMode,
          routerConfig: routerConfig,
        );
      },
    );
  }
}
