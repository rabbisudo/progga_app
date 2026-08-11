import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../profile/presentation/profile_notifier.dart';
import '../data/leaderboard_repository.dart';
import '../domain/leaderboard_model.dart';
import '../../../core/widgets/custom_avatar.dart';
import '../../../core/widgets/custom_back_button.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  static const int _pageSize = 30;

  final ScrollController _scrollController = ScrollController();
  final List<LeaderboardEntryModel> _entries = [];

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

  String _formatPoints(int xp) {
    if (xp >= 1000) {
      final double val = xp / 1000.0;
      return '${val.toStringAsFixed(val % 1 == 0 ? 0 : 1)}K পয়েন্ট';
    } else if (xp > 0 && xp < 100) {
      final double val = xp.toDouble();
      return '${val.toStringAsFixed(1)} পয়েন্ট';
    }
    return '$xp পয়েন্ট';
  }

  Widget _buildProBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 5),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF29B6F6), Color(0xFF0288D1)],
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text(
        'P',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              const ShimmerSkeleton(
                width: 40,
                height: 40,
                borderRadius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerSkeleton(
                      width: 120,
                      height: 16,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 6),
                    ShimmerSkeleton(
                      width: index % 2 == 0 ? 80 : 50,
                      height: 12,
                      borderRadius: 3,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const ShimmerSkeleton(
                    width: 24,
                    height: 16,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 6),
                  const ShimmerSkeleton(
                    width: 60,
                    height: 12,
                    borderRadius: 3,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greenAccentColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF017A47);
    final greenBgColor = isDark ? const Color(0xFF1B3B2B) : const Color(0xFFE2EBE4);

    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value?.profile;
    final myUserId = profileAsync.value?.id;

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
          xp: profile.xp,
          level: profile.level,
          solvedQuestionsCount: profile.solvedQuestionsCount,
          league: profile.league,
          currentStreak: profile.currentStreak,
        );
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: context.canPop()
            ? CustomBackButton(
                color: isDark ? Colors.white : Colors.black87,
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(
          'লিডারবোর্ড',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? _buildSkeletonLoader(context)
                : _error != null && _entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'লিডারবোর্ড লোড করা যায়নি',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _fetchPage(reset: true),
                              child: const Text('আবার চেষ্টা করুন'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: greenAccentColor,
                        onRefresh: () => _fetchPage(reset: true),
                        child: _entries.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.4,
                                    child: Center(
                                      child: Text(
                                        'লিডারবোর্ডে কোনো শিক্ষার্থী নেই',
                                        style: TextStyle(
                                          color: isDark ? Colors.white54 : Colors.black54,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 12),
                                itemCount: _entries.length + (_isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  // Loading spinner at bottom
                                  if (index == _entries.length) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: greenAccentColor,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  final entry = _entries[index];
                                  final isMe = entry.userId == myUserId;
                                  final int rank = entry.rank;
                                  
                                  // Distinct colors & indicators for Top 3
                                  Color rowBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
                                  Widget rankIcon = Text(
                                    '$rank',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  );

                                  if (rank == 1) {
                                    rowBg = isDark ? const Color(0xFF2D291E) : const Color(0xFFFFFDE7);
                                    rankIcon = const Text('🥇', style: TextStyle(fontSize: 24));
                                  } else if (rank == 2) {
                                    rowBg = isDark ? const Color(0xFF242526) : const Color(0xFFF5F6F7);
                                    rankIcon = const Text('🥈', style: TextStyle(fontSize: 24));
                                  } else if (rank == 3) {
                                    rowBg = isDark ? const Color(0xFF26211E) : const Color(0xFFFAF2EC);
                                    rankIcon = const Text('🥉', style: TextStyle(fontSize: 24));
                                  } else if (isMe) {
                                    rowBg = greenBgColor;
                                  }

                                  final String name = entry.fullName.isNotEmpty
                                      ? entry.fullName
                                      : entry.username;
                                  final String avatar = (entry.avatarKey != null &&
                                          entry.avatarKey!.isNotEmpty)
                                      ? entry.avatarKey!
                                      : 'https://api.dicebear.com/9.x/avataaars/svg?seed=${Uri.encodeComponent(entry.userId)}';
                                  final bool showPro = false;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: rowBg,
                                      border: isMe
                                          ? Border(
                                              left: BorderSide(
                                                color: greenAccentColor,
                                                width: 4,
                                              ),
                                              bottom: BorderSide(
                                                color: isDark
                                                    ? Colors.white10
                                                    : Colors.grey.shade100,
                                                width: 1,
                                              ),
                                            )
                                          : Border(
                                              bottom: BorderSide(
                                                color: isDark
                                                    ? Colors.white10
                                                    : Colors.grey.shade100,
                                                width: 1,
                                              ),
                                            ),
                                    ),
                                    child: Row(
                                      children: [
                                        Stack(
                                          children: [
                                            CustomAvatar(
                                              avatarUrl: avatar,
                                              radius: 20,
                                              backgroundColor: isMe
                                                  ? greenAccentColor.withOpacity(0.3)
                                                  : greenAccentColor.withOpacity(0.12),
                                              fallbackWidget: Text(
                                                name.isNotEmpty
                                                    ? name[0].toUpperCase()
                                                    : '👤',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: greenAccentColor,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                width: 9,
                                                height: 9,
                                                decoration: BoxDecoration(
                                                  color: index % 2 == 0
                                                      ? const Color(0xFF4CAF50)
                                                      : Colors.grey.shade400,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isDark
                                                        ? const Color(0xFF121212)
                                                        : Colors.white,
                                                    width: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: isMe || rank <= 3
                                                        ? FontWeight.w800
                                                        : FontWeight.w700,
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              if (showPro) _buildProBadge(),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            rankIcon,
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatPoints(entry.xp),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
          ),

          // Sticky bottom row for current user
          if (meEntry != null)
            Builder(builder: (context) {
              final me = meEntry!;
              final String meAvatar = (me.avatarKey != null && me.avatarKey!.isNotEmpty)
                  ? me.avatarKey!
                  : 'https://api.dicebear.com/9.x/avataaars/svg?seed=${Uri.encodeComponent(me.userId)}';
              return Container(
                decoration: BoxDecoration(
                  color: greenBgColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                      width: 1,
                    ),
                    left: BorderSide(color: greenAccentColor, width: 5),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: 12 + MediaQuery.of(context).padding.bottom + 8,
                ),
                child: Row(
                  children: [
                    CustomAvatar(
                      avatarUrl: meAvatar,
                      radius: 22,
                      backgroundColor: greenAccentColor.withOpacity(0.2),
                      fallbackWidget: Text(
                        me.fullName.isNotEmpty ? me.fullName[0].toUpperCase() : '😎',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: greenAccentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        me.fullName.isNotEmpty ? me.fullName : 'আপনার প্রোফাইল',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          me.rank > 0 ? '${me.rank} th' : '--',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          _formatPoints(me.xp),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
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
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

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
