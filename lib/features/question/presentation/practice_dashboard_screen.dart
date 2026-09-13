import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/widgets/custom_avatar.dart';
import '../../profile/presentation/profile_notifier.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../profile/presentation/notifications_notifier.dart';

// Local Widgets and Views
import 'widgets/premium_bottom_nav_bar.dart';
import 'widgets/shimmer_skeleton.dart';
import 'widgets/bouncing_card.dart';
import 'views/home_dashboard_view.dart';
import 'views/question_bank_view.dart';
import 'views/mock_exam_list_view.dart';

const String _streakFlameThemedSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24">
  <defs>
    <linearGradient id="themeFlameGrad" x1="0%" y1="100%" x2="0%" y2="0%">
      <stop offset="0%" stop-color="#0058B7"/>
      <stop offset="55%" stop-color="#0071F9"/>
      <stop offset="100%" stop-color="#38BDF8"/>
    </linearGradient>
    <linearGradient id="themeInnerGrad" x1="0%" y1="100%" x2="0%" y2="0%">
      <stop offset="0%" stop-color="#38BDF8"/>
      <stop offset="100%" stop-color="#BAE6FD"/>
    </linearGradient>
  </defs>
  <path fill="url(#themeFlameGrad)" d="M12.832 21.801c3.126-.626 7.168-2.875 7.168-8.69c0-5.291-3.873-8.815-6.658-10.434c-.619-.36-1.342.113-1.342.828v1.828c0 1.442-.606 4.074-2.29 5.169c-.86.559-1.79-.278-1.894-1.298l-.086-.838c-.1-.974-1.092-1.565-1.87-.971C4.461 8.46 3 10.33 3 13.11C3 20.221 8.289 22 10.933 22q.232 0 .484-.015C10.111 21.874 8 21.064 8 18.444c0-2.05 1.495-3.435 2.631-4.11c.306-.18.663.055.663.41v.59c0 .45.175 1.155.59 1.637c.47.546 1.159-.026 1.214-.744c.018-.226.246-.37.442-.256c.641.375 1.46 1.175 1.46 2.473c0 2.048-1.129 2.99-2.168 3.357" />
  <path fill="url(#themeInnerGrad)" d="M12.2 13.5c1.2 1.1 1.8 2.3 1.8 3.5 0 2-1.4 3.5-3 3.8.3-.7.5-1.5.5-2.3 0-1.5-.7-2.6-1.4-3.3.4-.1.8-.2 1.1-.2.4 0 .8.1 1 .5z" />
</svg>''';

String _getTimeOfDayGreeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) {
    return 'শুভ সকাল';
  } else if (hour >= 12 && hour < 15) {
    return 'শুভ দুপুর';
  } else if (hour >= 15 && hour < 18) {
    return 'শুভ বিকেল';
  } else if (hour >= 18 && hour < 22) {
    return 'শুভ সন্ধ্যা';
  } else {
    return 'শুভ রাত্রি';
  }
}

String _getGreetingEmoji() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) {
    return '🌅';
  } else if (hour >= 12 && hour < 15) {
    return '☀️';
  } else if (hour >= 15 && hour < 18) {
    return '🌇';
  } else if (hour >= 18 && hour < 22) {
    return '✨';
  } else {
    return '🌙';
  }
}

String _toBengaliDigits(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  String result = input;
  for (int i = 0; i < 10; i++) {
    result = result.replaceAll(english[i], bengali[i]);
  }
  return result;
}

class PracticeDashboardScreen extends ConsumerStatefulWidget {
  const PracticeDashboardScreen({super.key});

  @override
  ConsumerState<PracticeDashboardScreen> createState() => _PracticeDashboardScreenState();
}

class _PracticeDashboardScreenState extends ConsumerState<PracticeDashboardScreen> {
  int _currentNavIndex = 0;
  final Set<int> _activatedTabs = {0};

  @override
  void initState() {
    super.initState();
    // Non-blocking notification permission check after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermission();
    });
  }

  Future<void> _requestNotificationPermission() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;


    final unreadNotificationsCount = ref.watch(unreadNotificationsCountProvider);

    // Redirect to onboarding if profile is loaded and user has not completed onboarding
    if (profileAsync.value != null && profileAsync.value!.id.isNotEmpty) {
      final userData = profileAsync.value!;
      if (userData.profile == null || userData.profile!.className == null || userData.profile!.className!.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/onboarding');
        });
      }
    }

    // Lazy tab initialization: only instantiate and mount tabs that have been activated by user
    final List<Widget> views = [
      HomeDashboardView(
        onTabSelected: (idx) {
          setState(() {
            _currentNavIndex = idx;
            _activatedTabs.add(idx);
          });
        },
      ),
      _activatedTabs.contains(1) ? const QuestionBankView() : const SizedBox.shrink(),
      _activatedTabs.contains(2) ? const MockExamListView() : const SizedBox.shrink(),
      _activatedTabs.contains(3) ? const ProfileScreen() : const SizedBox.shrink(),
    ];

    // Greeting calculations for personalized header
    final profile = profileAsync.value?.profile;
    final displayName = profile?.fullName.trim().split(' ').first ?? '';
    final String greetingText = _getTimeOfDayGreeting();
    final String greetingEmoji = _getGreetingEmoji();

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _currentNavIndex == 0
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight: 64,
              titleSpacing: 16,
              title: Row(
                children: [
                  // Left: Avatar + Greeting & Name (Tappable to go to Profile)
                  Expanded(
                    child: profile == null
                        ? const Row(
                            children: [
                              ShimmerSkeleton(width: 42, height: 42, borderRadius: 21),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ShimmerSkeleton(width: 65, height: 12, borderRadius: 6),
                                  SizedBox(height: 5),
                                  ShimmerSkeleton(width: 95, height: 16, borderRadius: 6),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Avatar: Tappable to open Profile/Settings
                              BouncingCard(
                                onTap: () => context.push('/profile'),
                                scaleFactor: 0.94,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF0071F9).withValues(alpha: 0.5)
                                          : const Color(0xFF0071F9).withValues(alpha: 0.25),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isDark ? Colors.black : const Color(0xFF0071F9))
                                            .withValues(alpha: 0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: CustomAvatar(
                                    avatarUrl: profile.avatarKey,
                                    radius: 19,
                                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F1FF),
                                    fallbackWidget: const Text(
                                      '👨‍🎓',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Greeting & Display Name: Non-clickable static text
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          greetingText,
                                          style: TextStyle(
                                            fontFamily: 'Li Ador Noirrit',
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          greetingEmoji,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      displayName.isNotEmpty ? displayName : 'শিক্ষার্থী',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Li Ador Noirrit',
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 10),
                  // Right: Fiery Gradient Streak Pill + Notification Bell
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      profile == null
                          ? const ShimmerSkeleton(width: 58, height: 36, borderRadius: 18)
                          : BouncingCard(
                              onTap: () => context.push('/streak'),
                              scaleFactor: 0.95,
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(horizontal: 11),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isDark
                                        ? [
                                            theme.colorScheme.primary.withValues(alpha: 0.24),
                                            theme.colorScheme.primary.withValues(alpha: 0.12),
                                          ]
                                        : [
                                            const Color(0xFFF0F6FF),
                                            const Color(0xFFE2EFFF),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF38BDF8).withValues(alpha: 0.45)
                                        : theme.colorScheme.primary.withValues(alpha: 0.22),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isDark ? Colors.black : theme.colorScheme.primary)
                                          .withValues(alpha: isDark ? 0.3 : 0.10),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SvgPicture.string(
                                      _streakFlameThemedSvg,
                                      width: 18,
                                      height: 18,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _toBengaliDigits('${profile.currentStreak}'),
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFF38BDF8) : theme.colorScheme.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.5,
                                        fontFamily: 'Li Ador Noirrit',
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      const SizedBox(width: 8),
                      BouncingCard(
                        onTap: () => context.push('/notifications'),
                        scaleFactor: 0.95,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF8FAFC),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.notifications_outlined,
                                size: 19,
                                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                              ),
                              if (unreadNotificationsCount > 0)
                                Positioned(
                                  top: 7,
                                  right: 7,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : (_currentNavIndex == 3 || _currentNavIndex == 1
              ? null
              : AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  title: Text(
                    'মক পরীক্ষা',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                )),
      body: SafeArea(
        bottom: false,
        top: _currentNavIndex == 3 || _currentNavIndex == 1,
        child: IndexedStack(
          index: _currentNavIndex,
          children: views,
        ),
      ),
      bottomNavigationBar: PremiumBottomNavBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (index) {
          if (index == 3) {
            context.push('/profile');
          } else {
            setState(() {
              _currentNavIndex = index;
              _activatedTabs.add(index);
            });
          }
        },
      ),
    );
  }
}
