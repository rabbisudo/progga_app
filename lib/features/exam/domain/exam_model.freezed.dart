// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exam_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ExamQuestionModel _$ExamQuestionModelFromJson(Map<String, dynamic> json) {
  return _ExamQuestionModel.fromJson(json);
}

/// @nodoc
mixin _$ExamQuestionModel {
  String get id => throw _privateConstructorUsedError;
  String get examId => throw _privateConstructorUsedError;
  String? get questionId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  QuestionModel get question => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ExamQuestionModelCopyWith<ExamQuestionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExamQuestionModelCopyWith<$Res> {
  factory $ExamQuestionModelCopyWith(
          ExamQuestionModel value, $Res Function(ExamQuestionModel) then) =
      _$ExamQuestionModelCopyWithImpl<$Res, ExamQuestionModel>;
  @useResult
  $Res call(
      {String id,
      String examId,
      String? questionId,
      int sortOrder,
      QuestionModel question});

  $QuestionModelCopyWith<$Res> get question;
}

/// @nodoc
class _$ExamQuestionModelCopyWithImpl<$Res, $Val extends ExamQuestionModel>
    implements $ExamQuestionModelCopyWith<$Res> {
  _$ExamQuestionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? examId = null,
    Object? questionId = freezed,
    Object? sortOrder = null,
    Object? question = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      examId: null == examId
          ? _value.examId
          : examId // ignore: cast_nullable_to_non_nullable
              as String,
      questionId: freezed == questionId
          ? _value.questionId
          : questionId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      question: null == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as QuestionModel,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $QuestionModelCopyWith<$Res> get question {
    return $QuestionModelCopyWith<$Res>(_value.question, (value) {
      return _then(_value.copyWith(question: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ExamQuestionModelImplCopyWith<$Res>
    implements $ExamQuestionModelCopyWith<$Res> {
  factory _$$ExamQuestionModelImplCopyWith(_$ExamQuestionModelImpl value,
          $Res Function(_$ExamQuestionModelImpl) then) =
      __$$ExamQuestionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String examId,
      String? questionId,
      int sortOrder,
      QuestionModel question});

  @override
  $QuestionModelCopyWith<$Res> get question;
}

/// @nodoc
class __$$ExamQuestionModelImplCopyWithImpl<$Res>
    extends _$ExamQuestionModelCopyWithImpl<$Res, _$ExamQuestionModelImpl>
    implements _$$ExamQuestionModelImplCopyWith<$Res> {
  __$$ExamQuestionModelImplCopyWithImpl(_$ExamQuestionModelImpl _value,
      $Res Function(_$ExamQuestionModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? examId = null,
    Object? questionId = freezed,
    Object? sortOrder = null,
    Object? question = null,
  }) {
    return _then(_$ExamQuestionModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      examId: null == examId
          ? _value.examId
          : examId // ignore: cast_nullable_to_non_nullable
              as String,
      questionId: freezed == questionId
          ? _value.questionId
          : questionId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      question: null == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as QuestionModel,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExamQuestionModelImpl implements _ExamQuestionModel {
  const _$ExamQuestionModelImpl(
      {required this.id,
      required this.examId,
      this.questionId,
      required this.sortOrder,
      required this.question});

  factory _$ExamQuestionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExamQuestionModelImplFromJson(json);

  @override
  final String id;
  @override
  final String examId;
  @override
  final String? questionId;
  @override
  final int sortOrder;
  @override
  final QuestionModel question;

  @override
  String toString() {
    return 'ExamQuestionModel(id: $id, examId: $examId, questionId: $questionId, sortOrder: $sortOrder, question: $question)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExamQuestionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.examId, examId) || other.examId == examId) &&
            (identical(other.questionId, questionId) ||
                other.questionId == questionId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.question, question) ||
                other.question == question));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, examId, questionId, sortOrder, question);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExamQuestionModelImplCopyWith<_$ExamQuestionModelImpl> get copyWith =>
      __$$ExamQuestionModelImplCopyWithImpl<_$ExamQuestionModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExamQuestionModelImplToJson(
      this,
    );
  }
}

abstract class _ExamQuestionModel implements ExamQuestionModel {
  const factory _ExamQuestionModel(
      {required final String id,
      required final String examId,
      final String? questionId,
      required final int sortOrder,
      required final QuestionModel question}) = _$ExamQuestionModelImpl;

  factory _ExamQuestionModel.fromJson(Map<String, dynamic> json) =
      _$ExamQuestionModelImpl.fromJson;

  @override
  String get id;
  @override
  String get examId;
  @override
  String? get questionId;
  @override
  int get sortOrder;
  @override
  QuestionModel get question;
  @override
  @JsonKey(ignore: true)
  _$$ExamQuestionModelImplCopyWith<_$ExamQuestionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExamSourceImageModel _$ExamSourceImageModelFromJson(Map<String, dynamic> json) {
  return _ExamSourceImageModel.fromJson(json);
}

/// @nodoc
mixin _$ExamSourceImageModel {
  String get id => throw _privateConstructorUsedError;
  String get examId => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ExamSourceImageModelCopyWith<ExamSourceImageModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExamSourceImageModelCopyWith<$Res> {
  factory $ExamSourceImageModelCopyWith(ExamSourceImageModel value,
          $Res Function(ExamSourceImageModel) then) =
      _$ExamSourceImageModelCopyWithImpl<$Res, ExamSourceImageModel>;
  @useResult
  $Res call({String id, String examId, String url});
}

/// @nodoc
class _$ExamSourceImageModelCopyWithImpl<$Res,
        $Val extends ExamSourceImageModel>
    implements $ExamSourceImageModelCopyWith<$Res> {
  _$ExamSourceImageModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? examId = null,
    Object? url = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      examId: null == examId
          ? _value.examId
          : examId // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExamSourceImageModelImplCopyWith<$Res>
    implements $ExamSourceImageModelCopyWith<$Res> {
  factory _$$ExamSourceImageModelImplCopyWith(_$ExamSourceImageModelImpl value,
          $Res Function(_$ExamSourceImageModelImpl) then) =
      __$$ExamSourceImageModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String examId, String url});
}

/// @nodoc
class __$$ExamSourceImageModelImplCopyWithImpl<$Res>
    extends _$ExamSourceImageModelCopyWithImpl<$Res, _$ExamSourceImageModelImpl>
    implements _$$ExamSourceImageModelImplCopyWith<$Res> {
  __$$ExamSourceImageModelImplCopyWithImpl(_$ExamSourceImageModelImpl _value,
      $Res Function(_$ExamSourceImageModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? examId = null,
    Object? url = null,
  }) {
    return _then(_$ExamSourceImageModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      examId: null == examId
          ? _value.examId
          : examId // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExamSourceImageModelImpl implements _ExamSourceImageModel {
  const _$ExamSourceImageModelImpl(
      {required this.id, required this.examId, required this.url});

  factory _$ExamSourceImageModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExamSourceImageModelImplFromJson(json);

  @override
  final String id;
  @override
  final String examId;
  @override
  final String url;

  @override
  String toString() {
    return 'ExamSourceImageModel(id: $id, examId: $examId, url: $url)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExamSourceImageModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.examId, examId) || other.examId == examId) &&
            (identical(other.url, url) || other.url == url));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, examId, url);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExamSourceImageModelImplCopyWith<_$ExamSourceImageModelImpl>
      get copyWith =>
          __$$ExamSourceImageModelImplCopyWithImpl<_$ExamSourceImageModelImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExamSourceImageModelImplToJson(
      this,
    );
  }
}

abstract class _ExamSourceImageModel implements ExamSourceImageModel {
  const factory _ExamSourceImageModel(
      {required final String id,
      required final String examId,
      required final String url}) = _$ExamSourceImageModelImpl;

  factory _ExamSourceImageModel.fromJson(Map<String, dynamic> json) =
      _$ExamSourceImageModelImpl.fromJson;

  @override
  String get id;
  @override
  String get examId;
  @override
  String get url;
  @override
  @JsonKey(ignore: true)
  _$$ExamSourceImageModelImplCopyWith<_$ExamSourceImageModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ExamModel _$ExamModelFromJson(Map<String, dynamic> json) {
  return _ExamModel.fromJson(json);
}

/// @nodoc
mixin _$ExamModel {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  int get duration => throw _privateConstructorUsedError;
  double get totalMarks => throw _privateConstructorUsedError;
  double get negativeMarks => throw _privateConstructorUsedError;
  double get passMarks => throw _privateConstructorUsedError;
  bool get isPublished => throw _privateConstructorUsedError;
  List<ExamQuestionModel> get questions => throw _privateConstructorUsedError;
  List<ExamSourceImageModel> get sourceImages =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ExamModelCopyWith<ExamModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExamModelCopyWith<$Res> {
  factory $ExamModelCopyWith(ExamModel value, $Res Function(ExamModel) then) =
      _$ExamModelCopyWithImpl<$Res, ExamModel>;
  @useResult
  $Res call(
      {String id,
      String title,
      String? description,
      String type,
      int duration,
      double totalMarks,
      double negativeMarks,
      double passMarks,
      bool isPublished,
      List<ExamQuestionModel> questions,
      List<ExamSourceImageModel> sourceImages});
}

/// @nodoc
class _$ExamModelCopyWithImpl<$Res, $Val extends ExamModel>
    implements $ExamModelCopyWith<$Res> {
  _$ExamModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? type = null,
    Object? duration = null,
    Object? totalMarks = null,
    Object? negativeMarks = null,
    Object? passMarks = null,
    Object? isPublished = null,
    Object? questions = null,
    Object? sourceImages = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      totalMarks: null == totalMarks
          ? _value.totalMarks
          : totalMarks // ignore: cast_nullable_to_non_nullable
              as double,
      negativeMarks: null == negativeMarks
          ? _value.negativeMarks
          : negativeMarks // ignore: cast_nullable_to_non_nullable
              as double,
      passMarks: null == passMarks
          ? _value.passMarks
          : passMarks // ignore: cast_nullable_to_non_nullable
              as double,
      isPublished: null == isPublished
          ? _value.isPublished
          : isPublished // ignore: cast_nullable_to_non_nullable
              as bool,
      questions: null == questions
          ? _value.questions
          : questions // ignore: cast_nullable_to_non_nullable
              as List<ExamQuestionModel>,
      sourceImages: null == sourceImages
          ? _value.sourceImages
          : sourceImages // ignore: cast_nullable_to_non_nullable
              as List<ExamSourceImageModel>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExamModelImplCopyWith<$Res>
    implements $ExamModelCopyWith<$Res> {
  factory _$$ExamModelImplCopyWith(
          _$ExamModelImpl value, $Res Function(_$ExamModelImpl) then) =
      __$$ExamModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String? description,
      String type,
      int duration,
      double totalMarks,
      double negativeMarks,
      double passMarks,
      bool isPublished,
      List<ExamQuestionModel> questions,
      List<ExamSourceImageModel> sourceImages});
}

/// @nodoc
class __$$ExamModelImplCopyWithImpl<$Res>
    extends _$ExamModelCopyWithImpl<$Res, _$ExamModelImpl>
    implements _$$ExamModelImplCopyWith<$Res> {
  __$$ExamModelImplCopyWithImpl(
      _$ExamModelImpl _value, $Res Function(_$ExamModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? type = null,
    Object? duration = null,
    Object? totalMarks = null,
    Object? negativeMarks = null,
    Object? passMarks = null,
    Object? isPublished = null,
    Object? questions = null,
    Object? sourceImages = null,
  }) {
    return _then(_$ExamModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      totalMarks: null == totalMarks
          ? _value.totalMarks
          : totalMarks // ignore: cast_nullable_to_non_nullable
              as double,
      negativeMarks: null == negativeMarks
          ? _value.negativeMarks
          : negativeMarks // ignore: cast_nullable_to_non_nullable
              as double,
      passMarks: null == passMarks
          ? _value.passMarks
          : passMarks // ignore: cast_nullable_to_non_nullable
              as double,
      isPublished: null == isPublished
          ? _value.isPublished
          : isPublished // ignore: cast_nullable_to_non_nullable
              as bool,
      questions: null == questions
          ? _value._questions
          : questions // ignore: cast_nullable_to_non_nullable
              as List<ExamQuestionModel>,
      sourceImages: null == sourceImages
          ? _value._sourceImages
          : sourceImages // ignore: cast_nullable_to_non_nullable
              as List<ExamSourceImageModel>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExamModelImpl implements _ExamModel {
  const _$ExamModelImpl(
      {required this.id,
      required this.title,
      this.description,
      required this.type,
      required this.duration,
      required this.totalMarks,
      required this.negativeMarks,
      required this.passMarks,
      required this.isPublished,
      required final List<ExamQuestionModel> questions,
      final List<ExamSourceImageModel> sourceImages = const []})
      : _questions = questions,
        _sourceImages = sourceImages;

  factory _$ExamModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExamModelImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String type;
  @override
  final int duration;
  @override
  final double totalMarks;
  @override
  final double negativeMarks;
  @override
  final double passMarks;
  @override
  final bool isPublished;
  final List<ExamQuestionModel> _questions;
  @override
  List<ExamQuestionModel> get questions {
    if (_questions is EqualUnmodifiableListView) return _questions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_questions);
  }

  final List<ExamSourceImageModel> _sourceImages;
  @override
  @JsonKey()
  List<ExamSourceImageModel> get sourceImages {
    if (_sourceImages is EqualUnmodifiableListView) return _sourceImages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sourceImages);
  }

  @override
  String toString() {
    return 'ExamModel(id: $id, title: $title, description: $description, type: $type, duration: $duration, totalMarks: $totalMarks, negativeMarks: $negativeMarks, passMarks: $passMarks, isPublished: $isPublished, questions: $questions, sourceImages: $sourceImages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExamModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.totalMarks, totalMarks) ||
                other.totalMarks == totalMarks) &&
            (identical(other.negativeMarks, negativeMarks) ||
                other.negativeMarks == negativeMarks) &&
            (identical(other.passMarks, passMarks) ||
                other.passMarks == passMarks) &&
            (identical(other.isPublished, isPublished) ||
                other.isPublished == isPublished) &&
            const DeepCollectionEquality()
                .equals(other._questions, _questions) &&
            const DeepCollectionEquality()
                .equals(other._sourceImages, _sourceImages));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      type,
      duration,
      totalMarks,
      negativeMarks,
      passMarks,
      isPublished,
      const DeepCollectionEquality().hash(_questions),
      const DeepCollectionEquality().hash(_sourceImages));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExamModelImplCopyWith<_$ExamModelImpl> get copyWith =>
      __$$ExamModelImplCopyWithImpl<_$ExamModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExamModelImplToJson(
      this,
    );
  }
}

abstract class _ExamModel implements ExamModel {
  const factory _ExamModel(
      {required final String id,
      required final String title,
      final String? description,
      required final String type,
      required final int duration,
      required final double totalMarks,
      required final double negativeMarks,
      required final double passMarks,
      required final bool isPublished,
      required final List<ExamQuestionModel> questions,
      final List<ExamSourceImageModel> sourceImages}) = _$ExamModelImpl;

  factory _ExamModel.fromJson(Map<String, dynamic> json) =
      _$ExamModelImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  String get type;
  @override
  int get duration;
  @override
  double get totalMarks;
  @override
  double get negativeMarks;
  @override
  double get passMarks;
  @override
  bool get isPublished;
  @override
  List<ExamQuestionModel> get questions;
  @override
  List<ExamSourceImageModel> get sourceImages;
  @override
  @JsonKey(ignore: true)
  _$$ExamModelImplCopyWith<_$ExamModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
