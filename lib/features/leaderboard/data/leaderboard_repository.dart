import '../../../core/network/api_client.dart';
import '../domain/leaderboard_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

class LeaderboardRepository {
  final ApiClient _apiClient;

  LeaderboardRepository(this._apiClient);

  Future<List<LeaderboardEntryModel>> fetchLeaderboard() async {
    try {
      final response = await _apiClient.dio.get('/leaderboards/global');
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
}

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return LeaderboardRepository(client);
});
