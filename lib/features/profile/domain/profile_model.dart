import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const UserProfile._();

  @JsonSerializable()
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
    @Default(5) int streakFreezes,
    @Default(0) int usedStreakFreezes,
    required int xp,
    required int coins,
    required int level,
    required String league,
    String? lastActiveDate,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);

    // Fallbacks for Class ID & Name
    if (map['classId'] == null) {
      if (map['class'] is Map) {
        map['classId'] = map['class']['id']?.toString() ?? map['class']['_id']?.toString();
      } else if (map['class_id'] != null) {
        map['classId'] = map['class_id'].toString();
      }
    }
    if (map['className'] == null) {
      if (map['class'] is Map) {
        map['className'] = map['class']['name']?.toString();
      } else if (map['class_name'] != null) {
        map['className'] = map['class_name'].toString();
      } else if (map['class'] is String) {
        map['className'] = map['class'];
      }
    }

    // Fallbacks for Group ID & Target Exam
    if (map['groupId'] == null) {
      if (map['group'] is Map) {
        map['groupId'] = map['group']['id']?.toString() ?? map['group']['_id']?.toString();
      } else if (map['subjectGroup'] is Map) {
        map['groupId'] = map['subjectGroup']['id']?.toString() ?? map['subjectGroup']['_id']?.toString();
      } else if (map['group_id'] != null) {
        map['groupId'] = map['group_id'].toString();
      }
    }
    if (map['targetExam'] == null) {
      if (map['group'] is Map) {
        map['targetExam'] = map['group']['name']?.toString();
      } else if (map['subjectGroup'] is Map) {
        map['targetExam'] = map['subjectGroup']['name']?.toString();
      } else if (map['target_exam'] != null) {
        map['targetExam'] = map['target_exam'].toString();
      } else if (map['group'] is String) {
        map['targetExam'] = map['group'];
      }
    }

    // Fallbacks for Batch ID & Name
    if (map['batchId'] == null) {
      if (map['batch'] is Map) {
        map['batchId'] = map['batch']['id']?.toString() ?? map['batch']['_id']?.toString();
      } else if (map['batch_id'] != null) {
        map['batchId'] = map['batch_id'].toString();
      }
    }
    if (map['batch'] is Map) {
      map['batch'] = (map['batch'] as Map)['name']?.toString();
    }

    return _$$UserProfileImplFromJson(map);
  }

  Map<String, dynamic> toJson() => _$$UserProfileImplToJson(this as _$UserProfileImpl);
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
    List<String>? monthlyActiveDates,
    List<String>? frozenStreakDates,
  }) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) => _$UserDataFromJson(json);
}
