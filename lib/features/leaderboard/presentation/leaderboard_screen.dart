import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../profile/presentation/profile_notifier.dart';
import '../data/leaderboard_repository.dart';
import '../domain/leaderboard_model.dart';
import '../../../core/widgets/custom_avatar.dart';
import '../../../core/widgets/custom_back_button.dart';

String _toBengaliDigits(String input) {
  const Map<String, String> digits = {
    '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
    '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'
  };
  return input.split('').map((char) => digits[char] ?? char).join();
}

String _getRankBangla(int rank) {
  if (rank == 1) return '১ম';
  if (rank == 2) return '২য়';
  if (rank == 3) return '৩য়';
  if (rank == 4) return '৪র্থ';
  if (rank == 5) return '৫ম';
  if (rank == 6) return '৬ষ্ঠ';
  if (rank == 7) return '৭ম';
  if (rank == 8) return '৮ম';
  if (rank == 9) return '৯ম';
  if (rank == 10) return '১০ম';
  return '${_toBengaliDigits(rank.toString())}তম';
}

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  static const int _pageSize = 30;

  final ScrollController _scrollController = ScrollController();
  final List<LeaderboardEntryModel> _entries = [];

  String _selectedLeague = 'ALL'; // 'ALL', 'BRONZE', 'SILVER', 'GOLD', 'CRYSTAL', 'ELITE', 'LEGEND'
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchPage(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchPage();
    }
  }

  Future<void> _fetchPage({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _entries.clear();
        _offset = 0;
        _hasMore = true;
        _isLoadingMore = false;
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final repo = ref.read(leaderboardRepositoryProvider);
      final newEntries = await repo.fetchLeaderboard(
        scope: 'global',
        league: _selectedLeague == 'ALL' ? '' : _selectedLeague,
        limit: _pageSize,
        offset: reset ? 0 : _offset,
      );

      if (mounted) {
        setState(() {
          if (reset) {
            _entries.addAll(newEntries);
            _offset = newEntries.length;
          } else {
            _entries.addAll(newEntries);
            _offset += newEntries.length;
          }
          _hasMore = newEntries.length >= _pageSize;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSelectLeague(String leagueId) {
    if (_selectedLeague == leagueId) return;
    setState(() {
      _selectedLeague = leagueId;
    });
    _fetchPage(reset: true);
  }

  String _formatPoints(int xp) {
    if (xp >= 1000) {
      final double val = xp / 1000.0;
      final formatted = val.toStringAsFixed(val % 1 == 0 ? 0 : 1);
      return '${_toBengaliDigits(formatted)}K XP';
    }
    return '${_toBengaliDigits(xp.toString())} XP';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D120F) : const Color(0xFFF8FAF9);
    final cardBg = isDark ? const Color(0xFF141C17) : Colors.white;
    final borderColor = isDark ? const Color(0xFF222F26) : const Color(0xFFE5ECE8);
    const brandGreen = Color(0xFF017A47);

    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value?.profile;
    final myUserId = profileAsync.value?.id;
    final userXp = profile?.xp ?? 0;
    final userStreak = profile?.currentStreak ?? 0;
    final userLeagueConfig = getLeagueConfigByXp(userXp);

    LeaderboardEntryModel? meEntry;
    if (myUserId != null) {
      final idx = _entries.indexWhere((e) => e.userId == myUserId);
      if (idx != -1) {
        meEntry = _entries[idx];
      } else if (profile != null && _entries.isNotEmpty) {
        meEntry = LeaderboardEntryModel(
          rank: 0,
          userId: myUserId,
          username: profile.fullName,
          fullName: profile.fullName,
          institution: profile.institution,
          avatarKey: profile.avatarKey,
          xp: userXp,
          level: profile.level,
          solvedQuestionsCount: profile.solvedQuestionsCount,
          league: userLeagueConfig.id,
          currentStreak: userStreak,
          batch: profile.batch,
        );
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: context.canPop()
            ? CustomBackButton(
                color: isDark ? Colors.white : Colors.black87,
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(
          'লিডারবোর্ড ও লিগ',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF16241C),
            fontWeight: FontWeight.bold,
            fontSize: 17,
            fontFamily: 'Li Ador Noirrit',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF16241C),
              size: 22,
            ),
            tooltip: 'লিগ সিস্টেম তথ্য',
            onPressed: () => _showLeagueInfoSheet(context, isDark, userXp),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 1. TOP USER LEAGUE SHOWCASE & XP PROGRESS CARD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: _buildUserLeagueHeaderCard(
              userXp: userXp,
              userStreak: userStreak,
              leagueConfig: userLeagueConfig,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
            ),
          ),

          // 2. HORIZONTAL LEAGUE FILTER TABS
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: _buildLeagueSelectorTabs(isDark: isDark),
          ),

          // 3. RANKINGS LIST / PODIUM
          Expanded(
            child: _isLoading
                ? _buildLeaderboardSkeleton(isDark)
                : _error != null && _entries.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 36),
                              const SizedBox(height: 12),
                              Text(
                                'লিডারবোর্ড লোড করা সম্ভব হয়নি',
                                style: TextStyle(
                                  fontFamily: 'Li Ador Noirrit',
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => _fetchPage(reset: true),
                                style: TextButton.styleFrom(
                                  backgroundColor: brandGreen.withValues(alpha: 0.1),
                                  foregroundColor: brandGreen,
                                ),
                                child: const Text('পুনরায় চেষ্টা করুন', style: TextStyle(fontFamily: 'Li Ador Noirrit')),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: brandGreen,
                        onRefresh: () => _fetchPage(reset: true),
                        child: _entries.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.35,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('🏆', style: TextStyle(fontSize: 40)),
                                          const SizedBox(height: 10),
                                          Text(
                                            _selectedLeague == 'ALL'
                                                ? 'লিডারবোর্ডে কোনো শিক্ষার্থী নেই'
                                                : '${getLeagueConfig(_selectedLeague).name}-এ এখনো কোনো শিক্ষার্থী নেই',
                                            style: TextStyle(
                                              color: isDark ? Colors.white54 : Colors.black54,
                                              fontFamily: 'Li Ador Noirrit',
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                padding: EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  top: 8,
                                  bottom: meEntry != null ? 90 : 24,
                                ),
                                itemCount: _entries.length >= 3
                                    ? (_entries.length - 2) + (_isLoadingMore ? 1 : 0)
                                    : _entries.length + (_isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  // Top 3 Podium Showcase (at index 0 when >= 3 entries)
                                  if (_entries.length >= 3 && index == 0) {
                                    return _buildTopPodiumShowcase(
                                      top1: _entries[0],
                                      top2: _entries[1],
                                      top3: _entries[2],
                                      myUserId: myUserId,
                                      isDark: isDark,
                                      cardBg: cardBg,
                                      borderColor: borderColor,
                                    );
                                  }

                                  // Pagination loading spinner
                                  final actualIndex = _entries.length >= 3 ? index + 2 : index;
                                  if (actualIndex == _entries.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20),
                                      child: Center(
                                        child: CircularProgressIndicator(color: brandGreen, strokeWidth: 2),
                                      ),
                                    );
                                  }

                                  // Regular Rank Tiles (Rank 4+)
                                  final entry = _entries[actualIndex];
                                  final isMe = entry.userId == myUserId;
                                  return _buildRankTile(
                                    entry: entry,
                                    isMe: isMe,
                                    isDark: isDark,
                                    cardBg: cardBg,
                                    borderColor: borderColor,
                                  );
                                },
                              ),
                      ),
          ),

          // 4. CLEAN STICKY BOTTOM USER BAR
          if (meEntry != null)
            _buildStickyUserBottomBar(
              me: meEntry,
              isDark: isDark,
              borderColor: borderColor,
            ),
        ],
      ),
    );
  }

  // --- Top User League Showcase & XP Progress Card ---
  Widget _buildUserLeagueHeaderCard({
    required int userXp,
    required int userStreak,
    required LeagueConfigModel leagueConfig,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    final progress = calculateLeagueProgress(userXp);
    final neededXp = calculateXpNeededForNextLeague(userXp);
    final nextLeague = getNextLeagueConfig(leagueConfig.id);
    final leagueColor = Color(leagueConfig.colorValue);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: leagueColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: leagueColor.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle tint
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      leagueColor.withValues(alpha: isDark ? 0.12 : 0.06),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // League Badge Image from Assets
                GestureDetector(
                  onTap: () => _showLeagueInfoSheet(context, isDark, userXp),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: leagueColor.withValues(alpha: 0.15),
                          boxShadow: [
                            BoxShadow(
                              color: leagueColor.withValues(alpha: 0.25),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        leagueConfig.asset,
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Text(
                          leagueConfig.icon,
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // League Details & Progress Bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // League Name & Badges
                      Row(
                        children: [
                          Text(
                            leagueConfig.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                              fontFamily: 'Li Ador Noirrit',
                            ),
                          ),
                          const Spacer(),
                          // Streak badge
                          if (userStreak > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                                border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🔥', style: TextStyle(fontSize: 10)),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${_toBengaliDigits(userStreak.toString())} দিন',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEA580C),
                                      fontFamily: 'Li Ador Noirrit',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // XP Points
                      Row(
                        children: [
                          Text(
                            '⚡ ${_toBengaliDigits(userXp.toString())} XP',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: leagueColor,
                              fontFamily: 'Li Ador Noirrit',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• (${_toBengaliDigits(leagueConfig.minXp.toString())} - ${leagueConfig.maxXp != null ? _toBengaliDigits(leagueConfig.maxXp.toString()) : '∞'} XP)',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                              fontFamily: 'Li Ador Noirrit',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(leagueColor),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // XP to next tier text
                      Text(
                        nextLeague != null
                            ? 'আর ${_toBengaliDigits(neededXp.toString())} XP পেলেই ${nextLeague.name}!'
                            : '🌟 সর্বোচ্চ লিগ অর্জন করেছেন!',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : const Color(0xFF4B5563),
                          fontFamily: 'Li Ador Noirrit',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Horizontal League Filter Bar ---
  Widget _buildLeagueSelectorTabs({required bool isDark}) {
    final tabs = [
      {'id': 'ALL', 'name': 'সব শিক্ষার্থী', 'icon': '🌐'},
      ...defaultLeagues.map((l) => {'id': l.id, 'name': l.name, 'icon': l.icon}),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final tab = tabs[idx];
          final isSelected = _selectedLeague == tab['id'];
          final leagueMeta = tab['id'] != 'ALL' ? getLeagueConfig(tab['id']) : null;
          final tabColor = leagueMeta != null ? Color(leagueMeta.colorValue) : const Color(0xFF017A47);

          return GestureDetector(
            onTap: () => _onSelectLeague(tab['id']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? tabColor.withValues(alpha: isDark ? 0.25 : 0.15)
                    : (isDark ? const Color(0xFF141C17) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? tabColor
                      : (isDark ? const Color(0xFF222F26) : const Color(0xFFE5ECE8)),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tab['icon']!, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    tab['name']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.white : tabColor)
                          : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                      fontFamily: 'Li Ador Noirrit',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Top 3 Podium Showcase ---
  Widget _buildTopPodiumShowcase({
    required LeaderboardEntryModel top1,
    required LeaderboardEntryModel top2,
    required LeaderboardEntryModel top3,
    required String? myUserId,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            _selectedLeague == 'ALL'
              ? 'শীর্ষ ৩ স্থান অধিকারী'
              : '${getLeagueConfig(_selectedLeague).name} শীর্ষ ৩ স্থান অধিকারী',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFamily: 'Li Ador Noirrit',
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place (Silver)
              Expanded(
                child: _buildPodiumColumn(
                  entry: top2,
                  rank: 2,
                  medalColor: const Color(0xFF64748B),
                  avatarRadius: 23,
                  isMe: top2.userId == myUserId,
                  isDark: isDark,
                ),
              ),
              // 1st Place (Gold / Champion)
              Expanded(
                child: _buildPodiumColumn(
                  entry: top1,
                  rank: 1,
                  medalColor: const Color(0xFFD97706),
                  avatarRadius: 29,
                  isCenter: true,
                  isMe: top1.userId == myUserId,
                  isDark: isDark,
                ),
              ),
              // 3rd Place (Bronze)
              Expanded(
                child: _buildPodiumColumn(
                  entry: top3,
                  rank: 3,
                  medalColor: const Color(0xFFB45309),
                  avatarRadius: 23,
                  isMe: top3.userId == myUserId,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn({
    required LeaderboardEntryModel entry,
    required int rank,
    required Color medalColor,
    required double avatarRadius,
    bool isCenter = false,
    required bool isMe,
    required bool isDark,
  }) {
    const brandGreen = Color(0xFF017A47);
    final String avatar = (entry.avatarKey != null && entry.avatarKey!.isNotEmpty)
        ? entry.avatarKey!
        : 'https://api.dicebear.com/9.x/avataaars/svg?seed=${Uri.encodeComponent(entry.userId)}';

    final name = entry.fullName.isNotEmpty ? entry.fullName : entry.username;
    final leagueMeta = getLeagueConfig(entry.league);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar Stack with Medal Ring
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCenter ? const Color(0xFFD97706) : medalColor.withValues(alpha: 0.5),
                  width: isCenter ? 2.5 : 2,
                ),
              ),
              child: CustomAvatar(
                avatarUrl: avatar,
                radius: avatarRadius,
                backgroundColor: brandGreen.withValues(alpha: 0.1),
                fallbackWidget: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: brandGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: isCenter ? 18 : 14,
                  ),
                ),
              ),
            ),
            // Floating Rank Badge
            Positioned(
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: medalColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getRankBangla(rank),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Li Ador Noirrit',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // User Name
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isCenter ? 13 : 12,
            fontWeight: isMe ? FontWeight.w800 : FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontFamily: 'Li Ador Noirrit',
          ),
        ),
        const SizedBox(height: 2),

        // League Mini-Tag
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(leagueMeta.icon, style: const TextStyle(fontSize: 9)),
            const SizedBox(width: 2),
            Text(
              leagueMeta.name.replaceAll(' লীগ', ''),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: Color(leagueMeta.colorValue),
                fontFamily: 'Li Ador Noirrit',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Points
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: medalColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _formatPoints(entry.xp),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: medalColor,
              fontFamily: 'Li Ador Noirrit',
            ),
          ),
        ),
      ],
    );
  }

  // --- Regular Rank Tiles (Rank 4+) ---
  Widget _buildRankTile({
    required LeaderboardEntryModel entry,
    required bool isMe,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    const brandGreen = Color(0xFF017A47);
    final rank = entry.rank;
    final name = entry.fullName.isNotEmpty ? entry.fullName : entry.username;
    final batchName = entry.batch ?? entry.institution ?? 'শিক্ষার্থী';
    final leagueMeta = getLeagueConfig(entry.league);

    final String avatar = (entry.avatarKey != null && entry.avatarKey!.isNotEmpty)
        ? entry.avatarKey!
        : 'https://api.dicebear.com/9.x/avataaars/svg?seed=${Uri.encodeComponent(entry.userId)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
      decoration: BoxDecoration(
        color: isMe
            ? brandGreen.withValues(alpha: isDark ? 0.15 : 0.08)
            : cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? brandGreen.withValues(alpha: 0.35) : borderColor,
        ),
      ),
      child: Row(
        children: [
          // Rank Number Pill
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B261F) : const Color(0xFFF3F6F4),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _toBengaliDigits(rank.toString()),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white60 : const Color(0xFF4B5563),
                  fontFamily: 'Li Ador Noirrit',
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Custom Avatar
          CustomAvatar(
            avatarUrl: avatar,
            radius: 18,
            backgroundColor: brandGreen.withValues(alpha: 0.1),
            fallbackWidget: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: brandGreen,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name, Subtitle, and League Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isMe ? FontWeight.w800 : FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                          fontFamily: 'Li Ador Noirrit',
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: brandGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'তুমি',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'Li Ador Noirrit'),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      leagueMeta.icon,
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      leagueMeta.name,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(leagueMeta.colorValue),
                        fontFamily: 'Li Ador Noirrit',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '• $batchName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                          fontFamily: 'Li Ador Noirrit',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Points Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: brandGreen.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatPoints(entry.xp),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: brandGreen,
                fontFamily: 'Li Ador Noirrit',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Sticky Bottom Bar for Current User ---
  Widget _buildStickyUserBottomBar({
    required LeaderboardEntryModel me,
    required bool isDark,
    required Color borderColor,
  }) {
    const brandGreen = Color(0xFF017A47);
    final String meAvatar = (me.avatarKey != null && me.avatarKey!.isNotEmpty)
        ? me.avatarKey!
        : 'https://api.dicebear.com/9.x/avataaars/svg?seed=${Uri.encodeComponent(me.userId)}';
    final leagueMeta = getLeagueConfig(me.league);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C17) : Colors.white,
        border: Border(
          top: BorderSide(color: borderColor),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: 10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: brandGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              me.rank > 0 ? _getRankBangla(me.rank) : '--',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                fontFamily: 'Li Ador Noirrit',
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Avatar
          CustomAvatar(
            avatarUrl: meAvatar,
            radius: 18,
            backgroundColor: brandGreen.withValues(alpha: 0.1),
            fallbackWidget: Text(
              me.fullName.isNotEmpty ? me.fullName[0].toUpperCase() : 'U',
              style: const TextStyle(color: brandGreen, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        me.fullName.isNotEmpty ? me.fullName : 'তোমার প্রোফাইল',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                          fontFamily: 'Li Ador Noirrit',
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: brandGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'তুমি',
                        style: TextStyle(color: brandGreen, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Li Ador Noirrit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(leagueMeta.icon, style: const TextStyle(fontSize: 10)),
                    const SizedBox(width: 3),
                    Text(
                      leagueMeta.name,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(leagueMeta.colorValue),
                        fontFamily: 'Li Ador Noirrit',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Points Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: brandGreen.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatPoints(me.xp),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: brandGreen,
                fontFamily: 'Li Ador Noirrit',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- League Tiers Bottom Sheet Modal ---
  void _showLeagueInfoSheet(BuildContext context, bool isDark, int userXp) {
    final currentLeague = getLeagueConfigByXp(userXp);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141C17) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 24 + MediaQuery.of(ctx).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(
                        'প্রজ্ঞা লিগ সিস্টেম',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                          fontFamily: 'Li Ador Noirrit',
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              Text(
                'প্রশ্ন সমাধান ও পরীক্ষায় অংশ নিয়ে XP অর্জন করুন এবং উচ্চতর লিগে উন্নীত হোন!',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF4B5563),
                  fontFamily: 'Li Ador Noirrit',
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: defaultLeagues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (c, idx) {
                    final league = defaultLeagues[idx];
                    final isUserCurrentLeague = league.id == currentLeague.id;
                    final leagueColor = Color(league.colorValue);

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUserCurrentLeague
                            ? leagueColor.withValues(alpha: isDark ? 0.2 : 0.1)
                            : (isDark ? const Color(0xFF1C2720) : const Color(0xFFF9FAFB)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUserCurrentLeague
                              ? leagueColor
                              : (isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                          width: isUserCurrentLeague ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            league.asset,
                            width: 44,
                            height: 44,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Text(league.icon, style: const TextStyle(fontSize: 26)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      league.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF111827),
                                        fontFamily: 'Li Ador Noirrit',
                                      ),
                                    ),
                                    if (isUserCurrentLeague) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: leagueColor,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          '✓ বর্তমান লিগ',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontFamily: 'Li Ador Noirrit',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  league.maxXp != null
                                      ? 'প্রয়োজন: ${_toBengaliDigits(league.minXp.toString())} - ${_toBengaliDigits(league.maxXp.toString())} XP'
                                      : 'প্রয়োজন: ${_toBengaliDigits(league.minXp.toString())}+ XP (সর্বোচ্চ)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: leagueColor,
                                    fontFamily: 'Li Ador Noirrit',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Leaderboard Skeleton Loader ---
  Widget _buildLeaderboardSkeleton(bool isDark) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
      itemCount: 8,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141C17) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF222F26) : const Color(0xFFE5ECE8)),
          ),
          child: Row(
            children: [
              const ShimmerSkeleton(width: 28, height: 28, borderRadius: 14),
              const SizedBox(width: 12),
              const ShimmerSkeleton(width: 38, height: 38, borderRadius: 19),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerSkeleton(width: (index % 2 == 0 ? 120.0 : 90.0), height: 14, borderRadius: 4),
                    const SizedBox(height: 6),
                    const ShimmerSkeleton(width: 60, height: 10, borderRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const ShimmerSkeleton(width: 64, height: 24, borderRadius: 10),
            ],
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------
// UI Helper Widgets: Skeleton and Scale Interactions
// ----------------------------------------------------
class ShimmerSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1B261F) : const Color(0xFFE8EFEA);
    final highlightColor = isDark ? const Color(0xFF26382D) : const Color(0xFFF4F9F5);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.35, 0.5, 0.65],
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              transform: _SlidingGradientTransform(slidePercent: _animation.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
