import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HiveService {
  static const String practiceBoxName = 'offline_practice_box';
  static const String settingsBoxName = 'profile_settings_box';

  HiveCipher? _cachedCipher;
  bool _isSettingsBoxInitialized = false;
  bool _isPracticeBoxInitialized = false;

  Future<HiveCipher?> _resolveCipher() async {
    if (_cachedCipher != null) return _cachedCipher;

    List<int>? encryptionKeyBytes;
    try {
      const secureStorage = FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      );
      var base64Key = await secureStorage.read(key: 'hive_encryption_key').timeout(
        const Duration(milliseconds: 1200),
        onTimeout: () => null,
      );
      if (base64Key == null) {
        final key = Hive.generateSecureKey();
        base64Key = base64UrlEncode(key);
        await secureStorage.write(key: 'hive_encryption_key', value: base64Key).timeout(
          const Duration(milliseconds: 1200),
          onTimeout: () {},
        );
      }
      encryptionKeyBytes = base64Url.decode(base64Key);
    } catch (_) {
      // Suppress KeyStore errors on unsupported/budget devices
    }

    _cachedCipher = encryptionKeyBytes != null ? HiveAesCipher(encryptionKeyBytes) : null;
    return _cachedCipher;
  }

  /// Critical fast-path startup initialization: ONLY initializes Hive & profile_settings_box
  Future<void> init({bool settingsOnly = true}) async {
    if (_isSettingsBoxInitialized && (!settingsOnly || _isPracticeBoxInitialized)) return;

    await Hive.initFlutter();
    final cipher = await _resolveCipher();

    if (!_isSettingsBoxInitialized) {
      await _openSafeBox(settingsBoxName, cipher);
      _isSettingsBoxInitialized = true;
    }

    if (!settingsOnly && !_isPracticeBoxInitialized) {
      await _openSafeBox(practiceBoxName, cipher);
      _isPracticeBoxInitialized = true;
    }
  }

  /// Returns whether settingsBox is currently open
  bool get isSettingsBoxOpen => Hive.isBoxOpen(settingsBoxName);

  /// Guarantees that settingsBox is open, falling back to unencrypted box if needed
  Future<void> ensureSettingsBoxOpen() async {
    if (Hive.isBoxOpen(settingsBoxName)) {
      _isSettingsBoxInitialized = true;
      return;
    }
    try {
      await Hive.initFlutter();
      final cipher = await _resolveCipher();
      await _openSafeBox(settingsBoxName, cipher);
    } catch (_) {
      try {
        await Hive.openBox(settingsBoxName);
      } catch (_) {}
    }
    _isSettingsBoxInitialized = Hive.isBoxOpen(settingsBoxName);
  }

  /// Non-blocking deferred background initialization for offline practice box
  Future<void> initPracticeBox() async {
    if (_isPracticeBoxInitialized || Hive.isBoxOpen(practiceBoxName)) {
      _isPracticeBoxInitialized = true;
      return;
    }
    final cipher = await _resolveCipher();
    await _openSafeBox(practiceBoxName, cipher);
    _isPracticeBoxInitialized = true;
  }

  Future<Box> _openSafeBox(String name, [HiveCipher? cipher]) async {
    try {
      if (Hive.isBoxOpen(name)) return Hive.box(name);
      return await Hive.openBox(name, encryptionCipher: cipher);
    } catch (_) {
      // Auto-recover from key mismatch (e.g. app reinstallation, cloud restore) or box corruption
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {}
      try {
        return await Hive.openBox(name, encryptionCipher: cipher);
      } catch (_) {
        // Last-resort fallback without cipher
        return await Hive.openBox(name);
      }
    }
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

  Map<String, dynamic>? getCachedMap(String key) {
    try {
      final data = getSettingsBox().get(key);
      if (data is Map) {
        return recursivelyCastMap(data);
      }
    } catch (_) {}
    return null;
  }

  Future<void> cacheMap(String key, Map<String, dynamic> map) async {
    try {
      await getSettingsBox().put(key, map);
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
