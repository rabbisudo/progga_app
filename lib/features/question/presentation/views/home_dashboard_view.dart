import 'dart:async';
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
import '../../../app_update/data/app_update_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/storage/secure_storage_service.dart';

class ActiveBannersNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    final hive = ref.read(hiveServiceProvider);
    final cached = hive.getCachedList('cached_active_banners');
    List<Map<String, dynamic>>? cachedList;
    if (cached != null && cached.isNotEmpty) {
      try {
        cachedList = cached.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }

    _fetchFresh();

    return cachedList ?? [];
  }

  Future<void> _fetchFresh() async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.get('/banners');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data;
        final result = list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        final hive = ref.read(hiveServiceProvider);
        await hive.cacheList('cached_active_banners', result);
        state = AsyncData(result);
      }
    } catch (e, st) {
      if (state.value == null || state.value!.isEmpty) {
        state = AsyncError(e, st);
      }
    }
  }

  Future<void> refresh() async {
    await _fetchFresh();
  }
}

final activeBannersProvider = AsyncNotifierProvider<ActiveBannersNotifier, List<Map<String, dynamic>>>(() {
  return ActiveBannersNotifier();
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(appUpdateServiceProvider).checkAndShowUpdateDialog(context);
        NotificationService().init();
        try {
          final apiClient = ref.read(apiClientProvider);
          final storage = ref.read(secureStorageServiceProvider);
          NotificationService().syncDeviceToken(apiClient, storage);
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profileAsync = ref.watch(userProfileProvider);
    final leaderboardAsync = ref.watch(myLeaderboardProvider);
    final bannersAsync = ref.watch(activeBannersProvider);
    final spacedCardsAsync = ref.watch(spacedRepetitionProvider);

    final profile = profileAsync.value?.profile;
    final myUserId = profileAsync.value?.id;

    // Read league name dynamically
    String leagueName = 'ব্রোঞ্জ লীগ';
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
          league: profile?.league ?? 'BRONZE',
          currentStreak: profile?.currentStreak ?? 0,
        ),
      );
      if (myEntry.xp > 0) currentXp = myEntry.xp;
      leagueName = _getLeagueBengaliName(myEntry.league);
    }

    final userName = profile?.fullName ?? 'User';
    final userScore = profile?.xp ?? 0;

    return RefreshIndicator(
      color: const Color(0xFF017A47),
      onRefresh: () async {
        try {
          // 1. Spaced Repetition (retention) cards stay cached on screen; sync in background
          ref.read(spacedRepetitionProvider.notifier).refresh();

          // 2. Refresh visible Profile, Leaderboard, and Banners in parallel (sub-second)
          await Future.wait([
            ref.read(userProfileProvider.notifier).refreshProfile(),
            ref.read(myLeaderboardProvider.notifier).refresh(),
            ref.read(activeBannersProvider.notifier).refresh(),
          ]).timeout(const Duration(seconds: 4), onTimeout: () => []);

          // 3. Silently invalidate curriculum providers for other tabs in background without blocking Home spinner
          ref.invalidate(studentCurriculumProvider);
          ref.invalidate(studentQbCurriculumProvider);
          if (profile?.classId != null && profile!.classId!.isNotEmpty) {
            ref.invalidate(qbClassSectionsProvider(profile.classId!));
            ref.invalidate(qbClassSeriesProvider(profile.classId!));
          }
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

            // 2. Premium Grid Action Cards (Clean, Simple & Modern)
            RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                child: Row(
                  children: [
                    _buildGridAction(
                      iconWidget: _buildImageIconAsset(
                        'assets/icons/qsbank.png',
                        Icons.inventory_2_outlined,
                        fallbackColor: const Color(0xFF0284C7),
                      ),
                      label: 'প্রশ্নব্যাংক',
                      onTap: () => widget.onTabSelected(1),
                      context: context,
                      badgeBgColor: isDark ? const Color(0xFF0F2537) : const Color(0xFFEBF5FF),
                      badgeBorderColor: isDark
                          ? const Color(0xFF0284C7).withValues(alpha: 0.3)
                          : const Color(0xFFBAE6FD).withValues(alpha: 0.7),
                    ),
                    _buildGridAction(
                      iconWidget: _buildImageIconAsset(
                        'assets/icons/exam.png',
                        Icons.edit_note_outlined,
                        fallbackColor: const Color(0xFF059669),
                      ),
                      label: 'মক পরীক্ষা',
                      onTap: () => widget.onTabSelected(2),
                      context: context,
                      badgeBgColor: isDark ? const Color(0xFF093122) : const Color(0xFFECFDF5),
                      badgeBorderColor: isDark
                          ? const Color(0xFF059669).withValues(alpha: 0.3)
                          : const Color(0xFFA7F3D0).withValues(alpha: 0.7),
                    ),
                    _buildGridAction(
                      iconWidget: _buildImageIconAsset(
                        'assets/icons/report.png',
                        Icons.bar_chart_outlined,
                        fallbackColor: const Color(0xFFE11D48),
                      ),
                      label: 'পরীক্ষার হিস্ট্রি',
                      onTap: () => context.push('/exam-history'),
                      context: context,
                      badgeBgColor: isDark ? const Color(0xFF331418) : const Color(0xFFFFF1F2),
                      badgeBorderColor: isDark
                          ? const Color(0xFFE11D48).withValues(alpha: 0.3)
                          : const Color(0xFFFECDD3).withValues(alpha: 0.7),
                    ),
                    _buildGridAction(
                      iconWidget: _buildImageIconAsset(
                        'assets/icons/ai.png',
                        Icons.psychology_outlined,
                        fallbackColor: const Color(0xFF9333EA),
                      ),
                      label: 'প্রজ্ঞা এআই',
                      onTap: () => context.push('/progga-ai'),
                      context: context,
                      badgeBgColor: isDark ? const Color(0xFF271342) : const Color(0xFFFAF5FF),
                      badgeBorderColor: isDark
                          ? const Color(0xFF9333EA).withValues(alpha: 0.3)
                          : const Color(0xFFE9D5FF).withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),

            // Spaced Repetition Card Widget with RepaintBoundary
            RepaintBoundary(
              child: spacedCardsAsync.when(
                data: (cards) {
                  final validMcqCards = cards.where((card) {
                    if (card == null || card is! Map) return false;
                    final q = card['question'];
                    if (q == null || q is! Map) return false;
                    final type = (q['type'] as String? ?? 'MCQ').trim().toUpperCase();
                    final options = q['options'];
                    return type == 'MCQ' && options is List && options.length >= 2;
                  }).toList();

                  if (validMcqCards.isEmpty) return const SizedBox.shrink();
                  return SpacedRepetitionWidget(
                    cards: validMcqCards,
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
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF017A47).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF017A47).withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        _getLeagueAsset(profile?.league),
                                        width: 14,
                                        height: 14,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.shield_outlined,
                                          size: 12,
                                          color: Color(0xFF017A47),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        leagueName,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF017A47),
                                          fontFamily: 'Li Ador Noirrit',
                                        ),
                                      ),
                                    ],
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
                            children: [
                              for (int i = 0; i < top3Players.length; i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    thickness: 0.8,
                                    color: isDark ? const Color(0xFF26282E) : const Color(0xFFE5ECE8),
                                    indent: 70,
                                    endIndent: 18,
                                  ),
                                _buildLeaderboardRow(
                                  name: top3Players[i].name,
                                  score: top3Players[i].score,
                                  avatarText: top3Players[i].avatarText,
                                  avatarBg: top3Players[i].avatarBg,
                                  isCurrentUser: top3Players[i].isCurrentUser,
                                  rank: i + 1,
                                  context: context,
                                ),
                              ],
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
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildImageIconAsset(
    String assetPath,
    IconData fallbackIcon, {
    Color fallbackColor = const Color(0xFF017A47),
  }) {
    return Image.asset(
      assetPath,
      width: 26,
      height: 26,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallbackIcon, size: 22, color: fallbackColor);
      },
    );
  }

  Widget _buildGridAction({
    required Widget iconWidget,
    required String label,
    required VoidCallback onTap,
    required BuildContext context,
    required Color badgeBgColor,
    required Color badgeBorderColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: BouncingCard(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13.0, horizontal: 4.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFE5E7EB),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.035),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: badgeBorderColor,
                      width: 1,
                    ),
                  ),
                  child: Center(child: iconWidget),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
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
    final bool isSingleChar = avatarText.length <= 2;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.push('/leaderboard'),
      child: Container(
        color: isCurrentUser
            ? const Color(0xFF017A47).withValues(alpha: isDark ? 0.12 : 0.06)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            // Left: Circular Avatar
            isUrl
                ? CustomAvatar(
                    avatarUrl: avatarText,
                    radius: 19,
                    backgroundColor: avatarBg,
                    fallbackWidget: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        isSingleChar ? avatarText : (name.isNotEmpty ? name[0].toUpperCase() : '?'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
            const SizedBox(width: 14),

            // Middle: User Name
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.w800 : FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontFamily: 'Li Ador Noirrit',
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Right: Rank Number on top & points underneath (Matching the exact screenshot)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rank.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: rank == 1
                        ? const Color(0xFFD97706)
                        : (isDark ? Colors.white : const Color(0xFF111827)),
                    fontFamily: 'Li Ador Noirrit',
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${_toBengaliDigits(score.toString())} পয়েন্ট',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                    fontFamily: 'Li Ador Noirrit',
                  ),
                ),
              ],
            ),
          ],
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
    if (leagueKey == null) return 'ব্রোঞ্জ লীগ';
    switch (leagueKey.trim().toLowerCase()) {
      case 'bronze':
        return 'ব্রোঞ্জ লীগ';
      case 'silver':
        return 'সিলভার লীগ';
      case 'gold':
        return 'গোল্ড লীগ';
      case 'crystal':
        return 'ক্রিস্টাল লীগ';
      case 'elite':
        return 'এলিট লীগ';
      case 'legend':
        return 'লিজেন্ড লীগ';
      default:
        return 'ব্রোঞ্জ লীগ';
    }
  }

  String _getLeagueAsset(String? leagueKey) {
    if (leagueKey == null) return 'assets/legue/bronze.webp';
    switch (leagueKey.trim().toLowerCase()) {
      case 'bronze':
        return 'assets/legue/bronze.webp';
      case 'silver':
        return 'assets/legue/silver.webp';
      case 'gold':
        return 'assets/legue/gold.webp';
      case 'crystal':
        return 'assets/legue/crydtsl.webp';
      case 'elite':
        return 'assets/legue/elite.webp';
      case 'legend':
        return 'assets/legue/legend.webp';
      default:
        return 'assets/legue/bronze.webp';
    }
  }
}
