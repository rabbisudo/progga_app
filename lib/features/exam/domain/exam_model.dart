import 'package:freezed_annotation/freezed_annotation.dart';
import '../../question/domain/question_model.dart';

part 'exam_model.freezed.dart';
part 'exam_model.g.dart';

@freezed
class ExamQuestionModel with _$ExamQuestionModel {
  const factory ExamQuestionModel({
    required String id,
    required String examId,
    required String questionId,
    required int sortOrder,
    required QuestionModel question,
  }) = _ExamQuestionModel;

  factory ExamQuestionModel.fromJson(Map<String, dynamic> json) => _$ExamQuestionModelFromJson(json);
}

@freezed
class ExamSourceImageModel with _$ExamSourceImageModel {
  const factory ExamSourceImageModel({
    required String id,
    required String examId,
    required String url,
  }) = _ExamSourceImageModel;

  factory ExamSourceImageModel.fromJson(Map<String, dynamic> json) => _$ExamSourceImageModelFromJson(json);
}

@freezed
class ExamModel with _$ExamModel {
  const factory ExamModel({
    required String id,
    required String title,
    String? description,
    required String type,
    required int duration,
    required double totalMarks,
    required double negativeMarks,
    required double passMarks,
    required bool isPublished,
    required List<ExamQuestionModel> questions,
    @Default([]) List<ExamSourceImageModel> sourceImages,
  }) = _ExamModel;

  factory ExamModel.fromJson(Map<String, dynamic> json) => _$ExamModelFromJson(json);
}
