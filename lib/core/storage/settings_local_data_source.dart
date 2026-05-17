import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsLocalDataSource {
  SettingsLocalDataSource(this._box);

  static const boxName = 'app_settings';
  static const themeModeKey = 'theme_mode';

  final Box<dynamic> _box;

  static Future<SettingsLocalDataSource> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return SettingsLocalDataSource(box);
  }

  ThemeMode readThemeMode() {
    final raw = _box.get(themeModeKey) as String?;
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.dark,
    };
  }

  Future<void> writeThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _box.put(themeModeKey, value);
  }
}
