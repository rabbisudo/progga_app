// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exam_runner_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ExamRunnerState {
  ExamModel? get exam => throw _privateConstructorUsedError;
  String? get sessionId => throw _privateConstructorUsedError;
  int get timeLeft => throw _privateConstructorUsedError;
  Map<String, String?> get selectedOptions =>
      throw _privateConstructorUsedError;
  Map<String, bool> get markedForReview => throw _privateConstructorUsedError;
  Map<String, int> get timeSpent => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isSaving => throw _privateConstructorUsedError;
  bool get isSubmitting => throw _privateConstructorUsedError;
  UserExamModel? get result => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ExamRunnerStateCopyWith<ExamRunnerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExamRunnerStateCopyWith<$Res> {
  factory $ExamRunnerStateCopyWith(
          ExamRunnerState value, $Res Function(ExamRunnerState) then) =
      _$ExamRunnerStateCopyWithImpl<$Res, ExamRunnerState>;
  @useResult
  $Res call(
      {ExamModel? exam,
      String? sessionId,
      int timeLeft,
      Map<String, String?> selectedOptions,
      Map<String, bool> markedForReview,
      Map<String, int> timeSpent,
      bool isLoading,
      bool isSaving,
      bool isSubmitting,
      UserExamModel? result,
      String? errorMessage});

  $ExamModelCopyWith<$Res>? get exam;
  $UserExamModelCopyWith<$Res>? get result;
}

/// @nodoc
class _$ExamRunnerStateCopyWithImpl<$Res, $Val extends ExamRunnerState>
    implements $ExamRunnerStateCopyWith<$Res> {
  _$ExamRunnerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exam = freezed,
    Object? sessionId = freezed,
    Object? timeLeft = null,
    Object? selectedOptions = null,
    Object? markedForReview = null,
    Object? timeSpent = null,
    Object? isLoading = null,
    Object? isSaving = null,
    Object? isSubmitting = null,
    Object? result = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      exam: freezed == exam
          ? _value.exam
          : exam // ignore: cast_nullable_to_non_nullable
              as ExamModel?,
      sessionId: freezed == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String?,
      timeLeft: null == timeLeft
          ? _value.timeLeft
          : timeLeft // ignore: cast_nullable_to_non_nullable
              as int,
      selectedOptions: null == selectedOptions
          ? _value.selectedOptions
          : selectedOptions // ignore: cast_nullable_to_non_nullable
              as Map<String, String?>,
      markedForReview: null == markedForReview
          ? _value.markedForReview
          : markedForReview // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
      timeSpent: null == timeSpent
          ? _value.timeSpent
          : timeSpent // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isSaving: null == isSaving
          ? _value.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
      isSubmitting: null == isSubmitting
          ? _value.isSubmitting
          : isSubmitting // ignore: cast_nullable_to_non_nullable
              as bool,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as UserExamModel?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ExamModelCopyWith<$Res>? get exam {
    if (_value.exam == null) {
      return null;
    }

    return $ExamModelCopyWith<$Res>(_value.exam!, (value) {
      return _then(_value.copyWith(exam: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $UserExamModelCopyWith<$Res>? get result {
    if (_value.result == null) {
      return null;
    }

    return $UserExamModelCopyWith<$Res>(_value.result!, (value) {
      return _then(_value.copyWith(result: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ExamRunnerStateImplCopyWith<$Res>
    implements $ExamRunnerStateCopyWith<$Res> {
  factory _$$ExamRunnerStateImplCopyWith(_$ExamRunnerStateImpl value,
          $Res Function(_$ExamRunnerStateImpl) then) =
      __$$ExamRunnerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ExamModel? exam,
      String? sessionId,
      int timeLeft,
      Map<String, String?> selectedOptions,
      Map<String, bool> markedForReview,
      Map<String, int> timeSpent,
      bool isLoading,
      bool isSaving,
      bool isSubmitting,
      UserExamModel? result,
      String? errorMessage});

  @override
  $ExamModelCopyWith<$Res>? get exam;
  @override
  $UserExamModelCopyWith<$Res>? get result;
}

/// @nodoc
class __$$ExamRunnerStateImplCopyWithImpl<$Res>
    extends _$ExamRunnerStateCopyWithImpl<$Res, _$ExamRunnerStateImpl>
    implements _$$ExamRunnerStateImplCopyWith<$Res> {
  __$$ExamRunnerStateImplCopyWithImpl(
      _$ExamRunnerStateImpl _value, $Res Function(_$ExamRunnerStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exam = freezed,
    Object? sessionId = freezed,
    Object? timeLeft = null,
    Object? selectedOptions = null,
    Object? markedForReview = null,
    Object? timeSpent = null,
    Object? isLoading = null,
    Object? isSaving = null,
    Object? isSubmitting = null,
    Object? result = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_$ExamRunnerStateImpl(
      exam: freezed == exam
          ? _value.exam
          : exam // ignore: cast_nullable_to_non_nullable
              as ExamModel?,
      sessionId: freezed == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String?,
      timeLeft: null == timeLeft
          ? _value.timeLeft
          : timeLeft // ignore: cast_nullable_to_non_nullable
              as int,
      selectedOptions: null == selectedOptions
          ? _value._selectedOptions
          : selectedOptions // ignore: cast_nullable_to_non_nullable
              as Map<String, String?>,
      markedForReview: null == markedForReview
          ? _value._markedForReview
          : markedForReview // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
      timeSpent: null == timeSpent
          ? _value._timeSpent
          : timeSpent // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isSaving: null == isSaving
          ? _value.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
      isSubmitting: null == isSubmitting
          ? _value.isSubmitting
          : isSubmitting // ignore: cast_nullable_to_non_nullable
              as bool,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as UserExamModel?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ExamRunnerStateImpl implements _ExamRunnerState {
  const _$ExamRunnerStateImpl(
      {this.exam,
      this.sessionId,
      required this.timeLeft,
      required final Map<String, String?> selectedOptions,
      required final Map<String, bool> markedForReview,
      required final Map<String, int> timeSpent,
      required this.isLoading,
      required this.isSaving,
      required this.isSubmitting,
      this.result,
      this.errorMessage})
      : _selectedOptions = selectedOptions,
        _markedForReview = markedForReview,
        _timeSpent = timeSpent;

  @override
  final ExamModel? exam;
  @override
  final String? sessionId;
  @override
  final int timeLeft;
  final Map<String, String?> _selectedOptions;
  @override
  Map<String, String?> get selectedOptions {
    if (_selectedOptions is EqualUnmodifiableMapView) return _selectedOptions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_selectedOptions);
  }

  final Map<String, bool> _markedForReview;
  @override
  Map<String, bool> get markedForReview {
    if (_markedForReview is EqualUnmodifiableMapView) return _markedForReview;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_markedForReview);
  }

  final Map<String, int> _timeSpent;
  @override
  Map<String, int> get timeSpent {
    if (_timeSpent is EqualUnmodifiableMapView) return _timeSpent;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_timeSpent);
  }

  @override
  final bool isLoading;
  @override
  final bool isSaving;
  @override
  final bool isSubmitting;
  @override
  final UserExamModel? result;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'ExamRunnerState(exam: $exam, sessionId: $sessionId, timeLeft: $timeLeft, selectedOptions: $selectedOptions, markedForReview: $markedForReview, timeSpent: $timeSpent, isLoading: $isLoading, isSaving: $isSaving, isSubmitting: $isSubmitting, result: $result, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExamRunnerStateImpl &&
            (identical(other.exam, exam) || other.exam == exam) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.timeLeft, timeLeft) ||
                other.timeLeft == timeLeft) &&
            const DeepCollectionEquality()
                .equals(other._selectedOptions, _selectedOptions) &&
            const DeepCollectionEquality()
                .equals(other._markedForReview, _markedForReview) &&
            const DeepCollectionEquality()
                .equals(other._timeSpent, _timeSpent) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isSaving, isSaving) ||
                other.isSaving == isSaving) &&
            (identical(other.isSubmitting, isSubmitting) ||
                other.isSubmitting == isSubmitting) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      exam,
      sessionId,
      timeLeft,
      const DeepCollectionEquality().hash(_selectedOptions),
      const DeepCollectionEquality().hash(_markedForReview),
      const DeepCollectionEquality().hash(_timeSpent),
      isLoading,
      isSaving,
      isSubmitting,
      result,
      errorMessage);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExamRunnerStateImplCopyWith<_$ExamRunnerStateImpl> get copyWith =>
      __$$ExamRunnerStateImplCopyWithImpl<_$ExamRunnerStateImpl>(
          this, _$identity);
}

abstract class _ExamRunnerState implements ExamRunnerState {
  const factory _ExamRunnerState(
      {final ExamModel? exam,
      final String? sessionId,
      required final int timeLeft,
      required final Map<String, String?> selectedOptions,
      required final Map<String, bool> markedForReview,
      required final Map<String, int> timeSpent,
      required final bool isLoading,
      required final bool isSaving,
      required final bool isSubmitting,
      final UserExamModel? result,
      final String? errorMessage}) = _$ExamRunnerStateImpl;

  @override
  ExamModel? get exam;
  @override
  String? get sessionId;
  @override
  int get timeLeft;
  @override
  Map<String, String?> get selectedOptions;
  @override
  Map<String, bool> get markedForReview;
  @override
  Map<String, int> get timeSpent;
  @override
  bool get isLoading;
  @override
  bool get isSaving;
  @override
  bool get isSubmitting;
  @override
  UserExamModel? get result;
  @override
  String? get errorMessage;
  @override
  @JsonKey(ignore: true)
  _$$ExamRunnerStateImplCopyWith<_$ExamRunnerStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
