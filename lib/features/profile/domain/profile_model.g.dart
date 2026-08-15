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
      birthday: json['birthday'] as String?,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      institution: json['institution'] as String?,
      className: json['className'] as String?,
      batch: json['batch'] as String?,
      board: json['board'] as String?,
      targetExam: json['targetExam'] as String?,
      classId: json['classId'] as String?,
      groupId: json['groupId'] as String?,
      batchId: json['batchId'] as String?,
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
      streakFreezes: (json['streakFreezes'] as num?)?.toInt() ?? 5,
      usedStreakFreezes: (json['usedStreakFreezes'] as num?)?.toInt() ?? 0,
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
      'birthday': instance.birthday,
      'gender': instance.gender,
      'address': instance.address,
      'institution': instance.institution,
      'className': instance.className,
      'batch': instance.batch,
      'board': instance.board,
      'targetExam': instance.targetExam,
      'classId': instance.classId,
      'groupId': instance.groupId,
      'batchId': instance.batchId,
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
      'streakFreezes': instance.streakFreezes,
      'usedStreakFreezes': instance.usedStreakFreezes,
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
      password: json['password'] as String?,
      role: json['role'] as String? ?? 'USER',
      isActive: json['isActive'] as bool,
      createdAt: json['createdAt'] as String,
      profile: json['profile'] == null
          ? null
          : UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
      streakHistory: (json['streakHistory'] as List<dynamic>?)
          ?.map((e) => e as bool)
          .toList(),
      monthlyActiveDates: (json['monthlyActiveDates'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      frozenStreakDates: (json['frozenStreakDates'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$UserDataImplToJson(_$UserDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'username': instance.username,
      'password': instance.password,
      'role': instance.role,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt,
      'profile': instance.profile,
      'streakHistory': instance.streakHistory,
      'monthlyActiveDates': instance.monthlyActiveDates,
      'frozenStreakDates': instance.frozenStreakDates,
    };
