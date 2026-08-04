// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OptionModelImpl _$$OptionModelImplFromJson(Map<String, dynamic> json) =>
    _$OptionModelImpl(
      id: json['id'] as String,
      questionId: json['questionId'] as String,
      optionText: json['optionText'] as String,
      imageKey: json['imageKey'] as String?,
      isCorrect: json['isCorrect'] as bool,
    );

Map<String, dynamic> _$$OptionModelImplToJson(_$OptionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'questionId': instance.questionId,
      'optionText': instance.optionText,
      'imageKey': instance.imageKey,
      'isCorrect': instance.isCorrect,
    };

_$ExplanationModelImpl _$$ExplanationModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ExplanationModelImpl(
      id: json['id'] as String,
      questionId: json['questionId'] as String,
      text: json['text'] as String,
      imageKey: json['imageKey'] as String?,
    );

Map<String, dynamic> _$$ExplanationModelImplToJson(
        _$ExplanationModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'questionId': instance.questionId,
      'text': instance.text,
      'imageKey': instance.imageKey,
    };

_$QuestionModelImpl _$$QuestionModelImplFromJson(Map<String, dynamic> json) =>
    _$QuestionModelImpl(
      id: json['id'] as String,
      questionText: json['questionText'] as String,
      imageKey: json['imageKey'] as String?,
      latexFormula: json['latexFormula'] as String?,
      difficulty: json['difficulty'] as String?,
      subjectId: json['subjectId'] as String,
      chapterId: json['chapterId'] as String,
      topicId: json['topicId'] as String?,
      board: json['board'] as String?,
      boardId: json['boardId'] as String?,
      collegeId: json['collegeId'] as String?,
      varsityId: json['varsityId'] as String?,
      year: (json['year'] as num?)?.toInt(),
      source: json['source'] as String?,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      estimatedTime: (json['estimatedTime'] as num).toInt(),
      marks: (json['marks'] as num).toDouble(),
      negativeMarks: (json['negativeMarks'] as num).toDouble(),
      status: json['status'] as String,
      type: json['type'] as String?,
      options: (json['options'] as List<dynamic>)
          .map((e) => OptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      explanations: (json['explanations'] as List<dynamic>?)
          ?.map((e) => ExplanationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$QuestionModelImplToJson(_$QuestionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'questionText': instance.questionText,
      'imageKey': instance.imageKey,
      'latexFormula': instance.latexFormula,
      'difficulty': instance.difficulty,
      'subjectId': instance.subjectId,
      'chapterId': instance.chapterId,
      'topicId': instance.topicId,
      'board': instance.board,
      'boardId': instance.boardId,
      'collegeId': instance.collegeId,
      'varsityId': instance.varsityId,
      'year': instance.year,
      'source': instance.source,
      'tags': instance.tags,
      'estimatedTime': instance.estimatedTime,
      'marks': instance.marks,
      'negativeMarks': instance.negativeMarks,
      'status': instance.status,
      'type': instance.type,
      'options': instance.options,
      'explanations': instance.explanations,
    };
