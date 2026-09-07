import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/widgets/custom_avatar.dart';
import '../../profile/presentation/profile_notifier.dart';
import '../../profile/presentation/profile_screen.dart';

// Local Widgets and Views
import 'widgets/premium_bottom_nav_bar.dart';
import 'widgets/shimmer_skeleton.dart';
import 'views/home_dashboard_view.dart';
import 'views/question_bank_view.dart';
import 'views/mock_exam_list_view.dart';

const String _streakFireSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="currentColor" d="M12.832 21.801c3.126-.626 7.168-2.875 7.168-8.69c0-5.291-3.873-8.815-6.658-10.434c-.619-.36-1.342.113-1.342.828v1.828c0 1.442-.606 4.074-2.29 5.169c-.86.559-1.79-.278-1.894-1.298l-.086-.838c-.1-.974-1.092-1.565-1.87-.971C4.461 8.46 3 10.33 3 13.11C3 20.221 8.289 22 10.933 22q.232 0 .484-.015C10.111 21.874 8 21.064 8 18.444c0-2.05 1.495-3.435 2.631-4.11c.306-.18.663.055.663.41v.59c0 .45.175 1.155.59 1.637c.47.546 1.159-.026 1.214-.744c.018-.226.246-.37.442-.256c.641.375 1.46 1.175 1.46 2.473c0 2.048-1.129 2.99-2.168 3.357" />
</svg>''';

String _getTimeOfDayGreeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) {
    return 'শুভ সকাল';
  } else if (hour >= 12 && hour < 15) {
    return 'শুভ দুপুর';
  } else if (hour >= 15 && hour < 18) {
    return 'শুভ বিকেল';
  } else {
    return 'শুভ সন্ধ্যা';
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


    // Redirect to onboarding if profile is loaded and user has not completed onboarding
    if (profileAsync.value != null && profileAsync.value!.id.isNotEmpty) {
      final userData = profileAsync.value!;
      if (userData.profile != null && (userData.profile!.className == null || userData.profile!.className!.isEmpty)) {
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
    final displayName = profile?.fullName.split(' ').first ?? '';
    final String greetingText = _getTimeOfDayGreeting();

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _currentNavIndex == 0
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              centerTitle: true,
              leadingWidth: 88,
              // Left: Balanced Sleek Streak Pill or Shimmer
              leading: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Center(
                  child: profile == null
                      ? const ShimmerSkeleton(width: 54, height: 28, borderRadius: 20)
                      : Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.push('/streak'),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                                    : const Color(0xFFE6FCF5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF0CA678).withValues(alpha: 0.4)
                                      : const Color(0xFF96F2D7),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.string(
                                    _streakFireSvg,
                                    width: 16,
                                    height: 16,
                                    colorFilter: ColorFilter.mode(
                                      isDark ? const Color(0xFF38D9A9) : const Color(0xFF086057),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _toBengaliDigits('${profile.currentStreak}'),
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF38D9A9) : const Color(0xFF086057),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      fontFamily: 'Li Ador Noirrit',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              // Center: Clean Bengali Greeting or Shimmer
              title: profile == null
                  ? const ShimmerSkeleton(width: 120, height: 18, borderRadius: 9)
                  : (displayName.isNotEmpty
                      ? Text(
                          '$greetingText, $displayName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Li Ador Noirrit',
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                            letterSpacing: 0.2,
                          ),
                        )
                      : const SizedBox.shrink()),
              // Right: Polished Avatar with symmetric 88px container width balance or Shimmer
              actions: [
                SizedBox(
                  width: 88,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: profile == null
                            ? const ShimmerSkeleton(width: 36, height: 36, borderRadius: 18)
                            : GestureDetector(
                                onTap: () => context.push('/profile'),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF0CA678).withValues(alpha: 0.5)
                                          : const Color(0xFF086057).withValues(alpha: 0.25),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isDark ? Colors.black : const Color(0xFF086057))
                                            .withValues(alpha: 0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: CustomAvatar(
                                    avatarUrl: profile.avatarKey,
                                    radius: 17,
                                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE6FCF5),
                                    fallbackWidget: const Text(
                                      '👨‍🎓',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
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
