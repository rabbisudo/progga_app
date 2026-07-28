// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_exam_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserAnswerModelImpl _$$UserAnswerModelImplFromJson(
        Map<String, dynamic> json) =>
    _$UserAnswerModelImpl(
      id: json['id'] as String,
      userExamId: json['userExamId'] as String,
      questionId: json['questionId'] as String,
      selectedOptionId: json['selectedOptionId'] as String?,
      status: json['status'] as String,
      markedForReview: json['markedForReview'] as bool,
      timeSpent: (json['timeSpent'] as num).toInt(),
      question: json['question'] == null
          ? null
          : QuestionModel.fromJson(json['question'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$UserAnswerModelImplToJson(
        _$UserAnswerModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userExamId': instance.userExamId,
      'questionId': instance.questionId,
      'selectedOptionId': instance.selectedOptionId,
      'status': instance.status,
      'markedForReview': instance.markedForReview,
      'timeSpent': instance.timeSpent,
      'question': instance.question,
    };

_$UserExamModelImpl _$$UserExamModelImplFromJson(Map<String, dynamic> json) =>
    _$UserExamModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      examId: json['examId'] as String,
      status: json['status'] as String,
      score: (json['score'] as num).toDouble(),
      totalQuestions: (json['totalQuestions'] as num).toInt(),
      correctCount: (json['correctCount'] as num).toInt(),
      wrongCount: (json['wrongCount'] as num).toInt(),
      skippedCount: (json['skippedCount'] as num).toInt(),
      accuracy: (json['accuracy'] as num).toDouble(),
      timeTaken: (json['timeTaken'] as num).toInt(),
      rank: (json['rank'] as num?)?.toInt(),
      percentile: (json['percentile'] as num?)?.toDouble(),
      startedAt: json['startedAt'] as String,
      endedAt: json['endedAt'] as String?,
      answers: (json['answers'] as List<dynamic>?)
          ?.map((e) => UserAnswerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$UserExamModelImplToJson(_$UserExamModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'examId': instance.examId,
      'status': instance.status,
      'score': instance.score,
      'totalQuestions': instance.totalQuestions,
      'correctCount': instance.correctCount,
      'wrongCount': instance.wrongCount,
      'skippedCount': instance.skippedCount,
      'accuracy': instance.accuracy,
      'timeTaken': instance.timeTaken,
      'rank': instance.rank,
      'percentile': instance.percentile,
      'startedAt': instance.startedAt,
      'endedAt': instance.endedAt,
      'answers': instance.answers,
    };
