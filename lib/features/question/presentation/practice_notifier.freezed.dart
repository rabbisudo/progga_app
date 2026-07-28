// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'practice_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PracticeState {
  List<QuestionModel> get questions => throw _privateConstructorUsedError;
  String? get nextCursor => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isLoadingMore => throw _privateConstructorUsedError;
  String? get subjectId => throw _privateConstructorUsedError;
  String? get chapterId => throw _privateConstructorUsedError;
  String? get difficulty => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PracticeStateCopyWith<PracticeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PracticeStateCopyWith<$Res> {
  factory $PracticeStateCopyWith(
          PracticeState value, $Res Function(PracticeState) then) =
      _$PracticeStateCopyWithImpl<$Res, PracticeState>;
  @useResult
  $Res call(
      {List<QuestionModel> questions,
      String? nextCursor,
      bool isLoading,
      bool isLoadingMore,
      String? subjectId,
      String? chapterId,
      String? difficulty,
      String? errorMessage});
}

/// @nodoc
class _$PracticeStateCopyWithImpl<$Res, $Val extends PracticeState>
    implements $PracticeStateCopyWith<$Res> {
  _$PracticeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questions = null,
    Object? nextCursor = freezed,
    Object? isLoading = null,
    Object? isLoadingMore = null,
    Object? subjectId = freezed,
    Object? chapterId = freezed,
    Object? difficulty = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      questions: null == questions
          ? _value.questions
          : questions // ignore: cast_nullable_to_non_nullable
              as List<QuestionModel>,
      nextCursor: freezed == nextCursor
          ? _value.nextCursor
          : nextCursor // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoadingMore: null == isLoadingMore
          ? _value.isLoadingMore
          : isLoadingMore // ignore: cast_nullable_to_non_nullable
              as bool,
      subjectId: freezed == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String?,
      chapterId: freezed == chapterId
          ? _value.chapterId
          : chapterId // ignore: cast_nullable_to_non_nullable
              as String?,
      difficulty: freezed == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PracticeStateImplCopyWith<$Res>
    implements $PracticeStateCopyWith<$Res> {
  factory _$$PracticeStateImplCopyWith(
          _$PracticeStateImpl value, $Res Function(_$PracticeStateImpl) then) =
      __$$PracticeStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<QuestionModel> questions,
      String? nextCursor,
      bool isLoading,
      bool isLoadingMore,
      String? subjectId,
      String? chapterId,
      String? difficulty,
      String? errorMessage});
}

/// @nodoc
class __$$PracticeStateImplCopyWithImpl<$Res>
    extends _$PracticeStateCopyWithImpl<$Res, _$PracticeStateImpl>
    implements _$$PracticeStateImplCopyWith<$Res> {
  __$$PracticeStateImplCopyWithImpl(
      _$PracticeStateImpl _value, $Res Function(_$PracticeStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questions = null,
    Object? nextCursor = freezed,
    Object? isLoading = null,
    Object? isLoadingMore = null,
    Object? subjectId = freezed,
    Object? chapterId = freezed,
    Object? difficulty = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_$PracticeStateImpl(
      questions: null == questions
          ? _value._questions
          : questions // ignore: cast_nullable_to_non_nullable
              as List<QuestionModel>,
      nextCursor: freezed == nextCursor
          ? _value.nextCursor
          : nextCursor // ignore: cast_nullable_to_non_nullable
              as String?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoadingMore: null == isLoadingMore
          ? _value.isLoadingMore
          : isLoadingMore // ignore: cast_nullable_to_non_nullable
              as bool,
      subjectId: freezed == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String?,
      chapterId: freezed == chapterId
          ? _value.chapterId
          : chapterId // ignore: cast_nullable_to_non_nullable
              as String?,
      difficulty: freezed == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$PracticeStateImpl implements _PracticeState {
  const _$PracticeStateImpl(
      {required final List<QuestionModel> questions,
      this.nextCursor,
      required this.isLoading,
      required this.isLoadingMore,
      this.subjectId,
      this.chapterId,
      this.difficulty,
      this.errorMessage})
      : _questions = questions;

  final List<QuestionModel> _questions;
  @override
  List<QuestionModel> get questions {
    if (_questions is EqualUnmodifiableListView) return _questions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_questions);
  }

  @override
  final String? nextCursor;
  @override
  final bool isLoading;
  @override
  final bool isLoadingMore;
  @override
  final String? subjectId;
  @override
  final String? chapterId;
  @override
  final String? difficulty;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'PracticeState(questions: $questions, nextCursor: $nextCursor, isLoading: $isLoading, isLoadingMore: $isLoadingMore, subjectId: $subjectId, chapterId: $chapterId, difficulty: $difficulty, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PracticeStateImpl &&
            const DeepCollectionEquality()
                .equals(other._questions, _questions) &&
            (identical(other.nextCursor, nextCursor) ||
                other.nextCursor == nextCursor) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isLoadingMore, isLoadingMore) ||
                other.isLoadingMore == isLoadingMore) &&
            (identical(other.subjectId, subjectId) ||
                other.subjectId == subjectId) &&
            (identical(other.chapterId, chapterId) ||
                other.chapterId == chapterId) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_questions),
      nextCursor,
      isLoading,
      isLoadingMore,
      subjectId,
      chapterId,
      difficulty,
      errorMessage);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PracticeStateImplCopyWith<_$PracticeStateImpl> get copyWith =>
      __$$PracticeStateImplCopyWithImpl<_$PracticeStateImpl>(this, _$identity);
}

abstract class _PracticeState implements PracticeState {
  const factory _PracticeState(
      {required final List<QuestionModel> questions,
      final String? nextCursor,
      required final bool isLoading,
      required final bool isLoadingMore,
      final String? subjectId,
      final String? chapterId,
      final String? difficulty,
      final String? errorMessage}) = _$PracticeStateImpl;

  @override
  List<QuestionModel> get questions;
  @override
  String? get nextCursor;
  @override
  bool get isLoading;
  @override
  bool get isLoadingMore;
  @override
  String? get subjectId;
  @override
  String? get chapterId;
  @override
  String? get difficulty;
  @override
  String? get errorMessage;
  @override
  @JsonKey(ignore: true)
  _$$PracticeStateImplCopyWith<_$PracticeStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
