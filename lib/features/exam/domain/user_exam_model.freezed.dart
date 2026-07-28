// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_exam_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserAnswerModel _$UserAnswerModelFromJson(Map<String, dynamic> json) {
  return _UserAnswerModel.fromJson(json);
}

/// @nodoc
mixin _$UserAnswerModel {
  String get id => throw _privateConstructorUsedError;
  String get userExamId => throw _privateConstructorUsedError;
  String get questionId => throw _privateConstructorUsedError;
  String? get selectedOptionId => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // CORRECT, WRONG, SKIPPED
  bool get markedForReview => throw _privateConstructorUsedError;
  int get timeSpent => throw _privateConstructorUsedError;
  QuestionModel? get question => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserAnswerModelCopyWith<UserAnswerModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserAnswerModelCopyWith<$Res> {
  factory $UserAnswerModelCopyWith(
          UserAnswerModel value, $Res Function(UserAnswerModel) then) =
      _$UserAnswerModelCopyWithImpl<$Res, UserAnswerModel>;
  @useResult
  $Res call(
      {String id,
      String userExamId,
      String questionId,
      String? selectedOptionId,
      String status,
      bool markedForReview,
      int timeSpent,
      QuestionModel? question});

  $QuestionModelCopyWith<$Res>? get question;
}

/// @nodoc
class _$UserAnswerModelCopyWithImpl<$Res, $Val extends UserAnswerModel>
    implements $UserAnswerModelCopyWith<$Res> {
  _$UserAnswerModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userExamId = null,
    Object? questionId = null,
    Object? selectedOptionId = freezed,
    Object? status = null,
    Object? markedForReview = null,
    Object? timeSpent = null,
    Object? question = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userExamId: null == userExamId
          ? _value.userExamId
          : userExamId // ignore: cast_nullable_to_non_nullable
              as String,
      questionId: null == questionId
          ? _value.questionId
          : questionId // ignore: cast_nullable_to_non_nullable
              as String,
      selectedOptionId: freezed == selectedOptionId
          ? _value.selectedOptionId
          : selectedOptionId // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      markedForReview: null == markedForReview
          ? _value.markedForReview
          : markedForReview // ignore: cast_nullable_to_non_nullable
              as bool,
      timeSpent: null == timeSpent
          ? _value.timeSpent
          : timeSpent // ignore: cast_nullable_to_non_nullable
              as int,
      question: freezed == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as QuestionModel?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $QuestionModelCopyWith<$Res>? get question {
    if (_value.question == null) {
      return null;
    }

    return $QuestionModelCopyWith<$Res>(_value.question!, (value) {
      return _then(_value.copyWith(question: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserAnswerModelImplCopyWith<$Res>
    implements $UserAnswerModelCopyWith<$Res> {
  factory _$$UserAnswerModelImplCopyWith(_$UserAnswerModelImpl value,
          $Res Function(_$UserAnswerModelImpl) then) =
      __$$UserAnswerModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userExamId,
      String questionId,
      String? selectedOptionId,
      String status,
      bool markedForReview,
      int timeSpent,
      QuestionModel? question});

  @override
  $QuestionModelCopyWith<$Res>? get question;
}

/// @nodoc
class __$$UserAnswerModelImplCopyWithImpl<$Res>
    extends _$UserAnswerModelCopyWithImpl<$Res, _$UserAnswerModelImpl>
    implements _$$UserAnswerModelImplCopyWith<$Res> {
  __$$UserAnswerModelImplCopyWithImpl(
      _$UserAnswerModelImpl _value, $Res Function(_$UserAnswerModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userExamId = null,
    Object? questionId = null,
    Object? selectedOptionId = freezed,
    Object? status = null,
    Object? markedForReview = null,
    Object? timeSpent = null,
    Object? question = freezed,
  }) {
    return _then(_$UserAnswerModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userExamId: null == userExamId
          ? _value.userExamId
          : userExamId // ignore: cast_nullable_to_non_nullable
              as String,
      questionId: null == questionId
          ? _value.questionId
          : questionId // ignore: cast_nullable_to_non_nullable
              as String,
      selectedOptionId: freezed == selectedOptionId
          ? _value.selectedOptionId
          : selectedOptionId // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      markedForReview: null == markedForReview
          ? _value.markedForReview
          : markedForReview // ignore: cast_nullable_to_non_nullable
              as bool,
      timeSpent: null == timeSpent
          ? _value.timeSpent
          : timeSpent // ignore: cast_nullable_to_non_nullable
              as int,
      question: freezed == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as QuestionModel?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserAnswerModelImpl implements _UserAnswerModel {
  const _$UserAnswerModelImpl(
      {required this.id,
      required this.userExamId,
      required this.questionId,
      this.selectedOptionId,
      required this.status,
      required this.markedForReview,
      required this.timeSpent,
      this.question});

  factory _$UserAnswerModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserAnswerModelImplFromJson(json);

  @override
  final String id;
  @override
  final String userExamId;
  @override
  final String questionId;
  @override
  final String? selectedOptionId;
  @override
  final String status;
// CORRECT, WRONG, SKIPPED
  @override
  final bool markedForReview;
  @override
  final int timeSpent;
  @override
  final QuestionModel? question;

  @override
  String toString() {
    return 'UserAnswerModel(id: $id, userExamId: $userExamId, questionId: $questionId, selectedOptionId: $selectedOptionId, status: $status, markedForReview: $markedForReview, timeSpent: $timeSpent, question: $question)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserAnswerModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userExamId, userExamId) ||
                other.userExamId == userExamId) &&
            (identical(other.questionId, questionId) ||
                other.questionId == questionId) &&
            (identical(other.selectedOptionId, selectedOptionId) ||
                other.selectedOptionId == selectedOptionId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.markedForReview, markedForReview) ||
                other.markedForReview == markedForReview) &&
            (identical(other.timeSpent, timeSpent) ||
                other.timeSpent == timeSpent) &&
            (identical(other.question, question) ||
                other.question == question));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, userExamId, questionId,
      selectedOptionId, status, markedForReview, timeSpent, question);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserAnswerModelImplCopyWith<_$UserAnswerModelImpl> get copyWith =>
      __$$UserAnswerModelImplCopyWithImpl<_$UserAnswerModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserAnswerModelImplToJson(
      this,
    );
  }
}

abstract class _UserAnswerModel implements UserAnswerModel {
  const factory _UserAnswerModel(
      {required final String id,
      required final String userExamId,
      required final String questionId,
      final String? selectedOptionId,
      required final String status,
      required final bool markedForReview,
      required final int timeSpent,
      final QuestionModel? question}) = _$UserAnswerModelImpl;

  factory _UserAnswerModel.fromJson(Map<String, dynamic> json) =
      _$UserAnswerModelImpl.fromJson;

  @override
  String get id;
  @override
  String get userExamId;
  @override
  String get questionId;
  @override
  String? get selectedOptionId;
  @override
  String get status;
  @override // CORRECT, WRONG, SKIPPED
  bool get markedForReview;
  @override
  int get timeSpent;
  @override
  QuestionModel? get question;
  @override
  @JsonKey(ignore: true)
  _$$UserAnswerModelImplCopyWith<_$UserAnswerModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserExamModel _$UserExamModelFromJson(Map<String, dynamic> json) {
  return _UserExamModel.fromJson(json);
}

/// @nodoc
mixin _$UserExamModel {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get examId => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // IN_PROGRESS, COMPLETED, TIMED_OUT
  double get score => throw _privateConstructorUsedError;
  int get totalQuestions => throw _privateConstructorUsedError;
  int get correctCount => throw _privateConstructorUsedError;
  int get wrongCount => throw _privateConstructorUsedError;
  int get skippedCount => throw _privateConstructorUsedError;
  double get accuracy => throw _privateConstructorUsedError;
  int get timeTaken => throw _privateConstructorUsedError;
  int? get rank => throw _privateConstructorUsedError;
  double? get percentile => throw _privateConstructorUsedError;
  String get startedAt => throw _privateConstructorUsedError;
  String? get endedAt => throw _privateConstructorUsedError;
  List<UserAnswerModel>? get answers => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserExamModelCopyWith<UserExamModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserExamModelCopyWith<$Res> {
  factory $UserExamModelCopyWith(
          UserExamModel value, $Res Function(UserExamModel) then) =
      _$UserExamModelCopyWithImpl<$Res, UserExamModel>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String examId,
      String status,
      double score,
      int totalQuestions,
      int correctCount,
      int wrongCount,
      int skippedCount,
      double accuracy,
      int timeTaken,
      int? rank,
      double? percentile,
      String startedAt,
      String? endedAt,
      List<UserAnswerModel>? answers});
}

/// @nodoc
class _$UserExamModelCopyWithImpl<$Res, $Val extends UserExamModel>
    implements $UserExamModelCopyWith<$Res> {
  _$UserExamModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? examId = null,
    Object? status = null,
    Object? score = null,
    Object? totalQuestions = null,
    Object? correctCount = null,
    Object? wrongCount = null,
    Object? skippedCount = null,
    Object? accuracy = null,
    Object? timeTaken = null,
    Object? rank = freezed,
    Object? percentile = freezed,
    Object? startedAt = null,
    Object? endedAt = freezed,
    Object? answers = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      examId: null == examId
          ? _value.examId
          : examId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      totalQuestions: null == totalQuestions
          ? _value.totalQuestions
          : totalQuestions // ignore: cast_nullable_to_non_nullable
              as int,
      correctCount: null == correctCount
          ? _value.correctCount
          : correctCount // ignore: cast_nullable_to_non_nullable
              as int,
      wrongCount: null == wrongCount
          ? _value.wrongCount
          : wrongCount // ignore: cast_nullable_to_non_nullable
              as int,
      skippedCount: null == skippedCount
          ? _value.skippedCount
          : skippedCount // ignore: cast_nullable_to_non_nullable
              as int,
      accuracy: null == accuracy
          ? _value.accuracy
          : accuracy // ignore: cast_nullable_to_non_nullable
              as double,
      timeTaken: null == timeTaken
          ? _value.timeTaken
          : timeTaken // ignore: cast_nullable_to_non_nullable
              as int,
      rank: freezed == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as int?,
      percentile: freezed == percentile
          ? _value.percentile
          : percentile // ignore: cast_nullable_to_non_nullable
              as double?,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as String,
      endedAt: freezed == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      answers: freezed == answers
          ? _value.answers
          : answers // ignore: cast_nullable_to_non_nullable
              as List<UserAnswerModel>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserExamModelImplCopyWith<$Res>
    implements $UserExamModelCopyWith<$Res> {
  factory _$$UserExamModelImplCopyWith(
          _$UserExamModelImpl value, $Res Function(_$UserExamModelImpl) then) =
      __$$UserExamModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String examId,
      String status,
      double score,
      int totalQuestions,
      int correctCount,
      int wrongCount,
      int skippedCount,
      double accuracy,
      int timeTaken,
      int? rank,
      double? percentile,
      String startedAt,
      String? endedAt,
      List<UserAnswerModel>? answers});
}

/// @nodoc
class __$$UserExamModelImplCopyWithImpl<$Res>
    extends _$UserExamModelCopyWithImpl<$Res, _$UserExamModelImpl>
    implements _$$UserExamModelImplCopyWith<$Res> {
  __$$UserExamModelImplCopyWithImpl(
      _$UserExamModelImpl _value, $Res Function(_$UserExamModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? examId = null,
    Object? status = null,
    Object? score = null,
    Object? totalQuestions = null,
    Object? correctCount = null,
    Object? wrongCount = null,
    Object? skippedCount = null,
    Object? accuracy = null,
    Object? timeTaken = null,
    Object? rank = freezed,
    Object? percentile = freezed,
    Object? startedAt = null,
    Object? endedAt = freezed,
    Object? answers = freezed,
  }) {
    return _then(_$UserExamModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      examId: null == examId
          ? _value.examId
          : examId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      totalQuestions: null == totalQuestions
          ? _value.totalQuestions
          : totalQuestions // ignore: cast_nullable_to_non_nullable
              as int,
      correctCount: null == correctCount
          ? _value.correctCount
          : correctCount // ignore: cast_nullable_to_non_nullable
              as int,
      wrongCount: null == wrongCount
          ? _value.wrongCount
          : wrongCount // ignore: cast_nullable_to_non_nullable
              as int,
      skippedCount: null == skippedCount
          ? _value.skippedCount
          : skippedCount // ignore: cast_nullable_to_non_nullable
              as int,
      accuracy: null == accuracy
          ? _value.accuracy
          : accuracy // ignore: cast_nullable_to_non_nullable
              as double,
      timeTaken: null == timeTaken
          ? _value.timeTaken
          : timeTaken // ignore: cast_nullable_to_non_nullable
              as int,
      rank: freezed == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as int?,
      percentile: freezed == percentile
          ? _value.percentile
          : percentile // ignore: cast_nullable_to_non_nullable
              as double?,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as String,
      endedAt: freezed == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      answers: freezed == answers
          ? _value._answers
          : answers // ignore: cast_nullable_to_non_nullable
              as List<UserAnswerModel>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserExamModelImpl implements _UserExamModel {
  const _$UserExamModelImpl(
      {required this.id,
      required this.userId,
      required this.examId,
      required this.status,
      required this.score,
      required this.totalQuestions,
      required this.correctCount,
      required this.wrongCount,
      required this.skippedCount,
      required this.accuracy,
      required this.timeTaken,
      this.rank,
      this.percentile,
      required this.startedAt,
      this.endedAt,
      final List<UserAnswerModel>? answers})
      : _answers = answers;

  factory _$UserExamModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserExamModelImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String examId;
  @override
  final String status;
// IN_PROGRESS, COMPLETED, TIMED_OUT
  @override
  final double score;
  @override
  final int totalQuestions;
  @override
  final int correctCount;
  @override
  final int wrongCount;
  @override
  final int skippedCount;
  @override
  final double accuracy;
  @override
  final int timeTaken;
  @override
  final int? rank;
  @override
  final double? percentile;
  @override
  final String startedAt;
  @override
  final String? endedAt;
  final List<UserAnswerModel>? _answers;
  @override
  List<UserAnswerModel>? get answers {
    final value = _answers;
    if (value == null) return null;
    if (_answers is EqualUnmodifiableListView) return _answers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'UserExamModel(id: $id, userId: $userId, examId: $examId, status: $status, score: $score, totalQuestions: $totalQuestions, correctCount: $correctCount, wrongCount: $wrongCount, skippedCount: $skippedCount, accuracy: $accuracy, timeTaken: $timeTaken, rank: $rank, percentile: $percentile, startedAt: $startedAt, endedAt: $endedAt, answers: $answers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserExamModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.examId, examId) || other.examId == examId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.totalQuestions, totalQuestions) ||
                other.totalQuestions == totalQuestions) &&
            (identical(other.correctCount, correctCount) ||
                other.correctCount == correctCount) &&
            (identical(other.wrongCount, wrongCount) ||
                other.wrongCount == wrongCount) &&
            (identical(other.skippedCount, skippedCount) ||
                other.skippedCount == skippedCount) &&
            (identical(other.accuracy, accuracy) ||
                other.accuracy == accuracy) &&
            (identical(other.timeTaken, timeTaken) ||
                other.timeTaken == timeTaken) &&
            (identical(other.rank, rank) || other.rank == rank) &&
            (identical(other.percentile, percentile) ||
                other.percentile == percentile) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            const DeepCollectionEquality().equals(other._answers, _answers));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      examId,
      status,
      score,
      totalQuestions,
      correctCount,
      wrongCount,
      skippedCount,
      accuracy,
      timeTaken,
      rank,
      percentile,
      startedAt,
      endedAt,
      const DeepCollectionEquality().hash(_answers));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserExamModelImplCopyWith<_$UserExamModelImpl> get copyWith =>
      __$$UserExamModelImplCopyWithImpl<_$UserExamModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserExamModelImplToJson(
      this,
    );
  }
}

abstract class _UserExamModel implements UserExamModel {
  const factory _UserExamModel(
      {required final String id,
      required final String userId,
      required final String examId,
      required final String status,
      required final double score,
      required final int totalQuestions,
      required final int correctCount,
      required final int wrongCount,
      required final int skippedCount,
      required final double accuracy,
      required final int timeTaken,
      final int? rank,
      final double? percentile,
      required final String startedAt,
      final String? endedAt,
      final List<UserAnswerModel>? answers}) = _$UserExamModelImpl;

  factory _UserExamModel.fromJson(Map<String, dynamic> json) =
      _$UserExamModelImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get examId;
  @override
  String get status;
  @override // IN_PROGRESS, COMPLETED, TIMED_OUT
  double get score;
  @override
  int get totalQuestions;
  @override
  int get correctCount;
  @override
  int get wrongCount;
  @override
  int get skippedCount;
  @override
  double get accuracy;
  @override
  int get timeTaken;
  @override
  int? get rank;
  @override
  double? get percentile;
  @override
  String get startedAt;
  @override
  String? get endedAt;
  @override
  List<UserAnswerModel>? get answers;
  @override
  @JsonKey(ignore: true)
  _$$UserExamModelImplCopyWith<_$UserExamModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
