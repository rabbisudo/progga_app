import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (_) {}

    // Request permissions for Firebase Messaging asynchronously (non-blocking)
    requestPermissions().catchError((_) {});

    // Listen to incoming foreground messages
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // Foreground message handling
      });
    } catch (_) {}

    _isInitialized = true;
  }

  bool isRealFcmToken(String? token) {
    if (token == null) return false;
    final trimmed = token.trim();
    if (trimmed.length < 50) return false;
    if (trimmed.contains(' ') || trimmed.contains('dummy') || trimmed.contains('test')) return false;
    final isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(trimmed);
    return !isUuid;
  }

  Future<String?> getValidToken() async {
    try {
      if (Platform.isIOS) {
        String? apns = await FirebaseMessaging.instance.getAPNSToken();
        int retries = 0;
        while (apns == null && retries < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          apns = await FirebaseMessaging.instance.getAPNSToken();
          retries++;
        }
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (isRealFcmToken(token)) {
        return token!.trim();
      }
    } catch (_) {}
    return null;
  }

  Future<void> syncDeviceToken(ApiClient apiClient, SecureStorageService storageService) async {
    try {
      final token = await getValidToken();
      if (token != null) {
        final deviceUuid = await storageService.getOrGenerateDeviceUuid();
        final deviceOs = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
        await apiClient.dio.post('/notifications/register-device', data: {
          'deviceToken': token,
          'deviceUuid': deviceUuid,
          'deviceOs': deviceOs,
        });
      }
    } catch (_) {}

    // Automatically sync on token rotation
    try {
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          if (isRealFcmToken(newToken)) {
            final deviceUuid = await storageService.getOrGenerateDeviceUuid();
            final deviceOs = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
            await apiClient.dio.post('/notifications/register-device', data: {
              'deviceToken': newToken.trim(),
              'deviceUuid': deviceUuid,
              'deviceOs': deviceOs,
            });
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  Future<void> requestPermissions() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (_) {}
  }

  Future<void> scheduleStreakReminder() async {
    // Handled via backend FCM cron jobs
  }

  Future<void> cancelStreakReminder() async {
    // Handled via backend FCM cron jobs
  }
}
