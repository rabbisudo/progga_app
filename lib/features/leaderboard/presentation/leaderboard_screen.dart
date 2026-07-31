import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'leaderboard_notifier.dart';
import '../../profile/presentation/profile_notifier.dart';
import '../domain/leaderboard_model.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_notifier.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final profileAsync = ref.watch(userProfileProvider);

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

    final profile = profileAsync.value?.profile;
    final myUserId = profileAsync.value?.id;

    // Determine current league name in Bangla
    String leagueName = 'আয়রন';
    if (profile != null) {
      switch (profile.league.toUpperCase()) {
        case 'BRONZE':
          leagueName = 'ব্রোঞ্জ';
          break;
        case 'SILVER':
          leagueName = 'সিলভার';
          break;
        case 'GOLD':
          leagueName = 'গোল্ড';
          break;
        case 'PLATINUM':
          leagueName = 'প্লাটিনাম';
          break;
        default:
          leagueName = 'আয়রন';
          break;
      }
    }

    final starPoints = profile != null ? (profile.xp % 100) : 0;
    final progressVal = profile != null ? (profile.xp % 100) / 100.0 : 0.01;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEBF1F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 18),
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
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF017A47))),
        error: (err, stack) => Center(
          child: Text(
            'লিডারবোর্ড ডাটা লোড করা যায়নি: $err',
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        data: (rawEntries) {
          // Format entries and identify current user
          final List<LeaderboardEntryModel> entries = List.from(rawEntries);

          // Find current user item in global entries list
          LeaderboardEntryModel? meEntry;
          if (myUserId != null) {
            final idx = entries.indexWhere((e) => e.userId == myUserId);
            if (idx != -1) {
              meEntry = entries[idx];
            } else if (profile != null) {
              meEntry = LeaderboardEntryModel(
                rank: 6099,
                userId: myUserId,
                username: profile.fullName,
                fullName: profile.fullName,
                xp: profile.xp,
                level: profile.level,
                solvedQuestionsCount: profile.solvedQuestionsCount,
                league: profile.league,
              );
            }
          }

          return Column(
            children: [
              // 1. Top Header Area matching screenshot (Light Blue/Grey Header)
              Container(
                width: double.infinity,
                color: const Color(0xFFEBF1F6),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  children: [
                    // League Icons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Active Main League Shield
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: const Color(0xFF78909C),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🛡️', style: TextStyle(fontSize: 38)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Smaller Next League Badge
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFA1887F),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🥉', style: TextStyle(fontSize: 22)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // League Title in Bangla
                    Text(
                      leagueName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // XP Progress Bar Capsule
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        children: [
                          // Left Star XP Points Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.amber.shade300, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Text('⭐', style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
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
                          // Linear progress track
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
                          Text('0', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                          Text('100', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Middle Leaderboard Player List (Clean White List with Floating Timer)
              Expanded(
                child: Stack(
                  children: [
                    RefreshIndicator(
                      color: const Color(0xFF017A47),
                      onRefresh: () async {
                        ref.invalidate(leaderboardProvider);
                        ref.invalidate(userProfileProvider);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final isMe = entry.userId == myUserId;

                          final String name = entry.fullName.isNotEmpty ? entry.fullName : entry.username;
                          final String? avatar = entry.avatarKey;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: isMe
                                          ? const Color(0xFF81C784)
                                          : const Color(0xFF017A47).withOpacity(0.12),
                                      backgroundImage: avatar != null && avatar.isNotEmpty
                                          ? NetworkImage(avatar)
                                          : null,
                                      child: (avatar == null || avatar.isEmpty)
                                          ? Text(
                                              name.isNotEmpty ? name[0].toUpperCase() : '👤',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isMe ? Colors.white : const Color(0xFF017A47),
                                              ),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: index % 2 == 1 ? const Color(0xFF4CAF50) : Colors.grey.shade400,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),

                                // Name
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isMe ? FontWeight.w800 : FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (index == 1) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade700,
                                            borderRadius: BorderRadius.circular(4),
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
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Rank & Points Column
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${entry.rank}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '${(entry.xp / 10.0).toStringAsFixed(1)} পয়েন্ট',
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
                        },
                      ),
                    ),

                    // Floating Timer Pill (Bottom Right) matching screenshot
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
                              '1d 01h 57m 27s',
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

              // 3. Fixed Sticky Bottom Row for Active Current User (Green Highlighted Bar)
              if (meEntry != null)
                Container(
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
                      // Avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF81C784),
                        backgroundImage: meEntry.avatarKey != null && meEntry.avatarKey!.isNotEmpty
                            ? NetworkImage(meEntry.avatarKey!)
                            : null,
                        child: (meEntry.avatarKey == null || meEntry.avatarKey!.isEmpty)
                            ? Text(
                                meEntry.fullName.isNotEmpty ? meEntry.fullName[0].toUpperCase() : '😎',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),

                      // Name
                      Expanded(
                        child: Text(
                          meEntry.fullName.isNotEmpty ? meEntry.fullName : 'Rabbi failure',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      // Rank ordinal suffix & XP points
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${meEntry.rank} th',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${meEntry.xp} পয়েন্ট',
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
                ),
            ],
          );
        },
      ),
    );
  }
}


