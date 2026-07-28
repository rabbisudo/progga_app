import 'package:freezed_annotation/freezed_annotation.dart';

part 'leaderboard_model.freezed.dart';
part 'leaderboard_model.g.dart';

@freezed
class LeaderboardEntryModel with _$LeaderboardEntryModel {
  const factory LeaderboardEntryModel({
    required int rank,
    required String userId,
    required String username,
    required String fullName,
    String? avatarKey,
    required int xp,
    required int level,
    required int solvedQuestionsCount,
    required String league,
  }) = _LeaderboardEntryModel;

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) => _$LeaderboardEntryModelFromJson(json);
}
