import '../../../core/network/api_client.dart';
import '../domain/academics_model.dart';
import '../../profile/presentation/profile_notifier.dart';
import '../../../core/storage/hive_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

class AcademicsRepository {
  final ApiClient _apiClient;
  final HiveService? _hiveService;

  AcademicsRepository(this._apiClient, [this._hiveService]);

  Map<String, dynamic> _recursivelyCastMap(Map<dynamic, dynamic> source) {
    return source.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _recursivelyCastMap(value));
      } else if (value is List) {
        return MapEntry(
          key.toString(),
          value.map((item) {
            if (item is Map) {
              return _recursivelyCastMap(item);
            }
            return item;
          }).toList(),
        );
      }
      return MapEntry(key.toString(), value);
    });
  }

  Future<List<AcademicClassModel>> fetchActiveClasses({bool forceRefresh = false}) async {
    // 1. Check local Hive cache first for instant (0ms) return
    if (!forceRefresh && _hiveService != null) {
      try {
        final cached = _hiveService!.getSettingsBox().get('cached_active_classes');
        if (cached != null && cached is List && cached.isNotEmpty) {
          return cached
              .map((e) => AcademicClassModel.fromJson(_recursivelyCastMap(e as Map)))
              .toList();
        }
      } catch (_) {}
    }

    // 2. Fetch from backend API
    try {
      final response = await _apiClient.dio.get('/academics/classes');
      final rawList = response.data as List<dynamic>;

      // 3. Persist into Hive cache for offline / instant future access
      if (_hiveService != null) {
        try {
          _hiveService!.getSettingsBox().put('cached_active_classes', rawList);
        } catch (_) {}
      }

      return rawList.map((e) => AcademicClassModel.fromJson(e)).toList();
    } on DioException catch (e) {
      // If offline or network error, fallback to cache if available
      if (_hiveService != null) {
        try {
          final cached = _hiveService!.getSettingsBox().get('cached_active_classes');
          if (cached != null && cached is List && cached.isNotEmpty) {
            return cached
                .map((e) => AcademicClassModel.fromJson(_recursivelyCastMap(e as Map)))
                .toList();
          }
        } catch (_) {}
      }
      throw _apiClient.handleError(e);
    }
  }

  /// Speed-First Single API: Fetches full curriculum (Subjects -> Chapters -> Topics)
  /// tailored for student based on their classId and optional groupId/batchId.
  Future<List<dynamic>> fetchStudentCurriculum({
    required String classId,
    String? groupId,
    String? batchId,
    String? userId,
    bool isQuestionBank = false,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/academics/curriculum',
        queryParameters: {
          'classId': classId,
          if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
          if (batchId != null && batchId.isNotEmpty) 'batchId': batchId,
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
  final hiveService = ref.watch(hiveServiceProvider);
  return AcademicsRepository(client, hiveService);
});

final activeClassesProvider = FutureProvider<List<AcademicClassModel>>((ref) async {
  final repo = ref.watch(academicsRepositoryProvider);
  return repo.fetchActiveClasses();
});

final Map<String, int> _lastAcademicsFetchTimestamps = {};
const int _kAcademicsCacheTtlMs = 24 * 60 * 60 * 1000; // 24 hours TTL

final studentCurriculumProvider = FutureProvider<List<dynamic>>((ref) async {
  final classId = ref.watch(userProfileProvider.select((u) => u.value?.profile?.classId));
  final groupId = ref.watch(userProfileProvider.select((u) => u.value?.profile?.groupId));
  final batchId = ref.watch(userProfileProvider.select((u) => u.value?.profile?.batchId));
  final userId = ref.watch(userProfileProvider.select((u) => u.value?.profile?.userId));

  if (classId == null || classId.isEmpty) {
    return [];
  }
  final repo = ref.watch(academicsRepositoryProvider);
  final hive = ref.read(hiveServiceProvider);
  final cacheKey = 'cached_student_curriculum_${classId}_${groupId ?? "none"}_${batchId ?? "none"}';

  final cached = hive.getCachedList(cacheKey);
  final lastFetch = _lastAcademicsFetchTimestamps[cacheKey] ?? 0;
  final isFresh = (DateTime.now().millisecondsSinceEpoch - lastFetch) < _kAcademicsCacheTtlMs;

  if (cached != null && cached.isNotEmpty) {
    if (!isFresh) {
      _lastAcademicsFetchTimestamps[cacheKey] = DateTime.now().millisecondsSinceEpoch;
      repo.fetchStudentCurriculum(
        classId: classId,
        groupId: groupId,
        batchId: batchId,
        userId: userId,
      ).then((freshData) async {
        await hive.cacheList(cacheKey, freshData);
      }).catchError((_) {});
    }
    return cached;
  }

  try {
    final freshData = await repo.fetchStudentCurriculum(
      classId: classId,
      groupId: groupId,
      batchId: batchId,
      userId: userId,
    );
    _lastAcademicsFetchTimestamps[cacheKey] = DateTime.now().millisecondsSinceEpoch;
    await hive.cacheList(cacheKey, freshData);
    return freshData;
  } catch (e) {
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    rethrow;
  }
});

final studentQbCurriculumProvider = FutureProvider<List<dynamic>>((ref) async {
  final classId = ref.watch(userProfileProvider.select((u) => u.value?.profile?.classId));
  final groupId = ref.watch(userProfileProvider.select((u) => u.value?.profile?.groupId));
  final batchId = ref.watch(userProfileProvider.select((u) => u.value?.profile?.batchId));
  final userId = ref.watch(userProfileProvider.select((u) => u.value?.profile?.userId));

  if (classId == null || classId.isEmpty) {
    return [];
  }
  final repo = ref.watch(academicsRepositoryProvider);
  final hive = ref.read(hiveServiceProvider);
  final cacheKey = 'cached_student_qb_curriculum_${classId}_${groupId ?? "none"}_${batchId ?? "none"}';

  final cached = hive.getCachedList(cacheKey);
  final lastFetch = _lastAcademicsFetchTimestamps[cacheKey] ?? 0;
  final isFresh = (DateTime.now().millisecondsSinceEpoch - lastFetch) < _kAcademicsCacheTtlMs;

  if (cached != null && cached.isNotEmpty) {
    if (!isFresh) {
      _lastAcademicsFetchTimestamps[cacheKey] = DateTime.now().millisecondsSinceEpoch;
      repo.fetchStudentCurriculum(
        classId: classId,
        groupId: groupId,
        batchId: batchId,
        userId: userId,
        isQuestionBank: true,
      ).then((freshData) async {
        await hive.cacheList(cacheKey, freshData);
      }).catchError((_) {});
    }
    return cached;
  }

  try {
    final freshData = await repo.fetchStudentCurriculum(
      classId: classId,
      groupId: groupId,
      batchId: batchId,
      userId: userId,
      isQuestionBank: true,
    );
    _lastAcademicsFetchTimestamps[cacheKey] = DateTime.now().millisecondsSinceEpoch;
    await hive.cacheList(cacheKey, freshData);
    return freshData;
  } catch (e) {
    if (cached != null && cached.isNotEmpty) {
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
final qbSeriesProvider = FutureProvider.family<List<dynamic>, String>((ref, subjectId) async {
  final classId = ref.watch(userProfileProvider.select((u) => u.value?.profile?.classId));
  final groupId = ref.watch(userProfileProvider.select((u) => u.value?.profile?.groupId));
  final batchId = ref.watch(userProfileProvider.select((u) => u.value?.profile?.batchId));

  if (classId == null || classId.isEmpty) {
    return [];
  }
  final repo = ref.watch(academicsRepositoryProvider);
  final hive = ref.read(hiveServiceProvider);
  final cacheKey = 'cached_qb_series_sub_${classId}_${groupId ?? "none"}_${batchId ?? "none"}';

  final cached = hive.getCachedList(cacheKey);
  final lastFetch = _lastAcademicsFetchTimestamps[cacheKey] ?? 0;
  final isFresh = (DateTime.now().millisecondsSinceEpoch - lastFetch) < _kAcademicsCacheTtlMs;

  if (cached != null && cached.isNotEmpty) {
    if (!isFresh) {
      _lastAcademicsFetchTimestamps[cacheKey] = DateTime.now().millisecondsSinceEpoch;
      repo.fetchQuestionBankSeries(
        classId: classId,
        subjectId: subjectId,
      ).then((freshData) async {
        await hive.cacheList(cacheKey, freshData);
      }).catchError((_) {});
    }
    return cached;
  }

  try {
    final freshData = await repo.fetchQuestionBankSeries(
      classId: classId,
      subjectId: subjectId,
    );
    _lastAcademicsFetchTimestamps[cacheKey] = DateTime.now().millisecondsSinceEpoch;
    await hive.cacheList(cacheKey, freshData);
    return freshData;
  } catch (e) {
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    rethrow;
  }
});

final qbExamsProvider = FutureProvider.family<List<dynamic>, String>((ref, idsStr) async {
  if (idsStr.isEmpty) return [];
  final ids = idsStr.split(',').where((id) => id.trim().isNotEmpty).toList();
  final repo = ref.watch(academicsRepositoryProvider);
  final hive = ref.read(hiveServiceProvider);
  final cacheKey = 'cached_qb_exams_${idsStr.hashCode}';

  final cached = hive.getCachedList(cacheKey);
  final lastFetch = _lastAcademicsFetchTimestamps[cacheKey] ?? 0;
  final isFresh = (DateTime.now().millisecondsSinceEpoch - lastFetch) < _kAcademicsCacheTtlMs;

  if (cached != null && cached.isNotEmpty) {
    if (!isFresh) {
      _lastAcademicsFetchTimestamps[cacheKey] = DateTime.now().millisecondsSinceEpoch;
      repo.fetchExamsByIds(ids).then((freshData) async {
        await hive.cacheList(cacheKey, freshData);
      }).catchError((_) {});
    }
    return cached;
  }

  try {
    final freshData = await repo.fetchExamsByIds(ids);
    _lastAcademicsFetchTimestamps[cacheKey] = DateTime.now().millisecondsSinceEpoch;
    await hive.cacheList(cacheKey, freshData);
    return freshData;
  } catch (e) {
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    rethrow;
  }
});

final qbClassSeriesProvider = FutureProvider.family<List<dynamic>, String>((ref, classId) async {
  final repo = ref.watch(academicsRepositoryProvider);
  final hive = ref.read(hiveServiceProvider);
  final cacheKey = 'cached_qb_series_$classId';

  final cached = hive.getCachedList(cacheKey);
  final lastFetch = _lastAcademicsFetchTimestamps[cacheKey] ?? 0;
  final isFresh = (DateTime.now().millisecondsSinceEpoch - lastFetch) < _kAcademicsCacheTtlMs;

  if (cached != null && cached.isNotEmpty) {
    if (!isFresh) {
      _lastAcademicsFetchTimestamps[cacheKey] = DateTime.now().millisecondsSinceEpoch;
      repo.fetchQuestionBankSeries(
        classId: classId,
        subjectId: '',
      ).then((freshData) async {
        await hive.cacheList(cacheKey, freshData);
      }).catchError((_) {});
    }
    return cached;
  }

  try {
    final freshData = await repo.fetchQuestionBankSeries(
      classId: classId,
      subjectId: '',
    );
    _lastAcademicsFetchTimestamps[cacheKey] = DateTime.now().millisecondsSinceEpoch;
    await hive.cacheList(cacheKey, freshData);
    return freshData;
  } catch (e) {
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    rethrow;
  }
});

final qbClassSectionsProvider = FutureProvider.family<List<dynamic>, String>((ref, classId) async {
  final groupId = ref.watch(userProfileProvider.select((u) => u.value?.profile?.groupId));
  final batchId = ref.watch(userProfileProvider.select((u) => u.value?.profile?.batchId));
  final repo = ref.watch(academicsRepositoryProvider);
  final hive = ref.read(hiveServiceProvider);
  final cacheKey = 'cached_qb_sections_${classId}_${groupId ?? "none"}_${batchId ?? "none"}';

  final cached = hive.getCachedList(cacheKey);
  final lastFetch = _lastAcademicsFetchTimestamps[cacheKey] ?? 0;
  final isFresh = (DateTime.now().millisecondsSinceEpoch - lastFetch) < _kAcademicsCacheTtlMs;

  if (cached != null && cached.isNotEmpty) {
    if (!isFresh) {
      _lastAcademicsFetchTimestamps[cacheKey] = DateTime.now().millisecondsSinceEpoch;
      repo.fetchQuestionBankSections(
        classId: classId,
        groupId: groupId,
        batchId: batchId,
      ).then((freshData) async {
        await hive.cacheList(cacheKey, freshData);
      }).catchError((_) {});
    }
    return cached;
  }

  try {
    final freshData = await repo.fetchQuestionBankSections(
      classId: classId,
      groupId: groupId,
      batchId: batchId,
    );
    _lastAcademicsFetchTimestamps[cacheKey] = DateTime.now().millisecondsSinceEpoch;
    await hive.cacheList(cacheKey, freshData);
    return freshData;
  } catch (e) {
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    rethrow;
  }
});
