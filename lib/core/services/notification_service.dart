import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  // Bengali streak reminder copy list
  final List<Map<String, String>> _streakTemplates = [
    {
      'title': 'আপনার স্ট্রিক ভেঙে যাচ্ছে! 😱',
      'body': 'আজ আর মাত্র ৪ ঘণ্টা বাকি! আপনার স্ট্রিকটি বাঁচাতে এখনই একটি কুইজ দিন।',
    },
    {
      'title': 'স্ট্রিকের আগুন নিভে গেল বলে! 🔥',
      'body': 'আপনার ফোনের ফায়ার সার্ভিসও কিন্তু এই স্ট্রিকের আগুন বাঁচাতে পারবে না! ১ মিনিটের কুইজ খেলে নিভতে দিন না।',
    },
    {
      'title': 'একদিনে সাফল্য আসে না, কিন্তু আজকের দিনটি গুরুত্বপূর্ণ! 📈',
      'body': 'আর মাত্র ১টি পরীক্ষার দূরত্বে আপনার সেরা রেকর্ড! আজকের প্র্যাকটিস সম্পূর্ণ করুন।',
    },
    {
      'title': 'কয়েন এবং এক্সপি হাতছাড়া করবেন না! 🪙',
      'body': 'আজকের পরীক্ষা না দিলে বোনাস কয়েন ও স্ট্রিক হারাবেন। জলদি অ্যাপে আসুন!',
    },
    {
      'title': 'প্রজ্ঞা আপনাকে মিস করছে... 🥺',
      'body': 'একটু সময় বের করে মাত্র ৫টি প্রশ্নের উত্তর দিন, আপনার স্ট্রিক সুরক্ষিত করুন।',
    },
  ];

  Future<void> scheduleStreakReminder() async {
    try {
      // 1. Cancel previous pending streak reminders (using a fixed ID, e.g., 999)
      await flutterLocalNotificationsPlugin.cancel(999);

      // 2. Select a random template
      final random = Random();
      final template = _streakTemplates[random.nextInt(_streakTemplates.length)];

      // 3. Set the schedule time to 20 hours from now (to notify in the evening, e.g., 8:00 PM if they haven't done it)
      final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(hours: 20));

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'streak_reminder_channel',
        'Streak Reminders',
        channelDescription: 'Notifications to remind users to save their study streak',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        999,
        template['title'],
        template['body'],
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }
  
  Future<void> cancelStreakReminder() async {
    try {
      await flutterLocalNotificationsPlugin.cancel(999);
    } catch (_) {}
  }
}
