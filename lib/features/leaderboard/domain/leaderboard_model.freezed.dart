// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leaderboard_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LeaderboardEntryModel _$LeaderboardEntryModelFromJson(
    Map<String, dynamic> json) {
  return _LeaderboardEntryModel.fromJson(json);
}

/// @nodoc
mixin _$LeaderboardEntryModel {
  int get rank => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String get fullName => throw _privateConstructorUsedError;
  String? get avatarKey => throw _privateConstructorUsedError;
  int get xp => throw _privateConstructorUsedError;
  int get level => throw _privateConstructorUsedError;
  int get solvedQuestionsCount => throw _privateConstructorUsedError;
  String get league => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LeaderboardEntryModelCopyWith<LeaderboardEntryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LeaderboardEntryModelCopyWith<$Res> {
  factory $LeaderboardEntryModelCopyWith(LeaderboardEntryModel value,
          $Res Function(LeaderboardEntryModel) then) =
      _$LeaderboardEntryModelCopyWithImpl<$Res, LeaderboardEntryModel>;
  @useResult
  $Res call(
      {int rank,
      String userId,
      String username,
      String fullName,
      String? avatarKey,
      int xp,
      int level,
      int solvedQuestionsCount,
      String league});
}

/// @nodoc
class _$LeaderboardEntryModelCopyWithImpl<$Res,
        $Val extends LeaderboardEntryModel>
    implements $LeaderboardEntryModelCopyWith<$Res> {
  _$LeaderboardEntryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rank = null,
    Object? userId = null,
    Object? username = null,
    Object? fullName = null,
    Object? avatarKey = freezed,
    Object? xp = null,
    Object? level = null,
    Object? solvedQuestionsCount = null,
    Object? league = null,
  }) {
    return _then(_value.copyWith(
      rank: null == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      avatarKey: freezed == avatarKey
          ? _value.avatarKey
          : avatarKey // ignore: cast_nullable_to_non_nullable
              as String?,
      xp: null == xp
          ? _value.xp
          : xp // ignore: cast_nullable_to_non_nullable
              as int,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      solvedQuestionsCount: null == solvedQuestionsCount
          ? _value.solvedQuestionsCount
          : solvedQuestionsCount // ignore: cast_nullable_to_non_nullable
              as int,
      league: null == league
          ? _value.league
          : league // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LeaderboardEntryModelImplCopyWith<$Res>
    implements $LeaderboardEntryModelCopyWith<$Res> {
  factory _$$LeaderboardEntryModelImplCopyWith(
          _$LeaderboardEntryModelImpl value,
          $Res Function(_$LeaderboardEntryModelImpl) then) =
      __$$LeaderboardEntryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int rank,
      String userId,
      String username,
      String fullName,
      String? avatarKey,
      int xp,
      int level,
      int solvedQuestionsCount,
      String league});
}

/// @nodoc
class __$$LeaderboardEntryModelImplCopyWithImpl<$Res>
    extends _$LeaderboardEntryModelCopyWithImpl<$Res,
        _$LeaderboardEntryModelImpl>
    implements _$$LeaderboardEntryModelImplCopyWith<$Res> {
  __$$LeaderboardEntryModelImplCopyWithImpl(_$LeaderboardEntryModelImpl _value,
      $Res Function(_$LeaderboardEntryModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rank = null,
    Object? userId = null,
    Object? username = null,
    Object? fullName = null,
    Object? avatarKey = freezed,
    Object? xp = null,
    Object? level = null,
    Object? solvedQuestionsCount = null,
    Object? league = null,
  }) {
    return _then(_$LeaderboardEntryModelImpl(
      rank: null == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      avatarKey: freezed == avatarKey
          ? _value.avatarKey
          : avatarKey // ignore: cast_nullable_to_non_nullable
              as String?,
      xp: null == xp
          ? _value.xp
          : xp // ignore: cast_nullable_to_non_nullable
              as int,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      solvedQuestionsCount: null == solvedQuestionsCount
          ? _value.solvedQuestionsCount
          : solvedQuestionsCount // ignore: cast_nullable_to_non_nullable
              as int,
      league: null == league
          ? _value.league
          : league // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LeaderboardEntryModelImpl implements _LeaderboardEntryModel {
  const _$LeaderboardEntryModelImpl(
      {required this.rank,
      required this.userId,
      required this.username,
      required this.fullName,
      this.avatarKey,
      required this.xp,
      required this.level,
      required this.solvedQuestionsCount,
      required this.league});

  factory _$LeaderboardEntryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LeaderboardEntryModelImplFromJson(json);

  @override
  final int rank;
  @override
  final String userId;
  @override
  final String username;
  @override
  final String fullName;
  @override
  final String? avatarKey;
  @override
  final int xp;
  @override
  final int level;
  @override
  final int solvedQuestionsCount;
  @override
  final String league;

  @override
  String toString() {
    return 'LeaderboardEntryModel(rank: $rank, userId: $userId, username: $username, fullName: $fullName, avatarKey: $avatarKey, xp: $xp, level: $level, solvedQuestionsCount: $solvedQuestionsCount, league: $league)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LeaderboardEntryModelImpl &&
            (identical(other.rank, rank) || other.rank == rank) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.avatarKey, avatarKey) ||
                other.avatarKey == avatarKey) &&
            (identical(other.xp, xp) || other.xp == xp) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.solvedQuestionsCount, solvedQuestionsCount) ||
                other.solvedQuestionsCount == solvedQuestionsCount) &&
            (identical(other.league, league) || other.league == league));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, rank, userId, username, fullName,
      avatarKey, xp, level, solvedQuestionsCount, league);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LeaderboardEntryModelImplCopyWith<_$LeaderboardEntryModelImpl>
      get copyWith => __$$LeaderboardEntryModelImplCopyWithImpl<
          _$LeaderboardEntryModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LeaderboardEntryModelImplToJson(
      this,
    );
  }
}

abstract class _LeaderboardEntryModel implements LeaderboardEntryModel {
  const factory _LeaderboardEntryModel(
      {required final int rank,
      required final String userId,
      required final String username,
      required final String fullName,
      final String? avatarKey,
      required final int xp,
      required final int level,
      required final int solvedQuestionsCount,
      required final String league}) = _$LeaderboardEntryModelImpl;

  factory _LeaderboardEntryModel.fromJson(Map<String, dynamic> json) =
      _$LeaderboardEntryModelImpl.fromJson;

  @override
  int get rank;
  @override
  String get userId;
  @override
  String get username;
  @override
  String get fullName;
  @override
  String? get avatarKey;
  @override
  int get xp;
  @override
  int get level;
  @override
  int get solvedQuestionsCount;
  @override
  String get league;
  @override
  @JsonKey(ignore: true)
  _$$LeaderboardEntryModelImplCopyWith<_$LeaderboardEntryModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}
