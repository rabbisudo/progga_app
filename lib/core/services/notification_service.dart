import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  if (kDebugMode) {
    debugPrint('FCM background message received: ${message.messageId}');
  }
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

    // Request permissions for Firebase Messaging (critical for iOS & Android 13+)
    await requestPermissions();

    // Listen to incoming foreground messages
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint('Handling a foreground message: ${message.messageId}');
          debugPrint('Notification title: ${message.notification?.title}');
          debugPrint('Notification body: ${message.notification?.body}');
        }
      });
    } catch (_) {}

    _isInitialized = true;
  }

  Future<void> syncDeviceToken(ApiClient apiClient, SecureStorageService storageService) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        final deviceUuid = await storageService.getOrGenerateDeviceUuid();
        final deviceOs = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
        await apiClient.dio.post('/notifications/register-device', data: {
          'deviceToken': token,
          'deviceUuid': deviceUuid,
          'deviceOs': deviceOs,
        });
        if (kDebugMode) {
          debugPrint('Successfully synced FCM device token with backend.');
        }
      }
    } catch (_) {}

    // Automatically sync on token rotation
    try {
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          final deviceUuid = await storageService.getOrGenerateDeviceUuid();
          final deviceOs = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
          await apiClient.dio.post('/notifications/register-device', data: {
            'deviceToken': newToken,
            'deviceUuid': deviceUuid,
            'deviceOs': deviceOs,
          });
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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notification permission error: $e');
      }
    }
  }

  Future<void> scheduleStreakReminder() async {
    // Handled via backend FCM cron jobs
  }

  Future<void> cancelStreakReminder() async {
    // Handled via backend FCM cron jobs
  }
}
