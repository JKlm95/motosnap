import 'package:flutter/material.dart';

import '../../../core/storage/settings_local_data_source.dart';
import '../domain/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._local);

  final SettingsLocalDataSource _local;

  @override
  Future<ThemeMode> loadThemeMode() async => _local.readThemeMode();

  @override
  Future<void> saveThemeMode(ThemeMode mode) => _local.writeThemeMode(mode);
}
