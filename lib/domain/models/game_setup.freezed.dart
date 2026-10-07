// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_setup.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GameSetup {

 bool get clock;/// O tempo do jogador.
 TimeControl get userTime;/// O tempo do adversário (a máquina, quando houver).
 TimeControl get opponentTime; OpponentKind get opponent;/// O nível do Maia. Nulo: o sugerido pelo rating do perfil.
 int? get maiaLevel;/// Às cegas: os lances falados, digitados ou tocados, sem ver as peças.
 bool get blind;
/// Create a copy of GameSetup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameSetupCopyWith<GameSetup> get copyWith => _$GameSetupCopyWithImpl<GameSetup>(this as GameSetup, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GameSetup;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameSetup&&(identical(other.clock, _this.clock) || other.clock == _this.clock)&&(identical(other.userTime, _this.userTime) || other.userTime == _this.userTime)&&(identical(other.opponentTime, _this.opponentTime) || other.opponentTime == _this.opponentTime)&&(identical(other.opponent, _this.opponent) || other.opponent == _this.opponent)&&(identical(other.maiaLevel, _this.maiaLevel) || other.maiaLevel == _this.maiaLevel)&&(identical(other.blind, _this.blind) || other.blind == _this.blind));
}


@override
int get hashCode {
  final _this = this as GameSetup;
  return Object.hash(runtimeType,_this.clock,_this.userTime,_this.opponentTime,_this.opponent,_this.maiaLevel,_this.blind);
}

@override
String toString() {
  final _this = this as GameSetup;
  return 'GameSetup(clock: ${_this.clock}, userTime: ${_this.userTime}, opponentTime: ${_this.opponentTime}, opponent: ${_this.opponent}, maiaLevel: ${_this.maiaLevel}, blind: ${_this.blind})';
}


}

/// @nodoc
abstract mixin class $GameSetupCopyWith<$Res>  {
  factory $GameSetupCopyWith(GameSetup value, $Res Function(GameSetup) _then) = _$GameSetupCopyWithImpl;
@useResult
$Res call({
 bool clock, TimeControl userTime, TimeControl opponentTime, OpponentKind opponent, int? maiaLevel, bool blind
});


$TimeControlCopyWith<$Res> get userTime;$TimeControlCopyWith<$Res> get opponentTime;

}
/// @nodoc
class _$GameSetupCopyWithImpl<$Res>
    implements $GameSetupCopyWith<$Res> {
  _$GameSetupCopyWithImpl(this._self, this._then);

  final GameSetup _self;
  final $Res Function(GameSetup) _then;

/// Create a copy of GameSetup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clock = null,Object? userTime = null,Object? opponentTime = null,Object? opponent = null,Object? maiaLevel = freezed,Object? blind = null,}) {
  return _then(GameSetup(
clock: null == clock ? _self.clock : clock // ignore: cast_nullable_to_non_nullable
as bool,userTime: null == userTime ? _self.userTime : userTime // ignore: cast_nullable_to_non_nullable
as TimeControl,opponentTime: null == opponentTime ? _self.opponentTime : opponentTime // ignore: cast_nullable_to_non_nullable
as TimeControl,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as OpponentKind,maiaLevel: freezed == maiaLevel ? _self.maiaLevel : maiaLevel // ignore: cast_nullable_to_non_nullable
as int?,blind: null == blind ? _self.blind : blind // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of GameSetup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res> get userTime {
  
  return $TimeControlCopyWith<$Res>(_self.userTime, (value) {
    return _then(_self.copyWith(userTime: value));
  });
}/// Create a copy of GameSetup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res> get opponentTime {
  
  return $TimeControlCopyWith<$Res>(_self.opponentTime, (value) {
    return _then(_self.copyWith(opponentTime: value));
  });
}
}


/// Adds pattern-matching-related methods to [GameSetup].
extension GameSetupPatterns on GameSetup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameSetup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameSetup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameSetup value)  $default,){
final _that = this;
switch (_that) {
case _GameSetup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameSetup value)?  $default,){
final _that = this;
switch (_that) {
case _GameSetup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool clock,  TimeControl userTime,  TimeControl opponentTime,  OpponentKind opponent,  int? maiaLevel,  bool blind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameSetup() when $default != null:
return $default(_that.clock,_that.userTime,_that.opponentTime,_that.opponent,_that.maiaLevel,_that.blind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool clock,  TimeControl userTime,  TimeControl opponentTime,  OpponentKind opponent,  int? maiaLevel,  bool blind)  $default,) {final _that = this;
switch (_that) {
case _GameSetup():
return $default(_that.clock,_that.userTime,_that.opponentTime,_that.opponent,_that.maiaLevel,_that.blind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool clock,  TimeControl userTime,  TimeControl opponentTime,  OpponentKind opponent,  int? maiaLevel,  bool blind)?  $default,) {final _that = this;
switch (_that) {
case _GameSetup() when $default != null:
return $default(_that.clock,_that.userTime,_that.opponentTime,_that.opponent,_that.maiaLevel,_that.blind);case _:
  return null;

}
}

}

/// @nodoc


class _GameSetup implements GameSetup {
  const _GameSetup({this.clock = true, this.userTime = GameSetup.defaultTime, this.opponentTime = GameSetup.defaultTime, this.opponent = OpponentKind.fallback, this.maiaLevel, this.blind = false});
  

@override@JsonKey() final  bool clock;
/// O tempo do jogador.
@override@JsonKey() final  TimeControl userTime;
/// O tempo do adversário (a máquina, quando houver).
@override@JsonKey() final  TimeControl opponentTime;
@override@JsonKey() final  OpponentKind opponent;
/// O nível do Maia. Nulo: o sugerido pelo rating do perfil.
@override final  int? maiaLevel;
/// Às cegas: os lances falados, digitados ou tocados, sem ver as peças.
@override@JsonKey() final  bool blind;

/// Create a copy of GameSetup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameSetupCopyWith<_GameSetup> get copyWith => __$GameSetupCopyWithImpl<_GameSetup>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameSetup&&(identical(other.clock, clock) || other.clock == clock)&&(identical(other.userTime, userTime) || other.userTime == userTime)&&(identical(other.opponentTime, opponentTime) || other.opponentTime == opponentTime)&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.maiaLevel, maiaLevel) || other.maiaLevel == maiaLevel)&&(identical(other.blind, blind) || other.blind == blind));
}


@override
int get hashCode {
    return Object.hash(runtimeType,clock,userTime,opponentTime,opponent,maiaLevel,blind);
}

@override
String toString() {
    return 'GameSetup(clock: $clock, userTime: $userTime, opponentTime: $opponentTime, opponent: $opponent, maiaLevel: $maiaLevel, blind: $blind)';
}


}

/// @nodoc
abstract mixin class _$GameSetupCopyWith<$Res> implements $GameSetupCopyWith<$Res> {
  factory _$GameSetupCopyWith(_GameSetup value, $Res Function(_GameSetup) _then) = __$GameSetupCopyWithImpl;
@override @useResult
$Res call({
 bool clock, TimeControl userTime, TimeControl opponentTime, OpponentKind opponent, int? maiaLevel, bool blind
});


@override $TimeControlCopyWith<$Res> get userTime;@override $TimeControlCopyWith<$Res> get opponentTime;

}
/// @nodoc
class __$GameSetupCopyWithImpl<$Res>
    implements _$GameSetupCopyWith<$Res> {
  __$GameSetupCopyWithImpl(this._self, this._then);

  final _GameSetup _self;
  final $Res Function(_GameSetup) _then;

/// Create a copy of GameSetup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clock = null,Object? userTime = null,Object? opponentTime = null,Object? opponent = null,Object? maiaLevel = freezed,Object? blind = null,}) {
  return _then(_GameSetup(
clock: null == clock ? _self.clock : clock // ignore: cast_nullable_to_non_nullable
as bool,userTime: null == userTime ? _self.userTime : userTime // ignore: cast_nullable_to_non_nullable
as TimeControl,opponentTime: null == opponentTime ? _self.opponentTime : opponentTime // ignore: cast_nullable_to_non_nullable
as TimeControl,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as OpponentKind,maiaLevel: freezed == maiaLevel ? _self.maiaLevel : maiaLevel // ignore: cast_nullable_to_non_nullable
as int?,blind: null == blind ? _self.blind : blind // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of GameSetup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res> get userTime {
  
  return $TimeControlCopyWith<$Res>(_self.userTime, (value) {
    return _then(_self.copyWith(userTime: value));
  });
}/// Create a copy of GameSetup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeControlCopyWith<$Res> get opponentTime {
  
  return $TimeControlCopyWith<$Res>(_self.opponentTime, (value) {
    return _then(_self.copyWith(opponentTime: value));
  });
}
}

// dart format on
