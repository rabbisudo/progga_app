import '../../../core/network/api_client.dart';
import '../domain/leaderboard_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

class LeagueConfigModel {
  final String id;
  final String name;
  final int minXp;
  final int? maxXp;
  final String asset;
  final String icon;
  final int colorValue;

  const LeagueConfigModel({
    required this.id,
    required this.name,
    required this.minXp,
    this.maxXp,
    required this.asset,
    required this.icon,
    required this.colorValue,
  });

  factory LeagueConfigModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString().toUpperCase();
    final defaultItem = getLeagueConfig(id);
    return LeagueConfigModel(
      id: id.isNotEmpty ? id : defaultItem.id,
      name: json['name'] ?? defaultItem.name,
      minXp: json['minXp'] ?? defaultItem.minXp,
      maxXp: json['maxXp'] ?? defaultItem.maxXp,
      asset: json['asset'] ?? defaultItem.asset,
      icon: defaultItem.icon,
      colorValue: defaultItem.colorValue,
    );
  }
}

const List<LeagueConfigModel> defaultLeagues = [
  LeagueConfigModel(
    id: 'BRONZE',
    name: 'ব্রোঞ্জ লীগ',
    minXp: 0,
    maxXp: 499,
    asset: 'assets/legue/bronze.webp',
    icon: '🥉',
    colorValue: 0xFFB45309,
  ),
  LeagueConfigModel(
    id: 'SILVER',
    name: 'সিলভার লীগ',
    minXp: 500,
    maxXp: 1499,
    asset: 'assets/legue/silver.webp',
    icon: '🥈',
    colorValue: 0xFF94A3B8,
  ),
  LeagueConfigModel(
    id: 'GOLD',
    name: 'গোল্ড লীগ',
    minXp: 1500,
    maxXp: 3499,
    asset: 'assets/legue/gold.webp',
    icon: '🥇',
    colorValue: 0xFFF59E0B,
  ),
  LeagueConfigModel(
    id: 'CRYSTAL',
    name: 'ক্রিস্টাল লীগ',
    minXp: 3500,
    maxXp: 5999,
    asset: 'assets/legue/crydtsl.webp',
    icon: '💎',
    colorValue: 0xFF06B6D4,
  ),
  LeagueConfigModel(
    id: 'ELITE',
    name: 'এলিট লীগ',
    minXp: 6000,
    maxXp: 8499,
    asset: 'assets/legue/elite.webp',
    icon: '👑',
    colorValue: 0xFFA855F7,
  ),
  LeagueConfigModel(
    id: 'LEGEND',
    name: 'লিজেন্ড লীগ',
    minXp: 8500,
    maxXp: null,
    asset: 'assets/legue/legend.webp',
    icon: '🌌',
    colorValue: 0xFFF43F5E,
  ),
];

LeagueConfigModel getLeagueConfig(String? leagueKey) {
  if (leagueKey == null || leagueKey.isEmpty) return defaultLeagues[0];
  final key = leagueKey.trim().toUpperCase();
  return defaultLeagues.firstWhere(
    (l) => l.id == key,
    orElse: () => defaultLeagues[0],
  );
}

LeagueConfigModel getLeagueConfigByXp(int xp) {
  if (xp >= 8500) return defaultLeagues[5]; // LEGEND
  if (xp >= 6000) return defaultLeagues[4]; // ELITE
  if (xp >= 3500) return defaultLeagues[3]; // CRYSTAL
  if (xp >= 1500) return defaultLeagues[2]; // GOLD
  if (xp >= 500) return defaultLeagues[1];  // SILVER
  return defaultLeagues[0];                 // BRONZE
}

LeagueConfigModel? getNextLeagueConfig(String? currentLeagueId) {
  final current = getLeagueConfig(currentLeagueId);
  final idx = defaultLeagues.indexWhere((l) => l.id == current.id);
  if (idx >= 0 && idx < defaultLeagues.length - 1) {
    return defaultLeagues[idx + 1];
  }
  return null; // Already max tier (Legend)
}

double calculateLeagueProgress(int xp) {
  if (xp >= 8500) return 1.0;
  if (xp >= 6000) return (xp - 6000) / (8500 - 6000);
  if (xp >= 3500) return (xp - 3500) / (6000 - 3500);
  if (xp >= 1500) return (xp - 1500) / (3500 - 1500);
  if (xp >= 500) return (xp - 500) / (1500 - 500);
  return (xp - 0) / 500.0;
}

int calculateXpNeededForNextLeague(int xp) {
  if (xp >= 8500) return 0;
  if (xp >= 6000) return 8500 - xp;
  if (xp >= 3500) return 6000 - xp;
  if (xp >= 1500) return 3500 - xp;
  if (xp >= 500) return 1500 - xp;
  return 500 - xp;
}

class LeaderboardCacheItem {
  final List<LeaderboardEntryModel> entries;
  final DateTime timestamp;

  LeaderboardCacheItem(this.entries, this.timestamp);

  bool isExpired([Duration ttl = const Duration(minutes: 5)]) {
    return DateTime.now().difference(timestamp) > ttl;
  }
}

class LeaderboardRepository {
  final ApiClient _apiClient;
  final Map<String, LeaderboardCacheItem> _cache = {};

  LeaderboardRepository(this._apiClient);

  void invalidateCache({String? league}) {
    if (league != null && league.isNotEmpty) {
      _cache.removeWhere((key, _) => key.contains(league));
    } else {
      _cache.clear();
    }
  }

  Future<List<LeaderboardEntryModel>> fetchLeaderboard({
    String scope = 'global',
    String league = '',
    int limit = 50,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$scope-$league-$limit-$offset';

    if (!forceRefresh && offset == 0 && _cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (!cached.isExpired()) {
        return cached.entries;
      }
    }

    try {
      final Map<String, dynamic> params = {
        'scope': scope,
        'limit': limit,
        'offset': offset,
      };
      if (league.isNotEmpty) {
        params['league'] = league;
      }
      final response = await _apiClient.dio.get(
        '/leaderboards/global',
        queryParameters: params,
      );
      List<dynamic> rawList = [];
      if (response.data is List) {
        rawList = response.data as List<dynamic>;
      } else if (response.data is Map && response.data['rankings'] is List) {
        rawList = response.data['rankings'] as List<dynamic>;
      }
      final result = rawList.map((e) => LeaderboardEntryModel.fromJson(e)).toList();

      if (offset == 0) {
        _cache[cacheKey] = LeaderboardCacheItem(result, DateTime.now());
      }

      return result;
    } on DioException catch (e) {
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!.entries;
      }
      throw _apiClient.handleError(e);
    }
  }

  Future<List<LeaderboardEntryModel>> fetchLeaderboardAroundMe() async {
    try {
      final response = await _apiClient.dio.get('/leaderboards/me');
      List<dynamic> rawList = [];
      if (response.data is List) {
        rawList = response.data as List<dynamic>;
      } else if (response.data is Map && response.data['rankings'] is List) {
        rawList = response.data['rankings'] as List<dynamic>;
      }
      return rawList.map((e) => LeaderboardEntryModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<List<LeagueConfigModel>> fetchLeaguesConfig() async {
    try {
      final response = await _apiClient.dio.get('/leaderboards/leagues');
      if (response.data is Map && response.data['data'] != null && response.data['data']['leagues'] is List) {
        final List<dynamic> list = response.data['data']['leagues'];
        return list.map((e) => LeagueConfigModel.fromJson(e)).toList();
      }
      return defaultLeagues;
    } catch (_) {
      return defaultLeagues;
    }
  }
}

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return LeaderboardRepository(client);
});
