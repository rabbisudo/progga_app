import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fl_chart/fl_chart.dart';
import 'practice_notifier.dart';
import 'package:go_router/go_router.dart';
import '../../profile/presentation/profile_notifier.dart';
import '../../profile/domain/profile_model.dart';
import '../../leaderboard/presentation/leaderboard_notifier.dart';
import '../../leaderboard/domain/leaderboard_model.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../academics/data/academics_repository.dart';

final activeBannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.dio.get('/banners');
    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> list = response.data;
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
  } catch (_) {}
  return [];
});

class PracticeDashboardScreen extends ConsumerStatefulWidget {
  const PracticeDashboardScreen({super.key});

  @override
  ConsumerState<PracticeDashboardScreen> createState() => _PracticeDashboardScreenState();
}

class _PracticeDashboardScreenState extends ConsumerState<PracticeDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(practiceProvider.notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(practiceProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final leaderboardAsync = ref.watch(myLeaderboardProvider);
    final bannersAsync = ref.watch(activeBannersProvider);


    // Graceful auto-logout & redirect on 401 Unauthorized exceptions without red screen crash
    if (profileAsync is AsyncError) {
      final error = profileAsync.error;
      if (error is NetworkException && error.statusCode == 401) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(userProfileProvider);
          ref.read(authProvider.notifier).logout();
          context.go('/login');
        });
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF017A47)),
          ),
        );
      }
    }

    if (leaderboardAsync is AsyncError) {
      final error = leaderboardAsync.error;
      if (error is NetworkException && error.statusCode == 401) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(userProfileProvider);
          ref.read(authProvider.notifier).logout();
          context.go('/login');
        });
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF017A47)),
          ),
        );
      }
    }

    ref.listen<AsyncValue<UserData>>(userProfileProvider, (previous, next) {
      if (next.hasError) {
        final error = next.error;
        if (error is NetworkException && error.statusCode == 401) {
          ref.invalidate(userProfileProvider);
          ref.read(authProvider.notifier).logout();
          context.go('/login');
        }
      }
    });

    // Redirect to onboarding if not set up yet
    if (profileAsync.value != null) {
      final userData = profileAsync.value!;
      if (userData.profile?.className == null || userData.profile!.className!.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/onboarding');
        });
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF017A47)),
          ),
        );
      }
    }

    final theme = Theme.of(context);

    // List of page view bodies matching each bottom navigation index
    final List<Widget> views = [
      _buildHomeDashboardView(state, theme, profileAsync, leaderboardAsync),
      _buildQuestionBankView(theme),
      _buildExamListView(theme),
      LeaderboardScreen(),
      _buildProgressView(theme),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _currentNavIndex == 0
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              leadingWidth: 90,
              // Left: Streak counter widget showing 🔥 ১ matching the screenshot
              leading: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0ECE6), // Light theme green tint of rgb(1, 122, 71)
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFB9D8C9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          profileAsync.maybeWhen(
                            data: (user) => '${user.profile?.currentStreak ?? 1}',
                            orElse: () => '১',
                          ),
                          style: const TextStyle(
                            color: Color(0xFF017A47),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: const SizedBox.shrink(),
              // Right: Circular profile avatar image
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      context.push('/profile');
                    },
                    child: profileAsync.value != null
                        ? CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFF18881),
                            backgroundImage: (profileAsync.value?.profile?.avatarKey != null &&
                                    profileAsync.value!.profile!.avatarKey!.isNotEmpty)
                                ? NetworkImage(profileAsync.value!.profile!.avatarKey!)
                                : null,
                            child: (profileAsync.value?.profile?.avatarKey != null &&
                                    profileAsync.value!.profile!.avatarKey!.isNotEmpty)
                                ? null
                                : const Text(
                                    '👨‍🎓',
                                    style: TextStyle(fontSize: 18),
                                  ),
                          )
                        : const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFF673AB7),
                            child: Icon(Icons.person, color: Colors.white, size: 16),
                          ),
                  ),
                ),
              ],
            )
          : (_currentNavIndex == 3
              ? null
              : AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  title: Text(
                    _currentNavIndex == 1
                        ? 'প্রশ্নব্যাংক'
                        : _currentNavIndex == 2
                            ? 'মক পরীক্ষা'
                            : 'প্রোগ্রেস',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                )),
      body: IndexedStack(
        index: _currentNavIndex,
        children: views,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE0ECE6), // Light theme green tint capsule
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF017A47),
              );
            }
            return const TextStyle(
              fontSize: 12,
              color: Color(0xFF495057),
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentNavIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentNavIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Color(0xFF495057)),
              selectedIcon: Icon(Icons.home, color: Color(0xFF017A47)),
              label: 'হোম',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined, color: Color(0xFF495057)),
              selectedIcon: Icon(Icons.inventory_2, color: Color(0xFF017A47)),
              label: 'প্রশ্নব্যাংক',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_outlined, color: Color(0xFF495057)),
              selectedIcon: Icon(Icons.edit, color: Color(0xFF017A47)),
              label: 'পরীক্ষা',
            ),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined, color: Color(0xFF495057)),
              selectedIcon: Icon(Icons.emoji_events, color: Color(0xFF017A47)),
              label: 'লিডারবোর্ড',
            ),
            NavigationDestination(
              icon: Icon(Icons.speed_outlined, color: Color(0xFF495057)),
              selectedIcon: Icon(Icons.speed, color: Color(0xFF017A47)),
              label: 'প্রোগ্রেস',
            ),
          ],
        ),
      ),
    );
  }

  // View 0: Home Dashboard matching the new screenshot
  Widget _buildHomeDashboardView(state, ThemeData theme, profileAsync, leaderboardAsync) {
    final profile = profileAsync.value?.profile;
    final myUserId = profileAsync.value?.id;
    final bannersAsync = ref.watch(activeBannersProvider);


    // Read league name dynamically from active user's entry in the leaderboard list if found
    String leagueName = 'আয়রন লীগ';
    int currentXp = profile?.xp ?? 0;
    if (leaderboardAsync.value != null && myUserId != null) {
      final myEntry = leaderboardAsync.value!.firstWhere(
        (e) => e.userId == myUserId,
        orElse: () => LeaderboardEntryModel(
          rank: 0,
          userId: '',
          username: '',
          fullName: '',
          xp: currentXp,
          level: profile?.level ?? 1,
          solvedQuestionsCount: 0,
          league: 'IRON',
        ),
      );
      if (myEntry.xp > 0) currentXp = myEntry.xp;
    }

    if (currentXp >= 5000) {
      leagueName = 'ইনফিনিটি লীগ';
    } else if (currentXp >= 3000) {
      leagueName = 'ডায়মন্ড লীগ';
    } else if (currentXp >= 1500) {
      leagueName = 'গোল্ড লীগ';
    } else if (currentXp >= 800) {
      leagueName = 'সিলভার লীগ';
    } else if (currentXp >= 300) {
      leagueName = 'ব্রোঞ্জ লীগ';
    } else {
      leagueName = 'আয়রন লীগ';
    }

    final userName = profile?.fullName ?? 'Rabbi failure';
    final userScore = profile?.xp ?? 3981;
    final starPoints = profile != null ? (profile.xp % 100) : 0;
    final progressVal = profile != null ? (profile.xp % 100) / 100.0 : 0.0;
    return RefreshIndicator(
      color: const Color(0xFF017A47),
      onRefresh: () async {
        ref.invalidate(userProfileProvider);
        ref.invalidate(myLeaderboardProvider);
        ref.invalidate(activeBannersProvider);
        try {
          await ref.read(userProfileProvider.future);
        } catch (_) {}
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // 1. Promo Banners Carousel Slider
          bannersAsync.when(
            data: (banners) => banners.isNotEmpty
                ? BannerSliderWidget(banners: banners)
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // 2. Clean Action Grid Buttons Row of 4 items (Icon + Label)

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                _buildGridAction(
                  iconWidget: _buildImageIconAsset('assets/icons/qsbank.png', Icons.inventory_2_outlined),
                  label: 'প্রশ্নব্যাংক',
                  onTap: () => setState(() => _currentNavIndex = 1),
                ),
                _buildGridAction(
                  iconWidget: _buildImageIconAsset('assets/icons/exam.png', Icons.edit_note_outlined),
                  label: 'মক পরীক্ষা',
                  onTap: () => setState(() => _currentNavIndex = 2),
                ),
                _buildGridAction(
                  iconWidget: _buildImageIconAsset('assets/icons/report.png', Icons.bar_chart_outlined),
                  label: 'রিপোর্ট',
                  onTap: () => setState(() => _currentNavIndex = 3),
                ),
                _buildGridAction(
                  iconWidget: _buildImageIconAsset('assets/icons/ai.png', Icons.psychology_outlined),
                  label: 'Progga AI',
                  onTap: () {},
                ),
              ],
            ),
          ),

          // 3. Active Leaderboard Section matching the new screenshot
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFECEFF1), width: 1.2),
              ),
              child: Column(
                children: [
                  // Leaderboard header title row
                  InkWell(
                    onTap: () => context.push('/leaderboard'),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'লিডারবোর্ড',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF017A47).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  leagueName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF017A47),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text(
                                'সবগুলো দেখুন',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF017A47),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF017A47)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Star progress track bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFECEFF1)),
                      ),
                      child: Row(
                        children: [
                          Text('$starPoints XP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF017A47))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progressVal,
                                minHeight: 6,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  // Leaderboard list items loaded from API
                  if (leaderboardAsync is AsyncLoading && (leaderboardAsync.value == null || leaderboardAsync.value!.isEmpty)) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF017A47))),
                    ),
                  ] else if (leaderboardAsync is AsyncError || leaderboardAsync.value == null) ...[
                    _buildLeaderboardRow(
                      name: userName,
                      score: userScore,
                      avatarText: '😎',
                      avatarBg: const Color(0xFF81C784),
                      isCurrentUser: true,
                    ),
                  ] else ...[
                    Builder(
                      builder: (context) {
                        final entries = leaderboardAsync.value!;
                        // Convert entries to LeaderboardPlayer models
                        final List<LeaderboardPlayer> allPlayers = entries.map<LeaderboardPlayer>((e) {
                          final isMe = e.userId == myUserId;
                          // Use actual avatar URL if available; else show first letter of name
                          final avatarDisplay = e.avatarKey != null && e.avatarKey!.isNotEmpty
                              ? e.avatarKey!
                              : (e.fullName.isNotEmpty ? e.fullName[0].toUpperCase() : '?');
                          return LeaderboardPlayer(
                            name: e.fullName.isNotEmpty ? e.fullName : e.username,
                            score: e.xp,
                            avatarText: avatarDisplay,
                            avatarBg: isMe ? const Color(0xFF81C784) : const Color(0xFF26A69A),
                            isCurrentUser: isMe,
                          );
                        }).toList();

                        // If current user is not in the global ZSET list yet, insert them
                        final hasMe = allPlayers.any((p) => p.isCurrentUser);
                        if (!hasMe && profile != null) {
                          allPlayers.add(
                            LeaderboardPlayer(
                              name: userName,
                              score: userScore,
                              avatarText: '😎',
                              avatarBg: const Color(0xFF81C784),
                              isCurrentUser: true,
                            ),
                          );
                        }

                        // Sort players by score
                        allPlayers.sort((a, b) => b.score.compareTo(a.score));
                        int myIndex = allPlayers.indexWhere((p) => p.isCurrentUser);

                        List<LeaderboardPlayer> displayPlayers = [];
                        if (allPlayers.length < 3) {
                          displayPlayers = allPlayers.where((p) => p.isCurrentUser).toList();
                        } else if (myIndex == 0) {
                          displayPlayers = [allPlayers[0], allPlayers[1], allPlayers[2]];
                        } else if (myIndex == allPlayers.length - 1) {
                          displayPlayers = [allPlayers[myIndex - 2], allPlayers[myIndex - 1], allPlayers[myIndex]];
                        } else if (myIndex != -1) {
                          displayPlayers = [allPlayers[myIndex - 1], allPlayers[myIndex], allPlayers[myIndex + 1]];
                        } else {
                          displayPlayers = allPlayers.take(3).toList();
                        }

                        return Column(
                          children: [
                            ...displayPlayers.map((player) {
                              return _buildLeaderboardRow(
                                name: player.name,
                                score: player.score,
                                avatarText: player.avatarText,
                                avatarBg: player.avatarBg,
                                isCurrentUser: player.isCurrentUser,
                              );
                            }),
                          ],
                        );
                      }
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ), // end SingleChildScrollView
    ); // end RefreshIndicator
  }

  Widget _buildImageIconAsset(String assetPath, IconData fallbackIcon) {
    return Image.asset(
      assetPath,
      width: 56,
      height: 56,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallbackIcon, size: 48, color: const Color(0xFF017A47));
      },
    );
  }

  Widget _buildGridAction({
    required Widget iconWidget,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Row helper for building individual leaderboard entries
  Widget _buildLeaderboardRow({
    required String name,
    required int score,
    required String avatarText,
    required Color avatarBg,
    required bool isCurrentUser,
  }) {
    final bool isUrl = avatarText.startsWith('http') || avatarText.startsWith('https');
    final bool isSingleChar = avatarText.length == 1;

    return InkWell(
      onTap: () => context.push('/leaderboard'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrentUser ? const Color(0xFF017A47).withValues(alpha: 0.08) : Colors.transparent,
          border: isCurrentUser
              ? const Border(left: BorderSide(color: Color(0xFF017A47), width: 4))
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: avatarBg,
              backgroundImage: isUrl ? NetworkImage(avatarText) : null,
              child: isUrl
                  ? null
                  : Text(
                      isSingleChar ? avatarText : (name.isNotEmpty ? name[0].toUpperCase() : '?'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                  color: isCurrentUser ? const Color(0xFF017A47) : Colors.black87,
                ),
              ),
            ),
            Text(
              '$score XP',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF017A47),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // View 1: Question Bank View (Dynamic for User Class & Group)
  Widget _buildQuestionBankView(ThemeData theme) {
    final profile = ref.watch(userProfileProvider).value?.profile;
    final className = profile?.className ?? 'HSC 2026';
    final groupName = profile?.batch ?? profile?.targetExam ?? 'বিজ্ঞান';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Class & Group Dynamic Filter Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF017A47).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF017A47).withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school, size: 16, color: Color(0xFF017A47)),
                    const SizedBox(width: 6),
                    Text(
                      '$className • $groupName',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF017A47),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: const Text(
                    'ফিল্টার বদলান ➔',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF017A47),
                    ),
                  ),
                ),
              ],
            ),
          ),

          TextField(
            decoration: InputDecoration(
              hintText: '$className - $groupName প্রশ্ন খুঁজুন...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) {
                final titles = [
                  'কিসের মানের পরিবর্তনের জন্য লেন্সের ফোকাস দূরত্ব পরিবর্তিত হয়?',
                  'নিচের কোনটি লরেন্টজ বলের সঠিক সমীকরণ?',
                  'একটি তারের রোধ ১০ ওহম হলে তারটি টেনে দ্বিগুণ করলে রোধ কত হবে?',
                  'স্থির তড়িৎক্ষেত্রে অসীম থেকে একটি আধানকে আনতে কৃতকাজ কী?'
                ];
                final subjects = ['পদার্থবিজ্ঞান', 'পদার্থবিজ্ঞান', 'পদার্থবিজ্ঞান', 'পদার্থবিজ্ঞান'];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(titles[index], style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('$className • ${subjects[index]}', style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // View 2: Mock Exam List View (Dynamic for User Class & Group)
  Widget _buildExamListView(ThemeData theme) {
    final profile = ref.watch(userProfileProvider).value?.profile;
    final className = profile?.className ?? 'HSC 2026';
    final groupName = profile?.batch ?? profile?.targetExam ?? 'বিজ্ঞান';

    final curriculumAsync = ref.watch(studentCurriculumProvider);

    return curriculumAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF017A47)),
            SizedBox(height: 12),
            Text(
              'আপনার বিষয়ের পরীক্ষা প্রস্তুত হচ্ছে...',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text(
                'পরীক্ষা লোড করতে সমস্যা হয়েছে: $err',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(studentCurriculumProvider),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF017A47)),
                child: const Text('পুনরায় চেষ্টা করুন', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
      data: (subjects) {
        if (subjects.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📚', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 12),
                  Text(
                    '$className ($groupName)-এর জন্য কোনো বিষয় পাওয়া যায়নি।',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'প্রোফাইল থেকে অন্য বিষয়/ক্লাস নির্বাচন করুন।',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/profile'),
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                    label: const Text('ক্লাস পরিবর্তন করুন', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF017A47)),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 6,
            childAspectRatio: 3.2,
          ),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index] as Map<String, dynamic>;
            final subjectName = subject['name'] ?? 'বিষয়';
            final rawIcon = subject['icon'] as String?;
            final rawImageUrl = subject['imageUrl'] as String?;
            final chapters = (subject['chapters'] as List<dynamic>?) ?? [];

            // Prioritize icon image URL over subject banner image
            final iconImageUrl = (rawIcon != null && (rawIcon.startsWith('http://') || rawIcon.startsWith('https://')))
                ? rawIcon
                : ((rawImageUrl != null && rawImageUrl.isNotEmpty && (rawImageUrl.startsWith('http://') || rawImageUrl.startsWith('https://')))
                    ? rawImageUrl
                    : null);
            final emojiIcon = (rawIcon != null && !rawIcon.startsWith('http')) ? rawIcon : '📚';

            return Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                splashColor: const Color(0xFF017A47).withOpacity(0.12),
                highlightColor: const Color(0xFF017A47).withOpacity(0.06),
                onTap: () {
                  context.push(
                    '/topic-selection/${subject['id']}',
                    extra: subjectName,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: Center(
                          child: iconImageUrl != null
                              ? Image.network(
                                  iconImageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Text(
                                    emojiIcon,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                )
                              : Text(
                                  emojiIcon,
                                  style: const TextStyle(fontSize: 18),
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subjectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // View 3: Exam Completion History View
  Widget _buildHistoryListView(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        final titles = [
          'ভেক্টর ও নিউটনীয় বলবিদ্যা প্র্যাকটিস কুইজ',
          'জৈব রসায়ন পরিচিতি শর্ট টেস্ট',
          'ম্যাট্রিক্স ও নির্ণায়ক অধ্যায় টেস্ট'
        ];
        final marks = ['স্কোর: ১৮/২০', 'স্কোর: ৭/১০', 'স্কোর: ২৫/২৫'];
        final dates = ['১৮ জুলাই, ২০২৬', '১৬ জুলাই, ২০২৬', '১০ জুলাই, ২০২৬'];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE8F5E9),
              child: Icon(Icons.check, color: theme.colorScheme.primary),
            ),
            title: Text(titles[index], style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(dates[index], style: const TextStyle(fontSize: 12)),
            ),
            trailing: Text(marks[index], style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          ),
        );
      },
    );
  }

  // View 4: Student Progress Metrics with Graphs
  Widget _buildProgressView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Streaks multiplier card
          Card(
            color: const Color(0xFFFFF3E0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '৭ দিনের স্ট্রিক!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                      ),
                      Text(
                        'প্রতিদিন পরীক্ষা দিয়ে স্ট্রিক সচল রাখুন।',
                        style: TextStyle(fontSize: 13, color: Colors.orange[800]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // XP & Level stats card
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('মোট XP অর্জন', style: TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 8),
                        Text(
                          '১২৫০ XP',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('কারেন্ট লেভেল', style: TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 8),
                        Text(
                          'লেভেল ৫',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('সাপ্তাহিক কর্মদক্ষতা গ্রাফ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Performance Line Chart utilizing fl_chart
          Container(
            height: 200,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 4),
                      FlSpot(2, 3.5),
                      FlSpot(3, 5),
                      FlSpot(4, 6.5),
                      FlSpot(5, 7.5),
                      FlSpot(6, 9),
                    ],
                    isCurved: true,
                    color: const Color(0xFF005C39),
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF005C39).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class LeaderboardPlayer {
  final String name;
  final int score;
  final String avatarText;
  final Color avatarBg;
  final bool isCurrentUser;

  LeaderboardPlayer({
    required this.name,
    required this.score,
    required this.avatarText,
    required this.avatarBg,
    this.isCurrentUser = false,
  });
}

class QuestionBankIcon extends StatelessWidget {
  final Color color;
  const QuestionBankIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          Positioned(
            top: 2,
            left: 5,
            child: Container(
              width: 14,
              height: 18,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Positioned(
            top: 5,
            left: 2,
            child: FloatingWidget(
              child: Container(
                width: 14,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 8, height: 1.5, color: Colors.white),
                    Container(width: 6, height: 1.5, color: Colors.white),
                    Container(width: 4, height: 1.5, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickPracticeIcon extends StatelessWidget {
  final Color color;
  const QuickPracticeIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: PulseWidget(
              child: Icon(Icons.flash_on, size: 24, color: color),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 2,
            child: Container(width: 3, height: 3, decoration: BoxDecoration(color: color.withOpacity(0.5), shape: BoxShape.circle)),
          ),
          Positioned(
            top: 4,
            right: 2,
            child: Container(width: 2.5, height: 2.5, decoration: BoxDecoration(color: color.withOpacity(0.5), shape: BoxShape.circle)),
          ),
        ],
      ),
    );
  }
}

class MockExamIcon extends StatelessWidget {
  final Color color;
  const MockExamIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          Positioned(
            top: 2,
            left: 4,
            child: Container(
              width: 15,
              height: 19,
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            top: 1,
            left: 8,
            child: Container(
              width: 7,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
          Positioned(
            top: 7,
            left: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 7, height: 1.5, color: color),
                const SizedBox(height: 2),
                Container(width: 5, height: 1.5, color: color),
                const SizedBox(height: 2),
                Container(width: 7, height: 1.5, color: color),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Center(
                child: RotateWidget(
                  duration: const Duration(seconds: 4),
                  child: Transform.translate(
                    offset: const Offset(0, -1.5),
                    child: Container(
                      width: 1.2,
                      height: 3.5,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AIGuideIcon extends StatelessWidget {
  final Color color;
  const AIGuideIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotateWidget(
            duration: const Duration(seconds: 8),
            child: Stack(
              children: [
                Positioned(
                  top: 1,
                  left: 5,
                  child: Container(width: 3.5, height: 3.5, decoration: BoxDecoration(color: color.withOpacity(0.6), shape: BoxShape.circle)),
                ),
                Positioned(
                  bottom: 2,
                  right: 5,
                  child: Container(width: 3.5, height: 3.5, decoration: BoxDecoration(color: color.withOpacity(0.6), shape: BoxShape.circle)),
                ),
                Positioned(
                  top: 8,
                  right: 1,
                  child: Container(width: 2.5, height: 2.5, decoration: BoxDecoration(color: color.withOpacity(0.4), shape: BoxShape.circle)),
                ),
              ],
            ),
          ),
          PulseWidget(
            child: Icon(Icons.auto_awesome, size: 18, color: color),
          ),
        ],
      ),
    );
  }
}

// Micro-animation Loop Helper Widgets
class FloatingWidget extends StatefulWidget {
  final Widget child;
  const FloatingWidget({required this.child});

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget> {
  double _value = 0.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: _value),
      duration: const Duration(seconds: 1),
      onEnd: () {
        setState(() {
          _value = _value == 0.0 ? 3.0 : 0.0;
        });
      },
      builder: (context, offset, child) {
        return Transform.translate(
          offset: Offset(0, -offset),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class PulseWidget extends StatefulWidget {
  final Widget child;
  const PulseWidget({required this.child});

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: _scale),
      duration: const Duration(milliseconds: 900),
      onEnd: () {
        setState(() {
          _scale = _scale == 1.0 ? 1.15 : 1.0;
        });
      },
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class RotateWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  const RotateWidget({required this.child, this.duration = const Duration(seconds: 4)});

  @override
  State<RotateWidget> createState() => _RotateWidgetState();
}

class _RotateWidgetState extends State<RotateWidget> {
  double _angle = 0.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: _angle),
      duration: widget.duration,
      onEnd: () {
        setState(() {
          _angle += 6.28318;
        });
      },
      builder: (context, angle, child) {
        return Transform.rotate(
          angle: angle,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class BannerSliderWidget extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  const BannerSliderWidget({super.key, required this.banners});

  @override
  State<BannerSliderWidget> createState() => _BannerSliderWidgetState();
}

class _BannerSliderWidgetState extends State<BannerSliderWidget> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _startAutoTimer();
  }

  void _startAutoTimer() {
    _autoTimer?.cancel();
    if (widget.banners.length > 1) {
      _autoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_pageController.hasClients && widget.banners.isNotEmpty) {
          final nextPage = (_currentIndex + 1) % widget.banners.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SizedBox(
        height: 160,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.banners.length,
              itemBuilder: (context, index) {
                final banner = widget.banners[index];
                final String title = banner['title'] ?? '';
                final String badgeText = banner['badgeText'] ?? 'OFFER';
                final String? imageUrl = banner['imageUrl'];
                final String? rawTargetUrl = banner['targetUrl'];
                final bool isClickable = rawTargetUrl != null &&
                    rawTargetUrl.isNotEmpty &&
                    rawTargetUrl.trim() != '#' &&
                    rawTargetUrl.trim() != 'javascript:void(0)';
                final String targetUrl = isClickable ? rawTargetUrl.trim() : '';

                final List<Color> gradientColors = banner['colors'] ?? [const Color(0xFF004D40), const Color(0xFF00796B)];
                final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                  child: GestureDetector(
                    onTap: isClickable
                        ? () {
                            if (targetUrl.startsWith('/')) {
                              context.push(targetUrl);
                            }
                          }
                        : null,
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        gradient: !hasImage
                            ? LinearGradient(
                                colors: gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        image: hasImage
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: hasImage
                          ? const SizedBox.expand()
                          : Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFD9746E), Color(0xFFF18881)],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            badgeText,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: isClickable
                                              ? () {
                                                  if (targetUrl.startsWith('/')) {
                                                    context.push(targetUrl);
                                                  }
                                                }
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            elevation: 0,
                                            minimumSize: const Size(0, 30),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Get now',
                                            style: TextStyle(
                                              color: Color(0xFF004D40),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                                    ),
                                    child: Center(
                                      child: Text(banner['icon'] ?? '🦖', style: const TextStyle(fontSize: 38)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),

            // Sleek Floating Dots Overlay inside image
            if (widget.banners.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        widget.banners.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentIndex == i ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentIndex == i
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


