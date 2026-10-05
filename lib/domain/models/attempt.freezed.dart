// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attempt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Attempt {

 String get positionId;/// Quando a partida terminou.
 DateTime get playedAt; AttemptOutcome get outcome;/// O objetivo da posição foi cumprido.
 bool get fulfilled; OpponentKind get opponent;/// O nível do Maia, quando ele foi o adversário.
 int? get opponentLevel;/// Quando a partida começou. Nulo nas partidas de antes da Jornada.
 DateTime? get startedAt;/// A posição em que a partida começou (FEN) e os lances (UCI). Vazios nas
/// partidas de antes da Jornada.
 String? get startFen; List<String> get moves;/// Quanto cada lance levou, na ordem de [moves] (o do jogador e o do
/// adversário). Vazio nas partidas de antes de isto ser gravado.
 List<Duration> get moveTimes;/// O lado do jogador. Nulo nas partidas de antes de isto ser gravado.
 Side? get userSide;/// Como a partida terminou (mate, tempo, desistência...).
 GameEndReason? get endReason;/// O tempo do jogador e o do adversário. Nulos sem relógio.
 TimeControl? get userTime; TimeControl? get opponentTime;/// Quanto o relógio do jogador gastou na partida. Nulo sem relógio.
 Duration? get userClock;/// O desafio da Jornada, quando a partida foi um.
 String? get challengeId;/// A tentativa de speedrun e a etapa (a partir de 0), quando a partida foi
/// uma etapa.
 int? get speedrunAttemptId; int? get speedrunStage;
/// Create a copy of Attempt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttemptCopyWith<Attempt> get copyWith => _$AttemptCopyWithImpl<Attempt>(this as Attempt, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Attempt;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Attempt&&(identical(other.positionId, _this.positionId) || other.positionId == _this.positionId)&&(identical(other.playedAt, _this.playedAt) || other.playedAt == _this.playedAt)&&(identical(other.outcome, _this.outcome) || other.outcome == _this.outcome)&&(identical(other.fulfilled, _this.fulfilled) || other.fulfilled == _this.fulfilled)&&(identical(other.opponent, _this.opponent) || other.opponent == _this.opponent)&&(identical(other.opponentLevel, _this.opponentLevel) || other.opponentLevel == _this.opponentLevel)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.startFen, _this.startFen) || other.startFen == _this.startFen)&&const DeepCollectionEquality().equals(other.moves, _this.moves)&&const DeepCollectionEquality().equals(other.moveTimes, _this.moveTimes)&&(identical(other.userSide, _this.userSide) || other.userSide == _this.userSide)&&(identical(other.endReason, _this.endReason) || other.endReason == _this.endReason)&&(identical(other.userTime, _this.userTime) || other.userTime == _this.userTime)&&(identical(other.opponentTime, _this.opponentTime) || other.opponentTime == _this.opponentTime)&&(identical(other.userClock, _this.userClock) || other.userClock == _this.userClock)&&(identical(other.challengeId, _this.challengeId) || other.challengeId == _this.challengeId)&&(identical(other.speedrunAttemptId, _this.speedrunAttemptId) || other.speedrunAttemptId == _this.speedrunAttemptId)&&(identical(other.speedrunStage, _this.speedrunStage) || other.speedrunStage == _this.speedrunStage));
}


@override
int get hashCode {
  final _this = this as Attempt;
  return Object.hash(runtimeType,_this.positionId,_this.playedAt,_this.outcome,_this.fulfilled,_this.opponent,_this.opponentLevel,_this.startedAt,_this.startFen,const DeepCollectionEquality().hash(_this.moves),const DeepCollectionEquality().hash(_this.moveTimes),_this.userSide,_this.endReason,_this.userTime,_this.opponentTime,_this.userClock,_this.challengeId,_this.speedrunAttemptId,_this.speedrunStage);
}

@override
String toString() {
  final _this = this as Attempt;
  return 'Attempt(positionId: ${_this.positionId}, playedAt: ${_this.playedAt}, outcome: ${_this.outcome}, fulfilled: ${_this.fulfilled}, opponent: ${_this.opponent}, opponentLevel: ${_this.opponentLevel}, startedAt: ${_this.startedAt}, startFen: ${_this.startFen}, moves: ${_this.moves}, moveTimes: ${_this.moveTimes}, userSide: ${_this.userSide}, endReason: ${_this.endReason}, userTime: ${_this.userTime}, opponentTime: ${_this.opponentTime}, userClock: ${_this.userClock}, challengeId: ${_this.challengeId}, speedrunAttemptId: ${_this.speedrunAttemptId}, speedrunStage: ${_this.speedrunStage})';
}


}

/// @nodoc
abstract mixin class $AttemptCopyWith<$Res>  {
  factory $AttemptCopyWith(Attempt value, $Res Function(Attempt) _then) = _$AttemptCopyWithImpl;
@useResult
$Res call({
 String positionId, DateTime playedAt, AttemptOutcome outcome, bool fulfilled, OpponentKind opponent, int? opponentLevel, DateTime? startedAt, String? startFen, List<String> moves, List<Duration> moveTimes, Side? userSide, GameEndReason? endReason, TimeControl? userTime, TimeControl? opponentTime, Duration? userClock, String? challengeId, int? speedrunAttemptId, int? speedrunStage
});


$TimeControlCopyWith<$Res>? get userTime;$TimeControlCopyWith<$Res>? get opponentTime;

}
/// @nodoc
class _$AttemptCopyWithImpl<$Res>
    implements $AttemptCopyWith<$Res> {
  _$AttemptCopyWithImpl(this._self, this._then);

  final Attempt _self;
  final $Res Function(Attempt) _then;

/// Create a copy of Attempt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? positionId = null,Object? playedAt = null,Object? outcome = null,Object? fulfilled = null,Object? opponent = null,Object? opponentLevel = freezed,Object? startedAt = freezed,Object? startFen = freezed,Object? moves = null,Object? moveTimes = null,Object? userSide = freezed,Object? endReason = freezed,Object? userTime = freezed,Object? opponentTime = freezed,Object? userClock = freezed,Object? challengeId = freezed,Object? speedrunAttemptId = freezed,Object? speedrunStage = freezed,}) {
  return _then(Attempt(
positionId: null == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String,playedAt: null == playedAt ? _self.playedAt : playedAt // ignore: cast_nullable_to_non_nullable
as DateTime,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as AttemptOutcome,fulfilled: null == fulfilled ? _self.fulfilled : fulfilled // ignore: cast_nullable_to_non_nullable
as bool,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as OpponentKind,opponentLevel: freezed == opponentLevel ? _self.opponentLevel : opponentLevel // ignore: cast_nullable_to_non_nullable
as int?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,startFen: freezed == startFen ? _self.startFen : startFen // ignore: cast_nullable_to_non_nullable
as String?,moves: null == moves ? _self.moves : moves // ignore: cast_nullable_to_non_nullable
as List<String>,moveTimes: null == moveTimes ? _self.moveTimes : moveTimes // ignore: cast_nullable_to_non_nullable
as List<Duration>,userSide: freezed == userSide ? _self.userSide : userSide // ignore: cast_nullable_to_non_nullable
as Side?,endReason: freezed == endReason ? _self.endReason : endReason // ignore: cast_nullable_to_non_nullable
as GameEndReason?,userTime: freezed == userTime ? _self.userTime : userTime // ignore: cast_nullable_to_non_nullable
as TimeControl?,opponentTime: freezed == opponentTime ? _self.opponentTime : opponentTime // ignore: cast_nullable_to_non_nullable
as TimeControl?,userClock: freezed == userClock ? _self.userClock : userClock // ignore: cast_nullable_to_non_nullable
as Duration?,challengeId: freezed == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String?,speedrunAttemptId: freezed == speedrunAttemptId ? _self.speedrunAttemptId : speedrunAttemptId // ignore: cast_nullable_to_non_nullable
as int?,speedrunStage: freezed == speedrunStage ? _self.speedrunStage : speedrunStage // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of Attempt
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res>? get userTime {
    if (_self.userTime == null) {
    return null;
  }

  return $TimeControlCopyWith<$Res>(_self.userTime!, (value) {
    return _then(_self.copyWith(userTime: value));
  });
}/// Create a copy of Attempt
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res>? get opponentTime {
    if (_self.opponentTime == null) {
    return null;
  }

  return $TimeControlCopyWith<$Res>(_self.opponentTime!, (value) {
    return _then(_self.copyWith(opponentTime: value));
  });
}
}


/// Adds pattern-matching-related methods to [Attempt].
extension AttemptPatterns on Attempt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Attempt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Attempt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Attempt value)  $default,){
final _that = this;
switch (_that) {
case _Attempt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Attempt value)?  $default,){
final _that = this;
switch (_that) {
case _Attempt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String positionId,  DateTime playedAt,  AttemptOutcome outcome,  bool fulfilled,  OpponentKind opponent,  int? opponentLevel,  DateTime? startedAt,  String? startFen,  List<String> moves,  List<Duration> moveTimes,  Side? userSide,  GameEndReason? endReason,  TimeControl? userTime,  TimeControl? opponentTime,  Duration? userClock,  String? challengeId,  int? speedrunAttemptId,  int? speedrunStage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Attempt() when $default != null:
return $default(_that.positionId,_that.playedAt,_that.outcome,_that.fulfilled,_that.opponent,_that.opponentLevel,_that.startedAt,_that.startFen,_that.moves,_that.moveTimes,_that.userSide,_that.endReason,_that.userTime,_that.opponentTime,_that.userClock,_that.challengeId,_that.speedrunAttemptId,_that.speedrunStage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String positionId,  DateTime playedAt,  AttemptOutcome outcome,  bool fulfilled,  OpponentKind opponent,  int? opponentLevel,  DateTime? startedAt,  String? startFen,  List<String> moves,  List<Duration> moveTimes,  Side? userSide,  GameEndReason? endReason,  TimeControl? userTime,  TimeControl? opponentTime,  Duration? userClock,  String? challengeId,  int? speedrunAttemptId,  int? speedrunStage)  $default,) {final _that = this;
switch (_that) {
case _Attempt():
return $default(_that.positionId,_that.playedAt,_that.outcome,_that.fulfilled,_that.opponent,_that.opponentLevel,_that.startedAt,_that.startFen,_that.moves,_that.moveTimes,_that.userSide,_that.endReason,_that.userTime,_that.opponentTime,_that.userClock,_that.challengeId,_that.speedrunAttemptId,_that.speedrunStage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String positionId,  DateTime playedAt,  AttemptOutcome outcome,  bool fulfilled,  OpponentKind opponent,  int? opponentLevel,  DateTime? startedAt,  String? startFen,  List<String> moves,  List<Duration> moveTimes,  Side? userSide,  GameEndReason? endReason,  TimeControl? userTime,  TimeControl? opponentTime,  Duration? userClock,  String? challengeId,  int? speedrunAttemptId,  int? speedrunStage)?  $default,) {final _that = this;
switch (_that) {
case _Attempt() when $default != null:
return $default(_that.positionId,_that.playedAt,_that.outcome,_that.fulfilled,_that.opponent,_that.opponentLevel,_that.startedAt,_that.startFen,_that.moves,_that.moveTimes,_that.userSide,_that.endReason,_that.userTime,_that.opponentTime,_that.userClock,_that.challengeId,_that.speedrunAttemptId,_that.speedrunStage);case _:
  return null;

}
}

}

/// @nodoc


class _Attempt implements Attempt {
  const _Attempt({required this.positionId, required this.playedAt, required this.outcome, required this.fulfilled, required this.opponent, this.opponentLevel, this.startedAt, this.startFen,  List<String> moves = const <String>[],  List<Duration> moveTimes = const <Duration>[], this.userSide, this.endReason, this.userTime, this.opponentTime, this.userClock, this.challengeId, this.speedrunAttemptId, this.speedrunStage}): _moves = moves,_moveTimes = moveTimes;
  

@override final  String positionId;
/// Quando a partida terminou.
@override final  DateTime playedAt;
@override final  AttemptOutcome outcome;
/// O objetivo da posição foi cumprido.
@override final  bool fulfilled;
@override final  OpponentKind opponent;
/// O nível do Maia, quando ele foi o adversário.
@override final  int? opponentLevel;
/// Quando a partida começou. Nulo nas partidas de antes da Jornada.
@override final  DateTime? startedAt;
/// A posição em que a partida começou (FEN) e os lances (UCI). Vazios nas
/// partidas de antes da Jornada.
@override final  String? startFen;
 final  List<String> _moves;
@override@JsonKey() List<String> get moves {
  if (_moves is EqualUnmodifiableListView) return _moves;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_moves);
}

/// Quanto cada lance levou, na ordem de [moves] (o do jogador e o do
/// adversário). Vazio nas partidas de antes de isto ser gravado.
 final  List<Duration> _moveTimes;
/// Quanto cada lance levou, na ordem de [moves] (o do jogador e o do
/// adversário). Vazio nas partidas de antes de isto ser gravado.
@override@JsonKey() List<Duration> get moveTimes {
  if (_moveTimes is EqualUnmodifiableListView) return _moveTimes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_moveTimes);
}

/// O lado do jogador. Nulo nas partidas de antes de isto ser gravado.
@override final  Side? userSide;
/// Como a partida terminou (mate, tempo, desistência...).
@override final  GameEndReason? endReason;
/// O tempo do jogador e o do adversário. Nulos sem relógio.
@override final  TimeControl? userTime;
@override final  TimeControl? opponentTime;
/// Quanto o relógio do jogador gastou na partida. Nulo sem relógio.
@override final  Duration? userClock;
/// O desafio da Jornada, quando a partida foi um.
@override final  String? challengeId;
/// A tentativa de speedrun e a etapa (a partir de 0), quando a partida foi
/// uma etapa.
@override final  int? speedrunAttemptId;
@override final  int? speedrunStage;

/// Create a copy of Attempt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttemptCopyWith<_Attempt> get copyWith => __$AttemptCopyWithImpl<_Attempt>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Attempt&&(identical(other.positionId, positionId) || other.positionId == positionId)&&(identical(other.playedAt, playedAt) || other.playedAt == playedAt)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.fulfilled, fulfilled) || other.fulfilled == fulfilled)&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.opponentLevel, opponentLevel) || other.opponentLevel == opponentLevel)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.startFen, startFen) || other.startFen == startFen)&&const DeepCollectionEquality().equals(other.moves, _moves)&&const DeepCollectionEquality().equals(other.moveTimes, _moveTimes)&&(identical(other.userSide, userSide) || other.userSide == userSide)&&(identical(other.endReason, endReason) || other.endReason == endReason)&&(identical(other.userTime, userTime) || other.userTime == userTime)&&(identical(other.opponentTime, opponentTime) || other.opponentTime == opponentTime)&&(identical(other.userClock, userClock) || other.userClock == userClock)&&(identical(other.challengeId, challengeId) || other.challengeId == challengeId)&&(identical(other.speedrunAttemptId, speedrunAttemptId) || other.speedrunAttemptId == speedrunAttemptId)&&(identical(other.speedrunStage, speedrunStage) || other.speedrunStage == speedrunStage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,positionId,playedAt,outcome,fulfilled,opponent,opponentLevel,startedAt,startFen,const DeepCollectionEquality().hash(_moves),const DeepCollectionEquality().hash(_moveTimes),userSide,endReason,userTime,opponentTime,userClock,challengeId,speedrunAttemptId,speedrunStage);
}

@override
String toString() {
    return 'Attempt(positionId: $positionId, playedAt: $playedAt, outcome: $outcome, fulfilled: $fulfilled, opponent: $opponent, opponentLevel: $opponentLevel, startedAt: $startedAt, startFen: $startFen, moves: $moves, moveTimes: $moveTimes, userSide: $userSide, endReason: $endReason, userTime: $userTime, opponentTime: $opponentTime, userClock: $userClock, challengeId: $challengeId, speedrunAttemptId: $speedrunAttemptId, speedrunStage: $speedrunStage)';
}


}

/// @nodoc
abstract mixin class _$AttemptCopyWith<$Res> implements $AttemptCopyWith<$Res> {
  factory _$AttemptCopyWith(_Attempt value, $Res Function(_Attempt) _then) = __$AttemptCopyWithImpl;
@override @useResult
$Res call({
 String positionId, DateTime playedAt, AttemptOutcome outcome, bool fulfilled, OpponentKind opponent, int? opponentLevel, DateTime? startedAt, String? startFen, List<String> moves, List<Duration> moveTimes, Side? userSide, GameEndReason? endReason, TimeControl? userTime, TimeControl? opponentTime, Duration? userClock, String? challengeId, int? speedrunAttemptId, int? speedrunStage
});


@override $TimeControlCopyWith<$Res>? get userTime;@override $TimeControlCopyWith<$Res>? get opponentTime;

}
/// @nodoc
class __$AttemptCopyWithImpl<$Res>
    implements _$AttemptCopyWith<$Res> {
  __$AttemptCopyWithImpl(this._self, this._then);

  final _Attempt _self;
  final $Res Function(_Attempt) _then;

/// Create a copy of Attempt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? positionId = null,Object? playedAt = null,Object? outcome = null,Object? fulfilled = null,Object? opponent = null,Object? opponentLevel = freezed,Object? startedAt = freezed,Object? startFen = freezed,Object? moves = null,Object? moveTimes = null,Object? userSide = freezed,Object? endReason = freezed,Object? userTime = freezed,Object? opponentTime = freezed,Object? userClock = freezed,Object? challengeId = freezed,Object? speedrunAttemptId = freezed,Object? speedrunStage = freezed,}) {
  return _then(_Attempt(
positionId: null == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as String,playedAt: null == playedAt ? _self.playedAt : playedAt // ignore: cast_nullable_to_non_nullable
as DateTime,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as AttemptOutcome,fulfilled: null == fulfilled ? _self.fulfilled : fulfilled // ignore: cast_nullable_to_non_nullable
as bool,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as OpponentKind,opponentLevel: freezed == opponentLevel ? _self.opponentLevel : opponentLevel // ignore: cast_nullable_to_non_nullable
as int?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,startFen: freezed == startFen ? _self.startFen : startFen // ignore: cast_nullable_to_non_nullable
as String?,moves: null == moves ? _self._moves : moves // ignore: cast_nullable_to_non_nullable
as List<String>,moveTimes: null == moveTimes ? _self._moveTimes : moveTimes // ignore: cast_nullable_to_non_nullable
as List<Duration>,userSide: freezed == userSide ? _self.userSide : userSide // ignore: cast_nullable_to_non_nullable
as Side?,endReason: freezed == endReason ? _self.endReason : endReason // ignore: cast_nullable_to_non_nullable
as GameEndReason?,userTime: freezed == userTime ? _self.userTime : userTime // ignore: cast_nullable_to_non_nullable
as TimeControl?,opponentTime: freezed == opponentTime ? _self.opponentTime : opponentTime // ignore: cast_nullable_to_non_nullable
as TimeControl?,userClock: freezed == userClock ? _self.userClock : userClock // ignore: cast_nullable_to_non_nullable
as Duration?,challengeId: freezed == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String?,speedrunAttemptId: freezed == speedrunAttemptId ? _self.speedrunAttemptId : speedrunAttemptId // ignore: cast_nullable_to_non_nullable
as int?,speedrunStage: freezed == speedrunStage ? _self.speedrunStage : speedrunStage // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of Attempt
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res>? get userTime {
    if (_self.userTime == null) {
    return null;
  }

  return $TimeControlCopyWith<$Res>(_self.userTime!, (value) {
    return _then(_self.copyWith(userTime: value));
  });
}/// Create a copy of Attempt
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res>? get opponentTime {
    if (_self.opponentTime == null) {
    return null;
  }

  return $TimeControlCopyWith<$Res>(_self.opponentTime!, (value) {
    return _then(_self.copyWith(opponentTime: value));
  });
}
}

// dart format on
