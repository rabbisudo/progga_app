import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/leaderboard_repository.dart';
import '../domain/leaderboard_model.dart';

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntryModel>, String>((ref, scope) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.fetchLeaderboard(scope: scope);
});

final myLeaderboardProvider = FutureProvider<List<LeaderboardEntryModel>>((ref) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.fetchLeaderboardAroundMe();
});

final leaguesConfigProvider = FutureProvider<List<LeagueConfigModel>>((ref) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.fetchLeaguesConfig();
});
