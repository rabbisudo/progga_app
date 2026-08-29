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
  final cached = hive.getCachedList('cached_my_leaderboard');
  List<LeaderboardEntryModel>? cachedList;
  if (cached != null && cached.isNotEmpty) {
    try {
      cachedList = cached.map((e) => LeaderboardEntryModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {}
  }

  // Background fetch
  final fetchFuture = repo.fetchLeaderboardAroundMe().then((data) async {
    final jsonList = data.map((e) => e.toJson()).toList();
    await hive.cacheList('cached_my_leaderboard', jsonList);
    return data;
  }).catchError((_) => cachedList ?? <LeaderboardEntryModel>[]);

  if (cachedList != null && cachedList.isNotEmpty) {
    fetchFuture.ignore();
    return cachedList;
  }

  return fetchFuture;
});

final leaguesConfigProvider = FutureProvider<List<LeagueConfigModel>>((ref) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.fetchLeaguesConfig();
});
