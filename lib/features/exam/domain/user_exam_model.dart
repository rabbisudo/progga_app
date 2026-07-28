import 'package:freezed_annotation/freezed_annotation.dart';
import '../../question/domain/question_model.dart';

part 'user_exam_model.freezed.dart';
part 'user_exam_model.g.dart';

@freezed
class UserAnswerModel with _$UserAnswerModel {
  const factory UserAnswerModel({
    required String id,
    required String userExamId,
    required String questionId,
    String? selectedOptionId,
    required String status, // CORRECT, WRONG, SKIPPED
    required bool markedForReview,
    required int timeSpent,
    QuestionModel? question,
  }) = _UserAnswerModel;

  factory UserAnswerModel.fromJson(Map<String, dynamic> json) => _$UserAnswerModelFromJson(json);
}

@freezed
class UserExamModel with _$UserExamModel {
  const factory UserExamModel({
    required String id,
    required String userId,
    required String examId,
    required String status, // IN_PROGRESS, COMPLETED, TIMED_OUT
    required double score,
    required int totalQuestions,
    required int correctCount,
    required int wrongCount,
    required int skippedCount,
    required double accuracy,
    required int timeTaken,
    int? rank,
    double? percentile,
    required String startedAt,
    String? endedAt,
    List<UserAnswerModel>? answers,
  }) = _UserExamModel;

  factory UserExamModel.fromJson(Map<String, dynamic> json) => _$UserExamModelFromJson(json);
}
