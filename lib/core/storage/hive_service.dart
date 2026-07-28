import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HiveService {
  static const String practiceBoxName = 'offline_practice_box';
  static const String settingsBoxName = 'profile_settings_box';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(practiceBoxName);
    await Hive.openBox(settingsBoxName);
  }

  Box getPracticeBox() {
    return Hive.box(practiceBoxName);
  }

  Box getSettingsBox() {
    return Hive.box(settingsBoxName);
  }

  Future<void> clearAll() async {
    await getPracticeBox().clear();
    await getSettingsBox().clear();
  }
}

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});
