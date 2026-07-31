// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'question_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OptionModel _$OptionModelFromJson(Map<String, dynamic> json) {
  return _OptionModel.fromJson(json);
}

/// @nodoc
mixin _$OptionModel {
  String get id => throw _privateConstructorUsedError;
  String get questionId => throw _privateConstructorUsedError;
  String get optionText => throw _privateConstructorUsedError;
  String? get imageKey => throw _privateConstructorUsedError;
  bool get isCorrect => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OptionModelCopyWith<OptionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OptionModelCopyWith<$Res> {
  factory $OptionModelCopyWith(
          OptionModel value, $Res Function(OptionModel) then) =
      _$OptionModelCopyWithImpl<$Res, OptionModel>;
  @useResult
  $Res call(
      {String id,
      String questionId,
      String optionText,
      String? imageKey,
      bool isCorrect});
}

/// @nodoc
class _$OptionModelCopyWithImpl<$Res, $Val extends OptionModel>
    implements $OptionModelCopyWith<$Res> {
  _$OptionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? questionId = null,
    Object? optionText = null,
    Object? imageKey = freezed,
    Object? isCorrect = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      questionId: null == questionId
          ? _value.questionId
          : questionId // ignore: cast_nullable_to_non_nullable
              as String,
      optionText: null == optionText
          ? _value.optionText
          : optionText // ignore: cast_nullable_to_non_nullable
              as String,
      imageKey: freezed == imageKey
          ? _value.imageKey
          : imageKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isCorrect: null == isCorrect
          ? _value.isCorrect
          : isCorrect // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OptionModelImplCopyWith<$Res>
    implements $OptionModelCopyWith<$Res> {
  factory _$$OptionModelImplCopyWith(
          _$OptionModelImpl value, $Res Function(_$OptionModelImpl) then) =
      __$$OptionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String questionId,
      String optionText,
      String? imageKey,
      bool isCorrect});
}

/// @nodoc
class __$$OptionModelImplCopyWithImpl<$Res>
    extends _$OptionModelCopyWithImpl<$Res, _$OptionModelImpl>
    implements _$$OptionModelImplCopyWith<$Res> {
  __$$OptionModelImplCopyWithImpl(
      _$OptionModelImpl _value, $Res Function(_$OptionModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? questionId = null,
    Object? optionText = null,
    Object? imageKey = freezed,
    Object? isCorrect = null,
  }) {
    return _then(_$OptionModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      questionId: null == questionId
          ? _value.questionId
          : questionId // ignore: cast_nullable_to_non_nullable
              as String,
      optionText: null == optionText
          ? _value.optionText
          : optionText // ignore: cast_nullable_to_non_nullable
              as String,
      imageKey: freezed == imageKey
          ? _value.imageKey
          : imageKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isCorrect: null == isCorrect
          ? _value.isCorrect
          : isCorrect // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OptionModelImpl implements _OptionModel {
  const _$OptionModelImpl(
      {required this.id,
      required this.questionId,
      required this.optionText,
      this.imageKey,
      required this.isCorrect});

  factory _$OptionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$OptionModelImplFromJson(json);

  @override
  final String id;
  @override
  final String questionId;
  @override
  final String optionText;
  @override
  final String? imageKey;
  @override
  final bool isCorrect;

  @override
  String toString() {
    return 'OptionModel(id: $id, questionId: $questionId, optionText: $optionText, imageKey: $imageKey, isCorrect: $isCorrect)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OptionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.questionId, questionId) ||
                other.questionId == questionId) &&
            (identical(other.optionText, optionText) ||
                other.optionText == optionText) &&
            (identical(other.imageKey, imageKey) ||
                other.imageKey == imageKey) &&
            (identical(other.isCorrect, isCorrect) ||
                other.isCorrect == isCorrect));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, questionId, optionText, imageKey, isCorrect);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OptionModelImplCopyWith<_$OptionModelImpl> get copyWith =>
      __$$OptionModelImplCopyWithImpl<_$OptionModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OptionModelImplToJson(
      this,
    );
  }
}

abstract class _OptionModel implements OptionModel {
  const factory _OptionModel(
      {required final String id,
      required final String questionId,
      required final String optionText,
      final String? imageKey,
      required final bool isCorrect}) = _$OptionModelImpl;

  factory _OptionModel.fromJson(Map<String, dynamic> json) =
      _$OptionModelImpl.fromJson;

  @override
  String get id;
  @override
  String get questionId;
  @override
  String get optionText;
  @override
  String? get imageKey;
  @override
  bool get isCorrect;
  @override
  @JsonKey(ignore: true)
  _$$OptionModelImplCopyWith<_$OptionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExplanationModel _$ExplanationModelFromJson(Map<String, dynamic> json) {
  return _ExplanationModel.fromJson(json);
}

/// @nodoc
mixin _$ExplanationModel {
  String get id => throw _privateConstructorUsedError;
  String get questionId => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  String? get imageKey => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ExplanationModelCopyWith<ExplanationModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExplanationModelCopyWith<$Res> {
  factory $ExplanationModelCopyWith(
          ExplanationModel value, $Res Function(ExplanationModel) then) =
      _$ExplanationModelCopyWithImpl<$Res, ExplanationModel>;
  @useResult
  $Res call({String id, String questionId, String text, String? imageKey});
}

/// @nodoc
class _$ExplanationModelCopyWithImpl<$Res, $Val extends ExplanationModel>
    implements $ExplanationModelCopyWith<$Res> {
  _$ExplanationModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? questionId = null,
    Object? text = null,
    Object? imageKey = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      questionId: null == questionId
          ? _value.questionId
          : questionId // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      imageKey: freezed == imageKey
          ? _value.imageKey
          : imageKey // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExplanationModelImplCopyWith<$Res>
    implements $ExplanationModelCopyWith<$Res> {
  factory _$$ExplanationModelImplCopyWith(_$ExplanationModelImpl value,
          $Res Function(_$ExplanationModelImpl) then) =
      __$$ExplanationModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String questionId, String text, String? imageKey});
}

/// @nodoc
class __$$ExplanationModelImplCopyWithImpl<$Res>
    extends _$ExplanationModelCopyWithImpl<$Res, _$ExplanationModelImpl>
    implements _$$ExplanationModelImplCopyWith<$Res> {
  __$$ExplanationModelImplCopyWithImpl(_$ExplanationModelImpl _value,
      $Res Function(_$ExplanationModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? questionId = null,
    Object? text = null,
    Object? imageKey = freezed,
  }) {
    return _then(_$ExplanationModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      questionId: null == questionId
          ? _value.questionId
          : questionId // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      imageKey: freezed == imageKey
          ? _value.imageKey
          : imageKey // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExplanationModelImpl implements _ExplanationModel {
  const _$ExplanationModelImpl(
      {required this.id,
      required this.questionId,
      required this.text,
      this.imageKey});

  factory _$ExplanationModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExplanationModelImplFromJson(json);

  @override
  final String id;
  @override
  final String questionId;
  @override
  final String text;
  @override
  final String? imageKey;

  @override
  String toString() {
    return 'ExplanationModel(id: $id, questionId: $questionId, text: $text, imageKey: $imageKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExplanationModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.questionId, questionId) ||
                other.questionId == questionId) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.imageKey, imageKey) ||
                other.imageKey == imageKey));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, questionId, text, imageKey);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExplanationModelImplCopyWith<_$ExplanationModelImpl> get copyWith =>
      __$$ExplanationModelImplCopyWithImpl<_$ExplanationModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExplanationModelImplToJson(
      this,
    );
  }
}

abstract class _ExplanationModel implements ExplanationModel {
  const factory _ExplanationModel(
      {required final String id,
      required final String questionId,
      required final String text,
      final String? imageKey}) = _$ExplanationModelImpl;

  factory _ExplanationModel.fromJson(Map<String, dynamic> json) =
      _$ExplanationModelImpl.fromJson;

  @override
  String get id;
  @override
  String get questionId;
  @override
  String get text;
  @override
  String? get imageKey;
  @override
  @JsonKey(ignore: true)
  _$$ExplanationModelImplCopyWith<_$ExplanationModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

QuestionModel _$QuestionModelFromJson(Map<String, dynamic> json) {
  return _QuestionModel.fromJson(json);
}

/// @nodoc
mixin _$QuestionModel {
  String get id => throw _privateConstructorUsedError;
  String get questionText => throw _privateConstructorUsedError;
  String? get imageKey => throw _privateConstructorUsedError;
  String? get latexFormula => throw _privateConstructorUsedError;
  String? get difficulty => throw _privateConstructorUsedError;
  String get subjectId => throw _privateConstructorUsedError;
  String get chapterId => throw _privateConstructorUsedError;
  String? get topicId => throw _privateConstructorUsedError;
  String? get board => throw _privateConstructorUsedError;
  int? get year => throw _privateConstructorUsedError;
  String? get source => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  int get estimatedTime => throw _privateConstructorUsedError;
  double get marks => throw _privateConstructorUsedError;
  double get negativeMarks => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  List<OptionModel> get options => throw _privateConstructorUsedError;
  List<ExplanationModel>? get explanations =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QuestionModelCopyWith<QuestionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestionModelCopyWith<$Res> {
  factory $QuestionModelCopyWith(
          QuestionModel value, $Res Function(QuestionModel) then) =
      _$QuestionModelCopyWithImpl<$Res, QuestionModel>;
  @useResult
  $Res call(
      {String id,
      String questionText,
      String? imageKey,
      String? latexFormula,
      String? difficulty,
      String subjectId,
      String chapterId,
      String? topicId,
      String? board,
      int? year,
      String? source,
      List<String> tags,
      int estimatedTime,
      double marks,
      double negativeMarks,
      String status,
      List<OptionModel> options,
      List<ExplanationModel>? explanations});
}

/// @nodoc
class _$QuestionModelCopyWithImpl<$Res, $Val extends QuestionModel>
    implements $QuestionModelCopyWith<$Res> {
  _$QuestionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? questionText = null,
    Object? imageKey = freezed,
    Object? latexFormula = freezed,
    Object? difficulty = freezed,
    Object? subjectId = null,
    Object? chapterId = null,
    Object? topicId = freezed,
    Object? board = freezed,
    Object? year = freezed,
    Object? source = freezed,
    Object? tags = null,
    Object? estimatedTime = null,
    Object? marks = null,
    Object? negativeMarks = null,
    Object? status = null,
    Object? options = null,
    Object? explanations = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      questionText: null == questionText
          ? _value.questionText
          : questionText // ignore: cast_nullable_to_non_nullable
              as String,
      imageKey: freezed == imageKey
          ? _value.imageKey
          : imageKey // ignore: cast_nullable_to_non_nullable
              as String?,
      latexFormula: freezed == latexFormula
          ? _value.latexFormula
          : latexFormula // ignore: cast_nullable_to_non_nullable
              as String?,
      difficulty: freezed == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String?,
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      chapterId: null == chapterId
          ? _value.chapterId
          : chapterId // ignore: cast_nullable_to_non_nullable
              as String,
      topicId: freezed == topicId
          ? _value.topicId
          : topicId // ignore: cast_nullable_to_non_nullable
              as String?,
      board: freezed == board
          ? _value.board
          : board // ignore: cast_nullable_to_non_nullable
              as String?,
      year: freezed == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int?,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      estimatedTime: null == estimatedTime
          ? _value.estimatedTime
          : estimatedTime // ignore: cast_nullable_to_non_nullable
              as int,
      marks: null == marks
          ? _value.marks
          : marks // ignore: cast_nullable_to_non_nullable
              as double,
      negativeMarks: null == negativeMarks
          ? _value.negativeMarks
          : negativeMarks // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as List<OptionModel>,
      explanations: freezed == explanations
          ? _value.explanations
          : explanations // ignore: cast_nullable_to_non_nullable
              as List<ExplanationModel>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuestionModelImplCopyWith<$Res>
    implements $QuestionModelCopyWith<$Res> {
  factory _$$QuestionModelImplCopyWith(
          _$QuestionModelImpl value, $Res Function(_$QuestionModelImpl) then) =
      __$$QuestionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String questionText,
      String? imageKey,
      String? latexFormula,
      String? difficulty,
      String subjectId,
      String chapterId,
      String? topicId,
      String? board,
      int? year,
      String? source,
      List<String> tags,
      int estimatedTime,
      double marks,
      double negativeMarks,
      String status,
      List<OptionModel> options,
      List<ExplanationModel>? explanations});
}

/// @nodoc
class __$$QuestionModelImplCopyWithImpl<$Res>
    extends _$QuestionModelCopyWithImpl<$Res, _$QuestionModelImpl>
    implements _$$QuestionModelImplCopyWith<$Res> {
  __$$QuestionModelImplCopyWithImpl(
      _$QuestionModelImpl _value, $Res Function(_$QuestionModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? questionText = null,
    Object? imageKey = freezed,
    Object? latexFormula = freezed,
    Object? difficulty = freezed,
    Object? subjectId = null,
    Object? chapterId = null,
    Object? topicId = freezed,
    Object? board = freezed,
    Object? year = freezed,
    Object? source = freezed,
    Object? tags = null,
    Object? estimatedTime = null,
    Object? marks = null,
    Object? negativeMarks = null,
    Object? status = null,
    Object? options = null,
    Object? explanations = freezed,
  }) {
    return _then(_$QuestionModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      questionText: null == questionText
          ? _value.questionText
          : questionText // ignore: cast_nullable_to_non_nullable
              as String,
      imageKey: freezed == imageKey
          ? _value.imageKey
          : imageKey // ignore: cast_nullable_to_non_nullable
              as String?,
      latexFormula: freezed == latexFormula
          ? _value.latexFormula
          : latexFormula // ignore: cast_nullable_to_non_nullable
              as String?,
      difficulty: freezed == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String?,
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      chapterId: null == chapterId
          ? _value.chapterId
          : chapterId // ignore: cast_nullable_to_non_nullable
              as String,
      topicId: freezed == topicId
          ? _value.topicId
          : topicId // ignore: cast_nullable_to_non_nullable
              as String?,
      board: freezed == board
          ? _value.board
          : board // ignore: cast_nullable_to_non_nullable
              as String?,
      year: freezed == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int?,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      estimatedTime: null == estimatedTime
          ? _value.estimatedTime
          : estimatedTime // ignore: cast_nullable_to_non_nullable
              as int,
      marks: null == marks
          ? _value.marks
          : marks // ignore: cast_nullable_to_non_nullable
              as double,
      negativeMarks: null == negativeMarks
          ? _value.negativeMarks
          : negativeMarks // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      options: null == options
          ? _value._options
          : options // ignore: cast_nullable_to_non_nullable
              as List<OptionModel>,
      explanations: freezed == explanations
          ? _value._explanations
          : explanations // ignore: cast_nullable_to_non_nullable
              as List<ExplanationModel>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuestionModelImpl implements _QuestionModel {
  const _$QuestionModelImpl(
      {required this.id,
      required this.questionText,
      this.imageKey,
      this.latexFormula,
      this.difficulty,
      required this.subjectId,
      required this.chapterId,
      this.topicId,
      this.board,
      this.year,
      this.source,
      required final List<String> tags,
      required this.estimatedTime,
      required this.marks,
      required this.negativeMarks,
      required this.status,
      required final List<OptionModel> options,
      final List<ExplanationModel>? explanations})
      : _tags = tags,
        _options = options,
        _explanations = explanations;

  factory _$QuestionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuestionModelImplFromJson(json);

  @override
  final String id;
  @override
  final String questionText;
  @override
  final String? imageKey;
  @override
  final String? latexFormula;
  @override
  final String? difficulty;
  @override
  final String subjectId;
  @override
  final String chapterId;
  @override
  final String? topicId;
  @override
  final String? board;
  @override
  final int? year;
  @override
  final String? source;
  final List<String> _tags;
  @override
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  final int estimatedTime;
  @override
  final double marks;
  @override
  final double negativeMarks;
  @override
  final String status;
  final List<OptionModel> _options;
  @override
  List<OptionModel> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

  final List<ExplanationModel>? _explanations;
  @override
  List<ExplanationModel>? get explanations {
    final value = _explanations;
    if (value == null) return null;
    if (_explanations is EqualUnmodifiableListView) return _explanations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'QuestionModel(id: $id, questionText: $questionText, imageKey: $imageKey, latexFormula: $latexFormula, difficulty: $difficulty, subjectId: $subjectId, chapterId: $chapterId, topicId: $topicId, board: $board, year: $year, source: $source, tags: $tags, estimatedTime: $estimatedTime, marks: $marks, negativeMarks: $negativeMarks, status: $status, options: $options, explanations: $explanations)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.questionText, questionText) ||
                other.questionText == questionText) &&
            (identical(other.imageKey, imageKey) ||
                other.imageKey == imageKey) &&
            (identical(other.latexFormula, latexFormula) ||
                other.latexFormula == latexFormula) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.subjectId, subjectId) ||
                other.subjectId == subjectId) &&
            (identical(other.chapterId, chapterId) ||
                other.chapterId == chapterId) &&
            (identical(other.topicId, topicId) || other.topicId == topicId) &&
            (identical(other.board, board) || other.board == board) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.source, source) || other.source == source) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.estimatedTime, estimatedTime) ||
                other.estimatedTime == estimatedTime) &&
            (identical(other.marks, marks) || other.marks == marks) &&
            (identical(other.negativeMarks, negativeMarks) ||
                other.negativeMarks == negativeMarks) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._options, _options) &&
            const DeepCollectionEquality()
                .equals(other._explanations, _explanations));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      questionText,
      imageKey,
      latexFormula,
      difficulty,
      subjectId,
      chapterId,
      topicId,
      board,
      year,
      source,
      const DeepCollectionEquality().hash(_tags),
      estimatedTime,
      marks,
      negativeMarks,
      status,
      const DeepCollectionEquality().hash(_options),
      const DeepCollectionEquality().hash(_explanations));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestionModelImplCopyWith<_$QuestionModelImpl> get copyWith =>
      __$$QuestionModelImplCopyWithImpl<_$QuestionModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuestionModelImplToJson(
      this,
    );
  }
}

abstract class _QuestionModel implements QuestionModel {
  const factory _QuestionModel(
      {required final String id,
      required final String questionText,
      final String? imageKey,
      final String? latexFormula,
      final String? difficulty,
      required final String subjectId,
      required final String chapterId,
      final String? topicId,
      final String? board,
      final int? year,
      final String? source,
      required final List<String> tags,
      required final int estimatedTime,
      required final double marks,
      required final double negativeMarks,
      required final String status,
      required final List<OptionModel> options,
      final List<ExplanationModel>? explanations}) = _$QuestionModelImpl;

  factory _QuestionModel.fromJson(Map<String, dynamic> json) =
      _$QuestionModelImpl.fromJson;

  @override
  String get id;
  @override
  String get questionText;
  @override
  String? get imageKey;
  @override
  String? get latexFormula;
  @override
  String? get difficulty;
  @override
  String get subjectId;
  @override
  String get chapterId;
  @override
  String? get topicId;
  @override
  String? get board;
  @override
  int? get year;
  @override
  String? get source;
  @override
  List<String> get tags;
  @override
  int get estimatedTime;
  @override
  double get marks;
  @override
  double get negativeMarks;
  @override
  String get status;
  @override
  List<OptionModel> get options;
  @override
  List<ExplanationModel>? get explanations;
  @override
  @JsonKey(ignore: true)
  _$$QuestionModelImplCopyWith<_$QuestionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
