import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/leaderboard_repository.dart';
import '../domain/leaderboard_model.dart';

final leaderboardScopeProvider = StateProvider<String>((ref) => 'global');
final leaderboardLeagueProvider = StateProvider<String>((ref) => 'BRONZE');

typedef LeaderboardParam = ({String scope, String league});

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntryModel>, LeaderboardParam>((ref, arg) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.fetchLeaderboard(scope: arg.scope, league: arg.league);
});
