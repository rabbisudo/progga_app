import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/storage/hive_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/navigation/app_router.dart';
import 'core/network/api_client.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/auth/presentation/auth_notifier.dart';
import 'core/widgets/empty_state_widget.dart';
import 'features/profile/presentation/profile_notifier.dart';
import 'features/leaderboard/presentation/leaderboard_notifier.dart';
import 'features/academics/data/academics_repository.dart';
import 'package:dio/dio.dart';
import 'core/services/notification_service.dart';
import 'app.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Configure optimized memory-efficient image cache (64MB / 500 images) to keep RAM low without re-decoding lag
  PaintingBinding.instance.imageCache.maximumSizeBytes = 64 << 20; // 64 MB
  PaintingBinding.instance.imageCache.maximumSize = 500;

  // Keep native splash screen visible while background async initialization runs
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final hiveService = HiveService();
  final secureStorage = SecureStorageService(const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  ));

  String initialLocation = '/login';
  AuthState initialAuthState = const AuthState.initial();

  // Fast parallel local initialization: Concurrent Hive settings box & SecureStorage token lookup
  try {
    final results = await Future.wait([
      hiveService.init(settingsOnly: true),
      secureStorage.getAccessToken(),
    ]).timeout(
      const Duration(milliseconds: 2500),
      onTimeout: () => [null, null],
    );

    // Hard guarantee: Ensure settingsBox is OPEN before runApp is invoked, even if timeout fired
    if (!hiveService.isSettingsBoxOpen) {
      await hiveService.ensureSettingsBoxOpen();
    }

    final token = results[1] as String?;

    if (token != null && token.isNotEmpty) {
      initialLocation = '/home';

      try {
        // Check if user profile is already cached locally (instant read, <1ms)
        if (hiveService.isSettingsBoxOpen) {
          final cachedProfile = hiveService.getSettingsBox().get('cached_user_profile');
          if (cachedProfile != null && cachedProfile is Map) {
            initialAuthState = AuthState.authenticated(
              user: recursivelyCastMap(cachedProfile),
              accessToken: token,
            );
          } else {
            // Cache empty: authenticate with token immediately, background profile repository will fetch fresh data
            initialAuthState = AuthState.authenticated(
              user: const {},
              accessToken: token,
            );
          }
        }
      } catch (_) {
        initialAuthState = AuthState.authenticated(
          user: const {},
          accessToken: token,
        );
      }
    }
  } catch (_) {
    // Suppress initialization error in release
  } finally {
    // Ultimate failsafe: Ensure settingsBox is open before root providers mount
    if (!hiveService.isSettingsBoxOpen) {
      await hiveService.ensureSettingsBoxOpen();
    }

    // Custom ErrorWidget.builder to intercept unhandled exceptions with guaranteed Directionality
    ErrorWidget.builder = (FlutterErrorDetails details) {
      try {
        FlutterNativeSplash.remove();
      } catch (_) {}
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SafeErrorWidget(details: details),
      );
    };

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

    // Remove splash screen immediately once the first UI frame renders & start deferred services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        FlutterNativeSplash.remove();
      } catch (_) {}

      // Deferred background warmup: does not compete with first frame render
      _initDeferredServices(hiveService, secureStorage);
    });
  }
}

/// Initializes non-critical background services after the first frame has rendered
void _initDeferredServices(HiveService hiveService, SecureStorageService secureStorage) {
  // 1. Warm up offline practice box in background without blocking UI
  hiveService.initPracticeBox().catchError((_) {});

  // 2. Initialize Firebase and notification service asynchronously in background
  Firebase.initializeApp().then((_) async {
    await NotificationService().init();
    final token = await secureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      final dio = Dio();
      final apiClient = ApiClient(dio)..init(secureStorage);
      NotificationService().syncDeviceToken(apiClient, secureStorage).catchError((_) {});
    }
  }).catchError((_) {});
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

class SafeErrorWidget extends StatefulWidget {
  final FlutterErrorDetails details;
  const SafeErrorWidget({super.key, required this.details});

  @override
  State<SafeErrorWidget> createState() => _SafeErrorWidgetState();
}

class _SafeErrorWidgetState extends State<SafeErrorWidget> {
  @override
  void initState() {
    super.initState();
    try {
      FlutterNativeSplash.remove();
    } catch (_) {}
  }
  @override
  Widget build(BuildContext context) {
    final exception = widget.details.exception;
    final isNetwork = exception is NetworkException || 
                      exception.toString().contains('NetworkException') ||
                      exception.toString().contains('DioException') ||
                      exception.toString().contains('SocketException') ||
                      exception.toString().contains('timeout') ||
                      exception.toString().contains('Connection failed') ||
                      exception.toString().contains('Network connection failed');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F6F5),
      body: SafeArea(
        child: EmptyStateWidget(
          title: isNetwork ? 'নেটওয়ার্ক সংযোগ নেই' : 'একটি ত্রুটি ঘটেছে',
          subtitle: isNetwork 
              ? 'অনুগ্রহ করে আপনার ইন্টারনেট সংযোগটি পরীক্ষা করে আবার চেষ্টা করুন।'
              : 'অ্যাপ্লিকেশনটিতে একটি সমস্যা হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
          icon: isNetwork ? Icons.wifi_off_rounded : Icons.bug_report_rounded,
          onRetry: () {
            try {
              final container = ProviderScope.containerOf(context);
              container.invalidate(userProfileProvider);
              container.invalidate(myLeaderboardProvider);
              container.invalidate(studentCurriculumProvider);
              container.invalidate(studentQbCurriculumProvider);
            } catch (_) {
              // Fallback
            }
            setState(() {});
          },
        ),
      ),
    );
  }
}
