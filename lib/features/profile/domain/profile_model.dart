import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String userId,
    required String fullName,
    String? avatarKey,
    String? coverPhotoKey,
    String? bio,
    String? birthday,
    String? gender,
    String? address,
    String? institution,
    String? className,
    String? batch,
    String? board,
    String? targetExam,
    String? classId,
    String? groupId,
    String? batchId,
    double? targetGPA,
    required String country,
    required String language,
    required bool darkMode,
    required bool pushNotifications,
    required bool weeklyEmailReport,
    required bool profileVisible,
    required bool showStreakOnProfile,
    required int solvedQuestionsCount,
    required int solvedExamsCount,
    required double averageAccuracy,
    required int totalStudyTime,
    required int currentStreak,
    required int longestStreak,
    required int xp,
    required int coins,
    required int level,
    required String league,
    String? lastActiveDate,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
}

@freezed
class UserData with _$UserData {
  const factory UserData({
    required String id,
    required String email,
    required String username,
    @Default('USER') String role,
    required bool isActive,
    required String createdAt,
    UserProfile? profile,
    List<bool>? streakHistory,
  }) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) => _$UserDataFromJson(json);
}
