import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'leaderboard_notifier.dart';
import '../../profile/presentation/profile_notifier.dart';
import '../domain/leaderboard_model.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../../core/widgets/custom_avatar.dart';
import '../../../core/widgets/custom_back_button.dart';

class LeagueInfo {
  final String key;
  final String title;
  final Color bgColor;
  final Color badgeColor;
  final String mainIcon;
  final bool isInfinity;

  const LeagueInfo({
    required this.key,
    required this.title,
    required this.bgColor,
    required this.badgeColor,
    required this.mainIcon,
    this.isInfinity = false,
  });
}

const List<LeagueInfo> leaguesList = [
  LeagueInfo(
    key: 'IRON',
    title: 'আয়রন লীগ',
    bgColor: Color(0xFFEBF1F6),
    badgeColor: Color(0xFF78909C),
    mainIcon: '🛡️',
  ),
  LeagueInfo(
    key: 'BRONZE',
    title: 'ব্রোঞ্জ লীগ',
    bgColor: Color(0xFFFFF3E0),
    badgeColor: Color(0xFFA1887F),
    mainIcon: '🥉',
  ),
  LeagueInfo(
    key: 'SILVER',
    title: 'সিলভার লীগ',
    bgColor: Color(0xFFF0F4F8),
    badgeColor: Color(0xFF90A4AE),
    mainIcon: '🥈',
  ),
  LeagueInfo(
    key: 'GOLD',
    title: 'গোল্ড লীগ',
    bgColor: Color(0xFFFFF8E1),
    badgeColor: Color(0xFFFFB74D),
    mainIcon: '🥇',
  ),
  LeagueInfo(
    key: 'DIAMOND',
    title: 'ডায়মন্ড লীগ',
    bgColor: Color(0xFFE0F7FA),
    badgeColor: Color(0xFF00BCD4),
    mainIcon: '💎',
  ),
  LeagueInfo(
    key: 'INFINITY',
    title: 'ইনফিনিটি লীগ',
    bgColor: Color(0xFFE8EAF6),
    badgeColor: Color(0xFF3F51B5),
    mainIcon: '♾️',
    isInfinity: true,
  ),
];

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  int _getLeagueIndex(String key) {
    final idx = leaguesList.indexWhere((l) => l.key.toUpperCase() == key.toUpperCase());
    return idx != -1 ? idx : 0;
  }

  String _formatPoints(int xp) {
    if (xp >= 1000) {
      final double val = xp / 1000.0;
      return '${val.toStringAsFixed(val % 1 == 0 ? 0 : 1)}K পয়েন্ট';
    } else if (xp > 0 && xp < 100) {
      final double val = xp.toDouble();
      return '${val.toStringAsFixed(1)} পয়েন্ট';
    }
    return '$xp পয়েন্ট';
  }

  Widget _buildScopeTab(WidgetRef ref, String scopeKey, String label, String activeScope) {
    final isSelected = activeScope == scopeKey;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(leaderboardScopeProvider.notifier).state = scopeKey;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF017A47) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF495057),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShieldBadge(LeagueInfo info, {bool isLarge = false}) {
    final double size = isLarge ? 72.0 : 44.0;
    final double iconSize = isLarge ? 40.0 : 22.0;

    if (info.isInfinity) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2979FF), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isLarge ? 22 : 14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2979FF).withOpacity(0.35),
              blurRadius: isLarge ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text('♾️', style: TextStyle(fontSize: iconSize)),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: info.badgeColor,
        borderRadius: BorderRadius.circular(isLarge ? 20 : 14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: isLarge ? 10 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(info.mainIcon, style: TextStyle(fontSize: iconSize)),
      ),
    );
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeScope = ref.watch(leaderboardScopeProvider);
    final activeLeagueKey = ref.watch(leaderboardLeagueProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider((scope: activeScope, league: activeLeagueKey)));
    final profileAsync = ref.watch(userProfileProvider);


    final profile = profileAsync.value?.profile;
    final myUserId = profileAsync.value?.id;
    final int userXp = profile?.xp ?? 0;

    String defaultLeagueKey = 'IRON';
    if (userXp >= 5000) {
      defaultLeagueKey = 'INFINITY';
    } else if (userXp >= 3000) {
      defaultLeagueKey = 'DIAMOND';
    } else if (userXp >= 1500) {
      defaultLeagueKey = 'GOLD';
    } else if (userXp >= 800) {
      defaultLeagueKey = 'SILVER';
    } else if (userXp >= 300) {
      defaultLeagueKey = 'BRONZE';
    }

    final isUserSelected = ref.watch(leaderboardLeagueSelectedByUserProvider);
    if (!isUserSelected && profile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(leaderboardLeagueProvider) != defaultLeagueKey) {
          ref.read(leaderboardLeagueProvider.notifier).state = defaultLeagueKey;
        }
      });
    }

    final int userLeagueIndex = _getLeagueIndex(profile?.league ?? defaultLeagueKey);
    final int currentSelectedLeagueIdx = _getLeagueIndex(activeLeagueKey);
    final LeagueInfo currentLeague = leaguesList[currentSelectedLeagueIdx];

    final bool isLocked = currentSelectedLeagueIdx > userLeagueIndex;

    final starPoints = profile != null ? (profile.xp % 100) : 0;
    final progressVal = profile != null ? (profile.xp % 100) / 100.0 : 0.01;

    final LeagueInfo? prevLeague = currentSelectedLeagueIdx > 0 ? leaguesList[currentSelectedLeagueIdx - 1] : null;
    final LeagueInfo? nextLeague = currentSelectedLeagueIdx < leaguesList.length - 1 ? leaguesList[currentSelectedLeagueIdx + 1] : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: currentLeague.bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: context.canPop()
            ? CustomBackButton(
                color: Colors.black87,
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text(
          'লিডারবোর্ড',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: leaderboardAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: currentLeague.badgeColor)),
        error: (err, stack) => Center(
          child: Text(
            'লিডারবোর্ড ডাটা লোড করা যায়নি: $err',
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        data: (rawEntries) {
          final List<LeaderboardEntryModel> entries = List.from(rawEntries);

          LeaderboardEntryModel? meEntry;
          if (myUserId != null) {
            final idx = entries.indexWhere((e) => e.userId == myUserId);
            if (idx != -1) {
              meEntry = entries[idx];
            } else if (profile != null) {
              meEntry = LeaderboardEntryModel(
                rank: 6137,
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

          return Column(
            children: [
              // 1. Dynamic Top Header Area (Matching Screenshots exactly)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                color: currentLeague.bgColor,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                child: Column(
                  children: [
                    // 3-Badge Carousel Row (Previous, Active Large Shield, Next)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (prevLeague != null)
                          GestureDetector(
                            onTap: () {
                              ref.read(leaderboardLeagueSelectedByUserProvider.notifier).state = true;
                              ref.read(leaderboardLeagueProvider.notifier).state = prevLeague.key;
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: _buildShieldBadge(prevLeague, isLarge: false),
                            ),
                          )
                        else
                          const SizedBox(width: 60),

                        // Active Large Shield
                        _buildShieldBadge(currentLeague, isLarge: true),

                        if (nextLeague != null)
                          GestureDetector(
                            onTap: () {
                              ref.read(leaderboardLeagueSelectedByUserProvider.notifier).state = true;
                              ref.read(leaderboardLeagueProvider.notifier).state = nextLeague.key;
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: _buildShieldBadge(nextLeague, isLarge: false),
                            ),
                          )
                        else
                          const SizedBox(width: 60),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // League Title in Bangla
                    Text(
                      currentLeague.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Locked Banner OR XP Progress Bar Capsule
                    if (isLocked)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'এই লীগ আনলক করতে পূর্ববর্তী লীগ গুলো কমপ্লিট করো',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else ...[
                      // XP Progress Capsule
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.amber.shade400, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  const Text('⭐', style: TextStyle(fontSize: 13)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$starPoints',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progressVal > 0 ? progressVal : 0.02,
                                    minHeight: 6,
                                    backgroundColor: const Color(0xFFECEFF1),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('0', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                            Text('100', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 2. Middle Leaderboard Player List
              Expanded(
                child: Stack(
                  children: [
                    RefreshIndicator(
                      color: const Color(0xFF017A47),
                      onRefresh: () async {
                        ref.invalidate(leaderboardProvider((scope: activeScope, league: activeLeagueKey)));
                        ref.invalidate(userProfileProvider);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final isMe = entry.userId == myUserId;

                          final String name = entry.fullName.isNotEmpty ? entry.fullName : entry.username;
                          final String avatar = (entry.avatarKey != null && entry.avatarKey!.isNotEmpty)
                              ? entry.avatarKey!
                              : 'https://api.dicebear.com/9.x/avataaars/svg?seed=${Uri.encodeComponent(entry.userId)}';

                          final bool showPro = (index % 2 == 1) || (name.length % 2 == 0);

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFFE2EBE4) : Colors.white,
                              border: isMe
                                  ? const Border(left: BorderSide(color: Color(0xFF017A47), width: 4))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                // Avatar image with status indicator dot
                                Stack(
                                  children: [
                                    CustomAvatar(
                                      avatarUrl: avatar,
                                      radius: 20,
                                      backgroundColor: isMe
                                          ? const Color(0xFF81C784)
                                          : const Color(0xFF017A47).withOpacity(0.12),
                                      fallbackWidget: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '👤',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isMe ? Colors.white : const Color(0xFF017A47),
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
                                          color: index % 2 == 0 ? const Color(0xFF4CAF50) : Colors.grey.shade400,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),

                                // Name & Pro Badge
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isMe ? FontWeight.w800 : FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (showPro) _buildProBadge(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Rank & Points Column
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${entry.rank}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      _formatPoints(entry.xp),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
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

                    // Floating Timer Pill (Bottom Right) matching screenshots exactly
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE8E8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '0d 23h 25m 47s',
                              style: TextStyle(
                                color: Color(0xFFD32F2F),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.info_outline, size: 16, color: Color(0xFFD32F2F)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Fixed Sticky Bottom Row for Active Current User
              if (meEntry != null)
                Builder(
                  builder: (context) {
                    final me = meEntry!;
                    final String meAvatar = (me.avatarKey != null && me.avatarKey!.isNotEmpty)
                        ? me.avatarKey!
                        : 'https://api.dicebear.com/9.x/avataaars/svg?seed=${Uri.encodeComponent(me.userId)}';
                    return Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2EBE4),
                        border: Border(
                          top: BorderSide(color: Color(0xFFC8E6C9), width: 1),
                          left: BorderSide(color: Color(0xFF017A47), width: 5),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          CustomAvatar(
                            avatarUrl: meAvatar,
                            radius: 22,
                            backgroundColor: const Color(0xFF81C784),
                            fallbackWidget: Text(
                              me.fullName.isNotEmpty ? me.fullName[0].toUpperCase() : '😎',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 14),

                          Expanded(
                            child: Text(
                              me.fullName.isNotEmpty ? me.fullName : 'Rabbi failure',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${me.rank} th',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                _formatPoints(me.xp),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                ),
            ],
          );
        },
      ),
    );
  }
}
