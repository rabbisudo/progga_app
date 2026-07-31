import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/network/api_client.dart';
import '../domain/auth_state.dart';
import 'package:dio/dio.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final SecureStorageService _storage;
  final ApiClient _apiClient;

  AuthNotifier(this._storage, this._apiClient) : super(const AuthState.initial()) {
    checkActiveSession();
  }

  /**
   * Evaluates if a token is present, and tries fetching profile data.
   */
  Future<void> checkActiveSession() async {
    final token = await _storage.getAccessToken();
    if (token == null) {
      state = const AuthState.initial();
      return;
    }

    state = const AuthState.loading();
    try {
      final response = await _apiClient.dio.get('/users/me');
      if (response.statusCode == 200) {
        state = AuthState.authenticated(
          user: response.data,
          accessToken: token,
        );
      } else {
        await _storage.clearTokens();
        state = const AuthState.initial();
      }
    } catch (e) {
      await _storage.clearTokens();
      state = const AuthState.initial();
    }
  }

  /**
   * Submits a Google Sign-In verification payload (real or developer mocked).
   */
  Future<void> loginWithGoogle(String idToken) async {
    state = const AuthState.loading();
    try {
      final deviceUuid = await _storage.getOrGenerateDeviceUuid();
      
      final response = await _apiClient.dio.post('/auth/google', data: {
        'idToken': idToken,
        'deviceUuid': deviceUuid,
        'deviceOs': 'android', // Maps dynamically in app runtimes
        'deviceToken': 'fcm-dummy-token-placeholder',
      });

      if (response.statusCode == 200) {
        final data = response.data;
        final accessToken = data['tokens']['accessToken'] as String;
        final refreshToken = data['tokens']['refreshToken'] as String;
        final user = data['user'] as Map<String, dynamic>;

        // Write tokens to secure vaults
        await _storage.saveAccessToken(accessToken);
        await _storage.saveRefreshToken(refreshToken);

        state = AuthState.authenticated(
          user: user,
          accessToken: accessToken,
        );
      } else {
        state = const AuthState.error(message: 'Google login failed');
      }
    } on DioException catch (dioErr) {
      final networkErr = _apiClient.handleError(dioErr);
      state = AuthState.error(message: networkErr.message);
    } catch (e) {
      state = AuthState.error(message: e.toString());
    }
  }

  /**
   * Logs out user and purges cached session data.
   */
  Future<void> logout() async {
    await _storage.clearTokens();
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
    state = const AuthState.initial();
  }

  /**
   * Resets auth state back to initial.
   */
  void resetState() {
    state = const AuthState.initial();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final client = ref.watch(apiClientProvider);
  return AuthNotifier(storage, client);
});


