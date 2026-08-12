import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_jailbreak_detection_plus/flutter_jailbreak_detection_plus.dart';
import 'package:safe_device/safe_device.dart';
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

  // Run security checks (Root, Jailbreak, Emulator)
  bool isDeviceSecure = true;
  try {
    final jailbroken = await FlutterJailbreakDetectionPlus.jailbroken;
    final isRealDevice = await SafeDevice.isRealDevice;
    final isMockLocation = await SafeDevice.isMockLocation;

    if (kReleaseMode) {
      if (jailbroken || !isRealDevice || isMockLocation) {
        isDeviceSecure = false;
      }
    }
  } catch (e) {
    debugPrint('Security environments check warning: $e');
  }
  
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
      SecurityConfig.isDeviceSecure = isDeviceSecure;
      try {
        final token = await secureStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
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
                baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://proggadata.twelvemind.com/api/v1'),
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 4),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ));
              configureDioSslPinning(dio);
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

  // Custom ErrorWidget.builder to intercept unhandled exceptions (like NetworkExceptions during layout/build)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return SafeErrorWidget(details: details);
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

class SafeErrorWidget extends StatefulWidget {
  final FlutterErrorDetails details;
  const SafeErrorWidget({Key? key, required this.details}) : super(key: key);

  @override
  State<SafeErrorWidget> createState() => _SafeErrorWidgetState();
}

class _SafeErrorWidgetState extends State<SafeErrorWidget> {
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
