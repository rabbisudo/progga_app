import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _deviceUuidKey = 'device_uuid';

  SecureStorageService(this._storage);

  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token).timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
    } catch (_) {}
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRefreshToken(String token) async {
    // Single-token system: no-op
  }

  Future<String?> getRefreshToken() async {
    // Single-token system: return null
    return null;
  }

  Future<void> clearTokens() async {
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
      resetOnError: true,
    ),
  ));
});

