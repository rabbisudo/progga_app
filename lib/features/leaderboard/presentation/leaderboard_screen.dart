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

Color _getAvatarColor(String name) {
  final colors = [
    const Color(0xFF9333EA), // Purple
    const Color(0xFF0D9488), // Teal
    const Color(0xFFEA580C), // Orange
    const Color(0xFF16A34A), // Green
    const Color(0xFF2563EB), // Blue
    const Color(0xFF7C3AED), // Violet
    const Color(0xFFDB2777), // Pink
    const Color(0xFF0284C7), // Sky
    const Color(0xFFD97706), // Amber
  ];
  if (name.isEmpty) return colors[0];
  final hash = name.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
  return colors[hash % colors.length];
}

String _getInitials(String name) {
  if (name.trim().isEmpty) return 'U';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
    final first = parts[0].characters.first;
    final second = parts[1].characters.first;
    return '$first$second'.toUpperCase();
  }
  return name.trim().characters.first.toUpperCase();
}

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  static const int _pageSize = 50;

  final ScrollController _scrollController = ScrollController();
  late final PageController _pageController;
  final List<LeaderboardEntryModel> _entries = [];

  int _selectedLeagueIndex = 0;
  int _fetchVersion = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  Object? _error;
  bool _hasInitializedUserLeague = false;

  @override
  void initState() {
    super.initState();
    _selectedLeagueIndex = 0;
    _pageController = PageController(
      viewportFraction: 0.28,
      initialPage: _selectedLeagueIndex,
    );
    _scrollController.addListener(_onScroll);
    _fetchPage(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max > 100 && _scrollController.position.pixels >= max - 150) {
      _fetchPage();
    }
  }

  String get _selectedLeagueId => defaultLeagues[_selectedLeagueIndex].id;

  Future<void> _fetchPage({bool reset = false}) async {
    if (reset) {
      _fetchVersion++;
      setState(() {
        _isLoading = true;
        _error = null;
        _entries.clear();
        _offset = 0;
        _hasMore = true;
        _isLoadingMore = false;
      });
    } else {
      if (_isLoading || _isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    final currentVersion = _fetchVersion;
    final leagueId = _selectedLeagueId;

    try {
      final repo = ref.read(leaderboardRepositoryProvider);
      final newEntries = await repo.fetchLeaderboard(
        scope: 'global',
        league: leagueId,
        limit: _pageSize,
        offset: reset ? 0 : _offset,
      );

      if (!mounted || currentVersion != _fetchVersion) return;

      setState(() {
        if (reset) {
          _entries.clear();
          _entries.addAll(newEntries);
          _offset = newEntries.length;
        } else {
          // Strict deduplication by userId
          final existingIds = _entries.map((e) => e.userId).toSet();
          for (final item in newEntries) {
            if (!existingIds.contains(item.userId)) {
              _entries.add(item);
              existingIds.add(item.userId);
            }
          }
          _offset += newEntries.length;
        }
        _hasMore = newEntries.length >= _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted || currentVersion != _fetchVersion) return;
      setState(() {
        _error = e;
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onSelectLeagueIndex(int index) {
    if (_selectedLeagueIndex == index) return;
    setState(() {
      _selectedLeagueIndex = index;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    _fetchPage(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1014) : const Color(0xFFF6F8F7);
    final cardBg = isDark ? const Color(0xFF16171B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF26282E) : const Color(0xFFE5ECE8);
    const brandGreen = Color(0xFF017A47);

    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value?.profile;
    final myUserId = profileAsync.value?.id;
    final userXp = profile?.xp ?? 0;

    // Auto-select user's current league on initial load
    if (!_hasInitializedUserLeague && profile != null) {
      _hasInitializedUserLeague = true;
      final userLeague = getLeagueConfigByXp(userXp);
      final initialIndex = defaultLeagues.indexWhere((l) => l.id == userLeague.id);
      if (initialIndex != -1 && initialIndex != _selectedLeagueIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _onSelectLeagueIndex(initialIndex);
          }
        });
      }
    }

    final selectedLeague = defaultLeagues[_selectedLeagueIndex];

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
      ),
      body: RefreshIndicator(
        color: brandGreen,
        onRefresh: () => _fetchPage(reset: true),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. TOP LEAGUE SHOWCASE CAROUSEL (Dynamic Ambient Glow & Adaptive Theme)
              _buildLeagueShowcaseCard(
                selectedLeague: selectedLeague,
                userXp: userXp,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
              ),

              const SizedBox(height: 16),

              // 2. LEAGUE MEMBERS RANKINGS CARD
              _buildLeagueMembersCard(
                selectedLeague: selectedLeague,
                myUserId: myUserId,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. TOP LEAGUE CAROUSEL SHOWCASE (Clean & Crisp Modern Card)
  // ===========================================================================
  Widget _buildLeagueShowcaseCard({
    required LeagueConfigModel selectedLeague,
    required int userXp,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    final userCurrentLeague = getLeagueConfigByXp(userXp);
    final userLeagueIdx = defaultLeagues.indexWhere((l) => l.id == userCurrentLeague.id);
    final isCurrentActiveLeague = _selectedLeagueIndex == userLeagueIdx;
    final isLockedLeague = userXp < selectedLeague.minXp;
    final isCompletedLeague = userXp > (selectedLeague.maxXp ?? 99999999);
    final leagueColor = Color(selectedLeague.colorValue);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF26282E) : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Horizontal Badge Carousel (Clean & Crisp, No Muddy Shadows)
          SizedBox(
            height: 94,
            child: PageView.builder(
              controller: _pageController,
              itemCount: defaultLeagues.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                if (_selectedLeagueIndex != index) {
                  setState(() {
                    _selectedLeagueIndex = index;
                  });
                  _fetchPage(reset: true);
                }
              },
              itemBuilder: (context, index) {
                final league = defaultLeagues[index];
                final isSelected = index == _selectedLeagueIndex;

                return GestureDetector(
                  onTap: () => _onSelectLeagueIndex(index),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: isSelected ? 76 : 46,
                      height: isSelected ? 76 : 46,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isSelected ? 1.0 : 0.40,
                        child: Center(
                          child: Image.asset(
                            league.asset,
                            width: isSelected ? 74 : 44,
                            height: isSelected ? 74 : 44,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Text(
                              league.icon,
                              style: TextStyle(fontSize: isSelected ? 36 : 22),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // League Title Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5.5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E212B) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  selectedLeague.asset,
                  width: 17,
                  height: 17,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.shield_rounded,
                    size: 14,
                    color: leagueColor,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  selectedLeague.name,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    fontFamily: 'Li Ador Noirrit',
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Dynamic Status / Progress Bar
          if (isCurrentActiveLeague) ...[
            // Current Active League Progress Slider Bar
            _buildActiveLeagueProgressBar(
              selectedLeague: selectedLeague,
              userXp: userXp,
              isDark: isDark,
              leagueColor: leagueColor,
            ),
          ] else if (isLockedLeague) ...[
            // Locked League State
            _buildLockedLeagueStatus(
              selectedLeague: selectedLeague,
              isDark: isDark,
              leagueColor: leagueColor,
            ),
          ] else if (isCompletedLeague) ...[
            // Completed League State
            _buildCompletedLeagueStatus(
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  // --- Active League Progress Slider Bar ---
  Widget _buildActiveLeagueProgressBar({
    required LeagueConfigModel selectedLeague,
    required int userXp,
    required bool isDark,
    required Color leagueColor,
  }) {
    final minXp = selectedLeague.minXp;
    final maxXp = selectedLeague.maxXp ?? (minXp + 5000);
    final totalRange = (maxXp - minXp).toDouble();
    final double progress = totalRange > 0
        ? ((userXp - minXp) / totalRange).clamp(0.0, 1.0)
        : 1.0;

    final remaining = selectedLeague.maxXp != null
        ? ((selectedLeague.maxXp! + 1) - userXp).clamp(0, 99999999)
        : 0;

    return Column(
      children: [
        // Range text indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_toBengaliDigits(minXp.toString())} পয়েন্ট',
              style: TextStyle(
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                fontSize: 11.5,
                fontFamily: 'Li Ador Noirrit',
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${selectedLeague.maxXp != null ? _toBengaliDigits(selectedLeague.maxXp.toString()) : '∞'} পয়েন্ট',
              style: TextStyle(
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                fontSize: 11.5,
                fontFamily: 'Li Ador Noirrit',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Custom Slider Track with Floating Indicator Pill
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            const markerWidth = 66.0;
            final double leftOffset = ((trackWidth - markerWidth) * progress).clamp(0.0, trackWidth - markerWidth);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Base background track
                Container(
                  height: 7,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262933) : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                // Filled progress track
                Positioned(
                  left: 0,
                  top: 8,
                  child: Container(
                    height: 7,
                    width: trackWidth * progress,
                    decoration: BoxDecoration(
                      color: leagueColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                // Floating user points marker badge
                Positioned(
                  left: leftOffset,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E212B) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: leagueColor, width: 1.5),
                    ),
                    child: Text(
                      '${_toBengaliDigits(userXp.toString())} পয়েন্ট',
                      style: TextStyle(
                        color: leagueColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Li Ador Noirrit',
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Helper text below progress bar
        if (selectedLeague.maxXp != null && remaining > 0) ...[
          const SizedBox(height: 8),
          Text(
            'পরবর্তী লিগে পৌঁছাতে আর মাত্র ${_toBengaliDigits(remaining.toString())} পয়েন্ট প্রয়োজন 🚀',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
              fontSize: 11.5,
              fontFamily: 'Li Ador Noirrit',
              fontWeight: FontWeight.w500,
            ),
          ),
        ] else if (selectedLeague.maxXp == null) ...[
          const SizedBox(height: 8),
          Text(
            'আপনি সর্বোচ্চ লিগে অবস্থান করছেন! 🏆',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.amberAccent : const Color(0xFFD97706),
              fontSize: 12,
              fontFamily: 'Li Ador Noirrit',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  // --- Locked League Status Bar ---
  Widget _buildLockedLeagueStatus({
    required LeagueConfigModel selectedLeague,
    required bool isDark,
    required Color leagueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1E26).withValues(alpha: 0.8)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_rounded,
            size: 16,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'এই লীগে প্রবেশ করতে পয়েন্ট অর্জন করো',
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF475569),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Li Ador Noirrit',
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: leagueColor.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_toBengaliDigits(selectedLeague.minXp.toString())} পয়েন্ট দরকার',
              style: TextStyle(
                color: leagueColor,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                fontFamily: 'Li Ador Noirrit',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Completed League Status Bar ---
  Widget _buildCompletedLeagueStatus({
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 17,
            color: Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'এই লীগ সফলভাবে সম্পন্ন করেছেন',
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF065F46),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Li Ador Noirrit',
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'উত্তীর্ণ ✓',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                fontFamily: 'Li Ador Noirrit',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. LEAGUE MEMBERS RANKINGS CARD (Matching Image 2)
  // ===========================================================================
  Widget _buildLeagueMembersCard({
    required LeagueConfigModel selectedLeague,
    required String? myUserId,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar: [👥 ব্রোঞ্জ লীগ সদস্যরা] ------- [১৬৪ জন]
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.people_alt_rounded,
                      size: 18,
                      color: isDark ? Colors.white70 : const Color(0xFF1F2937),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${selectedLeague.name} সদস্যরা',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        fontFamily: 'Li Ador Noirrit',
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2315) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_toBengaliDigits(_entries.length.toString())} জন',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD97706),
                      fontFamily: 'Li Ador Noirrit',
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: borderColor),

          // Content: Loading Skeleton, Error State, Empty State, or Ranked Members
          if (_isLoading)
            _buildListSkeleton(isDark)
          else if (_error != null && _entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              child: Column(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    'সদস্যদের তালিকা লোড করা সম্ভব হয়নি',
                    style: TextStyle(
                      fontFamily: 'Li Ador Noirrit',
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _fetchPage(reset: true),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF017A47).withValues(alpha: 0.1),
                      foregroundColor: const Color(0xFF017A47),
                    ),
                    child: const Text('পুনরায় চেষ্টা করুন', style: TextStyle(fontFamily: 'Li Ador Noirrit')),
                  ),
                ],
              ),
            )
          else if (_entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Center(
                child: Column(
                  children: [
                    Image.asset(
                      selectedLeague.asset,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Text('🏆', style: TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${selectedLeague.name}-এ এখনো কোনো শিক্ষার্থী নেই',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                        fontFamily: 'Li Ador Noirrit',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _entries.length + (_isLoadingMore ? 1 : 0),
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 0.8,
                color: borderColor.withValues(alpha: 0.5),
                indent: 64,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                if (index == _entries.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF017A47), strokeWidth: 2),
                    ),
                  );
                }

                final entry = _entries[index];
                final isMe = entry.userId == myUserId;

                return _buildMemberTile(
                  entry: entry,
                  isMe: isMe,
                  isDark: isDark,
                );
              },
            ),
        ],
      ),
    );
  }

  // --- Single Member Row (Matching Image 2) ---
  Widget _buildMemberTile({
    required LeaderboardEntryModel entry,
    required bool isMe,
    required bool isDark,
  }) {
    final name = entry.fullName.isNotEmpty ? entry.fullName : entry.username;
    final initials = _getInitials(name);
    final avatarColor = _getAvatarColor(entry.userId.isNotEmpty ? entry.userId : name);
    final rank = entry.rank;

    return Container(
      color: isMe
          ? const Color(0xFF017A47).withValues(alpha: isDark ? 0.12 : 0.06)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Round Avatar with deterministic background & letters (or CustomAvatar)
          if (entry.avatarKey != null && entry.avatarKey!.isNotEmpty)
            CustomAvatar(
              avatarUrl: entry.avatarKey!,
              radius: 19,
              backgroundColor: avatarColor,
              fallbackWidget: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            )
          else
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

          const SizedBox(width: 14),

          // User Name
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isMe ? FontWeight.w800 : FontWeight.w700,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontFamily: 'Li Ador Noirrit',
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Rank Number & Points (Aligned Right, matching Image 2)
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
                '${_toBengaliDigits(entry.xp.toString())} পয়েন্ট',
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
    );
  }

  // --- List Skeleton Loader ---
  Widget _buildListSkeleton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
                Container(
                  width: 44,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
