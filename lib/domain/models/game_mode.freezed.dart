// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_mode.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GameMode {

 OpponentKind get opponent;/// O nível do Maia, quando ele é o adversário.
 int? get level;/// O lado do jogador. Nulo no tabuleiro livre.
 Side? get userSide;/// O que o jogador precisa fazer. Nulo fora do treino.
 PositionGoal? get goal;/// A posição do catálogo, para gravar a tentativa. Nula na posição
/// personalizada.
 String? get positionId;/// O desafio da Jornada, quando a partida é um.
 String? get challengeId;/// O speedrun, a tentativa e a etapa (a partir de 0), quando a partida é
/// uma etapa.
 String? get speedrunId; int? get speedrunAttemptId; int? get speedrunStage;
/// Create a copy of GameMode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameModeCopyWith<GameMode> get copyWith => _$GameModeCopyWithImpl<GameMode>(this as GameMode, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GameMode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameMode&&(identical(other.opponent, _this.opponent) || other.opponent == _this.opponent)&&(identical(other.level, _this.level) || other.level == _this.level)&&(identical(other.userSide, _this.userSide) || other.userSide == _this.userSide)&&(identical(other.goal, _this.goal) || other.goal == _this.goal)&&(identical(other.positionId, _this.positionId) || other.positionId == _this.positionId)&&(identical(other.challengeId, _this.challengeId) || other.challengeId == _this.challengeId)&&(identical(other.speedrunId, _this.speedrunId) || other.speedrunId == _this.speedrunId)&&(identical(other.speedrunAttemptId, _this.speedrunAttemptId) || other.speedrunAttemptId == _this.speedrunAttemptId)&&(identical(other.speedrunStage, _this.speedrunStage) || other.speedrunStage == _this.speedrunStage));
}


@override
int get hashCode {
  final _this = this as GameMode;
  return Object.hash(runtimeType,_this.opponent,_this.level,_this.userSide,_this.goal,_this.positionId,_this.challengeId,_this.speedrunId,_this.speedrunAttemptId,_this.speedrunStage);
}

@override
String toString() {
  final _this = this as GameMode;
  return 'GameMode(opponent: ${_this.opponent}, level: ${_this.level}, userSide: ${_this.userSide}, goal: ${_this.goal}, positionId: ${_this.positionId}, challengeId: ${_this.challengeId}, speedrunId: ${_this.speedrunId}, speedrunAttemptId: ${_this.speedrunAttemptId}, speedrunStage: ${_this.speedrunStage})';
}


}

/// @nodoc
abstract mixin class $GameModeCopyWith<$Res>  {
  factory $GameModeCopyWith(GameMode value, $Res Function(GameMode) _then) = _$GameModeCopyWithImpl;
@useResult
$Res call({
 OpponentKind opponent, int? level, Side? userSide, PositionGoal? goal, String? positionId, String? challengeId, String? speedrunId, int? speedrunAttemptId, int? speedrunStage
});




}
/// @nodoc
class _$GameModeCopyWithImpl<$Res>
    implements $GameModeCopyWith<$Res> {
  _$GameModeCopyWithImpl(this._self, this._then);

  final GameMode _self;
  final $Res Function(GameMode) _then;

/// Create a copy of GameMode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? opponent = null,Object? level = freezed,Object? userSide = freezed,Object? goal = freezed,Object? positionId = freezed,Object? challengeId = freezed,Object? speedrunId = freezed,Object? speedrunAttemptId = freezed,Object? speedrunStage = freezed,}) {
  return _then(GameMode(
opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as OpponentKind,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int?,userSide: freezed == userSide ? _self.userSide : userSide // ignore: cast_nullable_to_non_nullable
as Side?,goal: freezed == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as PositionGoal?,positionId: freezed == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String?,challengeId: freezed == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String?,speedrunId: freezed == speedrunId ? _self.speedrunId : speedrunId // ignore: cast_nullable_to_non_nullable
as String?,speedrunAttemptId: freezed == speedrunAttemptId ? _self.speedrunAttemptId : speedrunAttemptId // ignore: cast_nullable_to_non_nullable
as int?,speedrunStage: freezed == speedrunStage ? _self.speedrunStage : speedrunStage // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [GameMode].
extension GameModePatterns on GameMode {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameMode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameMode() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameMode value)  $default,){
final _that = this;
switch (_that) {
case _GameMode():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameMode value)?  $default,){
final _that = this;
switch (_that) {
case _GameMode() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OpponentKind opponent,  int? level,  Side? userSide,  PositionGoal? goal,  String? positionId,  String? challengeId,  String? speedrunId,  int? speedrunAttemptId,  int? speedrunStage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameMode() when $default != null:
return $default(_that.opponent,_that.level,_that.userSide,_that.goal,_that.positionId,_that.challengeId,_that.speedrunId,_that.speedrunAttemptId,_that.speedrunStage);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OpponentKind opponent,  int? level,  Side? userSide,  PositionGoal? goal,  String? positionId,  String? challengeId,  String? speedrunId,  int? speedrunAttemptId,  int? speedrunStage)  $default,) {final _that = this;
switch (_that) {
case _GameMode():
return $default(_that.opponent,_that.level,_that.userSide,_that.goal,_that.positionId,_that.challengeId,_that.speedrunId,_that.speedrunAttemptId,_that.speedrunStage);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OpponentKind opponent,  int? level,  Side? userSide,  PositionGoal? goal,  String? positionId,  String? challengeId,  String? speedrunId,  int? speedrunAttemptId,  int? speedrunStage)?  $default,) {final _that = this;
switch (_that) {
case _GameMode() when $default != null:
return $default(_that.opponent,_that.level,_that.userSide,_that.goal,_that.positionId,_that.challengeId,_that.speedrunId,_that.speedrunAttemptId,_that.speedrunStage);case _:
  return null;

}
}

}

/// @nodoc


class _GameMode extends GameMode {
  const _GameMode({this.opponent = OpponentKind.twoPlayers, this.level, this.userSide, this.goal, this.positionId, this.challengeId, this.speedrunId, this.speedrunAttemptId, this.speedrunStage}): super._();
  

@override@JsonKey() final  OpponentKind opponent;
/// O nível do Maia, quando ele é o adversário.
@override final  int? level;
/// O lado do jogador. Nulo no tabuleiro livre.
@override final  Side? userSide;
/// O que o jogador precisa fazer. Nulo fora do treino.
@override final  PositionGoal? goal;
/// A posição do catálogo, para gravar a tentativa. Nula na posição
/// personalizada.
@override final  String? positionId;
/// O desafio da Jornada, quando a partida é um.
@override final  String? challengeId;
/// O speedrun, a tentativa e a etapa (a partir de 0), quando a partida é
/// uma etapa.
@override final  String? speedrunId;
@override final  int? speedrunAttemptId;
@override final  int? speedrunStage;

/// Create a copy of GameMode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameModeCopyWith<_GameMode> get copyWith => __$GameModeCopyWithImpl<_GameMode>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameMode&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.level, level) || other.level == level)&&(identical(other.userSide, userSide) || other.userSide == userSide)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.positionId, positionId) || other.positionId == positionId)&&(identical(other.challengeId, challengeId) || other.challengeId == challengeId)&&(identical(other.speedrunId, speedrunId) || other.speedrunId == speedrunId)&&(identical(other.speedrunAttemptId, speedrunAttemptId) || other.speedrunAttemptId == speedrunAttemptId)&&(identical(other.speedrunStage, speedrunStage) || other.speedrunStage == speedrunStage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,opponent,level,userSide,goal,positionId,challengeId,speedrunId,speedrunAttemptId,speedrunStage);
}

@override
String toString() {
    return 'GameMode(opponent: $opponent, level: $level, userSide: $userSide, goal: $goal, positionId: $positionId, challengeId: $challengeId, speedrunId: $speedrunId, speedrunAttemptId: $speedrunAttemptId, speedrunStage: $speedrunStage)';
}


}

/// @nodoc
abstract mixin class _$GameModeCopyWith<$Res> implements $GameModeCopyWith<$Res> {
  factory _$GameModeCopyWith(_GameMode value, $Res Function(_GameMode) _then) = __$GameModeCopyWithImpl;
@override @useResult
$Res call({
 OpponentKind opponent, int? level, Side? userSide, PositionGoal? goal, String? positionId, String? challengeId, String? speedrunId, int? speedrunAttemptId, int? speedrunStage
});




}
/// @nodoc
class __$GameModeCopyWithImpl<$Res>
    implements _$GameModeCopyWith<$Res> {
  __$GameModeCopyWithImpl(this._self, this._then);

  final _GameMode _self;
  final $Res Function(_GameMode) _then;

/// Create a copy of GameMode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? opponent = null,Object? level = freezed,Object? userSide = freezed,Object? goal = freezed,Object? positionId = freezed,Object? challengeId = freezed,Object? speedrunId = freezed,Object? speedrunAttemptId = freezed,Object? speedrunStage = freezed,}) {
  return _then(_GameMode(
opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as OpponentKind,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int?,userSide: freezed == userSide ? _self.userSide : userSide // ignore: cast_nullable_to_non_nullable
as Side?,goal: freezed == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as PositionGoal?,positionId: freezed == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String?,challengeId: freezed == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String?,speedrunId: freezed == speedrunId ? _self.speedrunId : speedrunId // ignore: cast_nullable_to_non_nullable
as String?,speedrunAttemptId: freezed == speedrunAttemptId ? _self.speedrunAttemptId : speedrunAttemptId // ignore: cast_nullable_to_non_nullable
as int?,speedrunStage: freezed == speedrunStage ? _self.speedrunStage : speedrunStage // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
