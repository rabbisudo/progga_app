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

  Map<String, dynamic> recursivelyCastMap(Map<dynamic, dynamic> source) {
    return source.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), recursivelyCastMap(value));
      } else if (value is List) {
        return MapEntry(
          key.toString(),
          value.map((item) {
            if (item is Map) {
              return recursivelyCastMap(item);
            }
            return item;
          }).toList(),
        );
      }
      return MapEntry(key.toString(), value);
    });
  }

  List<dynamic>? getCachedList(String key) {
    try {
      final list = getSettingsBox().get(key);
      if (list is List) {
        return list.map((item) {
          if (item is Map) {
            return recursivelyCastMap(item);
          }
          return item;
        }).toList();
      }
    } catch (_) {}
    return null;
  }

  Future<void> cacheList(String key, List<dynamic> list) async {
    try {
      await getSettingsBox().put(key, list);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    await getPracticeBox().clear();
    await getSettingsBox().clear();
  }
}

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});
