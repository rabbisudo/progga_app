import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'leaderboard_notifier.dart';
import '../../profile/presentation/profile_notifier.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final profileAsync = ref.watch(userProfileProvider);

    // Resolve current user ID to highlight row
    final currentUserId = profileAsync.maybeWhen(
      data: (user) => user.id,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Global Leaderboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFF18881))),
        error: (err, stack) => Center(child: Text('Error loading leaderboards: $err', style: const TextStyle(color: Colors.white60))),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('Leaderboard is empty. Be the first to join!', style: TextStyle(color: Colors.white60)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isCurrentUser = entry.userId == currentUserId;
              
              // Top 3 ranks styling markers
              Color? rankColor;
              if (entry.rank == 1) {
                rankColor = Colors.amber;
              } else if (entry.rank == 2) {
                rankColor = const Color(0xFFC0C0C0); // Silver
              } else if (entry.rank == 3) {
                rankColor = const Color(0xFFCD7F32); // Bronze
              }

              return Card(
                color: isCurrentUser ? const Color(0xFF2C1E1D) : const Color(0xFF1E1E1E),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isCurrentUser ? Theme.of(context).primaryColor : Colors.white12,
                    width: isCurrentUser ? 2.0 : 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Rank position
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: rankColor?.withOpacity(0.2) ?? Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '#${entry.rank}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: rankColor ?? Colors.white70,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white10,
                        backgroundImage: entry.avatarKey != null ? NetworkImage(entry.avatarKey!) : null,
                        child: entry.avatarKey == null 
                            ? const Icon(Icons.person, size: 20, color: Colors.white70) 
                            : null,
                      ),
                      const SizedBox(width: 16),

                      // Profile Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.fullName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                                color: isCurrentUser ? Theme.of(context).primaryColor : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Level ${entry.level} • ${entry.league} League',
                              style: const TextStyle(fontSize: 11, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),

                      // Score Metric (XP)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${entry.xp} XP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isCurrentUser ? Theme.of(context).primaryColor : Colors.white,
                            ),
                          ),
                          Text(
                            '${entry.solvedQuestionsCount} Solved',
                            style: const TextStyle(fontSize: 10, color: Colors.white30),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
