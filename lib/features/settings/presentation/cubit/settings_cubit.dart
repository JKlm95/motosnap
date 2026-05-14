import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository)
    : super(const SettingsState(themeMode: ThemeMode.system));

  final SettingsRepository _repository;

  Future<void> load() async {
    final mode = await _repository.loadThemeMode();
    emit(SettingsState(themeMode: mode));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repository.saveThemeMode(mode);
    emit(SettingsState(themeMode: mode));
  }
}
