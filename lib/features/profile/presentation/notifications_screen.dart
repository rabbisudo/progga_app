import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/widgets/custom_back_button.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> with WidgetsBindingObserver {
  AuthorizationStatus _authStatus = AuthorizationStatus.notDetermined;
  bool _isLoadingStatus = true;

  // Mock notifications list
  final List<Map<String, dynamic>> _mockNotifications = [
    {
      'title': 'আজকের দৈনিক পরীক্ষা প্রস্তুত! 📝',
      'body': 'আপনার আজকের সিলেবাস অনুযায়ী দৈনিক পরীক্ষা শুরু করুন এবং নিজেকে ঝালিয়ে নিন।',
      'time': '১০ মিনিট আগে',
      'icon': Icons.assignment_outlined,
      'color': Color(0xFF086057),
      'isRead': false,
    },
    {
      'title': 'নতুন রসায়ন মডেল টেস্ট যুক্ত হয়েছে 🚀',
      'body': 'এইচএসসি ২০২৬ পরীক্ষার্থীদের জন্য বিশেষ রসায়ন মডেল টেস্ট ১ যুক্ত করা হয়েছে। অংশ নিন এখনই!',
      'time': '২ ঘণ্টা আগে',
      'icon': Icons.science_outlined,
      'color': Color(0xFFFF9F0A),
      'isRead': false,
    },
    {
      'title': 'সাপ্তাহিক লিডারবোর্ড আপডেট 🏆',
      'body': 'অভিনন্দন! গত সপ্তাহে আপনি শীর্ষ ১০% শিক্ষার্থীর মধ্যে স্থান পেয়েছেন। আপনার লিডারবোর্ড স্কোর দেখুন।',
      'time': '১ দিন আগে',
      'icon': Icons.emoji_events_outlined,
      'color': Color(0xFFFFD700),
      'isRead': true,
    },
    {
      'title': 'স্ট্রিক বিরতি সতর্কবার্তা ⚡',
      'body': 'আপনার ৬ দিনের স্ট্রিক ভেঙে যেতে পারে! আজকের পড়া সম্পন্ন করতে অন্তত একটি প্রশ্নের উত্তর দিন।',
      'time': '২ দিন আগে',
      'icon': Icons.local_fire_department_outlined,
      'color': Color(0xFFFF3B30),
      'isRead': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkNotificationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNotificationPermission();
    }
  }

  Future<void> _checkNotificationPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      if (mounted) {
        setState(() {
          _authStatus = settings.authorizationStatus;
          _isLoadingStatus = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      if (mounted) {
        setState(() {
          _authStatus = settings.authorizationStatus;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const brandTealColor = Color(0xFF086057);

    // Permission is not granted if it is denied or notDetermined
    final isPermissionDenied = _authStatus == AuthorizationStatus.denied;
    final isPermissionNotRequested = _authStatus == AuthorizationStatus.notDetermined;
    final hasNoPermission = isPermissionDenied || isPermissionNotRequested;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'নোটিফিকেশন',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1A202C),
            fontWeight: FontWeight.bold,
            fontSize: 17,
            fontFamily: 'Noto Sans Bengali',
          ),
        ),
        leading: CustomBackButton(
          color: isDark ? Colors.white : const Color(0xFF1A202C),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Permission Warning Banner
          if (!_isLoadingStatus && hasNoPermission)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C1C1C) : const Color(0xFFFFEAEA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF5E2B2B) : const Color(0xFFFFC0C0),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isPermissionDenied
                              ? 'আপনার অ্যাপের নোটিফিকেশন পারমিশন বন্ধ রয়েছে! প্র্যাকটিস আপডেট ও স্ট্রিক অ্যালার্ট পেতে নোটিফিকেশন অন করুন।'
                              : 'নোটিফিকেশন পারমিশন দেওয়া নেই। নতুন আপডেট এবং গুরুত্বপূর্ণ নোটিশ মিস না করতে নোটিফিকেশন অন করুন।',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87,
                            height: 1.4,
                            fontFamily: 'Noto Sans Bengali',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isPermissionNotRequested ? _requestNotificationPermission : _requestNotificationPermission, 
                      child: const Text(
                        'অন করুন',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Noto Sans Bengali',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 2. Notifications List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _mockNotifications.length,
              itemBuilder: (context, index) {
                final item = _mockNotifications[index];
                final isRead = item['isRead'] as bool;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _mockNotifications[index]['isRead'] = true;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? (isRead ? const Color(0xFF1E1E1E) : const Color(0xFF262A29))
                          : (isRead ? Colors.white : const Color(0xFFEAF5F2)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? (isRead ? Colors.white.withOpacity(0.05) : brandTealColor.withOpacity(0.2))
                            : (isRead ? Colors.black.withOpacity(0.04) : brandTealColor.withOpacity(0.12)),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withOpacity(isDark ? 0.15 : 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: item['color'] as Color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['title'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontFamily: 'Noto Sans Bengali',
                                      ),
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8, top: 4),
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: brandTealColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['body'] as String,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark ? Colors.grey[400] : Colors.grey.shade700,
                                  height: 1.4,
                                  fontFamily: 'Noto Sans Bengali',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['time'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white30 : Colors.grey.shade400,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Noto Sans Bengali',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
