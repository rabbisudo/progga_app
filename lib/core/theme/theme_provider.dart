import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/hive_service.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final HiveService _hiveService;
  static const String _themeKey = 'app_theme_mode';

  ThemeModeNotifier(this._hiveService) : super(ThemeMode.light) {
    _loadTheme();
  }

  void _loadTheme() {
    final box = _hiveService.getSettingsBox();
    final savedTheme = box.get(_themeKey) as String?;
    if (savedTheme != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.name == savedTheme,
        orElse: () => ThemeMode.light,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final box = _hiveService.getSettingsBox();
    await box.put(_themeKey, mode.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return ThemeModeNotifier(hiveService);
});
