import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'core/storage/hive_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/navigation/app_router.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/auth/presentation/auth_notifier.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Defer first frame to keep native splash screen visible while initializing
  WidgetsBinding.instance.deferFirstFrame();

  final hiveService = HiveService();
  final secureStorage = SecureStorageService(const FlutterSecureStorage());

  // Initialize Firebase, Hive, and check the active session in parallel
  String initialLocation = '/login';
  AuthState initialAuthState = const AuthState.initial();
  
  // Initialize Hive first to ensure the settings box is available for cached reads
  final hiveInitFuture = hiveService.init();

  await Future.wait([
    Future(() async {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        debugPrint('Firebase init error: $e');
      }
    }),
    hiveInitFuture,
    Future(() async {
      try {
        final token = await secureStorage.getAccessToken();
        if (token != null) {
          initialLocation = '/home';
          
          // Wait for Hive box to finish opening
          await hiveInitFuture;

          // Check if user profile is already cached locally (instant read, <1ms)
          final cachedProfile = hiveService.getSettingsBox().get('cached_user_profile');
          if (cachedProfile != null && cachedProfile is Map) {
            initialAuthState = AuthState.authenticated(
              user: recursivelyCastMap(cachedProfile),
              accessToken: token,
            );
          } else {
            // First time run after login (cache empty), fallback to fast background API fetch
            initialAuthState = AuthState.authenticated(user: const {}, accessToken: token);
            try {
              final dio = Dio(BaseOptions(
                baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://192.168.31.101:3000/api/v1'),
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 4),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ));
              final response = await dio.get('/users/me');
              if (response.statusCode == 200) {
                initialAuthState = AuthState.authenticated(user: response.data, accessToken: token);
                hiveService.getSettingsBox().put('cached_user_profile', response.data);
              }
            } catch (e) {
              debugPrint('API fetch profile error: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('Session check error: $e');
      }
    }),
  ]);

  runApp(
    ProviderScope(
      overrides: [
        hiveServiceProvider.overrideWithValue(hiveService),
        initialLocationProvider.overrideWithValue(initialLocation),
        authInitialStateProvider.overrideWithValue(initialAuthState),
      ],
      child: const ProggaApp(),
    ),
  );

  // Allow first frame to draw the resolved starting screen background cleanly
  WidgetsBinding.instance.allowFirstFrame();
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
