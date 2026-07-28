// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      avatarKey: json['avatarKey'] as String?,
      coverPhotoKey: json['coverPhotoKey'] as String?,
      bio: json['bio'] as String?,
      institution: json['institution'] as String?,
      className: json['className'] as String?,
      batch: json['batch'] as String?,
      board: json['board'] as String?,
      targetExam: json['targetExam'] as String?,
      targetGPA: (json['targetGPA'] as num?)?.toDouble(),
      country: json['country'] as String,
      language: json['language'] as String,
      darkMode: json['darkMode'] as bool,
      pushNotifications: json['pushNotifications'] as bool,
      weeklyEmailReport: json['weeklyEmailReport'] as bool,
      profileVisible: json['profileVisible'] as bool,
      showStreakOnProfile: json['showStreakOnProfile'] as bool,
      solvedQuestionsCount: (json['solvedQuestionsCount'] as num).toInt(),
      solvedExamsCount: (json['solvedExamsCount'] as num).toInt(),
      averageAccuracy: (json['averageAccuracy'] as num).toDouble(),
      totalStudyTime: (json['totalStudyTime'] as num).toInt(),
      currentStreak: (json['currentStreak'] as num).toInt(),
      longestStreak: (json['longestStreak'] as num).toInt(),
      xp: (json['xp'] as num).toInt(),
      coins: (json['coins'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      league: json['league'] as String,
      lastActiveDate: json['lastActiveDate'] as String?,
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'fullName': instance.fullName,
      'avatarKey': instance.avatarKey,
      'coverPhotoKey': instance.coverPhotoKey,
      'bio': instance.bio,
      'institution': instance.institution,
      'className': instance.className,
      'batch': instance.batch,
      'board': instance.board,
      'targetExam': instance.targetExam,
      'targetGPA': instance.targetGPA,
      'country': instance.country,
      'language': instance.language,
      'darkMode': instance.darkMode,
      'pushNotifications': instance.pushNotifications,
      'weeklyEmailReport': instance.weeklyEmailReport,
      'profileVisible': instance.profileVisible,
      'showStreakOnProfile': instance.showStreakOnProfile,
      'solvedQuestionsCount': instance.solvedQuestionsCount,
      'solvedExamsCount': instance.solvedExamsCount,
      'averageAccuracy': instance.averageAccuracy,
      'totalStudyTime': instance.totalStudyTime,
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
      'xp': instance.xp,
      'coins': instance.coins,
      'level': instance.level,
      'league': instance.league,
      'lastActiveDate': instance.lastActiveDate,
    };

_$UserDataImpl _$$UserDataImplFromJson(Map<String, dynamic> json) =>
    _$UserDataImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      role: json['role'] as String,
      isActive: json['isActive'] as bool,
      createdAt: json['createdAt'] as String,
      profile: json['profile'] == null
          ? null
          : UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
      streakHistory: (json['streakHistory'] as List<dynamic>?)
          ?.map((e) => e as bool)
          .toList(),
    );

Map<String, dynamic> _$$UserDataImplToJson(_$UserDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'username': instance.username,
      'role': instance.role,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt,
      'profile': instance.profile,
      'streakHistory': instance.streakHistory,
    };
