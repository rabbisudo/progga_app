import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../../leaderboard/domain/leaderboard_model.dart';
import '../../../leaderboard/presentation/leaderboard_notifier.dart';
import '../../../profile/presentation/profile_notifier.dart';
import '../../../academics/data/academics_repository.dart';
import '../../../../core/storage/hive_service.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/bouncing_card.dart';
import '../widgets/banner_slider.dart';
import '../widgets/spaced_repetition_widget.dart';
import 'spaced_repetition_notifier.dart';

final activeBannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final hive = ref.read(hiveServiceProvider);
  final cached = hive.getCachedList('cached_active_banners');
  List<Map<String, dynamic>>? cachedList;
  if (cached != null && cached.isNotEmpty) {
    try {
      cachedList = cached.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {}
  }

  // Background fetch for silent refresh
  final fetchFuture = client.dio.get('/banners').then((response) async {
    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> list = response.data;
      final result = list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      await hive.cacheList('cached_active_banners', result);
      return result;
    }
    return cachedList ?? <Map<String, dynamic>>[];
  }).catchError((_) => cachedList ?? <Map<String, dynamic>>[]);

  // 0ms immediate render from Hive cache if available
  if (cachedList != null && cachedList.isNotEmpty) {
    fetchFuture.ignore();
    return cachedList;
  }

  return fetchFuture;
});

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

class HomeDashboardView extends ConsumerStatefulWidget {
  final ValueChanged<int> onTabSelected;

  const HomeDashboardView({
    super.key,
    required this.onTabSelected,
  });

  @override
  ConsumerState<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends ConsumerState<HomeDashboardView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profileAsync = ref.watch(userProfileProvider);
    final leaderboardAsync = ref.watch(myLeaderboardProvider);
    final bannersAsync = ref.watch(activeBannersProvider);
    final curriculumAsync = ref.watch(studentCurriculumProvider);
    final spacedCardsAsync = ref.watch(spacedRepetitionProvider);

    final profile = profileAsync.value?.profile;
    final myUserId = profileAsync.value?.id;

    // Read league name dynamically
    String leagueName = 'আয়রন লীগ';
    if (profile != null) {
      leagueName = _getLeagueBengaliName(profile.league);
    }
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
          league: profile?.league ?? 'IRON',
          currentStreak: profile?.currentStreak ?? 0,
        ),
      );
      if (myEntry.xp > 0) currentXp = myEntry.xp;
      leagueName = _getLeagueBengaliName(myEntry.league);
    }

    final userName = profile?.fullName ?? 'User';
    final userScore = profile?.xp ?? 0;
    final starPoints = profile != null ? (profile.xp % 100) : 0;
    final progressVal = profile != null ? (profile.xp % 100) / 100.0 : 0.0;

    return RefreshIndicator(
      color: const Color(0xFF017A47),
      onRefresh: () async {
        try {
          await Future.wait([
            ref.refresh(userProfileProvider.future),
            ref.refresh(myLeaderboardProvider.future),
            ref.refresh(activeBannersProvider.future),
            ref.refresh(studentCurriculumProvider.future),
            ref.refresh(studentQbCurriculumProvider.future),
          ]);
        } catch (_) {}
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // 1. Promo Banners Carousel Slider with RepaintBoundary for 120 FPS
            RepaintBoundary(
              child: bannersAsync.when(
                data: (banners) => banners.isNotEmpty
                    ? BannerSliderWidget(banners: banners)
                    : const SizedBox.shrink(),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: ShimmerSkeleton(width: double.infinity, height: 160, borderRadius: 20),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // 2. Premium Grid Action Cards (Clean gradients + shadows + micro scales)
            RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                child: Row(
                  children: [
                    _buildGridAction(
                      iconWidget: _buildImageIconAsset('assets/icons/qsbank.png', Icons.inventory_2_outlined),
                      label: 'প্রশ্নব্যাংক',
                      onTap: () => widget.onTabSelected(1),
                      context: context,
                      gradientColors: isDark
                          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                          : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
                    ),
                    _buildGridAction(
                      iconWidget: _buildImageIconAsset('assets/icons/exam.png', Icons.edit_note_outlined),
                      label: 'মক পরীক্ষা',
                      onTap: () => widget.onTabSelected(2),
                      context: context,
                      gradientColors: isDark
                          ? [const Color(0xFF065F46), const Color(0xFF064E3B)]
                          : [const Color(0xFFDCFCE7), const Color(0xFFBBF7D0)],
                    ),
                    _buildGridAction(
                      iconWidget: _buildImageIconAsset('assets/icons/report.png', Icons.bar_chart_outlined),
                      label: 'পরীক্ষার হিস্ট্রি',
                      onTap: () => context.push('/exam-history'),
                      context: context,
                      gradientColors: isDark
                          ? [const Color(0xFF7F1D1D), const Color(0xFF991B1B)]
                          : [const Color(0xFFFEE2E2), const Color(0xFFFECACA)],
                    ),
                    _buildGridAction(
                      iconWidget: _buildImageIconAsset('assets/icons/ai.png', Icons.psychology_outlined),
                      label: 'প্রজ্ঞা এআই',
                      onTap: () => context.push('/progga-ai'),
                      context: context,
                      gradientColors: isDark
                          ? [const Color(0xFF581C87), const Color(0xFF4C1D95)]
                          : [const Color(0xFFF3E8FF), const Color(0xFFE9D5FF)],
                    ),
                  ],
                ),
              ),
            ),

            // Spaced Repetition Card Widget with RepaintBoundary
            RepaintBoundary(
              child: spacedCardsAsync.when(
                data: (cards) {
                  if (cards.isEmpty) return const SizedBox.shrink();
                  return SpacedRepetitionWidget(
                    cards: cards,
                    onFinished: () {
                      ref.read(spacedRepetitionProvider.notifier).refresh();
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (err, _) => const SizedBox.shrink(),
              ),
            ),

            // 3. Premium Redesigned Leaderboard Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    // Leaderboard header
                    InkWell(
                      onTap: () => context.push('/leaderboard'),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'লিডারবোর্ড',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontFamily: 'Li Ador Noirrit',
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  'সবগুলো দেখুন',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF017A47),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios, 
                                  size: 12, 
                                  color: const Color(0xFF017A47),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    


                    // Onboarding suggestion box when star points is 0 (or XP is low)
                    if (userScore == 0) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? const Color(0xFFFFB300).withOpacity(0.08) 
                              : const Color(0xFFFFB300).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? const Color(0xFFFFB300).withOpacity(0.2) 
                                : const Color(0xFFFFB300).withOpacity(0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tips_and_updates_outlined,
                              size: 18,
                              color: isDark ? Colors.amber[200] : const Color(0xFFE65100),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'কুইজ বা মক পরীক্ষায় অংশ নিয়ে পয়েন্ট অর্জন করুন এবং লিডারবোর্ডে এগিয়ে যান!',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.amber[200] : const Color(0xFFE65100),
                                  height: 1.3,
                                  fontFamily: 'Li Ador Noirrit',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    
                    // Shimmer loading inside leaderboard cards
                    if (leaderboardAsync.isLoading && (leaderboardAsync.value == null || leaderboardAsync.value!.isEmpty)) ...[
                      ...List.generate(3, (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        child: Row(
                          children: const [
                            ShimmerSkeleton(width: 24, height: 24, borderRadius: 12),
                            SizedBox(width: 12),
                            ShimmerSkeleton(width: 32, height: 32, borderRadius: 16),
                            SizedBox(width: 12),
                            ShimmerSkeleton(width: 120, height: 16, borderRadius: 4),
                            Spacer(),
                            ShimmerSkeleton(width: 50, height: 14, borderRadius: 4),
                          ],
                        ),
                      )),
                    ] else if (leaderboardAsync.hasError || leaderboardAsync.value == null) ...[
                      _buildLeaderboardRow(
                        name: userName,
                        score: userScore,
                        avatarText: userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        avatarBg: const Color(0xFF81C784),
                        isCurrentUser: true,
                        rank: 1,
                        context: context,
                      ),
                    ] else ...[
                      Builder(
                        builder: (context) {
                          final entries = leaderboardAsync.value!;
                          final List<LeaderboardPlayer> allPlayers = entries.map<LeaderboardPlayer>((e) {
                            final isMe = e.userId == myUserId;
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

                          // Add current user fallback if missing
                          final hasMe = allPlayers.any((p) => p.isCurrentUser);
                          if (!hasMe && profile != null) {
                            allPlayers.add(
                              LeaderboardPlayer(
                                name: userName,
                                score: userScore,
                                avatarText: userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                avatarBg: const Color(0xFF81C784),
                                isCurrentUser: true,
                              ),
                            );
                          }

                          // Sort all players descending by points
                          allPlayers.sort((a, b) => b.score.compareTo(a.score));

                          // Always display true Top 3 ranking players (1, 2, 3)
                          final top3Players = allPlayers.take(3).toList();

                          return Column(
                            children: List.generate(top3Players.length, (i) {
                              final player = top3Players[i];
                              return _buildLeaderboardRow(
                                name: player.name,
                                score: player.score,
                                avatarText: player.avatarText,
                                avatarBg: player.avatarBg,
                                isCurrentUser: player.isCurrentUser,
                                rank: i + 1,
                                context: context,
                              );
                            }),
                          );
                        }
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildImageIconAsset(String assetPath, IconData fallbackIcon) {
    return Image.asset(
      assetPath,
      width: 44,
      height: 44,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallbackIcon, size: 36, color: const Color(0xFF017A47));
      },
    );
  }

  Widget _buildGridAction({
    required Widget iconWidget,
    required String label,
    required VoidCallback onTap,
    required BuildContext context,
    required List<Color> gradientColors,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: BouncingCard(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.5),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isDark ? 0.1 : 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: iconWidget,
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Li Ador Noirrit',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardRow({
    required String name,
    required int score,
    required String avatarText,
    required Color avatarBg,
    required bool isCurrentUser,
    required int rank,
    required BuildContext context,
  }) {
    final bool isUrl = avatarText.startsWith('http') || avatarText.startsWith('https');
    final bool isSingleChar = avatarText.length == 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget rankWidget;
    Color rankBg;
    Color rankTextColor;
    if (rank == 1) {
      rankBg = isDark ? const Color(0xFF2A2315) : const Color(0xFFFEF3C7);
      rankTextColor = const Color(0xFFD97706);
    } else if (rank == 2) {
      rankBg = isDark ? const Color(0xFF1E2428) : const Color(0xFFF1F5F9);
      rankTextColor = const Color(0xFF64748B);
    } else if (rank == 3) {
      rankBg = isDark ? const Color(0xFF2A1E17) : const Color(0xFFFFEDD5);
      rankTextColor = const Color(0xFFB45309);
    } else {
      rankBg = isDark ? const Color(0xFF1E2922) : const Color(0xFFF3F6F4);
      rankTextColor = isDark ? Colors.white60 : const Color(0xFF4B5563);
    }

    rankWidget = Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: rankBg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _toBengaliDigits(rank.toString()),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: rankTextColor,
            fontFamily: 'Li Ador Noirrit',
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: isCurrentUser
              ? (isDark ? const Color(0xFF017A47).withOpacity(0.12) : const Color(0xFF017A47).withOpacity(0.06))
              : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8F9FA)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentUser
                ? (isDark ? const Color(0xFF017A47).withOpacity(0.4) : const Color(0xFF017A47).withOpacity(0.25))
                : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFECEFF1)),
            width: 1.2,
          ),
        ),
        child: InkWell(
          onTap: () => context.push('/leaderboard'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                rankWidget,
                const SizedBox(width: 10),
                isUrl
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isCurrentUser
                              ? Border.all(
                                  color: const Color(0xFF017A47),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: CustomAvatar(
                          avatarUrl: avatarText,
                          radius: 18,
                          backgroundColor: avatarBg,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isCurrentUser
                              ? Border.all(
                                  color: const Color(0xFF017A47),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: avatarBg,
                          child: Text(
                            isSingleChar ? avatarText : (name.isNotEmpty ? name[0].toUpperCase() : '?'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
                      color: isCurrentUser 
                          ? const Color(0xFF017A47) 
                          : (isDark ? Colors.white : Colors.black87),
                      fontFamily: 'Li Ador Noirrit',
                    ),
                  ),
                ),
                Text(
                  '${_toBengaliDigits(score.toString())} পয়েন্ট',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: Color(0xFF017A47),
                    fontFamily: 'Li Ador Noirrit',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  String _getLeagueBengaliName(String? leagueKey) {
    if (leagueKey == null) return 'আয়রন লীগ';
    switch (leagueKey.trim().toLowerCase()) {
      case 'bronze':
        return 'ব্রোঞ্জ লীগ';
      case 'silver':
        return 'সিলভার লীগ';
      case 'gold':
        return 'গোল্ড লীগ';
      case 'diamond':
        return 'ডায়মন্ড লীগ';
      case 'infinity':
        return 'ইনফিনিটি লীগ';
      case 'iron':
      default:
        return 'আয়রন লীগ';
    }
  }

  LinearGradient _getLeftIconGradient(int index, bool isDark) {
    final gradients = [
      [const Color(0xFF00B09B), const Color(0xFF96C93D)],
      [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)],
      [const Color(0xFFF12711), const Color(0xFFF5AF19)],
      [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
      [const Color(0xFFF857A6), const Color(0xFFFF5858)],
      [const Color(0xFF11998E), const Color(0xFF38EF7D)],
    ];
    final selected = gradients[index % gradients.length];
    final opacity = isDark ? 0.22 : 0.12;
    return LinearGradient(
      colors: selected.map((c) => c.withOpacity(opacity)).toList(),
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
