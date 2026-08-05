import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'leaderboard_notifier.dart';
import '../../profile/presentation/profile_notifier.dart';
import '../domain/leaderboard_model.dart';
import '../../../core/widgets/custom_avatar.dart';
import '../../../core/widgets/custom_back_button.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

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

  Widget _buildPremiumTabBar(
    BuildContext context,
    WidgetRef ref,
    List<({String key, String label})> availableScopes,
    String activeScope,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: availableScopes.map((scope) {
          final isSelected = activeScope == scope.key;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(leaderboardScopeProvider.notifier).state = scope.key;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    scope.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    final activeScope = ref.watch(leaderboardScopeProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider(activeScope));
    final profileAsync = ref.watch(userProfileProvider);

    final profile = profileAsync.value?.profile;
    final myUserId = profileAsync.value?.id;

    // Build the dynamic scope list based on available profile information
    final List<({String key, String label})> availableScopes = [
      (key: 'global', label: 'সারা দেশ'),
    ];

    if (profile != null) {
      if (profile.batch != null && profile.batch!.isNotEmpty) {
        availableScopes.add((key: 'batch', label: profile.batch!));
      } else if (profile.batchId != null && profile.batchId!.isNotEmpty) {
        availableScopes.add((key: 'batch', label: 'আমার ব্যাচ'));
      }

      if (profile.className != null && profile.className!.isNotEmpty) {
        availableScopes.add((key: 'class', label: profile.className!));
      } else if (profile.classId != null && profile.classId!.isNotEmpty) {
        availableScopes.add((key: 'class', label: 'আমার শ্রেণী'));
      }

      if (profile.targetExam != null && profile.targetExam!.isNotEmpty) {
        availableScopes.add((key: 'group', label: profile.targetExam!));
      } else if (profile.groupId != null && profile.groupId!.isNotEmpty) {
        availableScopes.add((key: 'group', label: 'আমার গ্রুপ'));
      }
    }

    // Fallback if activeScope is not in availableScopes
    final isValidScope = availableScopes.any((s) => s.key == activeScope);
    if (!isValidScope && availableScopes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(leaderboardScopeProvider.notifier).state = availableScopes.first.key;
      });
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
          _buildPremiumTabBar(context, ref, availableScopes, activeScope),
          Expanded(
            child: leaderboardAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
              error: (err, stack) => Center(
                child: Text(
                  'লিডারবোর্ড ডাটা লোড করা যায়নি: $err',
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
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
                      rank: 0, // Will show details without rank if not in top list
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
                    Expanded(
                      child: RefreshIndicator(
                        color: primaryColor,
                        onRefresh: () async {
                          ref.invalidate(leaderboardProvider(activeScope));
                          ref.invalidate(userProfileProvider);
                        },
                        child: entries.isEmpty
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
                                padding: const EdgeInsets.only(bottom: 20),
                                itemCount: entries.length,
                                itemBuilder: (context, index) {
                                  final entry = entries[index];
                                  final isMe = entry.userId == myUserId;

                                  final String name = entry.fullName.isNotEmpty
                                      ? entry.fullName
                                      : entry.username;
                                  final String avatar = (entry.avatarKey != null &&
                                          entry.avatarKey!.isNotEmpty)
                                      ? entry.avatarKey!
                                      : 'https://api.dicebear.com/9.x/avataaars/svg?seed=${Uri.encodeComponent(entry.userId)}';

                                  final bool showPro = (index % 2 == 1) || (name.length % 2 == 0);

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? primaryColor.withOpacity(isDark ? 0.2 : 0.1)
                                          : Colors.transparent,
                                      border: isMe
                                          ? Border(
                                              left: BorderSide(
                                                color: primaryColor,
                                                width: 4,
                                              ),
                                            )
                                          : Border(
                                              bottom: BorderSide(
                                                color: isDark ? Colors.white10 : Colors.grey.shade100,
                                                width: 1,
                                              ),
                                            ),
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
                                                  ? primaryColor.withOpacity(0.3)
                                                  : primaryColor.withOpacity(0.12),
                                              fallbackWidget: Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : '👤',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryColor,
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
                                                    color: isDark ? const Color(0xFF121212) : Colors.white,
                                                    width: 1.5,
                                                  ),
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
                                                    color: isDark ? Colors.white : Colors.black87,
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
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w900,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              _formatPoints(entry.xp),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white70 : Colors.black87,
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

                    // 3. Fixed Sticky Bottom Row for Active Current User
                    if (meEntry != null)
                      Builder(
                        builder: (context) {
                          final me = meEntry!;
                          final String meAvatar = (me.avatarKey != null && me.avatarKey!.isNotEmpty)
                              ? me.avatarKey!
                              : 'https://api.dicebear.com/9.x/avataaars/svg?seed=${Uri.encodeComponent(me.userId)}';
                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                                left: BorderSide(
                                  color: primaryColor,
                                  width: 5,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                CustomAvatar(
                                  avatarUrl: meAvatar,
                                  radius: 22,
                                  backgroundColor: primaryColor.withOpacity(0.2),
                                  fallbackWidget: Text(
                                    me.fullName.isNotEmpty ? me.fullName[0].toUpperCase() : '😎',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
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
                                      fontSize: 15,
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      _formatPoints(me.xp),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
