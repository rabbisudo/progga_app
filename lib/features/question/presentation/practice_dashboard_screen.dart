import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/custom_avatar.dart';
import '../../profile/presentation/profile_notifier.dart';
import '../../profile/presentation/profile_screen.dart';

// Local Widgets and Views
import 'widgets/premium_bottom_nav_bar.dart';
import 'widgets/micro_animations.dart';
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

  // Question Bank Navigation State
  List<String> _selectedSeriesStack = [];
  String? _activeExamTab;
  String _examSearchQuery = '';

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (profileAsync.isLoading && profileAsync.value == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF017A47)),
        ),
      );
    }

    if (profileAsync is AsyncError) {
      final error = profileAsync.error;
      if (error is NetworkException && error.statusCode == 401) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/login');
        });
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: const Center(
            child: CircularProgressIndicator(color: Color(0xFF017A47)),
          ),
        );
      }
    }

    // Redirect to onboarding if not set up yet
    if (profileAsync.value != null) {
      final userData = profileAsync.value!;
      if (userData.profile?.className == null || userData.profile!.className!.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/onboarding');
        });
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: const Center(
            child: CircularProgressIndicator(color: Color(0xFF017A47)),
          ),
        );
      }
    }

    // List of page view bodies matching each bottom navigation index
    final List<Widget> views = [
      HomeDashboardView(
        onTabSelected: (idx) {
          setState(() {
            _currentNavIndex = idx;
            if (idx != 1) {
              _selectedSeriesStack.clear();
              _activeExamTab = null;
              _examSearchQuery = '';
            }
          });
        },
      ),
      QuestionBankView(
        seriesStack: _selectedSeriesStack,
        onStackChanged: (stack) {
          setState(() {
            _selectedSeriesStack = stack;
          });
        },
        activeExamTab: _activeExamTab,
        onActiveExamTabChanged: (tab) {
          setState(() {
            _activeExamTab = tab;
          });
        },
        examSearchQuery: _examSearchQuery,
        onExamSearchQueryChanged: (query) {
          setState(() {
            _examSearchQuery = query;
          });
        },
      ),
      const MockExamListView(),
      const ProfileScreen(),
    ];

    // Greeting calculations for personalized header
    final profile = profileAsync.value?.profile;
    final displayName = profile?.fullName.split(' ').first ?? '';
    final String greetingText = _getTimeOfDayGreeting();

    final isQbStackNotEmpty = _currentNavIndex == 1 && _selectedSeriesStack.isNotEmpty;

    return PopScope(
      canPop: _currentNavIndex != 1 || _selectedSeriesStack.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentNavIndex == 1 && _selectedSeriesStack.isNotEmpty) {
          setState(() {
            _selectedSeriesStack.removeLast();
            _examSearchQuery = '';
          });
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _currentNavIndex == 0
            ? AppBar(
                backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                leadingWidth: 100,
                // Redesigned premium streak fire widget
                leading: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: InkWell(
                      onTap: () => context.push('/streak'),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF017A47).withOpacity(0.15) : const Color(0xFFE0ECE6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF017A47).withOpacity(0.3) : const Color(0xFFB9D8C9),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PulseWidget(
                              child: SvgPicture.string(
                                _streakFireSvg,
                                width: 20,
                                height: 20,
                                colorFilter: const ColorFilter.mode(Color(0xFF017A47), BlendMode.srcIn),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              profileAsync.maybeWhen(
                                data: (user) => _toBengaliDigits('${user.profile?.currentStreak ?? 1}'),
                                orElse: () => '১',
                              ),
                              style: const TextStyle(
                                color: Color(0xFF017A47),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                title: displayName.isNotEmpty
                    ? Text(
                        '$greetingText, $displayName',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      )
                    : const SizedBox.shrink(),
                // Right: Profile Avatar with a glowing ring outline
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        context.push('/profile');
                      },
                      child: Hero(
                        tag: 'user_avatar_hero',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF017A47),
                              width: 2,
                            ),
                          ),
                          child: CustomAvatar(
                            avatarUrl: profileAsync.value?.profile?.avatarKey,
                            radius: 17,
                            backgroundColor: const Color(0xFF017A47),
                            fallbackWidget: const Text(
                              '👨‍🎓',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : ((_currentNavIndex == 3 || isQbStackNotEmpty)
                ? null
                : AppBar(
                    backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    surfaceTintColor: Colors.transparent,
                    title: Text(
                      _currentNavIndex == 1 ? 'প্রশ্নব্যাংক' : 'মক পরীক্ষা',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    centerTitle: true,
                  )),
        body: SafeArea(
          top: isQbStackNotEmpty || _currentNavIndex == 3,
          bottom: isQbStackNotEmpty,
          child: IndexedStack(
            index: _currentNavIndex,
            children: views,
          ),
        ),
        bottomNavigationBar: isQbStackNotEmpty
            ? null
            : PremiumBottomNavBar(
                selectedIndex: _currentNavIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _currentNavIndex = index;
                    if (index != 1) {
                      _selectedSeriesStack.clear();
                      _activeExamTab = null;
                      _examSearchQuery = '';
                    }
                  });
                },
              ),
      ),
    );
  }
}
