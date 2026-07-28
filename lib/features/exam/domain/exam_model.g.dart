// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExamQuestionModelImpl _$$ExamQuestionModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ExamQuestionModelImpl(
      id: json['id'] as String,
      examId: json['examId'] as String,
      questionId: json['questionId'] as String,
      sortOrder: (json['sortOrder'] as num).toInt(),
      question:
          QuestionModel.fromJson(json['question'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ExamQuestionModelImplToJson(
        _$ExamQuestionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'examId': instance.examId,
      'questionId': instance.questionId,
      'sortOrder': instance.sortOrder,
      'question': instance.question,
    };

_$ExamModelImpl _$$ExamModelImplFromJson(Map<String, dynamic> json) =>
    _$ExamModelImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      duration: (json['duration'] as num).toInt(),
      totalMarks: (json['totalMarks'] as num).toDouble(),
      negativeMarks: (json['negativeMarks'] as num).toDouble(),
      passMarks: (json['passMarks'] as num).toDouble(),
      isPublished: json['isPublished'] as bool,
      questions: (json['questions'] as List<dynamic>)
          .map((e) => ExamQuestionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$ExamModelImplToJson(_$ExamModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'type': instance.type,
      'duration': instance.duration,
      'totalMarks': instance.totalMarks,
      'negativeMarks': instance.negativeMarks,
      'passMarks': instance.passMarks,
      'isPublished': instance.isPublished,
      'questions': instance.questions,
    };
