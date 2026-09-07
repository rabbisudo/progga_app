import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  static String? _memoryAccessToken;
  
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _deviceUuidKey = 'device_uuid';
  static const _hiveBackupBoxName = 'profile_settings_box';
  static const _hiveTokenKey = 'auth_session_token';

  SecureStorageService(this._storage);

  Future<void> saveAccessToken(String token) async {
    _memoryAccessToken = token;

    // 1. Save to primary encrypted storage
    try {
      await _storage.write(key: _accessTokenKey, value: token).timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
    } catch (_) {}

    // 2. Persist to reliable Hive backup layer
    try {
      if (Hive.isBoxOpen(_hiveBackupBoxName)) {
        await Hive.box(_hiveBackupBoxName).put(_hiveTokenKey, token);
      }
    } catch (_) {}
  }

  Future<String?> getAccessToken() async {
    // 1. Fastest: In-memory cache (<0.01ms)
    if (_memoryAccessToken != null && _memoryAccessToken!.isNotEmpty) {
      return _memoryAccessToken;
    }

    // 2. Read from primary secure storage
    String? token;
    try {
      token = await _storage.read(key: _accessTokenKey).timeout(
        const Duration(milliseconds: 1200),
        onTimeout: () => null,
      );
    } catch (_) {
      token = null;
    }

    // 3. Fail-safe: Read from Hive backup layer if KeyStore failed or returned null
    if (token == null || token.isEmpty) {
      try {
        if (Hive.isBoxOpen(_hiveBackupBoxName)) {
          final hiveToken = Hive.box(_hiveBackupBoxName).get(_hiveTokenKey);
          if (hiveToken is String && hiveToken.isNotEmpty) {
            token = hiveToken;
            // Re-sync back to primary storage
            try {
              await _storage.write(key: _accessTokenKey, value: token);
            } catch (_) {}
          }
        }
      } catch (_) {}
    }

    if (token != null && token.isNotEmpty) {
      _memoryAccessToken = token;
    }
    return token;
  }

  Future<void> saveRefreshToken(String token) async {
    // Single-token system: no-op
  }

  Future<String?> getRefreshToken() async {
    // Single-token system: return null
    return null;
  }

  Future<void> clearTokens() async {
    _memoryAccessToken = null;
    try {
      await _storage.delete(key: _accessTokenKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
      await _storage.delete(key: _refreshTokenKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
    } catch (_) {}

    try {
      if (Hive.isBoxOpen(_hiveBackupBoxName)) {
        await Hive.box(_hiveBackupBoxName).delete(_hiveTokenKey);
      }
    } catch (_) {}
  }

  /// Resolves device unique UUID, generating and persisting if not previously allocated.
  Future<String> getOrGenerateDeviceUuid() async {
    try {
      String? current = await _storage.read(key: _deviceUuidKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      if (current == null) {
        current = const Uuid().v4();
        await _storage.write(key: _deviceUuidKey, value: current).timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      }
      return current;
    } catch (_) {
      return const Uuid().v4();
    }
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  ));
});

