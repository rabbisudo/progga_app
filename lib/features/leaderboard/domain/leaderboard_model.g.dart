// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LeaderboardEntryModelImpl _$$LeaderboardEntryModelImplFromJson(
        Map<String, dynamic> json) =>
    _$LeaderboardEntryModelImpl(
      rank: (json['rank'] as num).toInt(),
      userId: json['userId'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      institution: json['institution'] as String?,
      avatarKey: json['avatarKey'] as String?,
      xp: (json['xp'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      solvedQuestionsCount: (json['solvedQuestionsCount'] as num).toInt(),
      league: json['league'] as String,
    );

Map<String, dynamic> _$$LeaderboardEntryModelImplToJson(
        _$LeaderboardEntryModelImpl instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'userId': instance.userId,
      'username': instance.username,
      'fullName': instance.fullName,
      'avatarKey': instance.avatarKey,
      'xp': instance.xp,
      'level': instance.level,
      'solvedQuestionsCount': instance.solvedQuestionsCount,
      'league': instance.league,
    };
