import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/leaderboard_repository.dart';
import '../domain/leaderboard_model.dart';
import '../../../core/storage/hive_service.dart';

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntryModel>, String>((ref, scope) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.fetchLeaderboard(scope: scope);
});

final myLeaderboardProvider = FutureProvider<List<LeaderboardEntryModel>>((ref) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  final hive = ref.read(hiveServiceProvider);
  try {
    final data = await repo.fetchLeaderboardAroundMe();
    final jsonList = data.map((e) => e.toJson()).toList();
    await hive.cacheList('cached_my_leaderboard', jsonList);
    return data;
  } catch (e) {
    final cached = hive.getCachedList('cached_my_leaderboard');
    if (cached != null) {
      return cached.map((e) => LeaderboardEntryModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    rethrow;
  }
});

final leaguesConfigProvider = FutureProvider<List<LeagueConfigModel>>((ref) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.fetchLeaguesConfig();
});
