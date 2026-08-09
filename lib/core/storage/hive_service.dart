import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HiveService {
  static const String practiceBoxName = 'offline_practice_box';
  static const String settingsBoxName = 'profile_settings_box';

  Future<void> init() async {
    await Hive.initFlutter();

    // Securely retrieve or generate standard AES-256 encryption key from Keystore/Keychain
    const secureStorage = FlutterSecureStorage();
    var base64Key = await secureStorage.read(key: 'hive_encryption_key');
    if (base64Key == null) {
      final key = Hive.generateSecureKey();
      base64Key = base64UrlEncode(key);
      await secureStorage.write(key: 'hive_encryption_key', value: base64Key);
    }
    final encryptionKeyBytes = base64Url.decode(base64Key);

    // Open boxes with AES-256 cipher encryption
    await Hive.openBox(
      practiceBoxName,
      encryptionCipher: HiveAesCipher(encryptionKeyBytes),
    );
    await Hive.openBox(
      settingsBoxName,
      encryptionCipher: HiveAesCipher(encryptionKeyBytes),
    );
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
