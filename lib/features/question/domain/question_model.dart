import 'package:freezed_annotation/freezed_annotation.dart';

part 'question_model.freezed.dart';
part 'question_model.g.dart';

@freezed
class OptionModel with _$OptionModel {
  const factory OptionModel({
    required String id,
    required String questionId,
    required String optionText,
    String? imageKey,
    required bool isCorrect,
  }) = _OptionModel;

  factory OptionModel.fromJson(Map<String, dynamic> json) => _$OptionModelFromJson(json);
}

@freezed
class ExplanationModel with _$ExplanationModel {
  const factory ExplanationModel({
    required String id,
    required String questionId,
    required String text,
    String? imageKey,
  }) = _ExplanationModel;

  factory ExplanationModel.fromJson(Map<String, dynamic> json) => _$ExplanationModelFromJson(json);
}

@freezed
class QuestionModel with _$QuestionModel {
  const factory QuestionModel({
    required String id,
    required String questionText,
    String? imageKey,
    String? latexFormula,
    String? difficulty,
    required String subjectId,
    required String chapterId,
    String? topicId,
    String? board,
    String? boardId,
    String? collegeId,
    String? varsityId,
    int? year,
    String? source,
    required List<String> tags,
    required int estimatedTime,
    required double marks,
    required double negativeMarks,
    required String status,
    String? type,
    required List<OptionModel> options,
    List<ExplanationModel>? explanations,
  }) = _QuestionModel;

  factory QuestionModel.fromJson(Map<String, dynamic> json) => _$QuestionModelFromJson(json);
}
