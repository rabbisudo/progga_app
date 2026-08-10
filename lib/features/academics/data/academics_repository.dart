import '../../../core/network/api_client.dart';
import '../domain/academics_model.dart';
import '../../profile/presentation/profile_notifier.dart';
import '../../../core/storage/hive_service.dart';
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

final studentCurriculumProvider = FutureProvider<List<dynamic>>((ref) async {
  final classId = ref.watch(userProfileProvider.select((v) => v.value?.profile?.classId));
  final groupId = ref.watch(userProfileProvider.select((v) => v.value?.profile?.groupId));
  final userId = ref.watch(userProfileProvider.select((v) => v.value?.profile?.userId));

  if (classId == null || classId.isEmpty) {
    return [];
  }
  final repo = ref.watch(academicsRepositoryProvider);
  final hive = ref.read(hiveServiceProvider);

  try {
    final data = await repo.fetchStudentCurriculum(
      classId: classId,
      groupId: groupId,
      userId: userId,
    );
    await hive.cacheList('cached_student_curriculum', data);
    return data;
  } catch (e) {
    final cached = hive.getCachedList('cached_student_curriculum');
    if (cached != null) {
      return cached;
    }
    rethrow;
  }
});

final studentQbCurriculumProvider = FutureProvider<List<dynamic>>((ref) async {
  final classId = ref.watch(userProfileProvider.select((v) => v.value?.profile?.classId));
  final groupId = ref.watch(userProfileProvider.select((v) => v.value?.profile?.groupId));
  final userId = ref.watch(userProfileProvider.select((v) => v.value?.profile?.userId));

  if (classId == null || classId.isEmpty) {
    return [];
  }
  final repo = ref.watch(academicsRepositoryProvider);
  final hive = ref.read(hiveServiceProvider);

  try {
    final data = await repo.fetchStudentCurriculum(
      classId: classId,
      groupId: groupId,
      userId: userId,
      isQuestionBank: true,
    );
    await hive.cacheList('cached_student_qb_curriculum', data);
    return data;
  } catch (e) {
    final cached = hive.getCachedList('cached_student_qb_curriculum');
    if (cached != null) {
      return cached;
    }
    rethrow;
  }
});

// Added Question Bank Series methods to AcademicsRepository
extension AcademicsRepositoryQBExtensions on AcademicsRepository {
  Future<List<dynamic>> fetchQuestionBankSeries({
    required String classId,
    required String subjectId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/academics/series',
        queryParameters: {
          'classId': classId,
          'subjectId': subjectId,
        },
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<List<dynamic>> fetchExamsByIds(List<String> ids) async {
    try {
      final response = await _apiClient.dio.get(
        '/academics/exams-by-ids',
        queryParameters: {
          'ids': ids.join(','),
        },
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<List<dynamic>> fetchQuestionBankSections({
    required String classId,
    String? groupId,
    String? batchId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/academics/qb-sections',
        queryParameters: {
          'classId': classId,
          if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
          if (batchId != null && batchId.isNotEmpty) 'batchId': batchId,
        },
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }
}

// Providers for Series, Sections and Exams
final qbSeriesProvider = FutureProvider.family.autoDispose<List<dynamic>, String>((ref, subjectId) async {
  final profile = ref.watch(userProfileProvider).value?.profile;
  if (profile == null || profile.classId == null || profile.classId!.isEmpty) {
    return [];
  }
  final repo = ref.watch(academicsRepositoryProvider);
  final hive = ref.read(hiveServiceProvider);
  final cacheKey = 'cached_qb_series_sub_${profile.classId}_$subjectId';

  try {
    final data = await repo.fetchQuestionBankSeries(
      classId: profile.classId!,
      subjectId: subjectId,
    );
    await hive.cacheList(cacheKey, data);
    return data;
  } catch (e) {
    final cached = hive.getCachedList(cacheKey);
    if (cached != null) {
      return cached;
    }
    rethrow;
  }
});

final qbExamsProvider = FutureProvider.family.autoDispose<List<dynamic>, String>((ref, idsStr) async {
  if (idsStr.isEmpty) return [];
  final ids = idsStr.split(',').where((id) => id.trim().isNotEmpty).toList();
  final repo = ref.watch(academicsRepositoryProvider);
  final hive = ref.read(hiveServiceProvider);
  final cacheKey = 'cached_qb_exams_${idsStr.hashCode}';

  try {
    final data = await repo.fetchExamsByIds(ids);
    await hive.cacheList(cacheKey, data);
    return data;
  } catch (e) {
    final cached = hive.getCachedList(cacheKey);
    if (cached != null) {
      return cached;
    }
    rethrow;
  }
});

final qbClassSeriesProvider = FutureProvider.family.autoDispose<List<dynamic>, String>((ref, classId) async {
  final repo = ref.watch(academicsRepositoryProvider);
  final hive = ref.read(hiveServiceProvider);
  final cacheKey = 'cached_qb_series_$classId';

  try {
    final data = await repo.fetchQuestionBankSeries(
      classId: classId,
      subjectId: '',
    );
    await hive.cacheList(cacheKey, data);
    return data;
  } catch (e) {
    final cached = hive.getCachedList(cacheKey);
    if (cached != null) {
      return cached;
    }
    rethrow;
  }
});

final qbClassSectionsProvider = FutureProvider.family.autoDispose<List<dynamic>, String>((ref, classId) async {
  final profile = ref.watch(userProfileProvider).value?.profile;
  final groupId = profile?.groupId;
  final batchId = profile?.batchId;
  final repo = ref.watch(academicsRepositoryProvider);
  final hive = ref.read(hiveServiceProvider);
  final cacheKey = 'cached_qb_sections_${classId}_${groupId ?? "none"}_${batchId ?? "none"}';

  try {
    final data = await repo.fetchQuestionBankSections(
      classId: classId,
      groupId: groupId,
      batchId: batchId,
    );
    await hive.cacheList(cacheKey, data);
    return data;
  } catch (e) {
    final cached = hive.getCachedList(cacheKey);
    if (cached != null) {
      return cached;
    }
    rethrow;
  }
});
