import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/leaderboard_repository.dart';
import '../domain/leaderboard_model.dart';
import '../../../core/storage/hive_service.dart';

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntryModel>, String>((ref, scope) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.fetchLeaderboard(scope: scope);
});

class MyLeaderboardNotifier extends AsyncNotifier<List<LeaderboardEntryModel>> {
  @override
  FutureOr<List<LeaderboardEntryModel>> build() async {
    final hive = ref.read(hiveServiceProvider);
    final cached = hive.getCachedList('cached_my_leaderboard');
    List<LeaderboardEntryModel>? cachedList;
    if (cached != null && cached.isNotEmpty) {
      try {
        cachedList = cached.map((e) => LeaderboardEntryModel.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    _fetchFresh();

    return cachedList ?? [];
  }

  Future<void> _fetchFresh() async {
    try {
      final repo = ref.read(leaderboardRepositoryProvider);
      final data = await repo.fetchLeaderboardAroundMe();
      final hive = ref.read(hiveServiceProvider);
      await hive.cacheList('cached_my_leaderboard', data.map((e) => e.toJson()).toList());
      state = AsyncData(data);
    } catch (e, st) {
      if (state.value == null || state.value!.isEmpty) {
        state = AsyncError(e, st);
      }
    }
  }

  Future<void> refresh() async {
    await _fetchFresh();
  }
}

final myLeaderboardProvider = AsyncNotifierProvider<MyLeaderboardNotifier, List<LeaderboardEntryModel>>(() {
  return MyLeaderboardNotifier();
});

final leaguesConfigProvider = FutureProvider<List<LeagueConfigModel>>((ref) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.fetchLeaguesConfig();
});
