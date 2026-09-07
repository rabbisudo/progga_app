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
    try {
      final box = _hiveService.getSettingsBox();
      final savedTheme = box.get(_themeKey) as String?;
      if (savedTheme != null) {
        state = ThemeMode.values.firstWhere(
          (e) => e.name == savedTheme,
          orElse: () => ThemeMode.light,
        );
      }
    } catch (_) {
      // Gracefully fall back to light theme if box is not available
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final box = _hiveService.getSettingsBox();
      await box.put(_themeKey, mode.name);
    } catch (_) {}
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return ThemeModeNotifier(hiveService);
});
