import '../../../core/network/api_client.dart';
import '../domain/question_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

class PaginatedQuestions {
  final List<QuestionModel> questions;
  final String? nextCursor;

  PaginatedQuestions({required this.questions, this.nextCursor});
}

class QuestionRepository {
  final ApiClient _apiClient;

  QuestionRepository(this._apiClient);

  Future<PaginatedQuestions> fetchQuestions({
    String? subjectId,
    String? chapterId,
    String? topicId,
    String? difficulty,
    String? boardId,
    String? collegeId,
    String? varsityId,
    String? year,
    String? type,
    String? classId,
    String? groupId,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'limit': limit,
        if (subjectId != null && subjectId.isNotEmpty) 'subjectId': subjectId,
        if (chapterId != null && chapterId.isNotEmpty) 'chapterId': chapterId,
        if (topicId != null && topicId.isNotEmpty) 'topicId': topicId,
        if (difficulty != null) 'difficulty': difficulty,
        if (boardId != null && boardId.isNotEmpty) 'boardId': boardId,
        if (collegeId != null && collegeId.isNotEmpty) 'collegeId': collegeId,
        if (varsityId != null && varsityId.isNotEmpty) 'varsityId': varsityId,
        if (year != null && year.isNotEmpty) 'year': year,
        if (type != null && type.isNotEmpty) 'type': type,
        if (classId != null && classId.isNotEmpty) 'classId': classId,
        if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
        if (cursor != null) 'cursor': cursor,
      };

      final response = await _apiClient.dio.get(
        '/questions',
        queryParameters: queryParams,
      );

      final rawList = response.data['data'] as List<dynamic>;
      final questions = rawList.map((q) => QuestionModel.fromJson(q)).toList();
      final nextCursor = response.data['meta']['nextCursor'] as String?;

      return PaginatedQuestions(
        questions: questions,
        nextCursor: nextCursor,
      );
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<QuestionModel> fetchQuestionDetails(String id) async {
    try {
      final response = await _apiClient.dio.get('/questions/$id');
      return QuestionModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<List<dynamic>> fetchPendingSpacedRepetition() async {
    try {
      final response = await _apiClient.dio.get('/questions/spaced-repetition/pending');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<Map<String, dynamic>> submitSpacedRepetitionAttempt({
    String? questionId,
    String? qbQuestionId,
    required bool isCorrect,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/questions/spaced-repetition/attempt',
        data: {
          if (questionId != null) 'questionId': questionId,
          if (qbQuestionId != null) 'qbQuestionId': qbQuestionId,
          'isCorrect': isCorrect,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }
}

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return QuestionRepository(client);
});
