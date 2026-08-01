import '../../../core/network/api_client.dart';
import '../domain/exam_model.dart';
import '../domain/user_exam_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

class ExamRepository {
  final ApiClient _apiClient;

  ExamRepository(this._apiClient);

  Future<List<ExamModel>> fetchExams(String? type) async {
    try {
      final response = await _apiClient.dio.get(
        '/exams',
        queryParameters: type != null ? {'type': type} : null,
      );
      final rawList = response.data as List<dynamic>;
      return rawList.map((e) => ExamModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<ExamModel> fetchExamDetails(String id) async {
    try {
      final response = await _apiClient.dio.get('/exams/$id');
      return ExamModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<UserExamModel> startExam(String examId) async {
    try {
      final response = await _apiClient.dio.post('/exams/$examId/start');
      return UserExamModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<UserExamModel> startCustomExam({
    String? subjectId,
    String? chapterId,
    String? topicId,
    int? limit,
    int? timeMinutes,
    String? title,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/exams/start-custom',
        data: {
          if (subjectId != null && subjectId.isNotEmpty) 'subjectId': subjectId,
          if (chapterId != null && chapterId.isNotEmpty) 'chapterId': chapterId,
          if (topicId != null && topicId.isNotEmpty) 'topicId': topicId,
          if (limit != null && limit > 0) 'totalQuestions': limit,
          if (timeMinutes != null && timeMinutes > 0) 'duration': timeMinutes,
          if (title != null && title.isNotEmpty) 'title': title,
        },
      );
      return UserExamModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<void> saveProgress(String sessionId, List<Map<String, dynamic>> answers) async {
    try {
      await _apiClient.dio.post(
        '/exams/sessions/$sessionId/save',
        data: {'answers': answers},
      );
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<UserExamModel> submitExam(String sessionId) async {
    try {
      final response = await _apiClient.dio.post('/exams/sessions/$sessionId/submit');
      return UserExamModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<List<UserAnswerModel>> fetchWrongAnswers(String sessionId) async {
    try {
      final response = await _apiClient.dio.get('/exams/sessions/$sessionId/wrong');
      final rawList = response.data as List<dynamic>;
      return rawList.map((a) => UserAnswerModel.fromJson(a)).toList();
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<Map<String, dynamic>> fetchExamResult(String sessionId) async {
    try {
      final response = await _apiClient.dio.get('/exams/sessions/$sessionId/result');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<Map<String, dynamic>> unlockExplanation(String questionId) async {
    try {
      final response = await _apiClient.dio.post('/questions/$questionId/explanation');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<Map<String, dynamic>> toggleBookmark(String questionId) async {
    try {
      final response = await _apiClient.dio.post('/questions/$questionId/bookmark');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<Map<String, dynamic>> reportQuestion(String questionId, String reason, {String? details}) async {
    try {
      final response = await _apiClient.dio.post(
        '/questions/$questionId/report',
        data: {
          'reason': reason,
          if (details != null && details.isNotEmpty) 'details': details,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }
}

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ExamRepository(client);
});
