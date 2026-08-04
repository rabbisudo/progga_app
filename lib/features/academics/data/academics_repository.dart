import '../../../core/network/api_client.dart';
import '../domain/academics_model.dart';
import '../../profile/presentation/profile_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

class AcademicsRepository {
  final ApiClient _apiClient;

  AcademicsRepository(this._apiClient);

  Future<List<AcademicClassModel>> fetchActiveClasses() async {
    try {
      final response = await _apiClient.dio.get('/academics/classes');
      final rawList = response.data as List<dynamic>;
      return rawList.map((e) => AcademicClassModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  /// Speed-First Single API: Fetches full curriculum (Subjects -> Chapters -> Topics)
  /// tailored for student based on their classId and optional groupId.
  Future<List<dynamic>> fetchStudentCurriculum({
    required String classId,
    String? groupId,
    String? userId,
    bool isQuestionBank = false,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/academics/curriculum',
        queryParameters: {
          'classId': classId,
          if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
          if (userId != null && userId.isNotEmpty) 'userId': userId,
          if (isQuestionBank) 'isQuestionBank': 'true',
        },
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }
}

final academicsRepositoryProvider = Provider<AcademicsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AcademicsRepository(client);
});

final activeClassesProvider = FutureProvider<List<AcademicClassModel>>((ref) async {
  final repo = ref.watch(academicsRepositoryProvider);
  return repo.fetchActiveClasses();
});

final studentCurriculumProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final profile = ref.watch(userProfileProvider).value?.profile;
  if (profile == null || profile.classId == null || profile.classId!.isEmpty) {
    return [];
  }
  final repo = ref.watch(academicsRepositoryProvider);
  return repo.fetchStudentCurriculum(
    classId: profile.classId!,
    groupId: profile.groupId,
    userId: profile.userId,
  );
});

final studentQbCurriculumProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final profile = ref.watch(userProfileProvider).value?.profile;
  if (profile == null || profile.classId == null || profile.classId!.isEmpty) {
    return [];
  }
  final repo = ref.watch(academicsRepositoryProvider);
  return repo.fetchStudentCurriculum(
    classId: profile.classId!,
    groupId: profile.groupId,
    userId: profile.userId,
    isQuestionBank: true,
  );
});
