import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  await Future.wait([
    Future(() async {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        debugPrint('Firebase init error: $e');
      }
    }),
    hiveService.init(),
    Future(() async {
      try {
        final token = await secureStorage.getAccessToken();
        if (token != null) {
          initialLocation = '/home';
          initialAuthState = AuthState.authenticated(user: const {}, accessToken: token);
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
