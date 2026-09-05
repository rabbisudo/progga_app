import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/widgets/custom_back_button.dart';
import '../domain/user_notification_model.dart';
import 'notifications_notifier.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> with WidgetsBindingObserver {
  AuthorizationStatus _authStatus = AuthorizationStatus.notDetermined;
  bool _isLoadingStatus = true;

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
      ref.read(notificationsProvider.notifier).fetchNotifications(isRefresh: true);
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

  void _handleNotificationTap(UserNotificationModel item) async {
    // 1. Mark as read
    if (!item.isRead) {
      ref.read(notificationsProvider.notifier).markAsRead(item.id);
    }

    // 2. Action Route / URL handling
    if (item.actionUrl != null && item.actionUrl!.trim().isNotEmpty) {
      final url = item.actionUrl!.trim();
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        try {
          context.push(url);
        } catch (_) {
          // If route not found, default to home
          context.go('/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const brandTealColor = Color(0xFF086057);

    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

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
            fontFamily: 'Li Ador Noirrit',
          ),
        ),
        leading: CustomBackButton(
          color: isDark ? Colors.white : const Color(0xFF1A202C),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                ref.read(notificationsProvider.notifier).markAllAsRead();
              },
              child: const Text(
                'সব পঠিত',
                style: TextStyle(
                  color: brandTealColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  fontFamily: 'Li Ador Noirrit',
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: brandTealColor,
        onRefresh: () async {
          await ref.read(notificationsProvider.notifier).fetchNotifications(isRefresh: true);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // 1. Permission Warning Banner (if disabled)
            if (!_isLoadingStatus && hasNoPermission)
              SliverToBoxAdapter(
                child: Container(
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
                                fontFamily: 'Li Ador Noirrit',
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
                          onPressed: _requestNotificationPermission,
                          child: const Text(
                            'অন করুন',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Li Ador Noirrit',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 2. Real Notifications List
            notificationsAsync.when(
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildShimmerItem(isDark),
                    childCount: 4,
                  ),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'নোটিফিকেশন লোড করা সম্ভব হয়নি',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            fontFamily: 'Li Ador Noirrit',
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(notificationsProvider.notifier).fetchNotifications(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandTealColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'আবার চেষ্টা করুন',
                            style: TextStyle(fontFamily: 'Li Ador Noirrit'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (notifications) {
                if (notifications.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: brandTealColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                size: 48,
                                color: brandTealColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'আপাতত কোনো নোটিফিকেশন নেই',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                fontFamily: 'Li Ador Noirrit',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'নতুন কোনো পরীক্ষা, স্ট্রিক বা আপডেট আসলে এখানে দেখতে পাবেন।',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : Colors.grey.shade600,
                                fontFamily: 'Li Ador Noirrit',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = notifications[index];
                        final isRead = item.isRead;
                        final hasImage = item.imageUrl != null && item.imageUrl!.trim().isNotEmpty;

                        return GestureDetector(
                          onTap: () => _handleNotificationTap(item),
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
                                    ? (isRead
                                        ? Colors.white.withOpacity(0.05)
                                        : brandTealColor.withOpacity(0.25))
                                    : (isRead
                                        ? Colors.black.withOpacity(0.04)
                                        : brandTealColor.withOpacity(0.15)),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: item.accentColor.withOpacity(isDark ? 0.15 : 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        item.iconData,
                                        color: item.accentColor,
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
                                                  item.title,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        isRead ? FontWeight.w600 : FontWeight.bold,
                                                    color: isDark ? Colors.white : Colors.black87,
                                                    fontFamily: 'Li Ador Noirrit',
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
                                            item.body,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: isDark ? Colors.grey[400] : Colors.grey.shade700,
                                              height: 1.4,
                                              fontFamily: 'Li Ador Noirrit',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                item.formattedRelativeTime,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? Colors.white30 : Colors.grey.shade400,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: 'Li Ador Noirrit',
                                                ),
                                              ),
                                              if (item.actionUrl != null &&
                                                  item.actionUrl!.trim().isNotEmpty &&
                                                  item.actionUrl != '/home')
                                                Row(
                                                  children: [
                                                    Text(
                                                      'দেখুন',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: brandTealColor,
                                                        fontWeight: FontWeight.bold,
                                                        fontFamily: 'Li Ador Noirrit',
                                                      ),
                                                    ),
                                                    const SizedBox(width: 2),
                                                    const Icon(
                                                      Icons.arrow_forward_ios_rounded,
                                                      size: 10,
                                                      color: brandTealColor,
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (hasImage) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: item.imageUrl!,
                                      height: 140,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        height: 140,
                                        color: isDark ? Colors.black26 : Colors.grey.shade200,
                                        child: const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => const SizedBox.shrink(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: notifications.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerItem(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
