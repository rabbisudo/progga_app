import '../../../core/network/api_client.dart';
import '../domain/leaderboard_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

class LeagueConfigModel {
  final String id;
  final String name;

  const LeagueConfigModel({required this.id, required this.name});

  factory LeagueConfigModel.fromJson(Map<String, dynamic> json) {
    return LeagueConfigModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class LeaderboardRepository {
  final ApiClient _apiClient;

  LeaderboardRepository(this._apiClient);

  Future<List<LeaderboardEntryModel>> fetchLeaderboard({
    String scope = 'global',
    String league = '',
    int limit = 50,
    int offset = 0,
  }) async {
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
      return rawList.map((e) => LeaderboardEntryModel.fromJson(e)).toList();
    } on DioException catch (e) {
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

const List<LeagueConfigModel> defaultLeagues = [
  LeagueConfigModel(id: 'iron', name: 'আয়রন লীগ'),
  LeagueConfigModel(id: 'bronze', name: 'ব্রোঞ্জ লীগ'),
  LeagueConfigModel(id: 'silver', name: 'সিলভার লীগ'),
  LeagueConfigModel(id: 'gold', name: 'গোল্ড লীগ'),
  LeagueConfigModel(id: 'diamond', name: 'ডায়মন্ড লীগ'),
  LeagueConfigModel(id: 'infinity', name: 'ইনফিনিটি লীগ'),
];

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return LeaderboardRepository(client);
});
